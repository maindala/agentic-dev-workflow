<!--
Template: qa-test-cases/<slug>.md
Save alongside: design-artifacts/<slug>.md and story-artifacts/design/<slug>.md (same slug)
Each test case's "Covers" field references a story ID from the companion story file.
See conventions/traceability.md.
-->

# <Feature Name> — QA Test Cases

Source design: `design-artifacts/<slug>.md`
Companion stories: `story-artifacts/design/<slug>.md`

---

### <PREFIX>-TC1 — <Test Case Title>
**Covers:** <PREFIX>-1
**Preconditions:** <state the environment/data needs to be in before this test runs>

**Steps:**
1. ...
2. ...

**Expected Result:** <specific, checkable outcome>

**Priority:** Must Have | Should Have | Nice to Have
**Automation:** Automated (`<test file or script>`) | Manual | Not automatable (content/strategy review)

---

### <PREFIX>-TC2 — <Test Case Title>
**Covers:** <PREFIX>-2
**Preconditions:** ...

**Steps:**
1. ...

**Expected Result:** ...

**Priority:** Must Have | Should Have | Nice to Have
**Automation:** Manual

---

<!--
For non-engineering design docs (positioning, messaging, strategy, etc.), "test cases" become a
review checklist instead of a functional test. Keep the same ID/Covers/format so the doc stays
scannable, but expect every case to read "Automation: Not automatable (content/strategy review)".
-->
