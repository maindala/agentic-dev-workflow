# Agentic Dev Workflow

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

## What this is not

This is not a claim that AI-DLC originated here, that this repo is a general-purpose agent
framework, or that any particular tool stack is required. It's a small, opinionated set of
documents and one shell script, published because the enforcement pattern in `ship-gate.sh` seemed
worth sharing on its own.

## License

MIT — see [`LICENSE`](LICENSE).
