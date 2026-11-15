#!/usr/bin/env bash
# shellcheck disable=SC1090 # Module paths are selected from a fixed allowlist.
# shellcheck disable=SC2034 # Shared state consumed by sourced modules.
set -Eeuo pipefail
DV_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$DV_ROOT/linux/lib/common.sh"
source "$DV_ROOT/linux/lib/packages.sh"
source "$DV_ROOT/linux/lib/aliases.sh"
trap 'printf "[dv] Setup failed at line %s; rerun after fixing the reported error.\n" "$LINENO" >&2' ERR
setup_args=("$@")
selection=all
while (($#)); do
    case $1 in
        --all) selection=all; shift ;;
        --only) (($# >= 2)) || die '--only requires a module'; selection=$2; shift 2 ;;
        --verify) selection=verify; shift ;;
        --dry-run) DV_DRY_RUN=true; shift ;;
        --help|-h) printf 'Usage: bash dev.sh setup [--all | --only system|git|ssh|python|node|docker|vscode|workspace|aliases|tools | --verify] [--dry-run]\n'; exit 0 ;;
        *) die "Unknown argument: $1" ;;
    esac
done
[[ $selection =~ ^(all|system|git|ssh|python|node|docker|vscode|workspace|aliases|tools|verify)$ ]] || die 'Unknown module'
# Preview and execute against the same persistent settings on later runs.
if [[ -z ${DV_CONFIG:-} && -f $HOME/.config/dv/config.ini ]]; then
    export DV_CONFIG="$HOME/.config/dv/config.ini"
fi
load_config
if [[ ( $selection == all || $selection == aliases ) && ${DV_INSTALL_ALIASES:-true} == true ]]; then
    load_aliases
fi
if [[ $selection == verify ]]; then exec "$DV_ROOT/linux/tools/dv" doctor; fi
((EUID != 0)) || die 'Run as your Linux development user, not root or sudo.'
require_ubuntu
source "$DV_ROOT/linux/lib/install.sh"
install_runtime
if [[ ${DV_DRY_RUN:-false} != true && $(cd -- "$DV_ROOT/.." && pwd -P) != "$(cd -- "$DV_TOOLS_ROOT/app" && pwd -P)" ]]; then
    # Continue from the installed copy so all modules and aliases use its config.
    export DV_TOOLS_ROOT
    exec bash "$DV_TOOLS_ROOT/app/internal/linux/setup.sh" "${setup_args[@]}"
fi
if [[ ${DV_DRY_RUN:-false} != true ]]; then
    umask 077
    mkdir -p "$HOME/.local/state/dv-dev-setup"
    DV_LOG_FILE="$HOME/.local/state/dv-dev-setup/setup.log"
    touch "$DV_LOG_FILE"; chmod 600 "$DV_LOG_FILE"
fi
for item in system git ssh python node docker vscode workspace aliases; do
    [[ $selection == all || $selection == "$item" ]] || continue
    flag=DV_INSTALL_${item^^}
    [[ ${!flag:-true} == true ]] || { log "Skip $item (configuration)"; continue; }
    log "Module: $item"
    case $item in
        system) module=01-system;; git) module=02-git;; ssh) module=03-ssh;; python) module=04-python;; node) module=05-node;; docker) module=06-docker;; vscode) module=07-vscode;; workspace) module=08-workspace;; aliases) module=10-aliases;;
    esac
    source "$DV_ROOT/linux/scripts/$module.sh"
done
log 'Setup complete. Open a new Bash shell for shell initialization changes.'
