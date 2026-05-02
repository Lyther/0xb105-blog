# Architecture

Zola builds Markdown from `content/` with the `terminimal` git submodule at `themes/terminimal`. There is no application `src/` tree; site source is `content/` plus optional overrides.

Overrides live in `templates/`, `sass/`, and `static/`. Generated output is `public/` (untracked).

Top-level content lanes are `ctf`, `research`, `kernel`, `cve`, and `projects`. Each lane is transparent so posts can appear in the root feed and archive while keeping stable lane URLs.

Verification: `make lint` runs `zola check`; `make build` produces `public/`.
