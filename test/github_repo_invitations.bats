#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup() {
  setup_github_invite_mocks
}

@test "github:repo:invite dry-run resolves agent targets without mutating" {
  run oikos_task github:repo:invite olavostauros/ideas --to delta --permission write
  [ "$status" -eq 0 ]
  [[ "$output" == *"Dry run. Rerun with --yes"* ]]
  [[ "$output" == *"delta (delta-oikos)"* ]]
  run ! grep -q -- '-X PUT' "$MOCK_GH_LOG"
}

@test "github:repo:invite --yes sends collaborator invitation with normalized permission" {
  run oikos_task github:repo:invite olavostauros/ideas --to delta --permission write --yes
  [ "$status" -eq 0 ]
  grep -q 'ARGS=api -X PUT /repos/olavostauros/ideas/collaborators/delta-oikos -f permission=push' "$MOCK_GH_LOG"
  [[ "$output" == *"delta"*"delta-oikos"*"ok"* ]]
}

@test "github:repo:invite can use an agent token as actor" {
  run oikos_task github:repo:invite olavostauros/ideas --as delta --to alpha --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"actor:     delta-oikos"* ]]
  grep -q 'GH_TOKEN=token-delta ARGS=api -X PUT /repos/olavostauros/ideas/collaborators/alpha-oikos -f permission=push' "$MOCK_GH_LOG"
}

@test "github:repo:accept-invite dry-run shows pending exact repo invitation" {
  run oikos_task github:repo:accept-invite olavostauros/ideas --as delta
  [ "$status" -eq 0 ]
  [[ "$output" == *"Dry run. Rerun with --yes"* ]]
  [[ "$output" == *"delta"*"delta-oikos"*"pending"* ]]
  run ! grep -q -- '-X PATCH' "$MOCK_GH_LOG"
}

@test "github:repo:accept-invite --yes accepts exact repo invitation" {
  run oikos_task github:repo:accept-invite olavostauros/ideas --as delta --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"delta"*"delta-oikos"*"accepted"*"WRITE"* ]]
  grep -q 'GH_TOKEN=token-delta ARGS=api -X PATCH /user/repository_invitations/321' "$MOCK_GH_LOG"
  run ! grep -q 'repository_invitations/322' "$MOCK_GH_LOG"
  run ! grep -q 'repository_invitations/323' "$MOCK_GH_LOG"
}

@test "github:repo:accept-invite reports no matching invite and current permission" {
  run oikos_task github:repo:accept-invite olavostauros/ideas --as alpha --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"alpha"*"alpha-oikos"*"none-found"*"no-access"* ]]
  run ! grep -q -- '-X PATCH' "$MOCK_GH_LOG"
}
