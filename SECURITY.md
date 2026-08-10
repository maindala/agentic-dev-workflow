# Security Policy

## Scope

This repository publishes a development *method* — shell hooks, Markdown templates, and CI/Action
tooling for a two-gate agentic dev workflow. There is no server, no hosted service, and no runtime
that processes user data. The realistic security surface is narrow:

- `hooks/*.sh` — shell scripts a downstream project installs as Claude Code hooks. A defect here
  could mean a gate that should block a command silently doesn't (see the fail-mode discussion in
  `ship-gate.sh`'s own comments and the README's enforcement-boundary section).
- `.github/actions/gate-check/` — a composite GitHub Action a downstream project's CI calls. A
  defect here could mean a PR that should fail a traceability check silently passes.
- Third-party GitHub Actions referenced from this repo's own workflows.

## Reporting a vulnerability

Email **it@maindala.com** with a description of the issue and, if possible, steps to reproduce.
Please do not open a public GitHub issue for a security report before it has been triaged.

You should get an acknowledgment within **5 business days**. We'll aim to give you a rough
timeline for a fix once the report is confirmed. There is no bug-bounty program.

## Supported versions

This repository does not currently tag or version releases — `main` is the supported line. If
versioned releases are introduced later, this section will be updated to state which lines
receive fixes.

## What's out of scope

- Vulnerabilities in the downstream Claude Code harness itself, or in third-party tools this repo
  merely documents integrating with (e.g. `mnemon`).
- Reports that assume a hook has not been reviewed before installation. Every hook here runs with
  the permissions of whoever installs it — read `hooks/README.md` and the script itself before use,
  the same way you would with any shell script from the internet.
