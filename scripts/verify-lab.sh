#!/usr/bin/env bash
set -euo pipefail

check() {
  local name="$1"
  shift
  echo -n "Checking $name... "
  if "$@" >/dev/null 2>&1; then
    echo "ok"
  else
    echo "FAIL"
    return 1
  fi
}

podman ps >/dev/null

check "kali-vnc" podman ps -f name=kali-vnc --format '{{.Names}}'
check "http-test" podman exec http-test curl -sf http://localhost:8000/
check "librenms" podman ps -f name=librenms --format '{{.Names}}'
check "gvm" podman ps -f name=vulnerability-scanner --format '{{.Names}}'

echo "All checks passed."
