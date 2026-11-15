# shellcheck shell=bash
case ${1:-show} in
    show) (($# <= 1)) || die 'Usage: dv workspace'; printf '%s\n' "$DV_WORKSPACE_ROOT" "$DV_PROJECTS_ROOT" ;;
    open)
        shift
        code_options=()
        while (($#)); do
            case $1 in
                --add)
                    ((${#code_options[@]} == 0)) || die 'Specify --add only once'
                    code_options=(--add)
                    shift ;;
                --help|-h)
                    (($# == 1 && ${#code_options[@]} == 0)) || die 'Usage: dv workspace open [--add] [--] [DIR ...]'
                    printf '%s\n' \
                        'Usage: dv workspace open [--add] [--] [DIR ...]' \
                        'No DIR: open the configured project root.' \
                        'One or more DIRs: open those existing directories in VS Code.' \
                        '--add DIR ...: add directories to the last active VS Code window.' \
                        'Relative paths are resolved from the current working directory.'
                    exit 0 ;;
                --) shift; break ;;
                -*) die "Unknown workspace open option: $1 (see workspace open --help)" ;;
                *) break ;;
            esac
        done
        if (($# == 0)); then
            ((${#code_options[@]} == 0)) || die '--add requires at least one directory'
            set -- "$DV_PROJECTS_ROOT"
        fi
        workspace_paths=()
        for directory in "$@"; do
            [[ -d $directory ]] || die "Directory not found: $directory"
            # Absolute paths cannot be interpreted as VS Code options.
            workspace_paths+=("$(cd -- "$directory" && pwd -P)")
        done
        has code || die 'VS Code command unavailable; make code available in PATH'
        code "${code_options[@]}" "${workspace_paths[@]}" ;;
    create) (($# == 2)) || die 'Usage: dv workspace create NAME'; valid_name "$2" || die 'Invalid project name'; mkdir -p -- "$DV_PROJECTS_ROOT/$2/"{sources,docs,builds} ;;
    *) die 'Usage: dv workspace [open [--add] [DIR ...]|create NAME]' ;;
esac
