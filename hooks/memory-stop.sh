#!/bin/bash
# Optional Stop hook: a lightweight, non-blocking reminder to consider
# persisting anything durable from this exchange to memory. It only nudges —
# the actual store/skip judgment is made by the agent, per the decision tree
# in memory/README.md. Silent if the agent's own last message already shows
# it considered this.
export PATH="$HOME/bin:$PATH"

INPUT=$(cat)
MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""' 2>/dev/null)

if echo "$MSG" | grep -qiE "remember|Stored.*imp="; then
  exit 0
fi

echo "[memory] Consider: does this exchange warrant persisting anything to memory?"
