#!/usr/bin/env bash
# Smoke test for dgcosenza/synchronet: verifies fresh initialization,
# non-root UID 1000 execution, capability configuration, HTTP webv4 response,
# and a negative check against an unbound port.
set -euo pipefail

IMAGE="${1:-dgcosenza/synchronet:ci-candidate}"
NAME="synchronet-ci-smoke-$$"
TMPDATA="$(mktemp -d)"
chmod 777 "$TMPDATA"

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker run --rm --user 0:0 -v "${TMPDATA}:/cleanup" --entrypoint rm "$IMAGE" -rf /cleanup/.deno /cleanup/backup /cleanup/ctrl /cleanup/data /cleanup/fido /cleanup/mods /cleanup/nodes /cleanup/text /cleanup/web /cleanup/xtrn /cleanup/.synchronet-init.lock >/dev/null 2>&1 || true
  rm -rf "$TMPDATA" 2>/dev/null || true
}
trap cleanup EXIT

docker run -d \
  --name "$NAME" \
  -e TZ=Etc/UTC \
  -v "${TMPDATA}:/sbbs-data" \
  "$IMAGE"

# Verify container runs as non-root UID/GID 1000 (sbbs).
UID_ACTUAL="$(docker exec "$NAME" id -u)"
GID_ACTUAL="$(docker exec "$NAME" id -g)"
test "$UID_ACTUAL" = "1000"
test "$GID_ACTUAL" = "1000"

# Verify cap_net_bind_service capability is set on the sbbs binary.
docker exec "$NAME" getcap /sbbs/exec/sbbs | grep -q 'cap_net_bind_service'

# A freshly initialized Synchronet database has no users, so webv4's
# index.xjs (and the image HEALTHCHECK that curls it) reports
# "Guest account unavailable". Bootstrap the sysop and Guest accounts with
# the upstream scripts exactly as a real install does, instead of weakening
# the health probe.
for _ in $(seq 1 90); do
  if docker exec "$NAME" test -f /sbbs-data/ctrl/sbbs.ini 2>/dev/null; then
    break
  fi
  sleep 2
done

USER_COUNT="$(docker exec "$NAME" /sbbs/exec/jsexec -n -r 'writeln(system.stats.total_users)' 2>/dev/null | grep -oE '^[0-9]+' | head -1 || true)"
if [ -z "${USER_COUNT}" ] || [ "${USER_COUNT}" -eq 0 ]; then
  # "Sysop" is a well-known sysop alias that matchuser() resolves to user #1
  # even on an empty database, so makeuser.js rejects it. Use a plain alias.
  # Upstream makeuser.js also requires -P to define its password variable;
  # generate a throwaway value at runtime and never print or persist it.
  echo "Creating initial bootstrap user account"
  BOOTSTRAP_PASS="$(openssl rand -hex 16)"
  docker exec "$NAME" /sbbs/exec/jsexec -n /sbbs/exec/makeuser.js Bootstrap -P "$BOOTSTRAP_PASS"
  unset BOOTSTRAP_PASS
fi
echo "Ensuring Guest account exists"
docker exec "$NAME" /sbbs/exec/jsexec -n /sbbs/exec/makeguest.js

# Wait for the container's Docker HEALTHCHECK to report healthy
HEALTHY=0
HEALTH_STATUS="missing"
for _ in $(seq 1 180); do
  HEALTH_STATUS="$(docker inspect --format '{{.State.Health.Status}}' "$NAME" 2>/dev/null || echo "missing")"
  if [ "$HEALTH_STATUS" = "healthy" ]; then
    HEALTHY=1
    break
  fi
  if [ "$HEALTH_STATUS" = "missing" ] || [ "$(docker inspect --format '{{.State.Running}}' "$NAME" 2>/dev/null || echo false)" != "true" ]; then
    echo "ERROR: container exited before becoming healthy (health status=${HEALTH_STATUS})" >&2
    docker logs "$NAME" >&2 || true
    exit 1
  fi
  sleep 2
done
if [ "$HEALTHY" -ne 1 ]; then
  echo "ERROR: container did not become healthy within 360s (status=${HEALTH_STATUS:-unknown})" >&2
  docker logs "$NAME" >&2 || true
  exit 1
fi
echo "Docker healthcheck: healthy"

# Wait for Synchronet initialization and webv4 HTTP service on port 80.
# Fresh unconfigured Synchronet databases have no Guest user yet (so index.xjs
# cannot open a guest session); create a static probe file once web/root exists
# and verify webv4 serves it with HTTP 200.
READY=0
for _ in $(seq 1 60); do
  if ! docker ps -q --filter "name=^/${NAME}$" | grep -q .; then
    echo "ERROR: container exited prematurely:" >&2
    docker logs "$NAME" >&2 || true
    exit 1
  fi
  if [ -d "${TMPDATA}/web/root" ] && [ ! -f "${TMPDATA}/web/root/smoke.txt" ]; then
    docker exec "$NAME" sh -c 'printf "synchronet-smoke-ok\n" > /sbbs-data/web/root/smoke.txt' 2>/dev/null || true
  fi
  CODE="$(docker exec "$NAME" curl -s --max-time 5 -o /dev/null -w '%{http_code}' http://127.0.0.1/smoke.txt 2>/dev/null || true)"
  if [ "$CODE" = "200" ]; then
    READY=1
    break
  fi
  sleep 2
done

if [ "$READY" -ne 1 ]; then
  echo "ERROR: Synchronet webv4 did not return HTTP 200 within timeout (last code=${CODE:-none})." >&2
  docker logs "$NAME" >&2 || true
  exit 1
fi

# Verify webv4 serves the expected static probe body and healthcheck curl succeeds.
BODY="$(docker exec "$NAME" curl --fail --silent --show-error --max-time 10 http://127.0.0.1/smoke.txt)"
test "$BODY" = "synchronet-smoke-ok"

# Verify sbbs daemon process runs under the non-root sbbs account.
docker exec "$NAME" ps -eo user,comm | grep -qE '^sbbs[[:space:]]+sbbs$'

# Verify /sbbs-data was initialized.
test -f "${TMPDATA}/ctrl/sbbs.ini"
test -f "${TMPDATA}/ctrl/version.txt"

# Negative test: confirm the HTTP check fails against a closed port.
if docker exec "$NAME" curl --fail --silent --output /dev/null --max-time 3 http://127.0.0.1:59999/; then
  echo "ERROR: healthcheck unexpectedly passed on closed port 59999" >&2
  exit 1
fi

echo "Smoke test passed (uid=${UID_ACTUAL}, gid=${GID_ACTUAL}, http=${CODE})."
