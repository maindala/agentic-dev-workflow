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
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

PATTERNS="${AGENTIC_WORKFLOW_GATE_PATTERNS:-gh[[:space:]]+pr[[:space:]]+merge|scripts/deploy/}"

if printf '%s' "$cmd" | grep -Eq "$PATTERNS"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: "Gate 2 (ship approval): this command merges a pull request or deploys. Confirm this was explicitly approved before proceeding."
    }
  }'
fi
