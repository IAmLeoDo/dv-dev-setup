# shellcheck shell=bash
# shellcheck disable=SC2016 # Shell initialization must expand when the user opens Bash.
apt_install git ca-certificates build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if [[ ! -e $PYENV_ROOT ]]; then run git clone --depth 1 --branch "$DV_PYENV_VERSION" https://github.com/pyenv/pyenv.git "$PYENV_ROOT"; fi
if [[ ${DV_DRY_RUN:-false} != true ]]; then
    [[ -x $PYENV_ROOT/bin/pyenv ]] || die 'Existing pyenv directory is not a usable installation'
    "$PYENV_ROOT/bin/pyenv" --version
    if [[ ! -d $PYENV_ROOT/versions/$DV_PYTHON_VERSION ]] && ! "$PYENV_ROOT/bin/pyenv" install --list | grep -Fx "  $DV_PYTHON_VERSION" >/dev/null; then
        die 'Configured Python is not supported by this pyenv installation; review and update pyenv explicitly.'
    fi
    "$PYENV_ROOT/bin/pyenv" install -s "$DV_PYTHON_VERSION"
    interpreter="$PYENV_ROOT/versions/$DV_PYTHON_VERSION/bin/python"
    "$interpreter" --version
    temporary=$(mktemp -d)
    "$interpreter" -m venv "$temporary/venv"
    "$temporary/venv/bin/python" -m pip --version
    rm -rf -- "$temporary"
fi
append_once "$HOME/.bashrc" 'export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"; export PATH="$PYENV_ROOT/bin:$PATH"; if command -v pyenv >/dev/null; then eval "$(pyenv init - bash)"; fi'
log "Use pyenv local $DV_PYTHON_VERSION in each project; existing global selection preserved."
