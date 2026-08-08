<!--
Worked example — companion to design-artifact.md in this directory.
The feature is invented; see README.md.
-->

# Webhook Delivery Log — User Stories

Source design: `design-artifact.md`
Last updated: 2026-03-14

## Personas

| Actor | Description |
|---|---|
| Integrator | Built the endpoint receiving our webhooks; debugging why it isn't working |
| Support engineer | Fields "did the webhook fire?" tickets; currently answers them by hand |
| On-call engineer | Needs to tell "our delivery failed" apart from "their endpoint rejected it" |

---

### WDL-1 — See recent delivery attempts
**As an** integrator, **I want to** list recent webhook delivery attempts for my account, **so that**
I can tell whether a webhook was sent without opening a support ticket.

**Acceptance Criteria:**
- `GET /deliveries` returns attempts for the authenticated account only.
- Each attempt shows endpoint URL, response status, duration, attempt number, and timestamp.
- Results are ordered oldest to newest.
- Response bodies are never included.
- An account with no attempts gets an empty list, not an error.

**Priority:** Must Have
**Status:** Shipped (PR #218)

---

### WDL-2 — Page through attempts without gaps or repeats
**As an** integrator, **I want** pagination that behaves correctly while new attempts are arriving,
**so that** I can read the full history without missing entries or seeing them twice.

**Acceptance Criteria:**
- `?since=<cursor>` returns only attempts after the cursor position.
- Each response carries a `nextCursor` for the following request.
- **Polling twice in succession never returns the same attempt twice** to the caller.
- **No attempt is ever skipped**, including when several share a timestamp.
- New attempts arriving mid-page do not shift or duplicate results.
- The cursor is opaque — clients never parse it.

**Priority:** Must Have
**Status:** Shipped (PR #218) — the first implementation satisfied "no gaps" but violated "no
repeats"; see the design doc's Build Notes for the cause and the fix.

---

### WDL-3 — Watch attempts live
**As an** integrator, **I want** a `deliveries tail` command that streams attempts as they happen,
**so that** I can deploy a fix and immediately watch the next attempt land.

**Acceptance Criteria:**
- `deliveries tail` polls and prints new attempts as they arrive.
- Each line shows timestamp, endpoint, status, and duration.
- Failed attempts are visually distinct from successful ones.
- Ctrl+C exits cleanly.
- An attempt already printed is never printed again, even if the API returns it more than once.

**Priority:** Must Have
**Status:** Shipped (PR #223)

---

### WDL-4 — Filter to the endpoint I care about
**As an** on-call engineer, **I want to** filter attempts by endpoint and status, **so that** I can
isolate one failing integration during an incident.

**Acceptance Criteria:**
- `?endpoint=` filters to a single configured endpoint.
- `?status=failed` returns only non-2xx attempts.
- Filters compose with each other and with `?since=`.
- An unknown endpoint returns an empty list, not an error.

**Priority:** Should Have
**Status:** Not Started — P3
