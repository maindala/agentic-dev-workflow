#!/bin/bash
# Optional SessionStart hook: surfaces memory status at the start of a session.
#
# This integrates with mnemon (https://github.com/mnemon-dev/mnemon, Apache-2.0),
# a third-party persistent-memory CLI — it is not part of this repo and not
# required to use the workflow. See memory/README.md for a file-based
# alternative that needs no external tool at all. If you use a different
# memory tool, or none, adapt or remove this hook.
export PATH="$HOME/bin:$PATH"

if ! command -v mnemon >/dev/null 2>&1; then
  exit 0
fi

STATS=$(mnemon status 2>/dev/null)
if [ -n "$STATS" ]; then
  INSIGHTS=$(echo "$STATS" | sed -n 's/.*"total_insights": *\([0-9]*\).*/\1/p' | head -1)
  EDGES=$(echo "$STATS" | sed -n 's/.*"edge_count": *\([0-9]*\).*/\1/p' | head -1)
  echo "[memory] Active (${INSIGHTS:-0} insights, ${EDGES:-0} edges)."
fi
