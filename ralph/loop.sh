#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Error on line $LINENO (exit $?)" >&2' ERR

MAX_ITERS=${1:-10}
COUNT=0

echo "=== Ralph Loop Starting ===" | tee -a ralph/progress.txt

while [ $COUNT -lt $MAX_ITERS ]; do
  ((++COUNT))
  echo "---- Iteration $COUNT ----" | tee -a ralph/progress.txt

  # Feed prompt + progress into agent
  set +e
  output=$(codex exec "$(cat ralph/prompt.md; echo; cat ralph/progress.txt)" \
    --sandbox workspace-write \
    --full-auto 2>&1)
  status=$?
  set -e

  echo "$output" | tee -a ralph/progress.txt
  if [ $status -ne 0 ]; then
    echo "codex failed with status $status" | tee -a ralph/progress.txt
    exit $status
  fi

  # Persist output into prd.json and progress.txt
  # Expect agent commits or direct file edits

  # Check for explicit completion signal
  if echo "$output" | grep -q "<promise>COMPLETE</promise>"; then
    echo "Completion reported by agent." | tee -a ralph/progress.txt
    break
  fi

  # Commit changes for durable state
  git add ralph/prd.json ralph/progress.txt .
  git commit -m "Ralph iteration $COUNT"
done

echo "=== Ralph Loop Finished ===" >> ralph/progress.txt
