# shellcheck shell=bash
(($# == 0)) || die 'Usage: dv versions'

# Report active executables; do not contact services or install missing tools.
report_version() {
    local label=$1 output
    shift
    if output=$("$@" 2>&1) && [[ -n $output ]]; then
        output=${output%%$'\n'*}
        output=${output%$'\r'}
        printf '%-16s %s\n' "$label" "$output"
    else
        printf '%-16s %s\n' "$label" 'version unavailable'
    fi
}

printf '%-16s %s\n' 'Tool' 'Installed version (current environment)'
for tool in git python3 node npm docker code; do
    if has "$tool"; then
        report_version "$tool" "$tool" --version
    else
        printf '%-16s %s\n' "$tool" 'not available in PATH'
    fi
done
if has docker; then
    report_version 'docker compose' docker compose version --short
else
    printf '%-16s %s\n' 'docker compose' 'not available in PATH'
fi
if [[ -x ${PYENV_ROOT:-$HOME/.pyenv}/bin/pyenv ]]; then
    report_version pyenv "${PYENV_ROOT:-$HOME/.pyenv}/bin/pyenv" --version
elif has pyenv; then
    report_version pyenv pyenv --version
else
    printf '%-16s %s\n' pyenv 'not installed'
fi
nvm_version() (
    # Load nvm without selecting a Node.js version or changing the caller's shell.
    set +u
    export NVM_DIR=${NVM_DIR:-$HOME/.nvm}
    # shellcheck disable=SC1091 # User-installed nvm location.
    source "$NVM_DIR/nvm.sh" --no-use
    nvm --version
)
if [[ -s ${NVM_DIR:-$HOME/.nvm}/nvm.sh ]]; then
    report_version nvm nvm_version
else
    printf '%-16s %s\n' nvm 'not installed'
fi
