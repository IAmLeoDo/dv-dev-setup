# shellcheck shell=bash
action=${1:-list}; (($# == 0)) || shift
if [[ $action == clone ]]; then
    (($# == 2)) || die 'Usage: dv worktree clone git@github.com:OWNER/REPO.git NAME'
    [[ $1 =~ ^git@github\.com:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die 'Use a GitHub SSH clone URL'
    valid_name "$2" || die 'Invalid project name'
    project="$DV_PROJECTS_ROOT/$2"
    target="$project/sources/$2-dev"
    [[ ! -e $target && ! -L $target ]] || die 'Development directory already exists'
    mkdir -p -- "$project/"{sources,docs,builds}
    git clone -- "$1" "$target"
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
    list) (($# == 0)) || die 'Usage: dv worktree list'; git worktree list ;;
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
        git worktree add -b "$branch" -- "$target" "$base" ;;
    open|remove)
        (($# == 1)) || die "Usage: dv worktree $action WORKTREE-NAME"
        valid_name "$1" || die 'Invalid worktree name'
        [[ $1 == "$project_name-"* && $1 != "$base_name" ]] || die 'Only task worktrees can be targeted'
        target="$sources/$1"
        [[ -d $target && ! -L $target ]] || die 'Worktree does not exist or is a symlink'
        [[ $(git -C "$target" rev-parse --show-toplevel) == "$target" ]] || die 'Target is not a worktree root'
        [[ $(git -C "$target" rev-parse --path-format=absolute --git-common-dir) == "$common" ]] || die 'Target belongs to another repository'
        if [[ $action == open ]]; then code "$target"; else
            [[ -z $(git -C "$target" status --porcelain --untracked-files=all) ]] || die 'Worktree contains uncommitted or untracked work'
            [[ -z $(git -C "$target" ls-files --others --ignored --exclude-standard) ]] || die 'Worktree contains ignored files; preserve them first'
            [[ $(pwd -P)/ != "$target/"* ]] || die 'Change to another worktree before removal'
            confirm "Remove clean worktree $1? Branch will be preserved." || die 'Removal cancelled'
            git worktree remove -- "$target"
        fi ;;
    *) die 'Unknown worktree action' ;;
esac
