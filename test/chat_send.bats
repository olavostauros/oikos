#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup() {
  TMPBIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$TMPBIN"

  export CHAT_ARGS_LOG="$BATS_TEST_TMPDIR/chat-args.log"
  export CHAT_BODY_LOG="$BATS_TEST_TMPDIR/chat-body.log"
  export CURL_ARGS_LOG="$BATS_TEST_TMPDIR/curl-args.log"
  export CURL_BODY_LOG="$BATS_TEST_TMPDIR/curl-body.log"
  export CURL_STATUS="${CURL_STATUS:-200}"
  export OIKOS_DISCORD_CHAT_CHANNEL="123456"
  unset CHAT_IDENTITY

  export CHAT="$TMPBIN/chat"
  cat > "$CHAT" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "${CHAT_ARGS_LOG:?}"
cat > "${CHAT_BODY_LOG:?}"
[ "${CHAT_FAIL:-}" = "1" ] && { echo "Aborted: unread messages" >&2; exit 1; }
echo "Sent to default."
BASH
  chmod +x "$CHAT"

  export CURL="$TMPBIN/curl"
  cat > "$CURL" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "${CURL_ARGS_LOG:?}"
cat > "${CURL_BODY_LOG:?}"
printf '%s' "${CURL_STATUS:-200}"
BASH
  chmod +x "$CURL"

  export SECRETS="$TMPBIN/secrets"
  cat > "$SECRETS" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
case "${2:-}" in
  knick/discord-token) echo "tok-knick" ;;
  *) echo "missing secret: ${2:-}" >&2; exit 1 ;;
esac
BASH
  chmod +x "$SECRETS"
}

@test "chat:send sends locally then mirrors to Discord as the sender" {
  run oikos_task chat:send --as knick --msg "PR is up"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Sent to default."* ]]
  [[ "$output" == *"Mirrored to Discord."* ]]
  [ "$(cat "$CHAT_ARGS_LOG")" = $'send\n--as\nknick' ]
  [ "$(cat "$CHAT_BODY_LOG")" = "PR is up" ]
  grep -qx 'https://discord.com/api/v10/channels/123456/messages' "$CURL_ARGS_LOG"
  grep -qx 'Authorization: Bot tok-knick' "$CURL_ARGS_LOG"
  [ "$(jq -r .content "$CURL_BODY_LOG")" = "PR is up" ]
}

@test "chat:send passes --chat and --force through and prefixes the chat name" {
  run oikos_task chat:send --as knick --chat den --force --msg "on it"

  [ "$status" -eq 0 ]
  [ "$(cat "$CHAT_ARGS_LOG")" = $'send\n--as\nknick\n--chat\nden\n--force' ]
  [ "$(jq -r .content "$CURL_BODY_LOG")" = "[den] on it" ]
}

@test "chat:send reads the message from stdin and CHAT_IDENTITY" {
  export CHAT_IDENTITY=knick
  run bash -c 'printf "from stdin\n" | oikos_task chat:send'

  [ "$status" -eq 0 ]
  [ "$(cat "$CHAT_BODY_LOG")" = "from stdin" ]
  [ "$(jq -r .content "$CURL_BODY_LOG")" = "from stdin" ]
}

@test "chat:send does not mirror when the local send fails" {
  export CHAT_FAIL=1
  run oikos_task chat:send --as knick --msg "nope"

  [ "$status" -eq 1 ]
  [ ! -e "$CURL_ARGS_LOG" ]
}

@test "chat:send still succeeds without a discord token, and says so" {
  run oikos_task chat:send --as knack --msg "hello"

  [ "$status" -eq 0 ]
  [[ "$output" == *"not mirrored — no secret knack/discord-token"* ]]
  [ ! -e "$CURL_ARGS_LOG" ]
}

@test "chat:send still succeeds without a channel configured" {
  unset OIKOS_DISCORD_CHAT_CHANNEL
  run oikos_task chat:send --as knick --msg "hello"

  [ "$status" -eq 0 ]
  [[ "$output" == *"not mirrored — OIKOS_DISCORD_CHAT_CHANNEL is unset"* ]]
  [ ! -e "$CURL_ARGS_LOG" ]
}

@test "chat:send warns but exits 0 when Discord rejects the mirror" {
  export CURL_STATUS=401
  run oikos_task chat:send --as knick --msg "hello"

  [ "$status" -eq 0 ]
  [[ "$output" == *"sent locally, but the Discord mirror failed (401)"* ]]
}

@test "chat:send clips the mirrored content at 2000 characters" {
  long="$(head -c 2500 /dev/zero | tr '\0' x)"
  run oikos_task chat:send --as knick --msg "$long"

  [ "$status" -eq 0 ]
  [ "$(jq -r '.content | length' "$CURL_BODY_LOG")" -eq 2000 ]
  [ "$(cat "$CHAT_BODY_LOG")" = "$long" ]
}

@test "chat:send requires an identity" {
  run oikos_task chat:send --msg "hello"

  [ "$status" -eq 1 ]
  [[ "$output" == *"identity required"* ]]
  [ ! -e "$CHAT_ARGS_LOG" ]
}
