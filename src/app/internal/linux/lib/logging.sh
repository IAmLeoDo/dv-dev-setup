# shellcheck shell=bash
log() { printf '[dv] %s\n' "$*"; if [[ ${DV_CHANGE_MODE:-} == --apply && ${DV_DRY_RUN:-true} != true && -n ${DV_LOG_FILE:-} ]]; then printf '[dv] %s\n' "$*" >> "$DV_LOG_FILE"; fi; }
die() { log "ERROR: $*" >&2; exit 1; }
run() { if [[ ${DV_DRY_RUN:-true} == true ]]; then printf '[dry-run]'; printf ' %q' "$@"; printf '\n'; else "$@"; fi; }
