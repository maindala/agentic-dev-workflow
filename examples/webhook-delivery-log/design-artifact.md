<!--
Worked example. The bug described in Build Notes is real; the webhook-delivery-log feature it is
set in is invented. See README.md in this directory.
-->

# Webhook Delivery Log

**Status:** Shipped (PR #218)

Written 2026-03-02 in response to: *"customers keep opening tickets asking whether we actually sent
their webhook — they have no way to see it themselves."*

---

## 1. The short answer

Expose the delivery attempts we already record, through a read-only API with cursor pagination, plus
a `deliveries tail` command in the CLI so customers can watch attempts live while they debug.

No new storage. Every attempt is already written to the delivery-attempts table for internal
retry accounting — this is a read surface over data we have.

## 2. Context

Support gets a recurring ticket: *"did the webhook fire?"* Answering it currently means an engineer
querying the attempts table by hand. The data is complete and already retained for 30 days; there is
simply no customer-facing way to see it.

The common case is a customer debugging their own endpoint in real time — deploying a fix, then
wanting to see the next attempt land. That makes live tailing the primary interaction, not an
afterthought, and it's what pushes this toward a cursor rather than offset pagination.

## 3. Proposed approach

**`GET /deliveries`** — returns attempts for the authenticated account, newest last, with:

- `?since=<cursor>` — opaque cursor; returns only attempts after it
- `?limit=` — default 50, max 200
- Response includes a `nextCursor` the client passes back on the following request

**Cursor format.** An opaque base64 string encoding `(attemptedAt, id)`. Ordering is
`ORDER BY attempted_at, id`, and the filter is the tuple comparison
`(attempted_at, id) > (cursor.attemptedAt, cursor.id)`. The `id` tiebreak is there because two
attempts can share a timestamp, and a timestamp-only cursor would either skip or repeat them.

**CLI.** `deliveries tail` polls every 2s with the last `nextCursor` and prints new attempts as they
arrive — endpoint URL, response status, duration, attempt number.

## 4. What's explicitly out of scope

- **Replaying a delivery.** Frequently requested alongside this, deliberately separate: replay is a
  write operation with its own authorization and idempotency questions. Read-only first.
- **Retention changes.** 30 days is what we keep; this doesn't extend it.
- **Request/response bodies.** Metadata only — status, timing, attempt count. Bodies can contain
  customer PII and would change the compliance posture of this endpoint entirely.

## 5. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Polling load from many concurrent tails | Medium | 2s floor enforced server-side; `limit` capped at 200 |
| Cursor breaks if ordering columns change | Medium | Cursor is opaque, so its encoding can change without a client change |
| Customers infer delivery success from a 2xx we recorded | Low | Document that status is what their endpoint returned, not proof of processing |

## 6. Phasing

- **P1** — `GET /deliveries` with cursor pagination
- **P2** — `deliveries tail` in the CLI
- **P3** — filtering by endpoint and status

## 7. Decisions needed at Gate 1

1. Cursor or offset pagination? *(Decided: cursor — offset skips or repeats rows when new attempts
   land mid-page, which is the normal case here.)*
2. Poll interval floor? *(Decided: 2s.)*
3. Include response bodies? *(Decided: no — see §4.)*

---

## Build Notes

### P1 — the cursor design was wrong, and the endpoint looked fine while being wrong

The tuple cursor in §3 does not work as specified. It was caught during the build, but only by
watching real output long enough to notice it repeating.

**Symptom.** Polling repeatedly returned some attempts on *every* request, indefinitely. Not a burst
of duplicates that settled — the same rows, forever, once they appeared.

**Root cause: the cursor was truncated on the way out, so it could never advance past its own row.**

The `attempted_at` column stores microsecond precision. The API serialises timestamps through a
millisecond-precision date type, so `10:04:11.238461` was emitted to the client as
`10:04:11.238`. The client sent that truncated value back as its cursor, and the comparison
`(attempted_at, id) > ('10:04:11.238', <id>)` was still **true for the very row the cursor was built
from** — its real timestamp `.238461` is greater than the truncated `.238`. So that row matched
again. And again. Every poll, permanently.

Two things made this easy to miss:

- **Nothing was wrong with the data.** Every returned row was real and correctly formed. There was no
  error, no malformed response, no failing assertion.
- **It doesn't reproduce on a fast test.** Insert two rows, poll twice, and the second poll returns
  the duplicate — which reads as an off-by-one in the comparison, not a precision problem. The
  precision cause only becomes obvious once you print the stored value next to the serialised one and
  see the digits missing.

**Fix.** Two changes, together:

1. Server-side, the filter became **inclusive and time-only**: `attempted_at >= cursor.attemptedAt`.
   The `id` tiebreak was dropped from the comparison entirely, because it can't be relied on when the
   timestamp half of the tuple doesn't round-trip.
2. Client-side, the tail keeps a **bounded set of recently-seen attempt IDs** (last 1000) and silently
   drops anything it has already printed.

**The tradeoff, recorded deliberately.** An inclusive filter guarantees the client re-receives rows it
has already seen — it trades duplicates for never skipping. That is the correct direction *for this
feature*: a missed delivery attempt is a silent correctness failure the customer cannot detect and
which defeats the entire purpose of the tail, while a duplicate is cosmetic and fully suppressible
client-side. **A different feature could easily want the opposite** — a billing export, say, should
prefer a gap it can detect and re-run over a double-count it can't. The cursor is not "solved" in the
abstract; it was resolved for this use case.

**What we'd do differently.** The design assumed a value would survive a round trip through
serialisation without checking whether the wire format could represent it. That's a cheap thing to
verify at design time and expensive to find later. Any cursor built from a stored value now has to
answer one question in the design doc: *does this survive the round trip exactly, and what happens if
it doesn't?*

**Verification.** Seeded two attempts sharing a microsecond timestamp, reproduced the original
duplicate-forever behaviour against the pre-fix code, confirmed it stopped after the fix, and
confirmed a newly inserted attempt still appeared exactly once across live polls.

### P2 — no surprises

`deliveries tail` shipped as designed. The dedup set from P1 lives here.

---

## Changelog

- **2026-03-02** — Initial design.
- **2026-03-04** — Gate 1 approved; cursor pagination, 2s floor, metadata only.
- **2026-03-11** — P1 shipped (PR #218). Cursor design corrected during the build — see Build Notes.
- **2026-03-14** — P2 shipped (PR #223).
