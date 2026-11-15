# shellcheck shell=bash
# shellcheck disable=SC2034 # Arrays are consumed by the aliases setup module.
load_aliases() {
    local line name target content
    local -A seen=()
    DV_ALIAS_NAMES=()
    DV_ALIAS_TARGETS=()
    content=$(config_section aliases) || return
    while IFS= read -r line || [[ -n $line ]]; do
        [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
        [[ $line =~ ^([a-zA-Z][a-zA-Z0-9_]*)=(.+)$ ]] || die 'Invalid alias assignment; expected name=supported command'
        name=${BASH_REMATCH[1]}; target=${BASH_REMATCH[2]}
        [[ ! -v seen[$name] ]] || die "Duplicate alias: $name"
        # Do not turn arbitrary configuration into shell code. Each target is
        # a literal supported command; operators and substitutions are rejected.
        case $target in
            'dv help'|'dv doctor'|'dv versions'|'dv cleanup'|'dv workspace'|'dv workspace open'|\
            'dv docker start'|'dv docker stop'|'dv docker restart'|'dv docker status'|\
            'dv git status'|'dv worktree list'|'git status'|'git diff'|'git log --oneline') ;;
            *) die "Unsupported command for alias $name; see docs/content/configuration.md" ;;
        esac
        seen[$name]=1
        DV_ALIAS_NAMES+=("$name")
        DV_ALIAS_TARGETS+=("$target")
    done <<< "$content"
}
