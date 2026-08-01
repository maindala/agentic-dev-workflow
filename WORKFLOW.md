# The Workflow

An 11-step cycle for every substantive piece of work, with exactly two points where a human must
explicitly say "go ahead" and nothing else. Everything else is autonomous by design — the agent
should not be stopping to ask permission for routine, reversible steps, because that defeats the
point of using one. This document describes the cycle generically; adapt the artifact locations and
any project-specific detail (deploy commands, service names) to your own repo.

## Front half — design and approval

1. **Recall context.** Before starting, the agent should surface whatever it already knows about
   this area — prior decisions, known gotchas, related work in flight. If you're using an external
   memory tool, this is where it fires; if not, this is a quick read of your own project's docs and
   recent history.
2. **Write three linked artifact documents**, all under one shared basename so they can be found and
   cross-referenced later:
   - A **design doc** — architecture *and* the phased build plan in one document, not two. See
     `templates/design-artifact.md`.
   - A **user stories doc** — the acceptance criteria a reviewer will actually check against. See
     `templates/user-stories.md`.
   - A **QA test cases doc** — test cases that trace back to specific story IDs. See
     `templates/qa-test-cases.md`.

   See `conventions/traceability.md` for the naming and ID rules that make these three documents
   actually traceable to each other, rather than three unrelated files that happen to describe the
   same feature.
3. **⛔ Gate 1 — design and plan approval.** Present the plan. Stop, and wait for an explicit
   go-ahead before writing any code. This is not a formality: a design that turns out to rest on a
   bad premise is far cheaper to catch here than after it's built. If the person reviewing pushes
   back, that's the gate working as intended, not friction to route around.

## Back half — build, self-review, ship (autonomous until the second gate)

4. **Implement**, but only after Gate 1 has actually been granted. Don't start speculatively while
   waiting for a response.
5. **Build and verify locally.** Whatever "the code compiles and does what it says" means for your
   stack — run it before treating anything as done.
6. **Self-review the diff.** Read your own change as if reviewing someone else's pull request,
   against the acceptance criteria written in step 2. Run lint, type-checks, and tests end to end.
   This step should not require a second agent or a human in the loop to happen — an agent that
   can build the thing can also read its own diff critically.
7. **Open a pull request.** Never push directly to the default branch, even for something that feels
   trivial. The PR is also where the design/story/QA documents get referenced, so a future reader can
   trace the change back to why it was made.
8. **⛔ Gate 2 — ship approval.** Stop, and wait for an explicit go-ahead before merging or deploying
   anything. Nothing lands until this is granted. **This gate should be enforced mechanically, not
   just written down** — see `hooks/ship-gate.sh`. A hook that forces a confirmation prompt on any
   merge or deploy command holds even if the agent is running with broad standing permissions,
   which prompt text alone does not.
9. **On approval: merge, then ship.** Whatever "ship" means for your project — deploy a service,
   publish a package, cut a release.

## After shipping

10. **Update the status record.** Whatever tracks what's actually live and why in your project — a
    changelog, a deploy-state table, a release doc — update it as part of the cycle, not as an
    afterthought. This is what keeps a status document trustworthy instead of stale.
11. **Persist anything durable to memory.** Decisions, corrections, and non-obvious context that a
    future session (yours or someone else's) will need and can't easily re-derive from the code or
    git history. See `memory/README.md` for what's worth keeping and what isn't.

## Why two gates and not zero or five

Zero gates means an agent with broad tool access can ship something wrong before anyone notices.
Five gates means the human becomes a rubber stamp on every trivial step, which trains them to stop
reading — the worst outcome, because the one time it matters, they wave it through anyway. Two gates
— one before any code is written, one before anything ships — put the human's attention exactly
where a wrong call is expensive to reverse, and nowhere else.
