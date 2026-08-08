#!/usr/bin/env bash
# Gate 2 (ship approval) enforcement hook for Claude Code.
#
# Fires on every Bash tool call. If the command about to run would merge a
# pull request or run a deploy, it forces a permission prompt — so nothing
# ships without an explicit human "go ahead", even in an auto-accept
# permission mode. Non-matching commands pass straight through (empty
# stdout = no opinion).
#
# Configure which commands count as "shipping" via AGENTIC_WORKFLOW_GATE_PATTERNS
# (an extended-regex alternation, e.g. 'gh[[:space:]]+pr[[:space:]]+merge|scripts/deploy/|npm publish').
# It defaults to matching `gh pr merge` and anything containing `scripts/deploy/` —
# adjust the default below for your own project's actual ship commands.
#
# Substring match (not a prefix rule) is deliberate: real merge/deploy commands
# are routinely wrapped (e.g. `GH_TOKEN=$(gh auth token) gh pr merge ...`), so
# the pattern has to match anywhere in the command string, not just at its start.
#
# Requires jq. FAILS CLOSED (emits ask) whenever the command can't be safely
# evaluated — jq missing, stdin isn't valid JSON, or the configured pattern
# doesn't compile — rather than silently defaulting to allow. A gate that
# can't tell what it's looking at must not conclude "allow".
input=$(cat)

fail_closed() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

if ! command -v jq >/dev/null 2>&1; then
  # Can't use jq to build the fail_closed message either — emit raw JSON.
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Gate 2 (ship approval): jq is required by this hook and was not found on PATH, so the command could not be safely evaluated. Confirm before proceeding."}}'
  exit 0
fi

if ! printf '%s' "$input" | jq -e . >/dev/null 2>&1; then
  fail_closed "Gate 2 (ship approval): the tool input was not valid JSON, so the command could not be safely evaluated. Confirm before proceeding."
fi

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

PATTERNS="${AGENTIC_WORKFLOW_GATE_PATTERNS:-gh[[:space:]]+pr[[:space:]]+merge|scripts/deploy/}"
printf '' | grep -Eq "$PATTERNS" 2>/dev/null
pattern_check=$?
if [ "$pattern_check" -gt 1 ]; then
  fail_closed "Gate 2 (ship approval): the configured AGENTIC_WORKFLOW_GATE_PATTERNS value is not a valid regex, so the command could not be safely evaluated. Confirm before proceeding."
fi

if printf '%s' "$cmd" | grep -Eq "$PATTERNS"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: "Gate 2 (ship approval): this command merges a pull request or deploys. Confirm this was explicitly approved before proceeding."
    }
  }'
fi
