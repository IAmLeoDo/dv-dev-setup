# shellcheck shell=bash
# shellcheck disable=SC1090 # nvm is trusted installed manager code, not config data.
cleanup_help() {
    printf '%s\n' \
        'Usage: dv cleanup [cache|project DIR|python VERSION|node VERSION|all|tools [NAME ...]|packages NAME ...] [OPTIONS]' \
        'Default: summary only; nothing runs without --apply.' \
        '  project DIR        Remove only .venv and node_modules in this project' \
        '  python X.Y.Z       Uninstall one exact pyenv Python version' \
        '  node X.Y.Z         Uninstall one exact nvm Node.js version' \
        '  all                Remove selected dev tools and caches; preserve personal data' \
        '  tools [NAME ...]    Select dv, pyenv, nvm, docker, git, ssh or packages' \
        '  packages NAME ...  Select exact supported APT packages (no purge/autoremove)' \
        '  --keep NAME,...    Keep selected tools during all/tools/packages cleanup' \
        '  --include-existing Include preexisting allowlisted APT packages explicitly' \
        '  --only python|node Limit project cleanup to one dependency directory' \
        '  --dry-run          Preview only (default); never writes or removes files' \
        '  --apply            Apply the displayed plan after terminal confirmation' \
        '  --yes              Skip confirmation; requires --apply' \
        'Project sources, lockfiles, SSH keys, user config, tool backups and Docker data are preserved.'
}
cleanup_guard() {
    local path=$1 canonical lexical protected
    [[ -d $path && ! -L $path ]] || die "Cleanup target must be a real directory: $path"
    canonical=$(readlink -m -- "$path")
    lexical=$(realpath -ms -- "$path")
    [[ $canonical == "$lexical" ]] || die "Cleanup does not follow directory symlinks: $path"
    [[ $canonical != / && $canonical != "$(readlink -m -- "$HOME")" ]] || die 'Refusing cleanup of filesystem/home root'
    for protected in "$HOME/.ssh" "$HOME/.config"; do
        protected=$(readlink -m -- "$protected")
        [[ $canonical != "$protected" && $canonical != "$protected/"* ]] || die "Protected cleanup target: $path"
    done
    protected=$(readlink -m -- "$DV_TOOLS_ROOT/app")
    if [[ $canonical == "$protected" || $canonical == "$protected/"* ]]; then
        [[ $cleanup_remove_dv == true && $canonical == "$protected" ]] || die 'Installed dv runtime is protected unless explicitly selected'
    fi
    if has mountpoint && mountpoint -q -- "$path"; then die "Cleanup target is a mount point: $path"; fi
}
cleanup_add() {
    local label=$1 path=$2 covered
    if [[ ! -e $path && ! -L $path ]]; then return; fi
    cleanup_guard "$path"
    path=$(readlink -m -- "$path")
    for covered in "${cleanup_paths[@]}"; do
        if [[ $path == "$covered" || $path == "$covered/"* ]]; then return; fi
    done
    cleanup_labels+=("$label")
    cleanup_paths+=("$path")
    cleanup_ids+=("$(stat -c '%d:%i' -- "$path")")
}
cleanup_home_path() {
    local path=$1
    [[ $(readlink -m -- "$path") == "$(readlink -m -- "$HOME")/"* ]] || die 'Cache and managed-version cleanup is limited to the Linux home directory'
}
cleanup_nvm_uninstall() (
    set +u
    export NVM_DIR=$cleanup_manager
    source "$NVM_DIR/nvm.sh" --no-use
    nvm uninstall "$cleanup_version"
)
cleanup_main() (
    local DV_LOG_FILE=''
    local action=cache apply=false accepted=false only=all option project='' argument='' keep_csv='' include_existing=false
    local cleanup_remove_dv=false cleanup_cli='' cleanup_alias='' cleanup_pyenv_root='' cleanup_nvm_root='' cleanup_lock=''
    local cleanup_manager='' cleanup_version='' path label size index active
    local -a positional=() cleanup_paths=() cleanup_labels=() cleanup_ids=() cleanup_packages=() cleanup_rc_lines=() keep_names=() cleanup_kept=() cleanup_notes=() matched_rc_lines=()
    local -A cleanup_keep=() cleanup_package_seen=()
    while (($#)); do
        case $1 in
            --help|-h) cleanup_help; return ;;
            --apply) [[ $apply != preview ]] || die 'Do not combine --apply and --dry-run'; apply=true; shift ;;
            --dry-run) [[ $apply != true ]] || die 'Do not combine --apply and --dry-run'; apply=preview; shift ;;
            --yes) accepted=true; shift ;;
            --keep) (($# >= 2)) || die '--keep requires comma-separated tool names'; keep_csv=$2; shift 2 ;;
            --keep=*) keep_csv=${1#--keep=}; [[ -n $keep_csv ]] || die '--keep requires tool names'; shift ;;
            --include-existing) include_existing=true; shift ;;
            --only) (($# >= 2)) || die '--only requires python or node'; only=$2; shift 2 ;;
            --) shift; positional+=("$@"); break ;;
            -*) die "Unknown cleanup option: $1" ;;
            *) positional+=("$1"); shift ;;
        esac
    done
    [[ ${DV_DRY_RUN:-false} != true || $apply != true ]] || die 'DV_DRY_RUN=true prevents --apply'
    [[ $accepted != true || $apply == true ]] || die '--yes requires --apply'
    ((${#positional[@]} == 0)) || action=${positional[0]}
    if ((${#positional[@]} >= 2)); then argument=${positional[1]}; fi
    [[ $only == all || $only == python || $only == node ]] || die '--only accepts python or node'
    [[ $action == project || $only == all ]] || die '--only is available for project cleanup'
    if [[ -n $keep_csv ]]; then
        [[ $action == all || $action == tools || $action == packages ]] || die '--keep is available for all/tools/packages cleanup'
        [[ $keep_csv != ,* && $keep_csv != *, && $keep_csv != *,,* ]] || die 'Invalid --keep list'
        IFS=, read -r -a keep_names <<< "$keep_csv"
        for option in "${keep_names[@]}"; do
            case $option in python) option=pyenv;; node) option=nvm;; esac
            case $option in dv|pyenv|nvm|docker|git|ssh|packages) cleanup_keep[$option]=1;; *) die "Unknown tool to keep: $option";; esac
        done
    fi
    [[ $include_existing != true || $action == all || $action == tools ]] || die '--include-existing is available for all/tools cleanup'
    case $action in
        all|tools)
            if [[ $action == all ]]; then ((${#positional[@]} <= 1)) || die 'Usage: dv cleanup all [--keep TOOL,...]'; fi
            if [[ $action == all || ${#positional[@]} -le 1 ]]; then
                for option in dv pyenv nvm packages; do cleanup_collect_tool "$option"; done
            else
                for option in "${positional[@]:1}"; do
                    case $option in python) option=pyenv;; node) option=nvm;; esac
                    cleanup_collect_tool "$option"
                done
            fi
            if [[ $action == all ]]; then
                cleanup_add 'pip cache' "$HOME/.cache/pip"
                cleanup_add 'npm cache' "$HOME/.npm/_cacache"
                for path in "${PYENV_ROOT:-$HOME/.pyenv}/cache" "${NVM_DIR:-$HOME/.nvm}/.cache"; do
                    cleanup_home_path "$path"; cleanup_add 'manager download cache' "$path"
                done
            fi ;;
        packages)
            ((${#positional[@]} >= 2)) || die 'Usage: dv cleanup packages EXACT_NAME ... [--apply]'
            for option in "${positional[@]:1}"; do cleanup_add_package "$option"; done ;;
        cache)
            ((${#positional[@]} <= 1)) || die 'Usage: dv cleanup cache [--apply]'
            cleanup_home_path "$HOME/.cache/pip"
            cleanup_add 'pip cache' "$HOME/.cache/pip"
            cleanup_add 'npm cache' "$HOME/.npm/_cacache"
            if [[ -x ${PYENV_ROOT:-$HOME/.pyenv}/bin/pyenv ]]; then
                path="${PYENV_ROOT:-$HOME/.pyenv}/cache"; cleanup_home_path "$path"; cleanup_add 'pyenv downloads' "$path"
            fi
            if [[ -s ${NVM_DIR:-$HOME/.nvm}/nvm.sh ]]; then
                path="${NVM_DIR:-$HOME/.nvm}/.cache"; cleanup_home_path "$path"; cleanup_add 'nvm downloads' "$path"
            fi ;;
        project)
            if ((${#positional[@]} != 2)) || [[ ! -d $argument ]]; then die 'Usage: dv cleanup project EXISTING_DIR [--only python|node] [--apply]'; fi
            project=$(cd -- "$argument" && pwd -P)
            for option in python node; do
                [[ $only == all || $only == "$option" ]] || continue
                if [[ $option == python ]]; then
                    label='.venv'; path="$project/.venv"
                    [[ ! -e $path && ! -L $path || -f $path/pyvenv.cfg ]] || die '.venv is not a recognized Python virtual environment'
                else
                    label=node_modules; path="$project/node_modules"
                    [[ ! -e $path && ! -L $path || -f $project/package.json ]] || die 'node_modules cleanup requires package.json in the selected project'
                fi
                if has git && git -C "$project" rev-parse --show-toplevel >/dev/null 2>&1; then
                    active=$(git -C "$project" ls-files -- "$label") || die 'Unable to check tracked project files'
                    [[ -z $active ]] || die "Refusing to remove Git-tracked files in $label"
                fi
                cleanup_add "$label" "$path"
            done ;;
        python)
            if ((${#positional[@]} != 2)) || [[ ! $argument =~ ^3\.[0-9]+\.[0-9]+$ ]]; then die 'Specify one exact Python 3 version, for example: dv cleanup python 3.13.12'; fi
            cleanup_version=$argument; cleanup_manager=${PYENV_ROOT:-$HOME/.pyenv}
            [[ -x $cleanup_manager/bin/pyenv ]] || die 'pyenv is unavailable'
            path="$cleanup_manager/versions/$cleanup_version"; cleanup_home_path "$path"
            cleanup_add "Python $cleanup_version (includes installed libraries)" "$path" ;;
        node)
            if ((${#positional[@]} != 2)) || [[ ! $argument =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then die 'Specify one exact Node.js version, for example: dv cleanup node 22.14.0'; fi
            cleanup_version="v${argument#v}"; cleanup_manager=${NVM_DIR:-$HOME/.nvm}
            [[ -s $cleanup_manager/nvm.sh ]] || die 'nvm is unavailable'
            path="$cleanup_manager/versions/node/$cleanup_version"; cleanup_home_path "$path"
            cleanup_add "Node $cleanup_version (includes global packages)" "$path" ;;
        *) die 'Unknown cleanup action; use dv cleanup --help' ;;
    esac
    if [[ $cleanup_remove_dv == true ]]; then cleanup_validate_dv_links; fi
    cleanup_validate_rc
    # Only list shell lines that actually exist, not hypothetical edits.
    if [[ -f $HOME/.bashrc ]]; then
        for option in "${cleanup_rc_lines[@]}"; do
            if grep -Fqx -- "$option" "$HOME/.bashrc"; then matched_rc_lines+=("$option"); fi
        done
    fi
    cleanup_rc_lines=("${matched_rc_lines[@]}")
    printf '\n  DV / CLEANUP SUMMARY\n  ------------------------------------------------------------\n'
    if [[ $apply == true ]]; then
        printf '  Mode: APPLY (explicit --apply supplied)\n'
    else
        printf '  Mode: PREVIEW (no changes)\n'
    fi
    if ((${#cleanup_kept[@]})); then
        printf '\n  KEEP\n'
        for option in "${cleanup_kept[@]}"; do printf '    %s\n' "$option"; done
    fi
    if ((${#cleanup_paths[@]})); then printf '\n  DIRECTORIES / TOOLS TO REMOVE\n'; fi
    for index in "${!cleanup_paths[@]}"; do
        path=${cleanup_paths[$index]}
        if size=$(du -shx -- "$path" 2>/dev/null); then size=${size%%$'\t'*}; else size=unknown; fi
        printf '    %-12s %s\n        ' "$size" "${cleanup_labels[$index]}"
        printf '%q\n' "$path"
    done
    [[ -z $cleanup_cli ]] || printf '\n  REMOVE CLI: %q\n' "$cleanup_cli"
    [[ -z $cleanup_alias ]] || printf '  REMOVE MANAGED ALIASES: %q\n' "$cleanup_alias"
    if ((${#cleanup_rc_lines[@]})); then printf '  SHELL: back up ~/.bashrc and remove %s matching managed lines\n' "${#cleanup_rc_lines[@]}"; fi
    if ((${#cleanup_packages[@]})); then
        printf '\n  PACKAGES TO UNINSTALL\n'
        for option in "${cleanup_packages[@]}"; do printf '    %s\n' "$option"; done
    fi
    for option in "${cleanup_notes[@]}"; do printf '\n  Note: %s\n' "$option"; done
    if [[ $apply != true ]]; then
        if ((${#cleanup_packages[@]})); then printf '\n  APT dependency validation runs only with --apply.\n'; fi
        printf '\n  Preview only. Nothing deleted or uninstalled. Add --apply to execute.\n'
        return
    fi
    if (( ${#cleanup_paths[@]} + ${#cleanup_packages[@]} == 0 )) && [[ -z $cleanup_cli && -z $cleanup_alias && ${#cleanup_rc_lines[@]} == 0 ]]; then log 'Nothing to clean'; return; fi
    ((EUID != 0)) || die 'Run cleanup as your Linux development user, not root or sudo.'
    require_ubuntu
    cleanup_apt_plan
    # Recheck the full plan before any mutation, including parent-shell selections.
    for index in "${!cleanup_paths[@]}"; do
        path=${cleanup_paths[$index]}; cleanup_guard "$path"
        [[ $(stat -c '%d:%i' -- "$path") == "${cleanup_ids[$index]}" ]] || die 'A cleanup target changed; preview again'
    done
    cleanup_check_in_use
    if [[ $accepted != true ]]; then
        confirm 'Remove exactly the tools, packages and dependencies listed above?' || die 'Cleanup cancelled; use --apply --yes only for an explicitly reviewed plan'
    fi
    # The user may have inspected the plan for some time; validate it again.
    if [[ $cleanup_remove_dv == true ]]; then cleanup_validate_dv_links; fi
    cleanup_validate_rc
    for index in "${!cleanup_paths[@]}"; do
        path=${cleanup_paths[$index]}; cleanup_guard "$path"
        [[ $(stat -c '%d:%i' -- "$path") == "${cleanup_ids[$index]}" ]] || die 'A cleanup target changed; preview again'
    done
    cleanup_check_in_use
    if [[ $cleanup_remove_dv == true && -d $DV_TOOLS_ROOT ]]; then
        cleanup_lock="$DV_TOOLS_ROOT/.install-lock"
        mkdir -- "$cleanup_lock" 2>/dev/null || die 'Another tools install/cleanup is running; review .install-lock'
        trap 'rmdir -- "$cleanup_lock"' EXIT
    fi
    # APT operates first; never purge config, autoremove or stop services here.
    if ((${#cleanup_packages[@]})); then
        sudo apt-get --assume-yes --no-auto-remove remove -- "${cleanup_packages[@]}"
        for option in "${cleanup_packages[@]}"; do
            if active=$(dpkg-query -W -f='${Status}' "$option" 2>/dev/null); then
                [[ $active != 'install ok installed' ]] || die "APT did not remove $option"
            else
                [[ $? == 1 ]] || die 'Unable to verify package removal'
            fi
        done
        cleanup_update_package_journal
    fi
    cleanup_edit_rc
    [[ -z $cleanup_cli ]] || rm -f -- "$cleanup_cli"
    [[ -z $cleanup_alias ]] || rm -f -- "$cleanup_alias"
    case $action in
        python) "$cleanup_manager/bin/pyenv" uninstall -f "$cleanup_version" ;;
        node) cleanup_nvm_uninstall ;;
        *) for path in "${cleanup_paths[@]}"; do rm -rf --one-file-system -- "$path"; done ;;
    esac
    for path in "${cleanup_paths[@]}"; do [[ ! -e $path && ! -L $path ]] || die "Cleanup did not remove the selected target: $path"; done
    log 'Cleanup complete. Project sources, lockfiles, keys and user config were preserved.'
    log 'Open a new Bash shell after removing tools; loaded aliases/functions in the current shell are unchanged.'
)
# shellcheck source=src/app/internal/linux/lib/cleanup-tools.sh
source "$DV_ROOT/linux/lib/cleanup-tools.sh"
cleanup_main "$@"
