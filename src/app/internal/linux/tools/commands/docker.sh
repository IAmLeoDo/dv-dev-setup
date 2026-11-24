# shellcheck shell=bash
parse_change_options "$@"
set -- "${DV_CHANGE_ARGS[@]}"
if [[ $# == 1 && ( $1 == --help || $1 == -h ) ]]; then
    printf '%s\n' \
        'Usage: dv docker start|stop|restart|test [--apply | --dry-run]' \
        '       dv docker status' \
        'Default: summary only. Add --apply to change services or run a test container.'
    exit 0
fi
(($# == 1)) || die 'Usage: dv docker start|stop|restart|test [--apply | --dry-run], or dv docker status'
case $1 in
    status)
        [[ -z $DV_CHANGE_MODE ]] || die 'Docker status is read-only; omit mode flags'
        require_systemd
        systemctl status docker.service docker.socket --no-pager ;;
    start|stop|restart|test)
        case $1 in
            start) log 'Plan: start docker.service' ;;
            stop) log 'Plan: stop docker.service and docker.socket; running containers may be interrupted' ;;
            restart) log 'Plan: restart docker.service; running containers may be interrupted' ;;
            test) log 'Plan: run/remove the hello-world container (may download its image), then query Compose version' ;;
        esac
        if [[ $DV_DRY_RUN == true ]]; then preview_notice; exit 0; fi
        require_systemd
        case $1 in
            start) run sudo systemctl start docker.service ;;
            stop) run sudo systemctl stop docker.service docker.socket ;;
            restart) run sudo systemctl restart docker.service ;;
            test) run sudo docker run --rm hello-world; run sudo docker compose version ;;
        esac ;;
    *) die 'Unknown Docker action' ;;
esac
