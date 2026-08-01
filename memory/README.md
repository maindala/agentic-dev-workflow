# Memory

An agent that starts every session from zero re-derives decisions it already made, re-litigates
choices you already settled, and misses context only a prior session had. Persistent memory fixes
that — but only if you're disciplined about what goes in, since a memory store full of noise is
worse than no memory at all: it buries the few facts that matter under restatements of things
already obvious from the code.

This works with **plain files and no external tooling.** An external memory tool (see below) is an
accelerator on top of this, not a prerequisite for it.

## The file-based convention

One fact per file, plus an index.

**`MEMORY.md`** — an index, not a memory. Each line is one entry, under ~150 characters:
`- [Title](file.md) — one-line hook`. Nothing else goes in this file; it exists so a session can
scan it quickly without opening every underlying file.

**Individual memory files** — one topic per file, with frontmatter:

```markdown
---
name: short-kebab-case-slug
description: one-line summary, specific enough to judge relevance later
metadata:
  type: preference | decision | fact | reference
---

The actual content. Link related memories with [[other-slug]] — a link to a slug that doesn't exist
yet is fine, it marks something worth writing later, not an error.
```

Four types cover most of what's worth keeping:

- **preference** — durable guidance about *how* to work: corrections you've given, and approaches
  you've confirmed worked. Record both directions — only recording corrections drifts an agent away
  from approaches you already validated.
- **decision** — a non-trivial conclusion reached during a session, or an architectural choice, that
  isn't obvious from reading the code afterward.
- **fact** — durable context about the project that no amount of reading the current code would
  recover (a migration history, a reason something is shaped the way it is).
- **reference** — a pointer to where up-to-date information lives externally (an issue tracker, a
  dashboard, a specific channel) rather than the information itself.

## What's worth storing (and what isn't)

Bias toward storing when genuinely uncertain — a low-value memory is cheap; a missing one is not.
But three things should never end up here, because they're cheaply recoverable elsewhere and rot
fast if duplicated:

- Anything derivable by reading the current code (patterns, file structure, architecture as it
  exists today).
- Anything git history already answers (who changed what, when, why — that's `git log`/`git blame`'s
  job).
- In-progress task state that belongs to the current conversation, not future ones.

A rough calibration for how much weight to give something: an explicit correction or confirmed
preference, a hard-won architectural conclusion, or project context nobody could re-derive — keep
it. A passing preference or a topic someone's currently exploring — worth a lighter-weight note. A
detail that's merely nice for conversational continuity — optional, and the first thing to skip
under time pressure.

## Optional accelerator: mnemon

[mnemon](https://github.com/mnemon-dev/mnemon) (Apache-2.0) is a third-party CLI that implements
this same idea — searchable, graph-linked memory — as a local daemon instead of plain files. It is
**not part of this repo, not required, and not ours** — if you use it, treat `hooks/memory-*.sh` as
optional wiring on top of the file-based convention above, not a replacement for it. The workflow in
`WORKFLOW.md` works identically with plain files, an mnemon-style tool, or nothing at all beyond
occasionally re-reading `MEMORY.md`.
