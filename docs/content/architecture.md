# Architecture

[Documentation index](../index.md)

Runtime source lives in `src/app/`. [Packaging](ship.md) produces a standalone `dist/` bundle and preserves relative module paths under `dist/vX.X.X_yyMMdd_HHmmss/internal/`.

## Ubuntu

Ubuntu owns Git, SSH Agent, pyenv, nvm, Docker Engine, and Linux project source. Keep source and project environments in the Linux filesystem; the outer project container is not the Git repository root.

`src/app/dev.sh setup` calls `internal/linux/setup.sh`. By default it summarizes
the runtime copy and selected modules without sourcing installers. With
`--apply`, it runs modules in this order: system → git → ssh → python → node →
docker → vscode → workspace → aliases. Shared configuration parsing, logging,
detection, mode parsing, and package helpers live in `internal/linux/lib/`.
Modules require the orchestrator's context and must not run independently.
`09-verify.sh` invokes diagnostics; `setup --verify` routes directly to the CLI
doctor command. All mutating commands require explicit `--apply`; configuration
cannot opt into execution. Preview and apply flags are mutually exclusive.

Other `dev.sh` commands route to `internal/linux/tools/dv`. The CLI resolves its symlink before loading command implementations from `tools/commands/`. It reads configuration on each invocation and requires no daemon, framework, or Python runtime. Setup/install with `--apply` copies an explicit Linux runtime allowlist from
`internal/linux/install-files.txt` into `DV_TOOLS_ROOT/app` (default
`~/.local/share/dv-dev-setup/app`). `~/.local/bin/dv` points into that copy.
`internal/linux/lib/install.sh` handles this copy for both entrypoints. Setup
continues from the installed runtime before running the selected modules;
`setup --only tools --apply` and `install --apply` copy/register tools without installing packages.
`setup --verify`, diagnostics, and help remain read-only.

Installed tools merge their shipped defaults with `~/.config/dv/config.ini`,
initialized once and preserved afterward; an explicit `DV_CONFIG` replaces that
override. Changed runtime trees are staged before replacement, with the previous
tree retained under `DV_TOOLS_ROOT/backups`. An installation lock rejects concurrent
updates. Existing unmanaged tool directories and unrelated CLI files are refused.
Generated aliases point to the installed app, so moving the checkout or bundle
no longer breaks daily commands.

Use elevated privileges only for package installation, the Docker repository/keyring, and service operations. Docker uses its official repository with a scoped signing key.

`internal/linux/lib/docker.sh` shares group-membership planning between the setup
preview and Docker module. Membership is unchanged by default; the explicit
`DV_DOCKER_ADD_USER_TO_GROUP=true` opt-in plus `--apply` appends the current
non-root account to `docker` without replacing its other groups. Group
administration is privileged; login/group activation is left to the user.

The aliases module validates `[aliases]` targets against a fixed command allowlist before setup changes the system. It generates a separate Bash file and registers it once in `.bashrc`. The implementation lives in `internal/linux/scripts/10-aliases.sh` and runs through `dev.sh setup --only aliases --apply`, using the shared setup context.

## Windows

Windows owns WSL features, account-specific distro registration, the VS Code UI, and Windows workloads such as .NET/WPF. `.wslconfig` belongs to the Windows profile; `/etc/wsl.conf` belongs to each Linux distro.

Native batch entrypoints run from CMD or PowerShell without invoking PowerShell internally.
`dev.bat` routes no-argument and `menu` invocations to `internal/windows/menu.bat`.
The menu uses native `choice` for numbered navigation and repeats after each
explicitly selected action; setup actions delegate to the existing platform
modules. Direct commands preserve exit codes and the optional final pause.
`DV_NO_PAUSE=true` prevents interactive menu entry and suppresses final pauses;
no-argument calls show help in this mode. Windows preparation and Ubuntu installation are separate workflows.

## macOS

Prepare an Ubuntu VM separately. Automatic VM provisioning and a native macOS setup adapter are not implemented.
