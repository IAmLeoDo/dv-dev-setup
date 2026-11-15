# shellcheck shell=bash
# shellcheck disable=SC2016 # Shell initialization expands HOME when Bash starts.
# Install only the Linux runtime allowlist; never run package installers here.
install_runtime() (
    set -Eeuo pipefail
    local source_app target cli config manifest relative existing legacy_cli=false stage='' backup='' lock=''
    source_app=$(cd -- "$DV_ROOT/.." && pwd -P)
    target="$DV_TOOLS_ROOT/app"
    cli="$HOME/.local/bin/dv"
    config="$HOME/.config/dv/config.ini"
    manifest="$source_app/internal/linux/install-files.txt"
    [[ -f $manifest ]] || die 'Linux runtime install manifest is missing'
    ((EUID != 0)) || die 'Install tools as your Linux development user, not root or sudo.'
    require_ubuntu
    if [[ -L $target || ( -e $target && ! -d $target ) ]]; then die 'Tool destination must be a regular directory'; fi
    if [[ -d $target ]]; then
        if [[ -L $target/.dv-managed-runtime || ! -f $target/.dv-managed-runtime ]] ||
            ! grep -Fqx 'dv-dev-setup runtime v1' "$target/.dv-managed-runtime"; then
            die 'Tool destination is unmanaged; preserve it and choose another DV_TOOLS_ROOT'
        fi
    fi
    if [[ -e $cli || -L $cli ]]; then
        [[ -L $cli ]] || die 'Existing ~/.local/bin/dv is not a symlink; preserve it before installing'
        existing=$(readlink -f -- "$cli") || existing=''
        if [[ $existing != "$source_app/internal/linux/tools/dv" && $existing != "$target/internal/linux/tools/dv" ]]; then
            if [[ $existing == */internal/linux/tools/dv && -f $existing ]] &&
                grep -Fq 'DV_ROOT/linux/lib/common.sh' "$existing" &&
                grep -Fq 'dv --version | versions | help' "$existing"; then
                legacy_cli=true
            else
                die 'Existing dv symlink belongs to another tool; inspect its target before replacing it'
            fi
        fi
    fi
    if [[ -e $config || -L $config ]]; then
        [[ -f $config && -r $config ]] || die 'User config must be a readable file: ~/.config/dv/config.ini'
    fi
    local -a files=()
    while IFS= read -r relative || [[ -n $relative ]]; do
        [[ -n $relative && $relative != \#* ]] || continue
        [[ $relative =~ ^[a-zA-Z0-9_./-]+$ && $relative != /* && $relative != *..* ]] || die 'Invalid Linux runtime manifest path'
        [[ -f $source_app/$relative && ! -L $source_app/$relative ]] || die "Missing or symlinked runtime file: $relative"
        files+=("$relative")
    done < "$manifest"
    ((${#files[@]} > 0)) || die 'Linux runtime install manifest is empty'
    if [[ ${DV_DRY_RUN:-false} == true ]]; then
        log "Would copy ${#files[@]} Linux runtime files to $target"
        log "Would link $cli to $target/internal/linux/tools/dv"
        [[ $legacy_cli == false ]] || log 'Would back up the previous dv symlink before migrating it'
        if [[ -e $config ]]; then log "Would preserve user config: $config"; else log "Would initialize user config: $config"; fi
        append_once "$HOME/.bashrc" 'export PATH="$HOME/.local/bin:$PATH"'
        return
    fi
    umask 077
    mkdir -p -- "$DV_TOOLS_ROOT" "$HOME/.local/bin" "$HOME/.config/dv"
    lock="$DV_TOOLS_ROOT/.install-lock"
    mkdir -- "$lock" 2>/dev/null || die 'Another tools installation is running (or .install-lock needs manual review)'
    cleanup_install() {
        [[ -z $stage || ! -d $stage ]] || rm -rf -- "$stage"
        if [[ -n $backup && -d $backup && ! -e $target ]]; then mv -- "$backup" "$target"; fi
        rmdir -- "$lock"
    }
    trap cleanup_install EXIT
    local changed=false
    if [[ ! -d $target ]]; then changed=true; fi
    for relative in "${files[@]}"; do
        if [[ ! -f $target/$relative || -L $target/$relative ]] || ! cmp -s -- "$source_app/$relative" "$target/$relative"; then changed=true; fi
    done
    if [[ $changed == true ]]; then
        stage=$(mktemp -d "$DV_TOOLS_ROOT/.app-stage.XXXXXX")
        for relative in "${files[@]}"; do
            mkdir -p -- "$(dirname -- "$stage/$relative")"
            cp -- "$source_app/$relative" "$stage/$relative"
            case $relative in *.sh|*/dv) chmod 700 "$stage/$relative" ;; esac
        done
        printf '%s\n' 'dv-dev-setup runtime v1' > "$stage/.dv-managed-runtime"
    fi
    # This file is an override for installed defaults; never overwrite user edits.
    if [[ ! -e $config ]]; then cp -n -- "$source_app/config.ini" "$config"; fi
    if [[ $changed == true ]]; then
        if [[ -d $target ]]; then
            mkdir -p -- "$DV_TOOLS_ROOT/backups"
            backup=$(mktemp -d "$DV_TOOLS_ROOT/backups/app.XXXXXX")
            rmdir -- "$backup"
            mv -- "$target" "$backup"
        fi
        mv -- "$stage" "$target"
        stage=''
        [[ -z $backup ]] || log "Previous tools preserved at $backup"
        log "Copied tools to $target"
    else
        log "Tools already match: $target"
    fi
    if [[ ! -L $cli ]]; then
        ln -s -- "$target/internal/linux/tools/dv" "$cli"
    elif [[ $(readlink -- "$cli") != "$target/internal/linux/tools/dv" ]]; then
        if [[ $legacy_cli == true ]]; then
            local cli_backup
            mkdir -p -- "$DV_TOOLS_ROOT/backups"
            cli_backup=$(mktemp "$DV_TOOLS_ROOT/backups/dv-link.XXXXXX")
            rm -f -- "$cli_backup"
            cp -P -- "$cli" "$cli_backup"
            log "Previous dv symlink preserved at $cli_backup"
        fi
        local link_temp
        link_temp=$(mktemp "$HOME/.local/bin/.dv-link.XXXXXX")
        rm -f -- "$link_temp"
        ln -s -- "$target/internal/linux/tools/dv" "$link_temp"
        mv -Tf -- "$link_temp" "$cli"
    fi
    append_once "$HOME/.bashrc" 'export PATH="$HOME/.local/bin:$PATH"'
    log "CLI: $cli"
    log "User config preserved at $config (DV_CONFIG can override it)"
)
