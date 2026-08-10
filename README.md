# Agentic Dev Workflow

[![CI](https://github.com/maindala/agentic-dev-workflow/actions/workflows/ci.yml/badge.svg)](https://github.com/maindala/agentic-dev-workflow/actions/workflows/ci.yml)

A two-gate development workflow for building software with an AI coding agent (Claude Code, or
similar), plus the artifact templates, traceability conventions, and enforcement tooling that make
it stick.

## Lineage

This is an implementation of **AWS's AI-Driven Development Lifecycle (AI-DLC)** for Claude Code — not
an alternative to it, and not something we invented. AI-DLC was introduced by Raja SP in
[an AWS DevOps blog post](https://aws.amazon.com/blogs/devops/ai-driven-development-life-cycle/) on
31 July 2025, and AWS open-sourced its workflow rules as
[`awslabs/aidlc-workflows`](https://github.com/awslabs/aidlc-workflows) (MIT-0) that November. If you
want the canonical methodology, start there.

What's here is a working adaptation of that methodology, refined over roughly a year of real use
running an AI coding agent against a production codebase — about 60 features shipped through it,
producing roughly 274,000 words of design/story/QA artifacts along the way. It adds three things we
found we needed that a generic workflow description doesn't give you on its own:

1. **A gate that's actually enforced, not just written down.** [`hooks/ship-gate.sh`](hooks/ship-gate.sh)
   is a Claude Code `PreToolUse` hook: it inspects every shell command the agent is about to run, and
   if the command would merge a pull request or run a deploy, it forces a human confirmation prompt —
   **even when the agent is running in an auto-accept permission mode.** A workflow gate that's only
   prompt text is a gate the agent can talk itself past under enough pressure or ambiguity; a gate
   backed by the harness resists that specific failure mode. It's not unconditional — the hook can
   still be disabled or edited by whoever controls the environment it runs in, and it depends on `jq`
   being installed — but it **fails closed**: if it can't parse its input, can't find `jq`, or its
   configured pattern doesn't compile, it asks rather than silently allowing.
2. **Persistent memory in the loop**, so an agent starting a new session recalls prior decisions
   instead of re-deriving or re-litigating them. See [`memory/README.md`](memory/README.md).
3. **A living status ledger** — a single place that records what's actually shipped, by whom, and
   why, updated as a mandatory step of every cycle rather than left to drift from reality.

## The workflow

Full description: [`WORKFLOW.md`](WORKFLOW.md). In short: write three linked artifact documents
(design, user stories, QA test cases) before any code is touched; get an explicit human go-ahead
(**Gate 1**); build and self-review autonomously; open a pull request; get a second explicit
human go-ahead before anything merges or deploys (**Gate 2**). Everything between the two gates is
autonomous — that's the whole point of using an agent — but nothing crosses either gate without a
human saying so.

## Traceability

Design docs, user stories, and QA test cases share one basename and reference each other by ID, so
you can trace a shipped feature from its architecture through its acceptance criteria to its test
coverage in one direction. See [`conventions/traceability.md`](conventions/traceability.md) and the
matching templates in [`templates/`](templates/).

## Enforcing the gates in CI

`ship-gate.sh` enforces Gate 2 inside an agent session. It has nothing to say about a PR that
never went through an agent session at all, or a merge from a machine where the hook was never
installed — that requires repository-level enforcement, not a local script:

- **[`.github/actions/gate-check`](.github/actions/gate-check/)** — a reusable composite Action
  that checks a pull request's traceability triad is present (design + user-stories + QA files
  sharing one basename, per [`conventions/traceability.md`](conventions/traceability.md)) and that
  the QA file references at least one story ID the stories file declares. It's wired into this
  repo's own [`.github/workflows/gate-check.yml`](.github/workflows/gate-check.yml), which doubles
  as reference wiring for adopting it elsewhere — either copy that workflow or reference the action
  directly as `maindala/agentic-dev-workflow/.github/actions/gate-check@<pinned-sha-or-tag>`.
- **[`templates/CODEOWNERS.example`](templates/CODEOWNERS.example)** — a starting-point
  `CODEOWNERS` file routing review of the gate/CI files themselves and of design artifacts to
  named owners.
- **[`conventions/branch-protection.md`](conventions/branch-protection.md)** — the manual GitHub
  repository settings (required status checks, required CODEOWNERS review, no admin bypass, and a
  note on why merge-commit identity matters) that make the gate-check Action and CODEOWNERS file
  actually binding rather than advisory.

### What CI enforcement does not cover

Read this section against the actual code, not just the description above — it's here so nobody
adopts this expecting more than it delivers:

- **No immutable audit storage.** The gate-check Action's output lives in GitHub Actions run logs,
  which are ordinary logs — retained per your plan's normal retention window, editable/deletable by
  anyone with admin on the repo, and not a tamper-evident or append-only record of any kind.
- **No identity integration.** Enforcement is scoped to GitHub accounts and GitHub's own
  permission model (CODEOWNERS, branch protection, required reviewers). There is no SSO, SAML, or
  external identity-provider binding, and no proof that the GitHub account approving a PR is who it
  claims to be beyond GitHub's own authentication.
- **No organization-wide reporting.** Each repo's gate-check run and branch-protection rule are
  local to that repo. There is no dashboard, aggregation, or cross-repo compliance view — if you
  need one, you build it against the GitHub API yourself.
- **`ship-gate.sh` is still just a local hook.** It can be disabled, edited, or skipped by whoever
  controls the environment it runs in (uninstall the hook, edit `settings.json`, or run the command
  outside an agent session entirely). CI enforcement narrows that gap for the merge/deploy path
  specifically — a PR without a complete traceability triad can be made to fail its required check
  regardless of what any local hook did or didn't catch — but it does not make the hook itself
  tamper-proof, and it enforces *traceability*, not the ship-gate's actual subject (that a human
  approved the merge/deploy).
- **The gate-check Action checks structure, not content.** It confirms three files exist and
  cross-reference by ID. It has no opinion on whether the acceptance criteria are any good, whether
  the QA cases were actually executed, or whether the design itself makes sense.
- **Branch protection has an admin escape hatch by default.** GitHub's "allow bypass" and
  "administrators can bypass" settings are opt-out, not opt-in absent — see
  `conventions/branch-protection.md` for the specific settings to disable, and note that disabling
  them is a manual step this repo cannot perform for you.

## Worked example

[`examples/webhook-delivery-log/`](examples/webhook-delivery-log/) is a complete filled-in triad —
design, stories, and test cases for one feature. It's there mainly for its **Build Notes** section,
which records a cursor-pagination design that turned out to be subtly wrong: the endpoint returned
correct data, errored on nothing, and quietly re-returned the same rows on every poll forever.
Recording that kind of finding is the part of this method that pays for the rest of it.

The bug is real; the feature it's set in is invented.

## Quick start

1. Copy `templates/design-artifact.md`, `templates/user-stories.md`, and `templates/qa-test-cases.md`
   into your own docs directory, using one shared basename per feature.
2. Install `hooks/ship-gate.sh` as a `PreToolUse` hook in your Claude Code `settings.json` — see
   [`hooks/README.md`](hooks/README.md).
3. Optionally wire up the memory convention in [`memory/README.md`](memory/README.md). It works with
   plain files; an external memory tool is an accelerator, not a requirement.
4. Follow the cycle in `WORKFLOW.md`.
5. Optionally, wire up [`.github/actions/gate-check`](.github/actions/gate-check/) and
   [`conventions/branch-protection.md`](conventions/branch-protection.md) so the traceability gate
   holds at the repository level, not only in your own local hook.

## What this is not

This is not a claim that AI-DLC originated here, that this repo is a general-purpose agent
framework, or that any particular tool stack is required. It's a small, opinionated set of
documents and one shell script, published because the enforcement pattern in `ship-gate.sh` seemed
worth sharing on its own.

## License

MIT — see [`LICENSE`](LICENSE).
