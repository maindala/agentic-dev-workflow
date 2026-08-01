# Traceability

The three artifact documents for a feature (design, user stories, QA test cases) are only useful as
a set if you can move between them without hunting. Two rules make that automatic.

## 1. One basename, three directories

Pick a short, stable slug for the feature (e.g. `csv-export-scheduling`) and use it as the
filename, unchanged, in all three locations:

```
design-artifacts/<slug>.md
story-artifacts/design/<slug>.md
qa-test-cases/<slug>.md
```

(Directory names are a suggestion — the point is that the three live in parallel locations under one
name, not that these exact paths are required.)

Never rename one without renaming the other two in the same change. If a design doc gains a new
phase (P2, P3, ...), update the existing files in place rather than creating `<slug>-p2.md` — the
whole point is that there is exactly one place to look.

## 2. Prefixed, numbered story IDs

Each user-stories document uses a short prefix (2–5 letters, derived from the slug) followed by a
number: `CES-1`, `CES-2`, `WNP-3`. This does two things:

- **Collision-proofing.** If multiple people or agents are writing story files in parallel, IDs
  never clash across files, because the prefix is unique to the doc.
- **A stable anchor for QA test cases.** Each test case in the QA doc references the story ID(s) it
  covers (`**Covers:** CES-1`), so a reviewer can trace design → story → test case in one direction
  without cross-referencing by title or line number, which drifts.

## 3. Status lines carry the real state

Every story gets a `**Status:**` line, and it is the single source of truth for whether that piece
of the design actually shipped:

```
**Status:** Shipped (PR #142)
**Status:** Partial — phase 1 of 3 shipped (PR #140)
**Status:** Not Started
```

Update this line as part of the same change that ships the work — not as a separate cleanup pass
later, which is how status lines rot into fiction. A `grep`-able set of Status lines across all your
story docs is a cheap, accurate feature inventory, but only if it's kept current in the same commit
as the thing it describes.

## For non-engineering design docs

Not every design doc describes software. For a positioning doc, a messaging pass, or a strategy
write-up, "test cases" become a review checklist instead of a functional test — same ID format,
same `Covers:` linkage, but `**Automation:** Not automatable (content/strategy review)` throughout.
The traceability discipline is still worth keeping even when there's no code to test.
