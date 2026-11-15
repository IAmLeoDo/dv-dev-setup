# shellcheck shell=bash
# shellcheck disable=SC2016 # Shell initialization must expand when the user opens Bash.
apt_install openssh-client keychain
run mkdir -p "$HOME/.ssh"
run chmod 700 "$HOME/.ssh"
key="$HOME/.ssh/id_ed25519"
if [[ -f $key ]]; then
    log 'Existing Ed25519 key preserved'
elif [[ ${DV_SSH_GENERATE:-false} == true ]]; then
    if [[ ${DV_SSH_NO_PASSPHRASE:-false} == true ]]; then
        run ssh-keygen -t ed25519 -f "$key" -C "${DV_GITHUB_USER:-devimony}" -N ''
    elif [[ -t 0 ]]; then
        run ssh-keygen -t ed25519 -f "$key" -C "${DV_GITHUB_USER:-devimony}"
    else die 'Key generation needs a terminal for a passphrase; explicitly set DV_SSH_NO_PASSPHRASE=true to opt out.'; fi
else log 'Key generation skipped. Set DV_SSH_GENERATE=true to create a key.'; fi
if [[ -f $key ]]; then run chmod 600 "$key"; fi
if [[ ! -e $HOME/.ssh/config ]]; then
    if [[ ${DV_DRY_RUN:-false} == true ]]; then
        log 'Would create ~/.ssh/config from config.ini [ssh]'
    else
        ssh_config_content=$(config_section ssh)
        (umask 077; printf '%s\n' "$ssh_config_content" > "$HOME/.ssh/config")
        chmod 600 "$HOME/.ssh/config"
    fi
else log 'Existing SSH config preserved; see config.ini [ssh]'; fi
append_once "$HOME/.bashrc" 'if command -v keychain >/dev/null && [[ -f "$HOME/.ssh/id_ed25519" ]]; then eval "$(keychain --eval --quiet --agents ssh "$HOME/.ssh/id_ed25519")"; fi'
if [[ -f $key.pub ]]; then log 'Register this PUBLIC key at https://github.com/settings/keys (not written to setup log):'; cat "$key.pub"; fi
if [[ ${DV_GITHUB_TEST:-false} == true ]]; then github_auth; fi
