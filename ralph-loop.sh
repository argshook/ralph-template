#!/usr/bin/env bash
MAX_ITERS=50
COUNTER=0

while [ "$COUNTER" -lt "$MAX_ITERS" ]; do
  ((COUNTER++))
  echo "Iteration $COUNTER"

  codex -p "$(cat task.md)" --sandbox sandbox-write --dangerously-auto-approve

  echo "Appending progress"
  echo "Iteration $COUNTER summary" >> progress.txt

  deno fmt
  deno lint
  deno test
  deno task build

  if [ $? -eq 0 ]; then
    echo "SUCCESS at $COUNTER"
    break
  fi

  git add .
  git commit -m "Iteration $COUNTER progress"
done

