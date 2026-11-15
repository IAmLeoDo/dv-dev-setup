# shellcheck shell=bash
(($# == 1)) || die 'Usage: dv docker start|stop|restart|status|test'
require_systemd
case $1 in
    start) run sudo systemctl start docker.service ;;
    stop) run sudo systemctl stop docker.service docker.socket ;;
    restart) run sudo systemctl restart docker.service ;;
    status) systemctl status docker.service docker.socket --no-pager ;;
    test) sudo docker run --rm hello-world; sudo docker compose version ;;
    *) die 'Unknown Docker action' ;;
esac
