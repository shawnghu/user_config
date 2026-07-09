#!/bin/bash
# Delayed Vast.ai instance stop (preserves disk; does NOT destroy).
#
# Usage: bash vast_stop.sh [sleep_seconds] [instance_id]
#   sleep_seconds  default 7200 (2h). Pass 0 to fire immediately.
#   instance_id    default $CONTAINER_ID (set inside every Vast pod).
#
# API keys are read from the environment (populated by ~/.secrets_env, which
# install.sh / setup_service_auth.sh writes from secrets.age):
#   - $CONTAINER_API_KEY  pod-embedded, container-scoped key (tried first: from
#                         inside the pod this is usually the only key that can
#                         see the instance)
#   - $VAST_API_KEY, $VAST_API_KEY_2   account-level keys (fallbacks)
#
# Fires PUT {"state":"stopped"} to the Vast API, falling back HTTP -> CLI across
# every available token with retry/backoff. Log goes to tmpfs so a full disk
# can't break it.
LOG=/dev/shm/vast_stop.log
SLEEP=${1:-7200}
INSTANCE=${2:-${CONTAINER_ID:?set CONTAINER_ID or pass instance id as 2nd arg}}

# Assemble the token list in priority order, dropping any that are unset.
TOKENS=()
for t in "$CONTAINER_API_KEY" "$VAST_API_KEY" "$VAST_API_KEY_2"; do
    [ -n "$t" ] && TOKENS+=("$t")
done
if [ "${#TOKENS[@]}" -eq 0 ]; then
    echo "No Vast API key in env (CONTAINER_API_KEY / VAST_API_KEY / VAST_API_KEY_2). Source ~/.secrets_env." >&2
    exit 1
fi

sleep "$SLEEP"
echo "=== fired at $(date -u +%FT%TZ) instance=$INSTANCE ===" >> "$LOG"
success=0

# Attempt 1: HTTP API, each token x3 with 15s backoff.
for TOKEN in "${TOKENS[@]}"; do
    for i in 1 2 3; do
        code=$(curl -s -o /dev/shm/vast_stop.body -w "%{http_code}" -X PUT \
            -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
            -d '{"state":"stopped"}' \
            "https://console.vast.ai/api/v0/instances/$INSTANCE/")
        echo "http[${TOKEN:0:8}...] attempt $i: HTTP $code" >> "$LOG"
        case "$code" in 2*) success=1; break 2;; esac
        sleep 15
    done
done

# Attempt 2: vastai CLI, each token x3 with 30s backoff.
if [ "$success" = 0 ]; then
    VASTAI=$(command -v vastai || echo /opt/instance-tools/bin/vastai)
    for TOKEN in "${TOKENS[@]}"; do
        for i in 1 2 3; do
            "$VASTAI" stop instance "$INSTANCE" --api-key "$TOKEN" >> "$LOG" 2>&1
            rc=$?
            echo "cli[${TOKEN:0:8}...] attempt $i: rc=$rc" >> "$LOG"
            [ "$rc" = 0 ] && success=1 && break 2
            sleep 30
        done
    done
fi

echo "=== done at $(date -u +%FT%TZ) success=$success ===" >> "$LOG"
[ "$success" = 1 ]
