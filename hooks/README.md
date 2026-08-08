# Hooks

Two independent families. `ship-gate.sh` is the important one — it's what makes Gate 2 (§`WORKFLOW.md`)
mechanically real instead of a written convention an agent could talk itself past. The `memory-*.sh`
scripts are optional and only relevant if you're using a persistent-memory tool.

## `ship-gate.sh` (recommended)

A Claude Code `PreToolUse` hook. Install by adding it to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/your/project/hooks/ship-gate.sh"
          }
        ]
      }
    ]
  }
}
```

Requires `jq`. By default it matches `gh pr merge` and any command containing `scripts/deploy/` —
set the `AGENTIC_WORKFLOW_GATE_PATTERNS` environment variable to override with your own project's
actual ship commands (extended-regex alternation). See the comment header in the script itself for
the exact matching rules and why substring matching is deliberate.

The hook **fails closed**: if `jq` isn't installed, if it can't parse its input, or if your
`AGENTIC_WORKFLOW_GATE_PATTERNS` doesn't compile as a regex, it asks for confirmation rather than
silently letting the command through. In practice this means a missing `jq` shows up immediately as
every command needing confirmation, not as the gate quietly doing nothing — install `jq` and it goes
back to only flagging real matches.

Verify it after installing: have the agent attempt a matching command (in a safe, throwaway context)
and confirm you get a permission prompt with the gate's reason string, even if your permission mode
is otherwise set to auto-accept.

## `memory-*.sh` (optional)

Three small hooks (`SessionStart`, `UserPromptSubmit`, `Stop`) that nudge the agent to consider
recalling and persisting memory at the right points in a session. They integrate with
[mnemon](https://github.com/mnemon-dev/mnemon) (Apache-2.0) if it's installed, but degrade to no-ops
if it isn't — see `memory/README.md` for the file-based convention that needs no external tool at
all. Install the same way as `ship-gate.sh`, wired to `SessionStart`, `UserPromptSubmit`, and `Stop`
respectively instead of `PreToolUse`.
