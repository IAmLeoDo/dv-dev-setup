# shellcheck shell=bash
[[ $# == 0 || ( $# == 1 && $1 == --github ) ]] || die 'Usage: dv doctor [--github]'

doctor_section() {
    printf '\n  %s\n  ------------------------------------------------------------\n' "$1"
}
doctor_row() {
    printf '  %-6s %-18s %s\n' "[$1]" "$2" "$3"
}
doctor_version() {
    local label=$1 output
    shift
    if ! has "$1"; then
        doctor_row WARN "$label" 'not available in PATH'
    elif output=$("$@" 2>/dev/null) && [[ -n $output ]]; then
        output=${output%%$'\n'*}
        doctor_row OK "$label" "${output%$'\r'}"
    else
        doctor_row WARN "$label" 'installed, but version query failed'
    fi
}

doctor_group() {
    printf '\n    %s\n' "$1"
}
doctor_runtime_version() {
    if has "$2"; then
        doctor_version "$@"
    else
        doctor_row INFO "$1" 'not available in PATH; install/select a version with the manager'
    fi
}

doctor_alias_text() {
    printf '         %s\n' "$1"
}
doctor_alias_heading() {
    printf '\n      %s\n' "$1"
}
doctor_alias_option() {
    printf '         %-22s %s\n' "$1" "$2"
}
doctor_alias_usage() {
    local name=$1 target=$2 syntax=''
    case $target in
        'dv doctor') syntax=' [--github]' ;;
        'dv workspace') syntax=' [show|open|create] [ARGS]' ;;
        'dv workspace open') syntax=' [--add] [--] [DIR ...]' ;;
        'dv cleanup') syntax=' [ACTION] [OPTIONS]' ;;
        'git status') syntax=' [OPTIONS] [-- PATH ...]' ;;
        'git diff'|'git log --oneline') syntax=' [OPTIONS] [REV ...] [-- PATH ...]' ;;
    esac
    doctor_row INFO "$name" "$target"
    doctor_alias_heading 'Usage'
    doctor_alias_text "$name$syntax"
    case $target in
        'dv cleanup')
            doctor_alias_heading 'Actions'
            doctor_alias_option cache 'Clear default download caches (default action)'
            doctor_alias_option 'project DIR' 'Remove .venv and node_modules in one project'
            doctor_alias_option 'python X.Y.Z' 'Remove one pyenv Python version'
            doctor_alias_option 'node X.Y.Z' 'Remove one nvm Node.js version'
            doctor_alias_option all 'Select managed tools, recorded packages and caches'
            doctor_alias_option 'tools [NAME ...]' 'Select specific tools, or all tools if omitted'
            doctor_alias_option 'packages NAME ...' 'Select exact allowed APT package names'
            doctor_alias_heading 'Summary only (nothing is removed)'
            doctor_alias_text "$name all --keep dv,pyenv,nvm"
            doctor_alias_text "$name project ./my-project --only node"
            doctor_alias_heading 'Apply (asks for confirmation)'
            doctor_alias_text "$name all --keep dv --apply"
            doctor_alias_heading 'Options'
            doctor_alias_option '--keep NAME,...' 'Keep selected tools (comma-separated names)'
            doctor_alias_option '--include-existing' 'Include preexisting allowed APT packages'
            doctor_alias_option '--only python|node' 'Limit project cleanup to one dependency type'
            doctor_alias_option --dry-run 'Summary only; do not change anything'
            doctor_alias_option --apply 'Validate the plan, confirm, then remove'
            doctor_alias_option --yes 'Skip the prompt; requires --apply'
            doctor_alias_option '--help, -h' 'Show cleanup help'
            doctor_alias_option -- 'End option parsing'
            doctor_alias_heading 'Tool names for --keep / tools'
            doctor_alias_text 'dv, pyenv, nvm, docker, git, ssh, packages'
            doctor_alias_text 'python = pyenv; node = nvm'
            ;;
        'dv workspace open')
            doctor_alias_heading 'Examples'
            doctor_alias_option "$name ." 'Open the current folder'
            doctor_alias_option "$name ./frontend ./backend" 'Open multiple folders'
            doctor_alias_option "$name --add ./shared" 'Add a folder to the last active window'
            doctor_alias_heading 'Options'
            doctor_alias_option '--add DIR ...' 'Add existing folders to the last active window'
            doctor_alias_option '--help, -h' 'Show folder-opening help'
            doctor_alias_option -- 'End options (for paths starting with -)'
            doctor_alias_text 'No DIR: use the configured project root.'
            doctor_alias_text 'Folders must exist. Quote paths containing spaces.' ;;
        'dv doctor')
            doctor_alias_heading 'Options'
            doctor_alias_option --github 'Also test GitHub SSH authentication (uses network)'
            doctor_alias_heading 'Example'
            doctor_alias_text "$name --github" ;;
        'dv workspace')
            doctor_alias_heading 'Actions'
            doctor_alias_option show 'Print workspace and project roots (default)'
            doctor_alias_option 'open [DIR ...]' 'Open the default root or selected folders'
            doctor_alias_option 'open --add DIR ...' 'Add folders to the last active editor window'
            doctor_alias_option 'create NAME' 'Create project sources/docs/builds directories'
            doctor_alias_heading 'Examples'
            doctor_alias_text "$name open ."
            doctor_alias_text "$name create my-project"
            doctor_alias_text "$name open --help" ;;
        'git status')
            doctor_alias_heading 'Examples'
            doctor_alias_option "$name --short" 'Compact status'
            doctor_alias_option "$name --branch --short" 'Include the current branch'
            doctor_alias_option "$name -- ./src" 'Limit output to a path'
            doctor_alias_text "All Git status options: $name --help" ;;
        'git diff')
            doctor_alias_heading 'Examples'
            doctor_alias_option "$name --stat" 'Changed-file summary'
            doctor_alias_option "$name --cached" 'Review staged changes'
            doctor_alias_option "$name -- ./src" 'Limit output to a path'
            doctor_alias_text "All Git diff options: $name --help" ;;
        'git log --oneline')
            doctor_alias_heading 'Examples'
            doctor_alias_option "$name -5" 'Last five commits'
            doctor_alias_option "$name --all --graph" 'Graph across branches'
            doctor_alias_option "$name -- ./src" 'History for one path'
            doctor_alias_text "All Git log options: $name --help" ;;
        'dv worktree list')
            doctor_alias_text 'Run inside a project worktree. No extra arguments.' ;;
        'dv docker start'|'dv docker stop'|'dv docker restart'|'dv docker status')
            doctor_alias_text 'No extra arguments. Requires systemd.'
            doctor_alias_text 'Start/stop/restart may prompt for sudo.' ;;
    esac
    printf '\n'
}

printf '\n  DV / ENVIRONMENT REPORT\n'
printf '  OK = available   WARN = needs review   INFO = context / not tested\n'

doctor_section 'TOOL PATHS'
app_directory=$(cd -- "$DV_ROOT/.." && pwd -P)
doctor_row INFO 'Tools root' "$DV_TOOLS_ROOT"
doctor_row INFO 'Active runtime' "$app_directory"
doctor_row INFO 'CLI executable' "$SELF"
doctor_row INFO 'CLI command' "$HOME/.local/bin/dv"
if [[ -f $app_directory/.dv-managed-runtime ]]; then
    doctor_row OK Installation 'running the installed runtime copy'
else
    doctor_row INFO Installation 'running from source/bundle; setup or install copies the tools'
fi
doctor_row INFO 'Default config' "$app_directory/config.ini"
doctor_row INFO 'User config' "$HOME/.config/dv/config.ini"
doctor_row INFO 'Alias file' "$HOME/.config/dv/aliases.bash"
doctor_row INFO 'pyenv root' "${PYENV_ROOT:-$HOME/.pyenv}"
doctor_row INFO 'nvm root' "${NVM_DIR:-$HOME/.nvm}"
if [[ -n ${DV_CONFIG:-} ]]; then
    doctor_row INFO 'Config override' "$(readlink -f -- "$DV_CONFIG")"
else
    doctor_row INFO 'Config override' 'none (using default config and environment overrides)'
fi
doctor_row INFO 'Run directory' "$(pwd -P)"

doctor_section '1. SYSTEM'
detect_os /etc/os-release
doctor_row INFO OS "$DV_OS_ID $DV_OS_VERSION ($DV_ARCH)"
if grep -qi microsoft /proc/sys/kernel/osrelease; then
    doctor_row INFO WSL "detected; kernel $(uname -r)"
    doctor_row INFO 'WSL version' 'confirm from Windows with wsl -l -v'
else
    doctor_row INFO WSL 'not detected'
fi

doctor_section '2. DEVELOPMENT TOOLS'
doctor_group 'Python / pyenv'
if [[ -x ${PYENV_ROOT:-$HOME/.pyenv}/bin/pyenv ]]; then
    doctor_version pyenv "${PYENV_ROOT:-$HOME/.pyenv}/bin/pyenv" --version
else
    doctor_row WARN pyenv 'version manager missing at PYENV_ROOT; review setup --only python'
fi
doctor_runtime_version '  python3 (PATH)' python3 --version

doctor_group 'Node.js / nvm'
if [[ -s ${NVM_DIR:-$HOME/.nvm}/nvm.sh ]]; then
    doctor_row OK nvm 'version manager installed; load Bash initialization to activate'
else
    doctor_row WARN nvm 'version manager missing at NVM_DIR; review setup --only node'
fi
doctor_runtime_version '  node (PATH)' node --version
doctor_runtime_version '  npm (PATH)' npm --version

doctor_group 'Other tools'
for tool in git code; do
    doctor_version "$tool" "$tool" --version
done

doctor_section '3. GIT & SSH'
if has git && git config --get user.name >/dev/null && git config --get user.email >/dev/null; then
    doctor_row OK 'Git identity' 'name and email configured'
else
    doctor_row WARN 'Git identity' 'incomplete; configure Git user.name and user.email'
fi
if ! has ssh-add; then
    doctor_row WARN 'SSH Agent' 'ssh-add unavailable; review setup --only ssh'
elif ssh-add -l >/dev/null 2>&1; then
    doctor_row OK 'SSH Agent' 'running with identities'
elif [[ -n ${SSH_AUTH_SOCK:-} ]]; then
    doctor_row WARN 'SSH Agent' 'socket configured, identities unavailable'
else
    doctor_row WARN 'SSH Agent' 'not configured'
fi
if [[ ${1:-} == --github ]]; then
    if auth_result=$(github_auth); then
        doctor_row OK 'GitHub SSH' "$auth_result"
    else
        doctor_row WARN 'GitHub SSH' "$auth_result"
    fi
else
    doctor_row INFO 'GitHub SSH' 'not tested; run dv doctor --github (or dvc --github)'
fi

doctor_section '4. DOCKER'
doctor_version 'Docker CLI' docker --version
if has docker; then
    doctor_version Compose docker compose version
else
    doctor_row WARN Compose 'unavailable; Docker CLI missing'
fi
if [[ $(cat /proc/1/comm) == systemd ]] && has systemctl; then
    service_state=$(systemctl is-active docker.service 2>/dev/null) || service_state=${service_state:-unknown}
    case $service_state in
        active) doctor_row OK Service "$service_state" ;;
        inactive)
            if [[ ${DV_DOCKER_ON_DEMAND:-false} == true ]]; then
                doctor_row INFO Service 'inactive (expected in on-demand mode)'
            else
                doctor_row WARN Service 'inactive; use dv docker start when needed'
            fi ;;
        *) doctor_row WARN Service "$service_state" ;;
    esac
    autostart_state=$(systemctl is-enabled docker.service 2>/dev/null) || autostart_state=${autostart_state:-unknown}
    case $autostart_state in
        enabled) doctor_row INFO Autostart enabled ;;
        disabled) doctor_row INFO Autostart 'disabled (manual startup)' ;;
        *) doctor_row WARN Autostart "$autostart_state" ;;
    esac
else
    doctor_row WARN Service 'systemd unavailable; service state not checked'
    doctor_row INFO Autostart 'not checked without systemd'
fi

doctor_section '5. WORKSPACE'
doctor_row INFO 'Workspace root' "$DV_WORKSPACE_ROOT"
for workspace_label in Projects Personal Experiments; do
    case $workspace_label in
        Projects) directory=$DV_PROJECTS_ROOT ;;
        Personal) directory="$DV_WORKSPACE_ROOT/personal" ;;
        Experiments) directory="$DV_WORKSPACE_ROOT/experiments" ;;
    esac
    if [[ -d $directory ]]; then
        doctor_row OK "$workspace_label" "$directory"
    else
        doctor_row WARN "$workspace_label" "$directory (missing; run setup --only workspace)"
    fi
done
doctor_row INFO 'Sources layout' "$DV_PROJECTS_ROOT/<project>/sources/<project>-dev"
if has git && current_checkout=$(git rev-parse --show-toplevel 2>/dev/null); then
    doctor_row INFO 'Current checkout' "$current_checkout"
    checkout_parent=$(dirname -- "$current_checkout")
    if [[ $checkout_parent == */sources ]]; then
        doctor_row INFO 'Project sources' "$checkout_parent"
    fi
else
    doctor_row INFO 'Current checkout' 'not inside a Git checkout; run from a project to inspect its path'
fi

doctor_section '6. ALIASES'
doctor_row INFO 'Setup toggle' "DV_INSTALL_ALIASES=${DV_INSTALL_ALIASES:-true} (controls future setup)"
alias_file="$HOME/.config/dv/aliases.bash"
if [[ -L $alias_file || ( -e $alias_file && ! -f $alias_file ) ]]; then
    doctor_row WARN 'Alias file' 'expected a regular file at ~/.config/dv/aliases.bash'
elif [[ ! -r $alias_file ]]; then
    doctor_row WARN 'Alias file' 'missing or unreadable; run setup --only aliases'
else
    alias_first_line=''
    IFS= read -r alias_first_line < "$alias_file" || true
    if [[ $alias_first_line != '# Generated by dv-dev-setup: Bash aliases' ]]; then
        doctor_row WARN 'Alias file' 'unmanaged; preserve it before running alias setup'
    elif bash -n "$alias_file" 2>/dev/null; then
        doctor_row OK 'Alias file' '~/.config/dv/aliases.bash (syntax valid; not executed)'
    else
        doctor_row WARN 'Alias file' 'invalid Bash syntax; review config.ini and rerun alias setup'
    fi
fi
# shellcheck disable=SC2016 # Match the literal startup line written by setup.
if [[ -r $HOME/.bashrc ]] && grep -Fqx -- '[ ! -f "$HOME/.config/dv/aliases.bash" ] || . "$HOME/.config/dv/aliases.bash"' "$HOME/.bashrc"; then
    doctor_row OK 'Bash startup' 'managed source line present in ~/.bashrc'
else
    doctor_row WARN 'Bash startup' 'managed source line missing; review setup --only aliases'
fi
# Validate in a subshell so bad alias configuration does not truncate the report.
# Only shared application code is sourced; the generated alias file is not run.
if configured_aliases=$(
    # shellcheck source=src/app/internal/linux/lib/aliases.sh
    source "$DV_ROOT/linux/lib/aliases.sh" || exit 1
    load_aliases || exit 1
    for alias_index in "${!DV_ALIAS_NAMES[@]}"; do
        doctor_alias_usage "${DV_ALIAS_NAMES[$alias_index]}" "${DV_ALIAS_TARGETS[$alias_index]}"
    done
); then
    doctor_row INFO Configuration 'configured aliases with full syntax; [] optional, ... multiple values'
    if [[ -n $configured_aliases ]]; then
        printf '%s\n' "$configured_aliases"
    else
        doctor_row INFO Configuration 'no aliases configured'
    fi
else
    doctor_row WARN Configuration 'invalid [aliases]; review config.ini or DV_CONFIG'
fi
doctor_row INFO 'Current shell' 'not inspected; child processes cannot see parent-shell aliases'
# shellcheck disable=SC2016 # Display the activation command without evaluating it.
doctor_row INFO Activation 'In your Bash terminal: source "$HOME/.config/dv/aliases.bash"'
printf '\n  Report complete. Review WARN rows; missing optional tools may be intentional.\n'
printf '  Checks do not install tools or change configuration.\n\n'
