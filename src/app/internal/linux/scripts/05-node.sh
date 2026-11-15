# shellcheck shell=bash
# shellcheck disable=SC2016 # Shell initialization must expand when the user opens Bash.
apt_install git ca-certificates curl
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ ! -e $NVM_DIR ]]; then run git clone --depth 1 --branch "$DV_NVM_VERSION" https://github.com/nvm-sh/nvm.git "$NVM_DIR"; fi
if [[ ${DV_DRY_RUN:-false} != true ]]; then
    [[ -s $NVM_DIR/nvm.sh ]] || die 'Existing nvm directory is not a usable installation'
    # nvm is upstream shell code, not user configuration.
    set +u
    source "$NVM_DIR/nvm.sh"
    nvm install "$DV_NODE_VERSION"
    node --version
    npm --version
    set -u
fi
append_once "$HOME/.bashrc" 'export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; if [[ -s "$NVM_DIR/nvm.sh" ]]; then . "$NVM_DIR/nvm.sh"; fi'
