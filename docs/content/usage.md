# Usage

[Documentation index](../index.md)

This repository prepares an Ubuntu 24.04 development environment with Git, SSH, pyenv, nvm, Docker Engine, and workspace/worktree tools. Start with [Installation](installation.md) for prerequisites and [Configuration](configuration.md) for supported options.

## Ubuntu Setup

Keep the checkout in the Linux filesystem. From the repository root, as a regular user with sudo access:

```bash
# Review src/app/config.ini first; do not store secrets in it.
bash src/app/dev.sh setup --dry-run
bash src/app/dev.sh setup --all
bash src/app/dev.sh install
export PATH="$HOME/.local/bin:$PATH"
dv doctor
```

Select a module with `setup --only tools|system|git|ssh|python|node|docker|vscode|workspace|aliases` (choose one name), or inspect the environment with `setup --verify`. Reruns preserve existing configuration; conflicting Git identity changes require confirmation. Setup logs are private and stored in `~/.local/state/dv-dev-setup/setup.log`, without captured tool output or keys.

## Bash Shortcuts

Edit `[aliases]` in `src/app/config.ini`, then run:

```bash
bash src/app/dev.sh setup --only aliases --dry-run
bash src/app/dev.sh setup --only aliases
# Open a new Bash shell:
dvc         # dv doctor
dvv         # dv versions
dvw         # dv workspace
gs          # git status
gd --stat   # git diff --stat
```

The module lives in `src/app/internal/linux/scripts/10-aliases.sh`. Full setup
also includes it unless `DV_INSTALL_ALIASES=false`. See
[alias configuration](configuration.md#bash-aliases-ubuntu--wsl) for supported
commands, overrides, and generated-file behavior.

## Windows Preparation

From the repository root in CMD:

```bat
src\app\dev.bat setup
src\app\dev.bat check
```

From PowerShell:

```powershell
.\src\app\dev.bat setup
.\src\app\dev.bat check
```

The menu covers WSL features, Ubuntu installation, resource configuration, and diagnostics. Run step 1 as administrator and steps 2–3 under the development account. Scripts do not elevate themselves or reboot automatically. Follow [Installation](installation.md), then run the Ubuntu workflow inside WSL. Windows owns the VS Code UI and Windows workloads such as .NET/WPF; Linux source belongs in the Linux filesystem.

Run `dev.bat` without arguments (or `dev.bat menu`) to open the interactive
Windows menu; in PowerShell use `.\dev.bat`. Double-clicking opens the same menu.
Use number keys to choose Setup, Check environment, Version, or Help; `Q` exits.
The setup submenu has four steps and `B` returns to the main menu (or finishes
when opened directly with `dev.bat setup`). Invalid selection keys are ignored.

The menu header uses a large ASCII `DV CLI` logo in red with version and
Windows/WSL target information in green. Set `NO_COLOR=1` before launching to
use plain text; `TERM=dumb` also disables colors. No terminal settings are changed.

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

## macOS Preparation

Prepare an Ubuntu VM separately, then follow the Ubuntu workflow inside it. Native macOS setup and automatic VM provisioning are not implemented.

## GitHub SSH

Run inside Ubuntu:

```bash
DV_SSH_GENERATE=true bash src/app/dev.sh setup --only ssh
# Enter the passphrase interactively. Register only the public .pub key with GitHub.
cat ~/.ssh/id_ed25519.pub
# Verify GitHub's host fingerprint independently before first acceptance.
ssh -T git@github.com
dv doctor --github
```

Keychain reuses an SSH Agent. Never commit private keys or store passphrases/tokens in configuration. Automated authentication uses BatchMode and strict host checking; exit code 1 is accepted only with GitHub's expected authentication-success response.

## Python and Node.js

Open a new Bash shell after setup. Work inside your actual project checkout:

```bash
cd ~/workspace/devimony/my-project/sources/my-project-dev
pyenv local 3.13.12
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
# Pin a specific Node.js version instead if reproducibility is required.
printf 'lts/*\n' > .nvmrc
nvm install
nvm use
```

Do not replace system Python or install project dependencies globally. See [Configuration](configuration.md) for version settings.

## Docker Engine

Docker requires systemd. In WSL, merge `[boot]` and `systemd=true` into `/etc/wsl.conf` if needed. Save work before running `wsl --shutdown` from Windows. Scripts do not edit this file automatically.

```bash
dv docker start
sudo docker ps
sudo docker compose version
dv docker test
dv docker stop
# Equivalent service operations:
sudo systemctl start docker
sudo systemctl stop docker.service docker.socket
```

The workflow uses Docker Engine rather than installing Docker Desktop. By default, service and socket autostart are disabled. Package installation may briefly start the daemon before setup stops it. `containerd` may remain active for other workloads. Users are not automatically added to the root-equivalent Docker group. The CLI does not prune data.

## VS Code

For Ubuntu hosts or VMs, prepare the editor connection separately; this repository supplies recommendations rather than installing a desktop editor.

For Windows + WSL, install VS Code and `ms-vscode-remote.remote-wsl` in the Windows UI, then run `code .` inside Ubuntu. VS Code manages its WSL server; do not install Linux desktop VS Code for this workflow. Install Python, Bash, and Docker extensions through **Install in WSL**. Recommendations are in `[vscode.extensions]` of `src/app/config.ini`. Merge sample settings manually.

For macOS + an Ubuntu VM, prepare SSH and a suitable remote-editor connection separately.

## Workspace and Git Worktree

```text
~/workspace/
├── devimony/<project>/
│   ├── sources/<project>-dev/  # Actual Git checkout
│   ├── docs/
│   └── builds/
├── personal/
└── experiments/
```

```bash
dv workspace
dv workspace create my-project
dv worktree clone git@github.com:OWNER/REPO.git my-project
cd ~/workspace/devimony/my-project/sources/my-project-dev
dv worktree add fix docker-startup
dv worktree add feature python-setup main
dv worktree list
dv worktree open my-project-fix-docker-startup
dv worktree remove my-project-fix-docker-startup
```

Clone preserves the remote default branch without assuming `develop`. Add defaults to the current HEAD and creates a task branch and directory. Remove requires confirmation and rejects uncommitted changes, untracked/ignored files, the primary worktree, and unsafe paths. It does not merge or delete branches. See [Git Worktree](git-worktree.md).

## Open One or More Folders in VS Code

The default `dvwo` alias forwards arguments to `dv workspace open`:

```bash
dvwo                                # Configured DV_PROJECTS_ROOT
dvwo .                              # Current directory
dvwo "$HOME/workspace/personal"      # An explicit directory
dvwo ./frontend ./backend           # Multiple folders in a multi-root workspace
dvwo --add ./shared ./docs           # Add folders to the last active VS Code window
dvwo --help
```

Without the alias, use `dv workspace open ...` or
`bash src/app/dev.sh workspace open ...`. All paths must be existing directories;
relative paths are resolved from the command's working directory. Quote paths
with spaces. Use `--` before a path starting with `-`, or prefix it with `./`.
All directories are validated before launching VS Code; the command does not
create folders or write a `.code-workspace` file. `--add` requires an explicit
folder. An explicit path does not require `DV_PROJECTS_ROOT` to exist.

VS Code opens multiple folder arguments as a multi-root workspace. `--add`
targets the last active window; see the official
[VS Code command-line reference](https://code.visualstudio.com/docs/configure/command-line)
and [multi-root workspace guide](https://code.visualstudio.com/docs/editing/workspaces/multi-root-workspaces).

## Versions

Inside Ubuntu, `dv --version` (or `dv version`) displays the dv release version. `dv versions` reports installed tool versions in the current environment, including Git, Python, Node.js, npm, Docker CLI/Compose, VS Code, pyenv, and nvm. Missing tools and unavailable version queries are shown explicitly; the command does not enforce configured versions or require the Docker daemon.

Without CLI installation, use `bash src/app/dev.sh --version` or `bash src/app/dev.sh versions` from the repository root. Windows CMD supports `src\app\dev.bat --version`; PowerShell supports `.\src\app\dev.bat --version`. Run Linux tool queries inside Ubuntu, including on macOS-hosted VMs.

## Environment Report

Run `dvc` (the default alias for `dv doctor`) or `bash src/app/dev.sh check` to
read a report split into System, Development tools, Git & SSH, Docker, Workspace,
and Aliases sections. Rows use `[OK]` for available/configured items, `[WARN]` for
missing items or failed queries, and `[INFO]` for context or skipped checks.
Review warnings against the tools you actually need; optional tools may be absent.

The report starts with **TOOL PATHS**, before System. It shows the tool storage
root, actual active runtime, CLI executable/link, default config, persistent user
config, selected override, and command working directory. It distinguishes a
direct source/bundle invocation from the installed runtime copy.

Setup copies Linux tools to `DV_TOOLS_ROOT/app` (default
`~/.local/share/dv-dev-setup/app`) and points both aliases and `~/.local/bin/dv`
there. Source or download directories can be moved afterward. Workspace shows
the project-source layout and current checkout; see
[where tools are installed](ship.md#where-tools-are-installed).

Development tools are grouped by version manager: **Python / pyenv** shows pyenv
first and the current `python3` beneath it; **Node.js / nvm** shows nvm first,
then the current `node` and `npm`. pyenv and nvm are the main setup checks.
Missing runtimes are informational because versions are installed or selected
separately. Runtime versions come from the current `PATH`; their presence does
not prove they are managed by pyenv/nvm. Git and VS Code appear under Other tools.

The final Aliases section lists the selected `[aliases]` mappings with full
command syntax, options, and copyable examples using each configured alias name.
Each alias starts with its short command mapping, followed by separate Usage,
Actions/Options, and Examples blocks. Long alternatives are listed one per line.
`dvwo` shows how to open one/multiple folders or add folders to the editor.
`dvc` shows `--github`. `dvclean` separates summary-only examples from an Apply
example, then explains every option and the accepted tool names. Git aliases show common options and their
native `--help` command. These hints are printed only; examples are never run.
The section also checks the
managed file's Bash syntax and the source line in `~/.bashrc`. It never executes
the generated file. These checks do not prove aliases are loaded in the terminal
that launched the command; the report shows how to activate them there.

GitHub authentication remains opt-in: `dvc --github` or `dv doctor --github`.
A stopped Docker service is informational when on-demand mode is configured.
The command inspects the environment without installing tools, starting services,
or changing configuration. It returns success when the report completes, even
when warning rows are present; invalid arguments still return an error.

## Cleanup and Removal

```bash
dv cleanup all --keep dv,pyenv,nvm       # Preview while keeping selected tools
dv cleanup all --keep dv,pyenv,nvm --apply
dv cleanup tools nvm                    # Preview one manager and all its versions
dv cleanup project ./my-project         # Preview project libraries only
dv cleanup cache                        # Preview default caches only
```

Without `--apply`, output is a summary of selected paths, tools, packages and
kept items; no APT simulation or cleanup commands run. `--apply` validates the
removal plan and asks for confirmation; `--apply --yes` is for
an explicitly reviewed automated plan. See [Cleanup](cleanup.md) for all tool
selections, exact-version/package removal, older installations without a package
ownership record, and preserved data. Cleanup runs inside Ubuntu/WSL, not through
the Windows preparation menu.

## CLI and Maintenance

Use `dv help`, `dv doctor [--github]`, `dv git status`, `dv workspace open`, and `dv docker status`. Git/worktree operations require the appropriate repository context. `dv install` copies the Linux runtime and registers its symlink in `~/.local/bin`; edit persistent settings in `~/.config/dv/config.ini`.

Read [Security](security.md), [Troubleshooting](troubleshooting.md), and [Maintenance](maintenance.md). Keep secrets out of configuration and preserve TLS/host verification. Pinned upstream tags still require trust in the upstream source.

## Validation

```bash
make check  # Requires make and ShellCheck; runs lint only.
```

CI runs ShellCheck and Bash packaging on Ubuntu, and batch packaging from Windows CMD. Validate actual installation on dedicated environments before release. See [Testing and Validation](../../README.md#testing-and-validation) for detailed checks and coverage limits.
