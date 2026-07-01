#!/bin/bash
# Beans Stop hook: two-layer sync.
#   1. Mechanical layer  - run the deterministic beans->Notion state push
#      (silent, diff-gated, never fails a session).
#   2. Judgment layer     - report beans status counts and nudge the agent to
#      promote any not-yet-linked beans worth sharing at a natural stopping point.

INPUT=$(cat)

# Avoid loops: don't fire on a stop-hook-triggered response.
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Mechanical state push. Self-gates on config/token and on unchanged state,
#    so this is a cheap no-op unless linked beans actually changed.
SYNC_SUMMARY="$(python3 "$SCRIPT_DIR/beans-notion-sync.py" 2>/dev/null)"

# 2. Judgment nudge. Only surface when there are beans at all. Take a single
#    snapshot so the counts are consistent and we spawn one subprocess, not three.
BEANS_JSON=$(beans --json list 2>/dev/null)
read -r CLOSED IN_PROGRESS OPEN TOTAL <<<"$(echo "$BEANS_JSON" | jq -r \
  '. as $beans | ($beans | reduce .[] as $b ({}; .[($b.status // "unknown")] += 1)) as $c
   | "\($c.closed // 0) \($c.in_progress // 0) \($c.open // 0) \($beans | length)"' \
  2>/dev/null)"
CLOSED=${CLOSED:-0}; IN_PROGRESS=${IN_PROGRESS:-0}; OPEN=${OPEN:-0}; TOTAL=${TOTAL:-0}
if [ "$TOTAL" -eq 0 ]; then
  exit 0
fi

MSG="Beans: ${CLOSED} closed, ${IN_PROGRESS} in progress, ${OPEN} open."
if [ -n "$SYNC_SUMMARY" ]; then
  MSG="$MSG ${SYNC_SUMMARY}."
fi
MSG="$MSG Linked beans sync to Notion automatically. At a natural stopping point, promote any unlinked beans worth sharing and publish doc artifacts to the Document Hub."

# Build the JSON with jq so quotes/backslashes/newlines in MSG are escaped
# safely rather than producing malformed JSON.
jq -n --arg msg "$MSG" '{systemMessage: $msg}'
