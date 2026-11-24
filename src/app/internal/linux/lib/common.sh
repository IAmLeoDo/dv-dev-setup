# shellcheck shell=bash
# shellcheck disable=SC2034 # Shared state consumed by sourced modules.
DV_ROOT=${DV_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
# Consent is scoped to this invocation, never inherited from the environment.
DV_CHANGE_MODE=''
# shellcheck source=linux/lib/logging.sh
source "$DV_ROOT/linux/lib/logging.sh"
# shellcheck source=linux/lib/detection.sh
source "$DV_ROOT/linux/lib/detection.sh"
# Mutations require a flag on this invocation; environment/config cannot opt in.
# Keep -- intact so filenames following it are never interpreted as mode flags.
parse_change_options() {
    local option locked=${DV_DRY_RUN:-false}
    DV_DRY_RUN=true
    DV_CHANGE_MODE=''
    DV_CHANGE_ARGS=()
    while (($#)); do
        option=$1; shift
        case $option in
            --apply|--dry-run)
                [[ -z $DV_CHANGE_MODE || $DV_CHANGE_MODE == "$option" ]] || die 'Do not combine --apply and --dry-run'
                DV_CHANGE_MODE=$option ;;
            --) DV_CHANGE_ARGS+=(-- "$@"); break ;;
            *) DV_CHANGE_ARGS+=("$option") ;;
        esac
    done
    if [[ $DV_CHANGE_MODE == --apply ]]; then
        [[ $locked != true ]] || die 'DV_DRY_RUN=true prevents --apply'
        DV_DRY_RUN=false
    fi
}
preview_notice() {
    log 'Preview only. Nothing changed. Add --apply to this command to execute the plan.'
}
load_config() {
    local tools_root_from_env=${DV_TOOLS_ROOT+x}
    # Installed tools automatically use the persistent user override.
    if [[ -z ${DV_CONFIG:-} && -f $DV_ROOT/../.dv-managed-runtime && -f $HOME/.config/dv/config.ini ]]; then
        DV_CONFIG="$HOME/.config/dv/config.ini"
    fi
    local file=${DV_CONFIG:-$DV_ROOT/../config.ini} line key value input section
    local -A assigned=()
    local inputs=("$DV_ROOT/../config.ini")
    if [[ -n ${DV_CONFIG:-} && ! -f $file ]]; then die "Configuration file not found"; fi
    [[ ! -f $file || $file == "${inputs[0]}" ]] || inputs+=("$file")
    for input in "${inputs[@]}"; do
    section=setup
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%$'\r'}
        [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
        if [[ $line =~ ^\[([^]]+)\]$ ]]; then section=${BASH_REMATCH[1]}; continue; fi
        [[ $section == setup ]] || continue
        [[ $line =~ ^(DV_[A-Z_]+)=(.*)$ ]] || die 'Invalid configuration assignment'
        key=${BASH_REMATCH[1]}; value=${BASH_REMATCH[2]}
        case $key in
            DV_TOOLS_ROOT|DV_ORG|DV_WORKSPACE_ROOT|DV_PROJECTS_ROOT|DV_GITHUB_USER|DV_GIT_NAME|DV_GIT_EMAIL|DV_GIT_DEFAULT_BRANCH|DV_PYTHON_VERSION|DV_PYENV_VERSION|DV_NODE_VERSION|DV_NVM_VERSION|DV_INSTALL_GIT|DV_INSTALL_SSH|DV_INSTALL_PYTHON|DV_INSTALL_NODE|DV_INSTALL_DOCKER|DV_INSTALL_ALIASES|DV_DOCKER_ON_DEMAND|DV_DOCKER_ADD_USER_TO_GROUP|DV_SSH_GENERATE|DV_SSH_NO_PASSPHRASE|DV_GITHUB_TEST|DV_DOCKER_TEST) ;;
            *) die "Unknown configuration key: $key" ;;
        esac
        if [[ $value == \"*\" || $value == \'*\' ]]; then value=${value:1:${#value}-2}; fi
        value=${value//\$HOME/$HOME}
        if [[ ! -v $key || -v assigned[$key] ]]; then
            printf -v "$key" '%s' "$value"
            assigned[$key]=1
        fi
    done < "$input"
    done
    : "${DV_TOOLS_ROOT:=$HOME/.local/share/dv-dev-setup}"
    : "${DV_ORG:=devimony}" "${DV_WORKSPACE_ROOT:=$HOME/workspace}" "${DV_PROJECTS_ROOT:=$DV_WORKSPACE_ROOT/$DV_ORG}"
    # An installed copy knows its own location even if it was initially installed
    # using a one-off DV_TOOLS_ROOT environment override.
    if [[ -f $DV_ROOT/../.dv-managed-runtime && -z $tools_root_from_env ]]; then
        DV_TOOLS_ROOT=$(cd -- "$DV_ROOT/../.." && pwd -P)
    fi
    local flag
    for flag in DV_INSTALL_GIT DV_INSTALL_SSH DV_INSTALL_PYTHON DV_INSTALL_NODE DV_INSTALL_DOCKER DV_INSTALL_ALIASES DV_DOCKER_ON_DEMAND DV_DOCKER_ADD_USER_TO_GROUP DV_SSH_GENERATE DV_SSH_NO_PASSPHRASE DV_GITHUB_TEST DV_DOCKER_TEST; do
        [[ ${!flag:-false} == true || ${!flag:-false} == false ]] || die "Invalid boolean: $flag"
    done
    [[ $DV_PYTHON_VERSION =~ ^3\.[0-9]+\.[0-9]+$ ]] || die 'Invalid Python version'
    [[ $DV_PYENV_VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ && $DV_NVM_VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die 'Invalid installer release'
    [[ $DV_NODE_VERSION == 'lts/*' || $DV_NODE_VERSION =~ ^v?[0-9]+(\.[0-9]+){0,2}$ ]] || die 'Invalid Node version'
    [[ $DV_ORG =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]] || die 'Invalid organization'
    local path
    for path in "$DV_TOOLS_ROOT" "$DV_WORKSPACE_ROOT" "$DV_PROJECTS_ROOT"; do
        [[ $path == /* && $path != / && $path != /mnt/* && $path != *'/../'* && $path != */.. ]] || die 'Tool/workspace paths must be absolute Linux filesystem paths (not / or /mnt/)'
    done
    DV_TOOLS_ROOT=$(readlink -m -- "$DV_TOOLS_ROOT")
    [[ $DV_TOOLS_ROOT != / && $DV_TOOLS_ROOT != /mnt && $DV_TOOLS_ROOT != /mnt/* ]] || die 'Tool storage must be on the Linux filesystem, outside /mnt/'
}
# Read raw template sections without evaluating their contents.
config_section() {
    local section=$1 input output
    local inputs=("$DV_ROOT/../config.ini")
    [[ -z ${DV_CONFIG:-} ]] || inputs=("$DV_CONFIG" "${inputs[@]}")
    for input in "${inputs[@]}"; do
        if output=$(awk -v section="$section" '
            { sub(/\r$/, "") }
            /^\[[^]]+\]$/ { active = ($0 == "[" section "]"); if (active) found = 1; next }
            active { print }
            END { if (!found) exit 1 }
        ' "$input"); then
            printf '%s\n' "$output"
            return
        fi
    done
    die "Missing configuration section: $section"
}
append_once() {
    local file=$1 line=$2
    if [[ -f $file ]] && grep -Fqx -- "$line" "$file"; then return; fi
    if [[ ${DV_DRY_RUN:-false} == true ]]; then log "Would append shell initialization to $file"; return; fi
    mkdir -p -- "$(dirname -- "$file")"
    printf '\n%s\n' "$line" >> "$file"
}
confirm() { local answer; [[ -t 0 ]] || return 1; read -r -p "$1 [y/N] " answer; [[ $answer == y || $answer == Y ]]; }
valid_name() { [[ $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; }
github_auth() {
    local output code=0
    output=$(ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=yes -T git@github.com 2>&1) || code=$?
    if [[ $code == 1 && $output == *'successfully authenticated, but GitHub does not provide shell access.'* ]]; then
        printf 'authenticated\n'
    else printf 'not authenticated (exit %s; check key registration, agent, and known_hosts)\n' "$code"; return 1; fi
}
