# shellcheck shell=bash
# shellcheck disable=SC2034 # Shared state consumed by sourced modules.
apt_install() {
    local package missing=()
    for package in "$@"; do
        if [[ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true) != 'install ok installed' ]]; then missing+=("$package"); fi
    done
    ((${#missing[@]})) || return 0
    if [[ ${DV_APT_UPDATED:-false} != true ]]; then run sudo apt-get update; DV_APT_UPDATED=true; fi
    run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
    if [[ ${DV_DRY_RUN:-false} != true ]]; then record_installed_packages "${missing[@]}"; fi
}

# Record only packages that setup found missing and successfully installed.
record_installed_packages() {
    local journal="$HOME/.local/state/dv-dev-setup/installed-packages.txt" package
    [[ ! -L $journal && ( ! -e $journal || -f $journal ) ]] || die 'Package ownership journal must be a regular file'
    (umask 077; mkdir -p -- "$(dirname -- "$journal")"; touch "$journal")
    chmod 600 "$journal"
    for package in "$@"; do
        [[ $package =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || die 'Invalid package ownership name'
        if ! grep -Fqx -- "$package" "$journal"; then printf '%s\n' "$package" >> "$journal"; fi
    done
}
