# shellcheck shell=bash
[[ $# == 1 && $1 == status ]] || die 'Usage: dv git status'
git rev-parse --show-toplevel >/dev/null 2>&1 || die 'Current directory is not a Git repository'
git status --short --branch
if git config --get user.name >/dev/null && git config --get user.email >/dev/null; then log 'identity: configured'; else log 'identity: incomplete'; fi
while IFS= read -r remote; do
    url=$(git remote get-url "$remote")
    if [[ $url =~ ^git@github\.com:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$ || $url =~ ^ssh://git@github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$ ]]; then log "remote $remote: GitHub SSH configured"; else log "remote $remote: not a supported GitHub SSH URL"; fi
done < <(git remote)
