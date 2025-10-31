#!/usr/bin/env bash
set -euo pipefail

if ! podman ps -f name=vulnerability-scanner --format '{{.Names}}' | grep -q vulnerability-scanner; then
  echo "vulnerability-scanner container not running" >&2
  exit 1
fi

echo "Attempting to contact GVM API..."
podman exec vulnerability-scanner gvm-cli socket --xml '<get_version/>' >/dev/null 2>&1 || {
  echo "GVM CLI check failed" >&2
  exit 1
}

echo "OpenVAS/GVM responsive"
