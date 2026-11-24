# shellcheck shell=bash
# shellcheck disable=SC2034 # Shared state consumed by sourced modules.
require_systemd
if has docker; then docker --version; fi
if has docker && ! dpkg-query -W docker-ce >/dev/null 2>&1; then
    die 'Existing non-docker-ce installation detected. Review package conflicts manually before migrating to Docker Engine.'
fi
apt_install ca-certificates curl gnupg
if [[ ${DV_DRY_RUN:-false} == true ]]; then
    log 'Would validate Docker signing key, configure scoped apt repository, and install missing Engine/Compose packages'
else
    temporary=$(mktemp -d)
    trap 'rm -rf -- "$temporary"' EXIT
    curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 https://download.docker.com/linux/ubuntu/gpg -o "$temporary/docker.asc"
    fingerprint=$(gpg --batch --show-keys --with-colons "$temporary/docker.asc" | awk -F: '$1 == "fpr" {print $10; exit}')
    [[ $fingerprint == 9DC858229FC7DD38854AE2D88D81803C0EBFCD88 ]] || die 'Docker signing key fingerprint mismatch'
    run sudo install -d -m 755 /etc/apt/keyrings
    if ! cmp -s "$temporary/docker.asc" /etc/apt/keyrings/docker.asc; then run sudo install -m 644 "$temporary/docker.asc" /etc/apt/keyrings/docker.asc; DV_APT_UPDATED=false; fi
    architecture=$(dpkg --print-architecture)
    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable\n' "$architecture" > "$temporary/docker.list"
    if [[ -e /etc/apt/sources.list.d/docker.sources ]]; then die 'Existing docker.sources detected; review it before adding docker.list'; fi
    if [[ -e /etc/apt/sources.list.d/docker.list ]] && ! cmp -s "$temporary/docker.list" /etc/apt/sources.list.d/docker.list; then die 'Existing Docker apt source differs; review manually'; fi
    if ! cmp -s "$temporary/docker.list" /etc/apt/sources.list.d/docker.list; then run sudo install -m 644 "$temporary/docker.list" /etc/apt/sources.list.d/docker.list; DV_APT_UPDATED=false; fi
fi
apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
if [[ $DV_DOCKER_ON_DEMAND == true ]]; then
    # Prevent package post-install scripts from leaving Engine running after setup.
    run sudo systemctl disable --now docker.service docker.socket
else run sudo systemctl enable --now docker.service; fi
# shellcheck source=src/app/internal/linux/lib/docker.sh
source "$DV_ROOT/linux/lib/docker.sh"
configure_docker_group
if [[ ${DV_DOCKER_TEST:-false} == true ]]; then
    was_active=false
    if systemctl is-active --quiet docker.service; then was_active=true; fi
    run sudo systemctl start docker.service
    result=0
    run sudo docker run --rm hello-world || result=$?
    run sudo docker compose version || result=$?
    if [[ $was_active == false && $DV_DOCKER_ON_DEMAND == true ]]; then run sudo systemctl stop docker.service docker.socket; fi
    ((result == 0)) || die 'Docker validation failed'
fi
