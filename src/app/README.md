# Runtime Source and Usage

This directory contains the runnable Ubuntu 24.04 development-environment setup and Windows WSL preparation scripts. It covers Git, SSH, Python, Node.js, Docker, and workspaces.

Run directly from source without packaging or installing Python first. Ubuntu uses `dev.sh`; Windows uses `dev.bat`. macOS requires a separately prepared Ubuntu VM.

## Components

```text
src/app/
├── internal/
│   ├── linux/
│   │   ├── lib/         # Configuration, logging, OS, and package helpers
│   │   ├── scripts/     # Installation modules
│   │   ├── tools/       # dv CLI and daily commands
│   │   └── setup.sh     # Ubuntu setup orchestration
│   └── windows/         # WSL features, Ubuntu registration, configuration, checks
├── config.ini           # Shared configuration and templates
├── dev.bat              # Windows batch entrypoint
├── dev.sh               # Ubuntu Bash entrypoint
└── README.md            # Runtime usage
```

Run modules through the entrypoints. Installation modules depend on shared setup context and must not be executed individually.

## Ubuntu

Open Bash in `src/app/` in the Linux filesystem. Use a regular development account with sudo access; do not run the whole script with sudo. Requirements are Ubuntu 24.04 x86_64/aarch64, Internet access, and systemd for Docker. In WSL, prefer `~/workspace/` over `/mnt/c/`.

```bash
# Review config.ini before setup.
bash dev.sh setup --dry-run
bash dev.sh setup
# Open a new Bash shell, return to this directory, then check:
bash dev.sh check
```

| Command | Purpose |
| --- | --- |
| `bash dev.sh --version` | Display the dv release version from `VERSION`. |
| `bash dev.sh versions` | Report installed tool versions in the current Ubuntu environment. |
| `bash dev.sh help` | Display usage. |
| `bash dev.sh setup --only aliases` | Configure Bash shortcuts from `[aliases]`. |
| `bash dev.sh setup --only git` | Run only the Git module. |
| `bash dev.sh setup --verify` | Inspect the environment without installing tools. |
| `bash dev.sh check --github` | Include GitHub SSH authentication checks. |
| `bash dev.sh cleanup all --keep dv,pyenv,nvm` | Preview cleanup while keeping selected tools. |
| `bash dev.sh cleanup tools nvm --apply` | Remove the selected tool after confirmation. |
| `bash dev.sh install [--dry-run]` | Copy the Linux runtime to the tools directory and register `dv`. |
| `bash dev.sh workspace` | Inspect the workspace. |
| `bash dev.sh workspace open [DIR ...]` | Open the default project root or specified folders in VS Code. |
| `bash dev.sh workspace open --add DIR ...` | Add folders to the last active VS Code window. |
| `bash dev.sh docker status` | Inspect Docker state. |

`--only` accepts `tools`, `system`, `git`, `ssh`, `python`, `node`, `docker`, `vscode`, `workspace`, or `aliases`. Configuration can disable supported module toggles. Diagnostics cover key tools and configuration, not every installed package. SSH registration and editor configuration still require manual steps.

Setup first copies the Linux runtime to `DV_TOOLS_ROOT/app` (default
`~/.local/share/dv-dev-setup/app`) and registers `~/.local/bin/dv`. It then runs
selected modules from that copy. `setup --only tools` or `install` copies just
the tools; dry-run writes nothing. User settings live in `~/.config/dv/config.ini`
and survive reinstalls. Aliases use the installed copy, so source or downloaded
bundles can be moved afterward. Diagnostics show **TOOL PATHS** before System.
Direct source help/diagnostic commands remain read-only and do not require installation.

## Windows

Open CMD in `src/app/`:

```bat
dev.bat help
dev.bat setup
dev.bat check
```

Or use PowerShell in the same directory:

```powershell
.\dev.bat help
.\dev.bat setup
.\dev.bat check
```

Use `dev.bat --version` in CMD or `.\dev.bat --version` in PowerShell to display the same dv release version. Run `bash dev.sh versions` inside Ubuntu to inspect Linux tools.

Both shells invoke native batch; no `.ps1` or internal PowerShell invocation is required.

| CMD command | Action | Account / privileges |
| --- | --- | --- |
| `dev.bat setup 1` | Enable WSL2 Windows features. | Administrator |
| `dev.bat setup 2` | Install Ubuntu 24.04 for the current account. | Normal development account |
| `dev.bat setup 3` | Configure `.wslconfig` with confirmation and backup. | Normal development account |
| `dev.bat check` | Check Windows and WSL readiness. | Normal account |

In PowerShell, prefix each batch path with `.\`. If step 1 requests a restart, save work and restart manually. After step 2, run `wsl -d Ubuntu-24.04` to create the initial Linux user and password. After step 3, save work before manually running `wsl --shutdown` to apply configuration.

Once Ubuntu is ready, place source in its Linux filesystem and follow the Ubuntu instructions above.

Run `dev.bat` without arguments (or `dev.bat menu`) to open the interactive
Windows menu; in PowerShell use `.\dev.bat`. Double-clicking opens the same menu.
Use number keys to choose Setup, Check environment, Version, or Help; `Q` exits.
The setup submenu has four steps and `B` returns to the main menu (or finishes
when opened directly with `dev.bat setup`). Invalid selection keys are ignored.

Each action shows its output and an OK, failure, or restart-required status.
Press a key to return to the menu. Setup runs only the selected step; opening
or navigating menus does not install anything. Scripts do not automatically
elevate or restart Windows. The menu returns the last action's exit code on exit.

Direct commands such as `dev.bat setup 1`, `dev.bat check`, and `dev.bat help`
remain available and wait for a key before returning, preserving their exit code.
For automation, set `DV_NO_PAUSE=true` before calling the script. This skips the
final wait; without arguments it shows help instead of opening a menu. Explicit
`menu` or `setup` without a step is rejected in this mode, so supply a step number:

```bat
rem CMD
set "DV_NO_PAUSE=true"
src\app\dev.bat help
```

```powershell
# PowerShell
$env:DV_NO_PAUSE = 'true'
.\src\app\dev.bat help
```

These examples run from the repository root. In `src/app/` or a bundle directory,
use `dev.bat` in CMD or `.\dev.bat` in PowerShell instead. Clear the variable
when finished (`set "DV_NO_PAUSE="` in CMD or `Remove-Item Env:DV_NO_PAUSE` in
PowerShell) to restore the wait.

## macOS

Prepare an Ubuntu VM separately and follow the Ubuntu instructions inside it. This repository does not provision VMs or run native macOS setup.

## Configuration

Edit `config.ini` beside the entrypoints:

- `[setup]`: tool versions, Git identity, workspace paths, and supported module toggles.
- `[aliases]`: Bash shortcut names and supported command targets; generated in `~/.config/dv/aliases.bash`.
- `[ssh]`: template used when `~/.ssh/config` does not exist.
- `[vscode.extensions]`, `[vscode.settings]`: recommendations to apply manually.
- `[wsl2]`, `[experimental]`: WSL resource settings and options.

Use `DV_CONFIG` for a private override. Never store secrets in configuration. See [Configuration](../../docs/content/configuration.md).

## Packaging

Packagers live in `src/scripts/ship/`. From **this directory (`src/app/`)**:

| Platform | Command |
| --- | --- |
| Ubuntu Bash | `bash ../scripts/ship/ship.sh` |
| Windows CMD | `..\scripts\ship\ship.bat` |
| Windows PowerShell | `..\scripts\ship\ship.bat` |
| macOS Bash | `bash ../scripts/ship/ship.sh` |

Packaging creates `dist/vX.X.X_yyMMdd_HHmmss/` at the repository root without requiring Python or make. Copy the entire bundle, including `internal/`, to the destination and use the same entrypoints. `config.ini` is included; external overrides are not. Do not keep persistent data in `dist/`.

## Development and Validation

See the [root README](../../README.md#develop) for module/CLI extension instructions and [Testing and Validation](../../README.md#testing-and-validation) for syntax, lint, packaging, and platform smoke checks. `make check` runs ShellCheck only; there is no current automated unit-test suite.

[Installation](../../docs/content/installation.md) · [Usage](../../docs/content/usage.md) · [Ship](../../docs/content/ship.md)

Without `--apply`, cleanup prints only a summary; it does not run APT simulation, uninstallers or file-removal commands. See [Cleanup](../../docs/content/cleanup.md) for
whole-environment cleanup with `--keep`, tool/library removal, APT ownership,
confirmation and preserved source/key/config data.
