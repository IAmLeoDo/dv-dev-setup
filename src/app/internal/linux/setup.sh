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
parse_change_options "$@"
set -- "${DV_CHANGE_ARGS[@]}"
selection=all
setup_modules=(system git ssh python node docker vscode workspace aliases)
while (($#)); do
    case $1 in
        --all) selection=all; shift ;;
        --only) (($# >= 2)) || die '--only requires a module'; selection=$2; shift 2 ;;
        --verify) selection=verify; shift ;;
        --help|-h) printf '%s\n' \
            'Usage: bash dev.sh setup [--all | --only system|git|ssh|python|node|docker|vscode|workspace|aliases|tools | --verify] [--apply | --dry-run]' \
            'Default: summary only, with no installs, file writes or service changes.' \
            'Add --apply to execute. --verify is read-only and accepts no mode flag.'; exit 0 ;;
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
if [[ $selection == verify ]]; then
    [[ -z $DV_CHANGE_MODE ]] || die '--verify is read-only; omit --apply/--dry-run'
    exec "$DV_ROOT/linux/tools/dv" doctor
fi
# Preview only plans the selected modules. Never source installers, request sudo,
# initialize managers, test SSH/Docker, prompt, or create logs in this branch.
if [[ $DV_DRY_RUN == true ]]; then
    source "$DV_ROOT/linux/lib/install.sh"
    install_runtime
    for item in "${setup_modules[@]}"; do
        [[ $selection == all || $selection == "$item" ]] || continue
        flag=DV_INSTALL_${item^^}
        [[ ${!flag:-true} == true ]] || { log "Skip $item (configuration)"; continue; }
        case $item in
            system) log 'System: install missing Ubuntu development prerequisites; no bulk upgrades' ;;
            git) log 'Git: install if missing; configure missing defaults; confirm before replacing existing identity' ;;
            ssh) log 'SSH: ensure client/keychain, permissions and shell initialization; preserve existing keys/config'
                [[ ${DV_SSH_GENERATE:-false} != true ]] || log 'SSH: generate an Ed25519 key only if absent; passphrase prompt during --apply'
                [[ ${DV_GITHUB_TEST:-false} != true ]] || log 'SSH: test GitHub authentication during --apply' ;;
            python) log "Python: ensure pyenv $DV_PYENV_VERSION and Python $DV_PYTHON_VERSION; preserve global selection" ;;
            node) log "Node: ensure nvm $DV_NVM_VERSION and Node $DV_NODE_VERSION; configure shell initialization" ;;
            docker) log "Docker: ensure verified APT source and missing Engine/Compose packages; on-demand=$DV_DOCKER_ON_DEMAND"
                # shellcheck source=src/app/internal/linux/lib/docker.sh
                source "$DV_ROOT/linux/lib/docker.sh"
                configure_docker_group
                [[ ${DV_DOCKER_TEST:-false} != true ]] || log 'Docker: run hello-world validation during --apply' ;;
            vscode) log 'VS Code: display manual host/WSL setup guidance and editor recommendations' ;;
            workspace) log "Workspace: ensure $DV_PROJECTS_ROOT, $DV_WORKSPACE_ROOT/personal and $DV_WORKSPACE_ROOT/experiments" ;;
            aliases) log "Aliases: write ${#DV_ALIAS_NAMES[@]} mappings to ~/.config/dv/aliases.bash; ensure .bashrc activation"
                for alias_index in "${!DV_ALIAS_NAMES[@]}"; do
                    log "  ${DV_ALIAS_NAMES[$alias_index]} -> ${DV_ALIAS_TARGETS[$alias_index]}"
                done ;;
        esac
    done
    preview_notice
    exit 0
fi
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
for item in "${setup_modules[@]}"; do
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
