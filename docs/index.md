# Documentation

Read the guides in this order. Review the first three before running setup;
then follow the daily workflows. The later guides cover troubleshooting,
implementation, packaging, and maintenance. Platform-specific instructions
within each guide follow Ubuntu, Windows, then macOS.

| Order | Guide | What to read it for |
| --- | --- | --- |
| 1 | [Installation](content/installation.md) | Understand platform requirements and the overall setup workflow. |
| 2 | [Configuration](content/configuration.md) | Review `config.ini`, private overrides, tool versions, and Bash aliases. |
| 3 | [Security](content/security.md) | Understand SSH keys, privileges, and installation-source checks before applying setup. |
| 4 | [Usage](content/usage.md) | Run the CLI and use SSH, Python, Node.js, Docker, VS Code, and workspaces. |
| 5 | [Git Worktree](content/git-worktree.md) | Work on multiple branches using the expected workspace layout. |
| 6 | [Cleanup](content/cleanup.md) | Clean dependencies, remove selected tools, or reset the managed environment while keeping chosen tools. |
| 7 | [Troubleshooting](content/troubleshooting.md) | Diagnose setup and environment problems as they arise. |
| 8 | [Architecture](content/architecture.md) | Understand runtime layout and platform responsibilities before changing code. |
| 9 | [Ship](content/ship.md) | Package, copy, and validate standalone distribution bundles. |
| 10 | [Maintenance](content/maintenance.md) | Update tool versions, preserve user data, and validate releases. |
| 11 | [Tooling Review](content/tooling-review.md) | Review current limitations and proposed improvements. |

All documentation content lives in [`content/`](content/); this file is the
entry point and reading-order index. See the [root README](../README.md) for
features, repository components, contributor instructions, and validation commands,
or [runtime usage](../src/app/README.md) for commands from the application directory.
