# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154 # Plan state is local to cleanup_main and shared with these helpers.
# shellcheck disable=SC2016 # Compare literal managed shell initialization lines.
# Helpers share the cleanup command's function-local plan (Bash dynamic scope).
cleanup_package_allowed() {
    case $1 in
        git|keychain|build-essential|libssl-dev|zlib1g-dev|libbz2-dev|libreadline-dev|libsqlite3-dev|libncursesw5-dev|tk-dev|libxml2-dev|libxmlsec1-dev|libffi-dev|liblzma-dev|docker-ce|docker-ce-cli|containerd.io|docker-buildx-plugin|docker-compose-plugin) return 0 ;;
        *) return 1 ;;
    esac
}
cleanup_package_kept() {
    [[ -v cleanup_keep[packages] ]] && return 0
    case $1 in
        git) [[ -v cleanup_keep[git] || -v cleanup_keep[pyenv] || -v cleanup_keep[nvm] || -v cleanup_keep[dv] ]] ;;
        build-essential) [[ -v cleanup_keep[pyenv] || -v cleanup_keep[nvm] ]] ;;
        lib*-dev|tk-dev) [[ -v cleanup_keep[pyenv] ]] ;;
        keychain) [[ -v cleanup_keep[ssh] ]] ;;
        docker-*|containerd.io) [[ -v cleanup_keep[docker] ]] ;;
        *) return 1 ;;
    esac
}
cleanup_add_package() {
    local package=$1 status
    cleanup_package_allowed "$package" || die "Package is outside the cleanup allowlist: $package"
    if cleanup_package_kept "$package"; then cleanup_kept+=("package: $package"); return; fi
    [[ ! -v cleanup_package_seen[$package] ]] || return 0
    has dpkg-query || die 'Package cleanup requires dpkg-query'
    if status=$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null); then
        :
    else
        [[ $? == 1 ]] || die 'Unable to read package installation state'
        status=''
    fi
    [[ $status == 'install ok installed' ]] || return 0
    cleanup_package_seen[$package]=1
    cleanup_packages+=("$package")
}
cleanup_group_matches() {
    case $1 in
        docker) [[ $2 == docker-* || $2 == containerd.io ]] ;;
        git) [[ $2 == git ]] ;;
        ssh) [[ $2 == keychain ]] ;;
        packages) return 0 ;;
        *) return 1 ;;
    esac
}
cleanup_collect_packages() {
    local group=${1:-packages} package journal="$HOME/.local/state/dv-dev-setup/installed-packages.txt"
    if [[ $include_existing == true ]]; then
        for package in git keychain build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; do
            if cleanup_group_matches "$group" "$package"; then cleanup_add_package "$package"; fi
        done
    elif [[ -f $journal && ! -L $journal ]]; then
        while IFS= read -r package || [[ -n $package ]]; do
            [[ -n $package ]] || continue
            [[ $package =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || die 'Invalid package ownership journal'
            if cleanup_package_allowed "$package" && cleanup_group_matches "$group" "$package"; then cleanup_add_package "$package"; fi
        done < "$journal"
    else
        cleanup_notes+=('No package ownership record; select older packages explicitly or use --include-existing.')
    fi
}
cleanup_collect_tool() {
    local tool=$1 path
    case $tool in dv|pyenv|nvm|docker|git|ssh|packages) ;; *) die "Unknown cleanup tool: $tool";; esac
    if [[ -v cleanup_keep[$tool] ]]; then cleanup_kept+=("tool: $tool"); return; fi
    case $tool in
        dv)
            cleanup_remove_dv=true
            path="$DV_TOOLS_ROOT/app"
            if [[ -e $path || -L $path ]]; then
                if [[ -L $path || ! -f $path/.dv-managed-runtime || -L $path/.dv-managed-runtime ]] ||
                    ! grep -Fqx 'dv-dev-setup runtime v1' "$path/.dv-managed-runtime"; then
                    die 'Refusing to remove an unmanaged dv runtime'
                fi
                cleanup_add 'dv runtime (user config and backups kept)' "$path"
            fi
            cleanup_rc_lines+=('[ ! -f "$HOME/.config/dv/aliases.bash" ] || . "$HOME/.config/dv/aliases.bash"')
            ;;
        pyenv)
            path=${PYENV_ROOT:-$HOME/.pyenv}
            if [[ -e $path || -L $path ]]; then
                [[ -x $path/bin/pyenv ]] || die 'Refusing to remove an unrecognized pyenv directory'
                cleanup_home_path "$path"
                cleanup_add 'pyenv + all Python versions and their libraries' "$path"
                cleanup_pyenv_root=$path
                cleanup_rc_lines+=('export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"; export PATH="$PYENV_ROOT/bin:$PATH"; if command -v pyenv >/dev/null; then eval "$(pyenv init - bash)"; fi')
            fi ;;
        nvm)
            path=${NVM_DIR:-$HOME/.nvm}
            if [[ -e $path || -L $path ]]; then
                [[ -s $path/nvm.sh ]] || die 'Refusing to remove an unrecognized nvm directory'
                cleanup_home_path "$path"
                cleanup_add 'nvm + all Node versions and global packages' "$path"
                cleanup_nvm_root=$path
                cleanup_rc_lines+=('export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; if [[ -s "$NVM_DIR/nvm.sh" ]]; then . "$NVM_DIR/nvm.sh"; fi')
            fi ;;
        docker|git|ssh|packages) cleanup_collect_packages "$tool" ;;
        *) die "Unknown cleanup tool: $tool" ;;
    esac
}
cleanup_validate_dv_links() {
    local path="$HOME/.local/bin/dv" existing first=''
    if [[ -e $path || -L $path ]]; then
        [[ -L $path ]] || die 'Refusing to delete an unrelated ~/.local/bin/dv file'
        existing=$(readlink -m -- "$path")
        if [[ $existing != "$(readlink -m -- "$DV_TOOLS_ROOT/app/internal/linux/tools/dv")" ]]; then
            if [[ $existing != */internal/linux/tools/dv || ! -f $existing ]] ||
                ! grep -Fq 'DV_ROOT/linux/lib/common.sh' "$existing" ||
                ! grep -Fq 'dv --version | versions | help' "$existing"; then
                die 'Refusing to remove an unrelated dv symlink'
            fi
        fi
        cleanup_cli=$path
    fi
    path="$HOME/.config/dv/aliases.bash"
    if [[ -e $path || -L $path ]]; then
        [[ -f $path && ! -L $path ]] || die 'Refusing to remove a symlinked/nonregular alias file'
        IFS= read -r first < "$path" || true
        [[ $first == '# Generated by dv-dev-setup: Bash aliases' ]] || die 'Refusing to remove an unmanaged alias file'
        cleanup_alias=$path
    fi
}
cleanup_validate_rc() {
    local file="$HOME/.bashrc"
    if ((${#cleanup_rc_lines[@]})) && [[ -e $file || -L $file ]]; then
        [[ -f $file && ! -L $file && -r $file && -w $file ]] || die 'Managed shell lines require a writable, regular ~/.bashrc; review it manually'
    fi
}
cleanup_edit_rc() (
    local file="$HOME/.bashrc" line remove skip temporary backup
    [[ -f $file && ${#cleanup_rc_lines[@]} -gt 0 ]] || return 0
    local changed=false
    for remove in "${cleanup_rc_lines[@]}"; do
        if grep -Fqx -- "$remove" "$file"; then changed=true; fi
    done
    [[ $changed == true ]] || return 0
    umask 077
    mkdir -p -- "$HOME/.local/state/dv-dev-setup/cleanup-backups"
    backup=$(mktemp "$HOME/.local/state/dv-dev-setup/cleanup-backups/bashrc.XXXXXX")
    cp -p -- "$file" "$backup"
    temporary=$(mktemp "$HOME/.bashrc.cleanup.XXXXXX")
    trap 'rm -f -- "$temporary"' EXIT
    while IFS= read -r line || [[ -n $line ]]; do
        skip=false
        for remove in "${cleanup_rc_lines[@]}"; do [[ $line != "$remove" ]] || skip=true; done
        [[ $skip == true ]] || printf '%s\n' "$line" >> "$temporary"
    done < "$file"
    chmod --reference="$file" "$temporary"
    mv -Tf -- "$temporary" "$file"
    log "Shell initialization backed up at $backup; only exact managed lines removed"
)
cleanup_validate_journal() {
    local file="$HOME/.local/state/dv-dev-setup/installed-packages.txt" package
    [[ -e $file || -L $file ]] || return 0
    [[ -f $file && ! -L $file && -r $file ]] || die 'Package ownership journal must be a readable regular file'
    while IFS= read -r package || [[ -n $package ]]; do
        [[ -z $package || $package =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || die 'Invalid package ownership journal'
    done < "$file"
}
cleanup_apt_plan() {
    local output line package
    local -A planned=()
    ((${#cleanup_packages[@]})) || return 0
    if ! has apt-get || ! has dpkg-query; then die 'APT cleanup requires apt-get and dpkg-query'; fi
    cleanup_validate_journal
    output=$(LC_ALL=C apt-get --simulate --no-auto-remove remove -- "${cleanup_packages[@]}") || die 'APT removal simulation failed'
    printf '\n  APT REMOVAL SIMULATION\n%s\n' "$output"
    # Never silently accept removal of extra packages, even if APT proposes them.
    while IFS= read -r line; do
        [[ $line == Remv\ * ]] || continue
        read -r _ package _ <<< "$line"
        package=${package%%:*}
        [[ -v cleanup_package_seen[$package] ]] || die "APT would also remove $package; select it explicitly if allowed, or keep the dependent tool"
        planned[$package]=1
    done <<< "$output"
    for package in "${cleanup_packages[@]}"; do
        [[ -v planned[$package] ]] || die "APT did not produce a verifiable removal plan for $package"
    done
}
cleanup_check_in_use() {
    local path active manager_root
    for path in "${cleanup_paths[@]}"; do
        active=$(pwd -P)
        [[ $active != "$path" && $active != "$path/"* ]] || die 'Change out of the cleanup target directory before applying cleanup'
        if [[ -n ${VIRTUAL_ENV:-} ]]; then
            active=$(readlink -m -- "$VIRTUAL_ENV")
            [[ $active != "$path" && $active != "$path/"* ]] || die 'Deactivate the selected virtual environment before cleanup'
        fi
    done
    if [[ -n $cleanup_pyenv_root && -n ${VIRTUAL_ENV:-} ]]; then die 'Deactivate the current virtual environment before removing pyenv'; fi
    manager_root=$cleanup_pyenv_root
    [[ $action != python ]] || manager_root=$cleanup_manager
    if [[ -n $manager_root ]]; then
        active=$("$manager_root/bin/pyenv" which python3 2>/dev/null) || active=''
        if [[ $action == python ]]; then path=${cleanup_paths[0]}; else path=$manager_root; fi
        [[ $active != "$path/"* ]] || die 'Selected Python installation is active; switch to system/another version before cleanup'
    fi
    if [[ -n $cleanup_nvm_root || $action == node ]]; then
        active=$(command -v node) || active=''
        [[ -z $active ]] || active=$(readlink -f -- "$active")
        if [[ $action == node ]]; then path=${cleanup_paths[0]}; else path=$cleanup_nvm_root; fi
        [[ $active != "$path/"* ]] || die 'Selected Node installation is active; deactivate it before cleanup'
    fi
    local package
    for package in "${cleanup_packages[@]}"; do
        case $package in
            docker-*|containerd.io)
                if has systemctl && [[ $(cat /proc/1/comm) == systemd ]]; then
                    local unit
                    for unit in docker.service docker.socket; do
                        if systemctl is-active --quiet "$unit"; then die 'Docker is active; save work and stop its service/socket manually before package cleanup'; fi
                    done
                    if [[ $package == containerd.io ]] && systemctl is-active --quiet containerd.service; then
                        die 'containerd is active; review other workloads and stop it manually before package cleanup'
                    fi
                fi
                if has pgrep && { pgrep -x dockerd >/dev/null || { [[ $package == containerd.io ]] && pgrep -x containerd >/dev/null; }; }; then
                    die 'Docker/containerd is running; save container work and stop the selected services manually before package cleanup'
                fi ;;
        esac
    done
}
cleanup_update_package_journal() (
    local journal="$HOME/.local/state/dv-dev-setup/installed-packages.txt" package temporary
    [[ -f $journal && ! -L $journal ]] || return 0
    temporary=$(mktemp "${journal}.cleanup.XXXXXX")
    trap 'rm -f -- "$temporary"' EXIT
    while IFS= read -r package || [[ -n $package ]]; do
        [[ -n $package ]] || continue
        [[ $package =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || die 'Invalid package ownership journal'
        [[ -v cleanup_package_seen[$package] ]] || printf '%s\n' "$package" >> "$temporary"
    done < "$journal"
    chmod 600 "$temporary"
    mv -Tf -- "$temporary" "$journal"
)
