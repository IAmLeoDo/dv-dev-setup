# shellcheck shell=bash
parse_change_options "$@"
set -- "${DV_CHANGE_ARGS[@]}"
case ${1:-show} in
    --help|-h)
        (($# == 1)) || die 'Usage: dv workspace [show|open|create]'
        printf '%s\n' 'Usage: dv workspace [show|open [--add] [--] [DIR ...]|create NAME] [--apply | --dry-run]' \
            'Open/create default to summary only. Add --apply to open VS Code or create directories.' ;;
    show)
        (($# <= 1)) || die 'Usage: dv workspace'
        [[ -z $DV_CHANGE_MODE ]] || die 'Workspace show is read-only; omit mode flags'
        printf '%s\n' "$DV_WORKSPACE_ROOT" "$DV_PROJECTS_ROOT" ;;
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
                        'Usage: dv workspace open [--apply | --dry-run] [--add] [--] [DIR ...]' \
                        'Default: summary only. Add --apply before -- to open VS Code.' \
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
        if [[ $DV_DRY_RUN == true ]]; then
            log 'Plan: open existing folders in VS Code'
            run code "${code_options[@]}" "${workspace_paths[@]}"
            preview_notice
        else
            has code || die 'VS Code command unavailable; make code available in PATH'
            run code "${code_options[@]}" "${workspace_paths[@]}"
        fi ;;
    create)
        (($# == 2)) || die 'Usage: dv workspace create NAME [--apply | --dry-run]'
        valid_name "$2" || die 'Invalid project name'
        run mkdir -p -- "$DV_PROJECTS_ROOT/$2/"{sources,docs,builds}
        [[ $DV_DRY_RUN != true ]] || preview_notice ;;
    *) die 'Usage: dv workspace [open [--add] [DIR ...]|create NAME]' ;;
esac
