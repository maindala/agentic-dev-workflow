#!/bin/bash
# Optional UserPromptSubmit hook: reminds the agent to consider recall at the
# start of a turn, and to consider writing to memory at the end of it.
# See hooks/memory-session-start.sh and memory/README.md for context — this
# is tool-agnostic prompt text, not a dependency on any specific memory tool.
echo "[memory] Evaluate: recall needed? After responding, evaluate: remember needed?"
