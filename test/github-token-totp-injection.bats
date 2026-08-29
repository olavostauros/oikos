#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup() {
  TMPBIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$TMPBIN"
  export TMPBIN
  FAKE_SECRET_STORE="$BATS_TEST_TMPDIR/secrets"
  mkdir -p "$FAKE_SECRET_STORE"
  export FAKE_SECRET_STORE
  write_fake_github_auth_secret_tools
  printf 'JBSWY3DPEHPK3PXP' > "$FAKE_SECRET_STORE/beta_github-totp"
  export SECRETS_BIN="$TMPBIN/secrets"
  export SECRETS="$TMPBIN/secrets"
  export WEBSITES_BIN="$TMPBIN/websites"
  export SHIMMER_BIN="$TMPBIN/shimmer"
  export GH_BIN="$TMPBIN/gh"
  export GH="$TMPBIN/gh"
}

write_fake_websites() {
  local expected_task="$1"
  cat > "$TMPBIN/websites" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" > "\$BATS_TEST_TMPDIR/websites-args"
printf 'GITHUB_TOTP_CODE=%s\n' "\${GITHUB_TOTP_CODE:-}" > "\$BATS_TEST_TMPDIR/websites-env"
printf 'GITHUB_TOTP_COMMAND=%s\n' "\${GITHUB_TOTP_COMMAND:-}" >> "\$BATS_TEST_TMPDIR/websites-env"
printf 'GITHUB_USERNAME=%s\n' "\${GITHUB_USERNAME:-}" >> "\$BATS_TEST_TMPDIR/websites-env"
if [ -n "\${GITHUB_TOTP_COMMAND:-}" ]; then
  bash -lc "\$GITHUB_TOTP_COMMAND" >> "\$BATS_TEST_TMPDIR/websites-totp-output"
  bash -lc "\$GITHUB_TOTP_COMMAND" >> "\$BATS_TEST_TMPDIR/websites-totp-output"
fi
if [ "\${1:-}" != "$expected_task" ]; then
  echo "unexpected websites task: \$*" >&2
  exit 1
fi
printf 'browser diagnostic\n' >&2
printf 'ghp_newtoken\n'
EOF
  chmod +x "$TMPBIN/websites"
}

write_fake_shimmer_and_gh() {
  cat > "$TMPBIN/shimmer" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$BATS_TEST_TMPDIR/shimmer-log"
if [ "${1:-}" = "github:token:store" ]; then
  key="${2:?agent}/github-pat"
  path="$FAKE_SECRET_STORE/$(printf '%s' "$key" | tr '/' '__')"
  printf '%s' "${3:?token}" > "$path"
  exit 0
fi
echo "unexpected shimmer command: $*" >&2
exit 1
EOF
  chmod +x "$TMPBIN/shimmer"

  cat > "$TMPBIN/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'ARGS=%s\n' "$*" >> "$BATS_TEST_TMPDIR/gh-log"
case "${1:-}" in
  api)
    case "${2:-}" in
      /user)
        printf 'beta-oikos\n'
        exit 0
        ;;
      repos/olavostauros/oikos/actions/secrets/public-key)
        printf 'fake-public-key\n'
        exit 0
        ;;
    esac
    ;;
  secret)
    case "${2:-}" in
      list)
        printf 'BETA_GITHUB_PAT\n'
        exit 0
        ;;
      set)
        payload=$(cat)
        printf 'SECRET_SET=%s\tBYTES=%s\tGH_TOKEN=%s\n' "${3:-}" "${#payload}" "${GH_TOKEN:-}" >> "$BATS_TEST_TMPDIR/gh-log"
        exit 0
        ;;
    esac
    ;;
esac
echo "unexpected gh command: $*" >&2
exit 2
EOF
  chmod +x "$TMPBIN/gh"
}

@test "github:token:create passes command-backed TOTP resolver when stored seed exists" {
  write_fake_websites github:token:create
  write_fake_shimmer_and_gh

  run oikos_task github:token:create --yes --no-sync-ci beta

  [ "$status" -eq 0 ]
  grep -q '^GITHUB_TOTP_CODE=$' "$BATS_TEST_TMPDIR/websites-env"
  grep -q '^GITHUB_TOTP_COMMAND=.* totp beta/github-totp$' "$BATS_TEST_TMPDIR/websites-env"
  grep -q '^GITHUB_USERNAME=beta-oikos$' "$BATS_TEST_TMPDIR/websites-env"
  [ "$(grep -c '^123456$' "$BATS_TEST_TMPDIR/websites-totp-output")" -eq 2 ]
  grep -q 'github:token:create beta --login-id beta' "$BATS_TEST_TMPDIR/websites-args"
  grep -q 'github:token:store beta ghp_newtoken' "$BATS_TEST_TMPDIR/shimmer-log"
  [[ "$output" == *"✓ verified as beta-oikos"* ]]
}

@test "github:token:rotate passes command-backed TOTP resolver when stored seed exists" {
  write_fake_websites github:token:rotate
  write_fake_shimmer_and_gh

  run oikos_task github:token:rotate --yes --no-sync-ci beta

  [ "$status" -eq 0 ]
  grep -q '^GITHUB_TOTP_CODE=$' "$BATS_TEST_TMPDIR/websites-env"
  grep -q '^GITHUB_TOTP_COMMAND=.* totp beta/github-totp$' "$BATS_TEST_TMPDIR/websites-env"
  [ "$(grep -c '^123456$' "$BATS_TEST_TMPDIR/websites-totp-output")" -eq 2 ]
  grep -q 'github:token:rotate beta --login-id beta' "$BATS_TEST_TMPDIR/websites-args"
  grep -q 'github:token:store beta ghp_newtoken' "$BATS_TEST_TMPDIR/shimmer-log"
  [[ "$output" == *"✓ verified as beta-oikos"* ]]
}

@test "github:token:create syncs only oikos GitHub PAT CI secret with caller GitHub auth" {
  write_fake_websites github:token:create
  write_fake_shimmer_and_gh

  GH_TOKEN=caller-token run oikos_task github:token:create --yes beta

  [ "$status" -eq 0 ]
  [[ "$output" == *"CI sync auth: ambient gh auth / GH_TOKEN"* ]]
  [[ "$output" == *"✓ synced oikos GitHub PAT CI secret"* ]]
  grep -q 'ARGS=secret set BETA_GITHUB_PAT --repo olavostauros/oikos' "$BATS_TEST_TMPDIR/gh-log"
  grep -q $'SECRET_SET=BETA_GITHUB_PAT\tBYTES=12\tGH_TOKEN=caller-token' "$BATS_TEST_TMPDIR/gh-log"
  ! grep -q 'GPG\|EMAIL\|B2\|PI_AUTH' "$BATS_TEST_TMPDIR/gh-log"
  [[ "$output$(cat "$BATS_TEST_TMPDIR/gh-log")" != *"ghp_newtoken"* ]]
  [[ "$output$(cat "$BATS_TEST_TMPDIR/gh-log")" != *"ghp_operator"* ]]
}

@test "github:token:rotate syncs only oikos GitHub PAT CI secret with caller GitHub auth" {
  write_fake_websites github:token:rotate
  write_fake_shimmer_and_gh

  GH_TOKEN=caller-token run oikos_task github:token:rotate --yes beta

  [ "$status" -eq 0 ]
  [[ "$output" == *"CI sync auth: ambient gh auth / GH_TOKEN"* ]]
  [[ "$output" == *"✓ synced oikos GitHub PAT CI secret"* ]]
  grep -q 'ARGS=secret set BETA_GITHUB_PAT --repo olavostauros/oikos' "$BATS_TEST_TMPDIR/gh-log"
  grep -q $'SECRET_SET=BETA_GITHUB_PAT\tBYTES=12\tGH_TOKEN=caller-token' "$BATS_TEST_TMPDIR/gh-log"
  ! grep -q 'GPG\|EMAIL\|B2\|PI_AUTH' "$BATS_TEST_TMPDIR/gh-log"
  [[ "$output$(cat "$BATS_TEST_TMPDIR/gh-log")" != *"ghp_newtoken"* ]]
  [[ "$output$(cat "$BATS_TEST_TMPDIR/gh-log")" != *"ghp_operator"* ]]
}

@test "github:token:create redacts credential material from browser diagnostics" {
  cat > "$TMPBIN/websites" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "diagnostic GITHUB_TOTP_COMMAND=${GITHUB_TOTP_COMMAND:-unset}" >&2
if [ -n "${GITHUB_TOTP_COMMAND:-}" ]; then
  echo "diagnostic bare totp $(bash -lc "$GITHUB_TOTP_COMMAND")" >&2
fi
echo "diagnostic password ${GITHUB_PASSWORD:-unset}" >&2
echo "diagnostic seed JBSWY3DPEHPK3PXP" >&2
echo "diagnostic recovery a1b2c-3d4e5" >&2
exit 42
EOF
  chmod +x "$TMPBIN/websites"
  write_fake_shimmer_and_gh

  run oikos_task github:token:create --yes --no-sync-ci beta

  [ "$status" -ne 0 ]
  [[ "$output" == *"GITHUB_TOTP_COMMAND=[REDACTED_TOTP_COMMAND]"* ]]
  [[ "$output" == *"bare totp [REDACTED_TOTP_CODE]"* ]]
  [[ "$output" == *"password [REDACTED_PASSWORD]"* ]]
  [[ "$output" == *"[REDACTED_BASE32]"* ]]
  [[ "$output" == *"[REDACTED_RECOVERY_CODE]"* ]]
  [[ "$output" != *"beta/github-totp"* ]]
  [[ "$output" != *"bare totp 123456"* ]]
  [[ "$output" != *"password-for-beta"* ]]
  [[ "$output" != *"JBSWY3DPEHPK3PXP"* ]]
  [[ "$output" != *"a1b2c-3d4e5"* ]]
}

@test "github:token:rotate redacts credential material from browser diagnostics" {
  cat > "$TMPBIN/websites" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "diagnostic GITHUB_TOTP_COMMAND=${GITHUB_TOTP_COMMAND:-unset}" >&2
if [ -n "${GITHUB_TOTP_COMMAND:-}" ]; then
  echo "diagnostic bare totp $(bash -lc "$GITHUB_TOTP_COMMAND")" >&2
fi
echo "diagnostic password ${GITHUB_PASSWORD:-unset}" >&2
echo "diagnostic seed JBSWY3DPEHPK3PXP" >&2
echo "diagnostic recovery a1b2c-3d4e5" >&2
exit 42
EOF
  chmod +x "$TMPBIN/websites"
  write_fake_shimmer_and_gh

  run oikos_task github:token:rotate --yes --no-sync-ci beta

  [ "$status" -ne 0 ]
  [[ "$output" == *"GITHUB_TOTP_COMMAND=[REDACTED_TOTP_COMMAND]"* ]]
  [[ "$output" == *"bare totp [REDACTED_TOTP_CODE]"* ]]
  [[ "$output" == *"password [REDACTED_PASSWORD]"* ]]
  [[ "$output" == *"[REDACTED_BASE32]"* ]]
  [[ "$output" == *"[REDACTED_RECOVERY_CODE]"* ]]
  [[ "$output" != *"beta/github-totp"* ]]
  [[ "$output" != *"bare totp 123456"* ]]
  [[ "$output" != *"password-for-beta"* ]]
  [[ "$output" != *"JBSWY3DPEHPK3PXP"* ]]
  [[ "$output" != *"a1b2c-3d4e5"* ]]
}
