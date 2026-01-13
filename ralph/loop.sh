#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Error on line $LINENO (exit $?)" >&2' ERR

MAX_ITERS=${1:-10}
COUNT=0

echo "=== Ralph Loop Starting ==="

while [ $COUNT -lt $MAX_ITERS ]; do
  ((++COUNT))
  echo "---- Iteration $COUNT ----"

  # Feed prompt + progress into agent
  set +e
  tmp_output=$(mktemp)
  codex exec "$(cat ralph/prompt.md; echo; cat ralph/progress.txt)" \
    --sandbox workspace-write \
    --full-auto 2>&1 | tee "$tmp_output"
  status=${PIPESTATUS[0]}
  output=$(cat "$tmp_output")
  rm -f "$tmp_output"
  set -e
  if [ $status -ne 0 ]; then
    echo "codex failed with status $status"
    exit $status
  fi

  # Persist output into prd.json and progress.txt
  # Expect agent commits or direct file edits

  # Check for explicit completion signal
  if echo "$output" | grep -q "<promise>COMPLETE</promise>"; then
    echo "Completion reported by agent."
    break
  fi

  # Commit changes for durable state
  git add ralph/prd.json ralph/progress.txt .
  git commit -m "Ralph iteration $COUNT"
done

echo "=== Ralph Loop Finished ==="
