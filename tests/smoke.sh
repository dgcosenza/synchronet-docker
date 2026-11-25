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

# Wait for Synchronet initialization and webv4 HTTP service on port 80.
READY=0
for _ in $(seq 1 60); do
  if ! docker ps -q --filter "name=^/${NAME}$" | grep -q .; then
    echo "ERROR: container exited prematurely:" >&2
    docker logs "$NAME" >&2 || true
    exit 1
  fi
  CODE="$(docker exec "$NAME" curl -s --max-time 5 -o /dev/null -w '%{http_code}' http://127.0.0.1/ 2>/dev/null || true)"
  if printf '%s' "$CODE" | grep -qE '^[23][0-9][0-9]$'; then
    READY=1
    break
  fi
  sleep 2
done

if [ "$READY" -ne 1 ]; then
  echo "ERROR: Synchronet webv4 did not return 2xx/3xx within timeout." >&2
  docker logs "$NAME" >&2 || true
  exit 1
fi

# Run the exact healthcheck command inside the container.
docker exec "$NAME" curl --fail --silent --show-error --output /dev/null --max-time 10 http://127.0.0.1/

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
