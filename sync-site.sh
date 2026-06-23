#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DOMAIN="card5.cyber-beast.tech"
TARGET_WEB_ROOT="${1:-/var/www/${SITE_DOMAIN}}"

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

ensure_command_exists() {
  local command_name="$1"
  local install_hint="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf "Required command '%s' was not found. %s\n" "$command_name" "$install_hint" >&2
    exit 1
  fi
}

run_as_needed() {
  if [[ "$1" == "sudo" ]]; then
    shift
    sudo "$@"
    return
  fi

  if [[ "$1" == "direct" ]]; then
    shift
    "$@"
    return
  fi

  "$@"
}

ensure_command_exists rsync "Install rsync first."

if [[ -z "$TARGET_WEB_ROOT" || "$TARGET_WEB_ROOT" == "/" ]]; then
  die "Target web root must be a non-root path."
fi

if ! command -v sudo >/dev/null 2>&1; then
  if [[ ! -w "$(dirname "$TARGET_WEB_ROOT")" ]]; then
    die "sudo is required to create or update '$TARGET_WEB_ROOT'."
  fi
  privilege_mode="direct"
else
  if [[ -e "$TARGET_WEB_ROOT" && -w "$TARGET_WEB_ROOT" ]]; then
    privilege_mode="direct"
  else
    privilege_mode="sudo"
  fi
fi

printf 'Syncing Dr. Zulkifli namecard for %s from %s to %s\n' "$SITE_DOMAIN" "$SCRIPT_DIR" "$TARGET_WEB_ROOT"

run_as_needed "$privilege_mode" mkdir -p "$TARGET_WEB_ROOT"

rsync_args=(
  -av
  --delete
  --delete-excluded
  --include='/index.html'
  --include='/styles.css'
  --include='/Dr-Zulkifli-Hasan.vcf'
  --include='/assets/'
  --include='/assets/***'
  --exclude='*'
  "$SCRIPT_DIR/"
  "$TARGET_WEB_ROOT/"
)

run_as_needed "$privilege_mode" rsync "${rsync_args[@]}"

printf 'Sync complete. Live site root updated for %s: %s\n' "$SITE_DOMAIN" "$TARGET_WEB_ROOT"
