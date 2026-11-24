# shellcheck shell=bash
# Share group planning between setup preview and the Docker installation module.
configure_docker_group() {
    if [[ ${DV_DOCKER_ADD_USER_TO_GROUP:-false} != true ]]; then
        log 'Docker group: membership unchanged; set DV_DOCKER_ADD_USER_TO_GROUP=true to opt in'
        return
    fi
    local docker_user account_groups session_groups
    docker_user=$(id -un) || die 'Cannot determine the current Linux account'
    ((EUID != 0)) || die 'Configure Docker access as your development user, not root or sudo.'
    account_groups=$(id -nG "$docker_user") || die 'Cannot inspect account group membership'
    log "Docker group: access for $docker_user grants root-equivalent privileges"
    if [[ " $account_groups " == *' docker '* ]]; then
        log "Docker group: $docker_user is already a member; preserve existing groups"
    elif [[ ${DV_DRY_RUN:-true} == true ]]; then
        if ! getent group docker >/dev/null; then log 'Would create the docker group if still missing after package installation'; fi
        log "Would add $docker_user to docker, preserving all existing supplementary groups"
    else
        [[ ${DV_CHANGE_MODE:-} == --apply ]] || die 'Docker group changes require explicit --apply'
        if ! getent group docker >/dev/null; then
            run sudo groupadd docker || die 'Cannot create the docker group'
        fi
        run sudo usermod -aG docker "$docker_user" || die 'Cannot add the current user to the docker group'
        account_groups=$(id -nG "$docker_user") || die 'Cannot verify Docker group membership'
        [[ " $account_groups " == *' docker '* ]] || die 'Docker group membership was not updated'
        log "Docker group: added $docker_user; existing supplementary groups preserved"
    fi
    session_groups=$(id -nG) || die 'Cannot inspect current session groups'
    if [[ " $session_groups " != *' docker '* ]]; then
        log 'After applying: log out and log back in, or run newgrp docker in your current Bash terminal.'
        log 'Setup does not refresh groups in the parent shell or change Docker socket permissions.'
    fi
}
