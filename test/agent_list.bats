#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup() {
  if [ ! -f "$REPO_DIR/notes/epsilon.md" ]; then
    skip "oikos readable notes are locked"
  fi
}

@test "agent:list preserves line-oriented CI roster" {
  run oikos_task agent:list --ci
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | head -n 1)" = "epsilon" ]
  [[ "$output" == *$'\neta' ]]
}

@test "agent:list --json emits explicit GitHub logins" {
  run oikos_task agent:list --json --ci
  [ "$status" -eq 0 ]

  AGENT_LIST_JSON="$output" python3 - <<'PY'
import json
import os

records = json.loads(os.environ["AGENT_LIST_JSON"])
by_name = {record["name"]: record for record in records}
assert by_name["epsilon"]["github_login"] == "epsilon"
assert by_name["eta"]["github_login"] == "eta-oikos"
assert all(record["ci"] is True for record in records)
PY
}
