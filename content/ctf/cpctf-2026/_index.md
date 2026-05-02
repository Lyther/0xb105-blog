+++
title = "CPCTF 2026 — Full AK"
description = "Complete writeup series for CPCTF 2026, all 54 challenges solved. Each entry is rewritten as a deep technology tutorial: vulnerability class, primitive, exploit, hardening, and references."
sort_by = "date"
paginate_by = 20
template = "index.html"
page_template = "page.html"
transparent = false

[extra]
section_description = "All 54 CPCTF 2026 challenges, AK'd, then expanded into tutorials worth reading on their own."
+++

CPCTF is the annual capture-the-flag and competitive-programming event run by [traP](https://trap.jp/), the programming circle at the Tokyo Institute of Technology. The 2026 edition fielded 54 challenges across nine categories: **Misc, Crypto, Reversing, Pwn, Forensics, PPC** (competitive programming), **Web, Shell, OSINT**. This series is a full **All Killed (AK)** writeup — every challenge solved — but rewritten so each entry stands on its own as a tutorial in the underlying technology, not just a solver dump.

## What "AK" means here

AK = "All Killed" = every challenge solved with first-blood-quality solutions, not just blind brute force. For each challenge I publish:

- **Vulnerability class or technique** — the named pattern (stack overflow, padding oracle, SSRF, prototype pollution, segment tree, …) so the article is searchable by the thing it teaches.
- **Background tutorial** — enough theory that a reader unfamiliar with the class can follow without leaving the page.
- **Static or dynamic analysis** of the artifact — source walk, decompilation notes, traffic capture, whatever applies.
- **Exploit / solution** — minimal working payload and a fully reproducible solver script.
- **Defensive takeaway** — how the bug class is prevented in production, with concrete mitigations and example secure code.
- **References** — primary sources, papers, tooling, related CVEs.

## Index

| # | Challenge | Category | Lv. | Score | Writeup |
|---|---|---|---|---|---|
| 01 | Sanity Check | Misc | 1 | 10.00 | pending |
| 02 | Dualcast | Crypto | 1 | 10.00 | pending |
| 03 | Hidden | Reversing | 1 | 10.00 | pending |
| 04 | Killionaire | Pwn | 1 | 10.00 | pending |
| 05 | L0v3 PDF | Forensics | 1 | 10.00 | pending |
| 06 | Modulo Equation | PPC | 1 | 10.00 | pending |
| 07 | mirage | Web | 1 | 10.00 | pending |
| 08 | ssh (welcome cli) | Shell | 1 | 10.00 | pending |
| 09 | Sign up for traP | PPC | 1 | 10.00 | pending |
| 10 | 01 String | PPC | 2 | 150.02 | pending |
| 11 | I Love DAG | PPC | 2 | 131.93 | pending |
| 12 | Digit Products 2 | PPC | 3 | 216.61 | pending |
| 13 | GCD Knapsack | PPC | 3 | 227.40 | pending |
| 14 | Bracket Stack Query 2 | PPC | 2 | 169.87 | pending |
| 15 | Insert Maze | PPC | 3 | 257.22 | pending |
| 16 | All Distance is Square Number | PPC | 4 | 354.32 | pending |
| 17 | RangeSum RangeUpdate RangeSqrt | PPC | 4 | 400.81 | pending |
| 18 | OR Mapping | PPC | 4 | 400.81 | pending |
| 19 | Sum of Prod of Root | PPC | 3 | 344.19 | pending |
| 20 | RPS Eliminations | PPC | 5 | 444.39 | pending |
| 21 | Get More Money | PPC | 5 | 444.39 | pending |
| 22 | Buffer Visualizer | Pwn | 2 | 50.00 | [→](@/ctf/cpctf-2026/buffer-visualizer.md) |
| 23 | Flag in Flags | Forensics | 2 | 50.00 | pending |
| 24 | Hidden Recipe | Web | 2 | 50.00 | pending |
| 25 | Let's remove script tag | Web | 2 | 138.97 | pending |
| 26 | Secret Recipe | Forensics | 2 | 142.59 | pending |
| 27 | PENGUIN | OSINT | 2 | 142.59 | pending |
| 28 | Janken Master | Crypto | 3 | 221.93 | pending |
| 29 | mod N Janken | Crypto | 5 | 257.22 | pending |
| 30 | QRRRRRRRRRR | Misc | 3 | 364.98 | pending |
| 31 | Bitwise Scrumble | Crypto | 4 | 138.97 | pending |
| 32 | 1, 0, 7 | Crypto | 3 | 115.34 | pending |
| 33 | Anomaly 2 | Crypto | 3 | 128.50 | pending |
| 34 | Hello LaTeX3 | Misc | 3 | 153.83 | pending |
| 35 | CPCTF jail | Shell | 3 | 165.74 | pending |
| 36 | Out of World | Reversing | 3 | 157.73 | pending |
| 37 | campaign | Pwn | 3 | 227.40 | pending |
| 38 | credentials | Forensics | 3 | 142.59 | pending |
| 39 | digest | Forensics | 3 | 201.42 | pending |
| 40 | Damaged Report | Misc | 4 | 292.21 | pending |
| 41 | tar me | Web | 3 | 250.90 | pending |
| 42 | CPCTF Market | Web | 4 | 400.81 | pending |
| 43 | Template Playground | Web | 4 | 308.10 | pending |
| 44 | coding agent | Pwn | 4 | 263.75 | pending |
| 45 | Physical CTF | Web | 5 | 284.71 | pending |
| 46 | diary | Pwn | 5 | 316.54 | pending |
| 47 | Omikuji | Reversing | 2 | 77.65 | pending |
| 48 | Very Exciting | Crypto | 2 | 97.07 | pending |
| 49 | Z | Web | 2 | 112.18 | pending |
| 50 | ssh2 | Shell | 2 | 57.52 | pending |
| 51 | viGor | Reversing | 4 | 244.76 | pending |
| 52 | Authorized Whale | Forensics | 5 | 376.23 | pending |
| 53 | IRIS OUT | OSINT | 2 | 94.18 | pending |
| 54 | Night View | OSINT | 3 | 216.61 | pending |

## Notes on style

The terse "challenge → trick → flag" format is fine for a private scoreboard, but it doesn't survive search engines and it doesn't help a reader who hasn't seen the bug class before. Each entry in this series is rewritten so it reads like a chapter, not a tweet — the kind of writeup I wish more events left behind.
