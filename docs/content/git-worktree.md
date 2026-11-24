# Git Worktree

[Documentation index](../index.md)

Run these commands in Ubuntu Bash after installing `dv`:

Clone/add/open/remove only summarize by default. The examples use `--apply` to
execute. Omit it (or use `--dry-run`) to preview; `list` is always read-only.

```bash
dv worktree clone git@github.com:OWNER/REPO.git app --apply
cd ~/workspace/devimony/app/sources/app-dev
dv worktree add feature login main --apply
dv worktree add fix login-validation --apply
dv worktree add fix session-timeout main --apply
dv worktree add refactor authentication main --apply
dv worktree list
dv worktree open app-feature-login --apply
```

Each task gets its own branch and directory: `feature/login` maps to `app-feature-login`. Names accept letters, digits, hyphens, and underscores; slashes and `..` are not allowed. The default base is the current worktree's HEAD. Supply an existing ref as the final argument to use another base; `develop` is not assumed.

After committing, pushing, and handling the merge according to the repository's workflow, return to `app-dev`:

```bash
dv worktree remove app-feature-login --apply
```

Removal requires terminal confirmation and leaves the branch intact. The CLI does not determine whether it has been merged. It refuses dirty worktrees, untracked or ignored files, the current directory, unrelated repositories, symlinks, and the primary development worktree. Ignored `.venv` and `node_modules` directories are protected too; preserve or move them before retrying. There is no `--force` option.

The outer `app/` directory contains `sources/`, `docs/`, and `builds/`; the Git root is `app/sources/app-dev/`. Worktree commands require this layout and must run from a worktree of the repository. Creating a workspace alone does not initialize Git.
