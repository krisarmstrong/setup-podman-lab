#!/usr/bin/env bash

# Detects lab version using git metadata or a fallback VERSION file.
# Arguments:
#   $1 - script directory (repository root)
#   $2 - fallback version string
lab_detect_version() {
  local script_dir="$1"
  local fallback="$2"
  local version="$fallback"

  if command -v git >/dev/null 2>&1 && git -C "$script_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git -C "$script_dir" describe --tags --dirty --always >/dev/null 2>&1; then
      version="$(git -C "$script_dir" describe --tags --dirty --always)"
    fi
  elif [ -f "$script_dir/VERSION" ]; then
    version="$(cat "$script_dir/VERSION")"
  fi

  printf '%s\n' "$version"
}
