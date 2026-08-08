<!--
Worked example — companion to design-artifact.md and user-stories.md in this directory.
The feature is invented; see README.md.
-->

# Webhook Delivery Log — QA Test Cases

Source design: `design-artifact.md`
Companion stories: `user-stories.md`

---

### WDL-TC1 — Attempts are scoped to the calling account
**Covers:** WDL-1
**Preconditions:** Two accounts, each with delivery attempts recorded.

**Steps:**
1. Call `GET /deliveries` authenticated as account A.
2. Compare the returned attempt IDs against account B's attempts.

**Expected Result:** Only account A's attempts are returned; no ID from account B appears. An account
with zero attempts receives an empty list and a 200, not a 404.

**Priority:** Must Have
**Automation:** Automated (`deliveries.scope.test`)

---

### WDL-TC2 — Response bodies are never exposed
**Covers:** WDL-1
**Preconditions:** An attempt whose recorded request body contains a recognisable string.

**Steps:**
1. Fetch that attempt via `GET /deliveries`.
2. Search the entire serialised response for the string.

**Expected Result:** Absent. Only metadata fields (endpoint, status, duration, attempt number,
timestamp) are present. Verified against the full response, not just the documented field list — the
concern is an unintended field, so checking only expected fields would miss it.

**Priority:** Must Have
**Automation:** Automated (`deliveries.fields.test`)

---

### WDL-TC3 — Polling repeatedly never repeats an attempt
**Covers:** WDL-2
**Preconditions:** An account with existing attempts and no new ones arriving.

**Steps:**
1. Call `GET /deliveries`, keep `nextCursor`.
2. Call again with `?since=<nextCursor>`.
3. Repeat five more times, collecting every returned ID.

**Expected Result:** Steps 2–3 return **zero** attempts — nothing new has happened. No ID appears in
more than one response.

**Note:** this is the case the original cursor design failed. It returned the boundary rows on every
poll indefinitely. Anything less than several consecutive polls can read as an ordinary off-by-one;
the repetition is what identifies it.

**Priority:** Must Have
**Automation:** Automated (`deliveries.cursor.test`)

---

### WDL-TC4 — Attempts sharing a timestamp are each returned exactly once
**Covers:** WDL-2
**Preconditions:** Two attempts written with an **identical** stored timestamp, to microsecond
precision — insert them in one statement rather than relying on two writes landing on the same value.

**Steps:**
1. Page through with `limit=1` so the page boundary falls between the two.
2. Continue until the list is exhausted, collecting all IDs.

**Expected Result:** Both attempts appear, each exactly once. Neither is skipped by the page boundary
nor returned twice.

**Note:** the precision mismatch behind the original bug is invisible unless the test data actually
exercises sub-millisecond values. Timestamps generated a few milliseconds apart will pass while the
bug is present.

**Priority:** Must Have
**Automation:** Automated (`deliveries.cursor.test`)

---

### WDL-TC5 — A new attempt appears in a running tail exactly once
**Covers:** WDL-3
**Preconditions:** `deliveries tail` running against an account with a configured endpoint.

**Steps:**
1. Trigger a webhook delivery.
2. Watch the tail for ~10s.
3. Keep watching for a further 60s.

**Expected Result:** The attempt appears once, within a few seconds, showing timestamp, endpoint,
status, and duration, with failure visually distinct from success. It does **not** reappear during
the extended watch — the client-side dedup suppresses the re-delivery the inclusive cursor causes.

**Priority:** Must Have
**Automation:** Manual

---

### WDL-TC6 — Poll interval floor is enforced server-side
**Covers:** WDL-2
**Preconditions:** Direct API access, bypassing the CLI.

**Steps:**
1. Issue `GET /deliveries` requests in a tight loop, well under 2s apart.
2. Observe responses.

**Expected Result:** Requests beyond the floor are rejected or throttled rather than served. The
limit is enforced by the server, not merely respected by the CLI — a custom client must not be able
to opt out of it.

**Priority:** Should Have
**Automation:** Automated (`deliveries.ratelimit.test`)

---

### WDL-TC7 — Filters narrow results and compose
**Covers:** WDL-4
**Preconditions:** An account with attempts across two endpoints, including successes and failures on
both.

**Steps:**
1. Call `GET /deliveries?endpoint=<A>` and check the endpoints in the result.
2. Call `?status=failed` and check the statuses.
3. Call `?endpoint=<A>&status=failed&since=<cursor>` and check all three constraints hold together.
4. Call `?endpoint=<unknown>`.

**Expected Result:** (1) only endpoint A; (2) only non-2xx; (3) all three applied simultaneously;
(4) empty list with a 200, not an error.

**Priority:** Should Have
**Status note:** WDL-4 is not built yet — this case is written at design time, before Gate 1, which is
the point: the acceptance criteria are agreed before the code exists, not reverse-engineered from it.

**Automation:** Not yet — story not started
