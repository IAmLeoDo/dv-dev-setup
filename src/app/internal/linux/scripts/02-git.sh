# shellcheck shell=bash
apt_install git
for entry in name email; do
    variable=DV_GIT_${entry^^}
    if [[ -n ${!variable:-} ]]; then
        current=$(git config --global --get "user.$entry" || true)
        if [[ -z $current || $current == "${!variable}" ]] || confirm "Replace existing Git user.$entry?"; then run git config --global "user.$entry" "${!variable}"; fi
    fi
done
if ! git config --global --get init.defaultBranch >/dev/null; then run git config --global init.defaultBranch "$DV_GIT_DEFAULT_BRANCH"; fi
log 'Git identity status:'
if git config --get user.name >/dev/null && git config --get user.email >/dev/null; then log configured; else log 'incomplete; configure user.name and user.email'; fi
