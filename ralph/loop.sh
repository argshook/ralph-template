#!/usr/bin/env bash
set -e

MAX_ITERS=${1:-30}
COUNT=0

echo "=== Ralph Loop Starting ===" >> ralph/progress.txt

while [ $COUNT -lt $MAX_ITERS ]; do
  ((COUNT++))
  echo "---- Iteration $COUNT ----" | tee -a ralph/progress.txt

  # Feed prompt + progress into agent
  output=$(codex -p "$(cat ralph/prompt.md; echo; cat ralph/progress.txt)" \
    --sandbox sandbox-write \
    --dangerously-auto-approve)

  echo "$output" | tee -a ralph/progress.txt

  # Persist output into prd.json and progress.txt
  # Expect agent commits or direct file edits

  # Check for explicit completion signal
  if echo "$output" | grep -q "<promise>COMPLETE</promise>"; then
    echo "Completion reported by agent." | tee -a ralph/progress.txt
    break
  fi

  # Run external feedback loops
  echo "Running external verification…" | tee -a ralph/progress.txt
  deno fmt
  deno lint
  deno test
  deno task build

  # Append verification results
  {
    echo "Types/Lint/Tests/Build checks passed at $(date)"
    echo ""
  } >> ralph/progress.txt

  # Commit changes for durable state
  git add ralph/prd.json ralph/progress.txt .
  git commit -m "Ralph iteration $COUNT"
done

echo "=== Ralph Loop Finished ===" >> ralph/progress.txt

