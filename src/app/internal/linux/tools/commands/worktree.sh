# shellcheck shell=bash
parse_change_options "$@"
set -- "${DV_CHANGE_ARGS[@]}"
action=${1:-list}; (($# == 0)) || shift
if [[ $action == --help || $action == -h ]]; then
    printf '%s\n' \
        'Usage: dv worktree clone URL NAME|add feature|fix|refactor NAME [BASE]|open NAME|remove NAME [--apply | --dry-run]' \
        '       dv worktree list' \
        'Default: summary only. Add --apply to clone, add, open or remove a worktree.' \
        'Removal still requires terminal confirmation and preserves the branch.'
    exit 0
fi
if [[ $action == clone ]]; then
    (($# == 2)) || die 'Usage: dv worktree clone git@github.com:OWNER/REPO.git NAME'
    [[ $1 =~ ^git@github\.com:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die 'Use a GitHub SSH clone URL'
    valid_name "$2" || die 'Invalid project name'
    project="$DV_PROJECTS_ROOT/$2"
    target="$project/sources/$2-dev"
    [[ ! -e $target && ! -L $target ]] || die 'Development directory already exists'
    run mkdir -p -- "$project/"{sources,docs,builds}
    run git clone -- "$1" "$target"
    [[ $DV_DRY_RUN != true ]] || preview_notice
    exit 0
fi
git rev-parse --show-toplevel >/dev/null 2>&1 || die 'Run from a project worktree'
common=$(git rev-parse --path-format=absolute --git-common-dir)
primary=$(dirname -- "$common")
sources=$(dirname -- "$primary")
base_name=$(basename -- "$primary")
[[ $base_name == *-dev && $(basename -- "$sources") == sources ]] || die 'Expected layout: PROJECT/sources/PROJECT-dev; clone with dv worktree clone'
project_name=${base_name%-dev}
case $action in
    list)
        (($# == 0)) || die 'Usage: dv worktree list'
        [[ -z $DV_CHANGE_MODE ]] || die 'Worktree list is read-only; omit mode flags'
        git worktree list ;;
    add)
        (($# == 2 || $# == 3)) || die 'Usage: dv worktree add feature|fix|refactor NAME [BASE]'
        [[ $1 == feature || $1 == fix || $1 == refactor ]] || die 'Invalid worktree category'
        valid_name "$2" || die 'Invalid task name'
        branch="$1/$2"; target="$sources/$project_name-$1-$2"
        git check-ref-format --branch "$branch" >/dev/null
        [[ ! -e $target && ! -L $target ]] || die 'Worktree directory already exists'
        git show-ref --verify --quiet "refs/heads/$branch" && die 'Branch already exists; choose another task name'
        base=${3:-HEAD}
        [[ $base != -* ]] || die 'Invalid base ref'
        git rev-parse --verify "$base^{commit}" >/dev/null || die 'Base must resolve to a commit'
        run git worktree add -b "$branch" -- "$target" "$base"
        [[ $DV_DRY_RUN != true ]] || preview_notice ;;
    open|remove)
        (($# == 1)) || die "Usage: dv worktree $action WORKTREE-NAME"
        valid_name "$1" || die 'Invalid worktree name'
        [[ $1 == "$project_name-"* && $1 != "$base_name" ]] || die 'Only task worktrees can be targeted'
        target="$sources/$1"
        [[ -d $target && ! -L $target ]] || die 'Worktree does not exist or is a symlink'
        [[ $(git -C "$target" rev-parse --show-toplevel) == "$target" ]] || die 'Target is not a worktree root'
        [[ $(git -C "$target" rev-parse --path-format=absolute --git-common-dir) == "$common" ]] || die 'Target belongs to another repository'
        if [[ $action == open ]]; then
            run code "$target"
            [[ $DV_DRY_RUN != true ]] || preview_notice
        else
            [[ -z $(git -C "$target" status --porcelain --untracked-files=all) ]] || die 'Worktree contains uncommitted or untracked work'
            [[ -z $(git -C "$target" ls-files --others --ignored --exclude-standard) ]] || die 'Worktree contains ignored files; preserve them first'
            [[ $(pwd -P)/ != "$target/"* ]] || die 'Change to another worktree before removal'
            if [[ $DV_DRY_RUN == true ]]; then
                log "Plan: remove clean worktree $target after terminal confirmation; preserve its branch"
                preview_notice
            else
                confirm "Remove clean worktree $1? Branch will be preserved." || die 'Removal cancelled'
                run git worktree remove -- "$target"
            fi
        fi ;;
    *) die 'Unknown worktree action' ;;
esac
