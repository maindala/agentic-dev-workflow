<!--
Template: design-artifacts/<slug>.md
Save as: design-artifacts/<your-feature-slug>.md
Companion files use the same slug — see conventions/traceability.md.
-->

# <Feature Name>

**Status:** DESIGN ONLY — awaiting Gate 1 | Approved at Gate 1 (<date>) | Shipped (PR #<n>)

Written <date> in response to: *<one-line summary of the request that triggered this doc>*

---

## 1. The short answer

One or two sentences: what's being proposed, and the headline recommendation if there's a
non-obvious choice to make.

## 2. Context

What prompted this. Link to prior related work if any exists. If research or investigation changed
the shape of the proposal from how it was first framed, say so plainly here — that correction is
often the most valuable part of the document.

## 3. Proposed approach

The actual design. Be concrete: what changes, where, and why this shape rather than an alternative.

## 4. What's explicitly out of scope

Say what you're *not* doing and why, especially if it looks like an obvious extension. This is what
keeps scope from creeping silently during the build.

## 5. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| ... | ... | ... |

## 6. Phasing (if applicable)

Break the work into independently shippable phases. Each phase should be small enough to build,
review, and ship on its own.

## 7. Decisions needed at Gate 1

Numbered list of the actual open questions a reviewer needs to answer before code gets written.
Don't bury a real decision inside prose — pull it out here so it can't be missed.

---

## Build Notes

*(Filled in during and after the build — not before. This section is the whole point of writing
the design down in the first place: a design that survives contact with the real system unchanged
is rare, and recording exactly where it didn't is what makes the next design better.)*

For each phase, once built:
- What was built, in one paragraph.
- **Where the design turned out to be wrong**, and what was actually done instead. Be specific about
  root cause, not just "we changed X to Y" — future readers need the *why* it broke, not just the
  patch.
- How it was verified (tests written, manual checks performed, what wasn't possible to verify and
  why).
- What's genuinely not done yet, versus what's out of scope entirely.

---

## Changelog

- **<date>** — Initial design.
- **<date>** — Gate 1 approved / revised / etc.
