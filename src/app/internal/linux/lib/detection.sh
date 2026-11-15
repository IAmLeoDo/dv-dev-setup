# shellcheck shell=bash
# shellcheck disable=SC2034 # Shared state consumed by sourced modules.
has() { command -v "$1" >/dev/null 2>&1; }
detect_os() {
    local file=${1:-/etc/os-release}
    [[ -r $file ]] || die "Cannot read OS information"
    DV_OS_ID=$(sed -n 's/^ID=//p' "$file" | tr -d '"')
    DV_OS_VERSION=$(sed -n 's/^VERSION_ID=//p' "$file" | tr -d '"')
    DV_ARCH=$(uname -m)
}
require_ubuntu() {
    detect_os /etc/os-release
    [[ $DV_OS_ID == ubuntu && $DV_OS_VERSION == 24.04 ]] || die "Supported: Ubuntu 24.04; found $DV_OS_ID $DV_OS_VERSION"
    [[ $DV_ARCH == x86_64 || $DV_ARCH == aarch64 ]] || die "Unsupported architecture: $DV_ARCH"
}
require_systemd() { [[ $(cat /proc/1/comm) == systemd ]] || die 'Enable [boot] systemd=true in /etc/wsl.conf, then run wsl --shutdown from Windows after saving work.'; }
