# 0xb105

Personal security lab and blog by Catherine Li.

The site publishes CTF writeups, cybersecurity research, Linux kernel patch notes, CVE analysis, and open-source side projects.

Production URL: <https://blog.0xb105.com>

Repository: `git@github.com:Lyther/0xb105-blog.git`

GitHub profile: <https://github.com/Lyther>

## Requirements

- Zola `0.22.1`
- Git submodules

Run `make install-zola` to install the pinned Zola binary into `.bin/` when `zola` is not already available.

## Commands

```bash
git submodule update --init --recursive
make dev
make lint
make build
```

`make dev` serves the site locally with drafts enabled. `make lint` runs `zola check`. `make build` writes the generated site to `public/`.

## Deployment

GitHub Pages deploys from `.github/workflows/pages.yml` on pushes to `main`.

Set the GitHub Pages source to GitHub Actions, then configure DNS:

```text
blog.0xb105.com  CNAME  lyther.github.io
```

`static/CNAME` keeps the custom domain attached after each deploy.

## Structure

- `content/`: posts and pages (primary site source; not a separate `src/` app tree)
- `content/ctf/`: CTF writeups
- `content/research/`: cybersecurity research
- `content/kernel/`: Linux kernel patch notes
- `content/cve/`: CVE analysis
- `content/projects/`: side projects
- `themes/terminimal/`: pinned theme submodule
- `templates/`, `sass/`, `static/`: project-specific theme overrides
- `scripts/`: Zola install helper for local/CI
- `static/CNAME`: GitHub Pages custom domain
- `docs/context/`: raw planning context
- `public/`: generated output, ignored by git
