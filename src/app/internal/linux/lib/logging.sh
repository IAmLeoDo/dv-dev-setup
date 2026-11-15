# shellcheck shell=bash
log() { printf '[dv] %s\n' "$*"; if [[ -n ${DV_LOG_FILE:-} ]]; then printf '[dv] %s\n' "$*" >> "$DV_LOG_FILE"; fi; }
die() { log "ERROR: $*" >&2; exit 1; }
run() { if [[ ${DV_DRY_RUN:-false} == true ]]; then printf '[dry-run]'; printf ' %q' "$@"; printf '\n'; else "$@"; fi; }
