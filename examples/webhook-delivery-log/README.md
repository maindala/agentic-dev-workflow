# Worked example — Webhook Delivery Log

A complete artifact triad for one feature, showing what this method actually produces.

## What this is, precisely

**The bug is real. The system is invented.**

The cursor bug documented in `design-artifact.md` genuinely happened, was genuinely missed at design
time, and was genuinely caught during the build. But it's been rewritten into a fictional
webhook-delivery-log feature, because the lesson doesn't depend on whose system it happened in — and
a document that never contained anything internal can't leak anything by accident.

That's a deliberate choice worth stating, since the obvious alternative was to publish a real
internal document with the sensitive parts stripped out. Redaction requires correctly listing every
sensitive token up front, and the ones you miss are the ones that didn't look sensitive. Rebuilding
removes the problem instead of managing it.

So: treat the feature as illustrative. Treat the failure, the fix, and the reasoning as real.

## The three files

| File | What to look at |
|---|---|
| [`design-artifact.md`](design-artifact.md) | **Read the Build Notes section first.** Everything above it is a design that turned out to be subtly wrong |
| [`user-stories.md`](user-stories.md) | `WDL-1`…`WDL-4`, each with acceptance criteria and a `Status:` line carrying its PR |
| [`qa-test-cases.md`](qa-test-cases.md) | `WDL-TC1`…`WDL-TC6`, each declaring which story it `Covers:` |

All three share the basename `webhook-delivery-log` and cross-reference by ID, per
[`../../conventions/traceability.md`](../../conventions/traceability.md). In a real project they'd
live in three parallel directories; they're collected in one folder here so the example reads as a
unit.

## Why this example was chosen

Because the design was **wrong in a way that testing wouldn't obviously catch**. The endpoint
returned correct data. Every row it returned was real. Nothing errored. It just also returned some
rows over and over, forever — and you'd only notice by watching output scroll past for long enough
to recognise it repeating.

That's the class of bug this method exists to surface: not a crash, but a design assumption that
looked fine on paper and quietly didn't hold. The Build Notes section is where it gets written down,
and it's the part most often missing from published design templates.

## What to take from it

1. **Build Notes is the point.** A design doc that only records what you intended is a historical
   curiosity. One that records where you were wrong is a debugging aid for the next person.
2. **The acceptance criteria are checkable.** "Polling twice never returns the same entry twice" is
   testable. "Pagination works correctly" isn't.
3. **Status lines carry PR numbers**, so the triad stays an accurate inventory rather than drifting
   into fiction.
4. **The tradeoff is recorded, not just the fix.** Knowing *why* duplicates were chosen over gaps
   matters more later than knowing which line changed.
