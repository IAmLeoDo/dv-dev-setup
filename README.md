# 🛠️ dv-dev-setup

Scripts for preparing a consistent development environment on Ubuntu, with Windows batch entrypoints for setting up Ubuntu on WSL2. Run directly from source or package a standalone bundle for another developer.

<a id="table-of-contents"></a>

## 📑 Table of Contents

- [✨ Features](#features)
- [💻 Platform Requirements](#platform-requirements)
- [📂 Repository Components](#repository-components)
- [🚀 Quick Start](#quick-start)
- [🏷️ Version Commands](#version-commands)
  - [🔢 Versioning Rules](#versioning-rules)
- [⚙️ Configuration](#configuration)
- [📦 Ship](#ship)
- [🧑‍💻 Develop](#develop)
  - [🌱 Clone and Prepare](#clone-and-prepare)
  - [🧩 Add an Ubuntu Setup Module](#add-an-ubuntu-setup-module)
  - [⌨️ Add a CLI Command](#add-a-cli-command)
  - [🪟 Extend Windows Setup](#extend-windows-setup)
  - [📏 Development Standards](#development-standards)
- [🧪 Testing and Validation](#testing-and-validation)
- [📚 Further Documentation](#further-documentation)

<a id="features"></a>

## ✨ Features

| Component | Capabilities |
| --- | --- |
| Ubuntu setup | Configure system prerequisites, Git, SSH, Python through pyenv, Node.js through nvm, Docker Engine, and workspace directories. Provide VS Code and remote-development guidance. |
| Windows preparation | Enable WSL features, install Ubuntu 24.04, configure WSL resource limits, and check host readiness through a batch menu. |
| Selective installation | Run the complete Ubuntu setup or select an individual module. Preview changes with dry-run and inspect the environment with diagnostics. |
| Daily CLI | Use `dv` for environment diagnostics, Git status, workspace management, Git worktrees, and Docker lifecycle commands. |
| Shared configuration | Configure tool versions, Git identity, workspace paths, WSL settings, Bash aliases, and editor recommendations in `config.ini`. |
| Distribution | Generate a standalone `dist/` bundle using Bash or native Windows batch, without Python or a build framework. |

Windows setup prepares the host; run Ubuntu setup separately inside Ubuntu. Some steps remain interactive, including first-time Ubuntu account creation, SSH key registration, editor configuration, and restarts.

<a id="platform-requirements"></a>

## 💻 Platform Requirements

- **Ubuntu:** Ubuntu 24.04 on x86_64 or aarch64, a regular development account with sudo access, and Internet access for installation. Docker requires systemd.
- **Windows:** A WSL2-capable Windows host; validate deployments on Windows 11 with Ubuntu 24.04. Run Windows entrypoints from CMD or PowerShell. Administrator access is required for enabling Windows features.
- **macOS:** Prepare an Ubuntu VM separately; this repository does not provision one. The Bash packaging script can run on macOS.
- **Development checks:** Bash, make, and ShellCheck for the Linux lint workflow. Windows validation requires a Windows environment.

Keep the Ubuntu checkout in the Linux filesystem, such as `~/workspace/`, rather than `/mnt/c/`. Run Ubuntu setup as your development user, without prefixing the entire command with sudo.

<a id="repository-components"></a>

## 📂 Repository Components

```text
.
├── .github/
│   └── workflows/               # Ubuntu and Windows CI
├── dist/                        # Generated bundle; ignored by Git
├── docs/
│   ├── index.md                 # Documentation and recommended reading order
│   └── content/                 # Detailed guides and reference material
├── src/
│   ├── app/
│   │   ├── internal/
│   │   │   ├── linux/
│   │   │   │   ├── lib/         # Configuration, logging, detection, packages
│   │   │   │   ├── scripts/     # Ordered installation modules
│   │   │   │   ├── tools/
│   │   │   │   │   ├── commands/ # CLI command implementations
│   │   │   │   │   └── dv       # CLI dispatcher and installation
│   │   │   │   └── setup.sh     # Module selection and orchestration
│   │   │   └── windows/         # WSL preparation and host checks
│   │   ├── config.ini           # Shared configuration and templates
│   │   ├── dev.bat              # Windows entrypoint
│   │   ├── dev.sh               # Ubuntu entrypoint
│   │   ├── README.md            # Detailed runtime usage
│   │   └── VERSION              # dv release version
│   └── scripts/                 # Scripts grouped by purpose
│       └── ship/
│           ├── ship.bat         # Windows batch packager
│           ├── ship.sh          # Bash packager
│           ├── ship-files.txt   # Explicit runtime-file allowlist
│           ├── ship-readme.txt  # Bundled usage instructions
│           └── ship-timestamp.js # Windows local timestamp formatter
├── AGENTS.md                    # Contributor and coding-agent guidelines
└── Makefile                     # ship, lint, and check targets
```

<a id="quick-start"></a>

## 🚀 Quick Start

No packaging step is required to use the checkout.

**Inside Ubuntu**, review `src/app/config.ini`, then run:

```bash
bash src/app/dev.sh help
bash src/app/dev.sh setup --dry-run
bash src/app/dev.sh setup
bash src/app/dev.sh check
```

To install one component or register the daily CLI:

```bash
bash src/app/dev.sh setup --only git
bash src/app/dev.sh install
# Open a new Bash shell after installation.
dv help
dv doctor
dv workspace
dv git status
```

Setup copies Linux runtime files to `~/.local/share/dv-dev-setup/app` and points
`~/.local/bin/dv` there. Aliases use this installed copy, so the source checkout
or downloaded bundle can be moved after setup. User settings are preserved in
`~/.config/dv/config.ini`. Use `setup --only tools` or `install` to refresh just
the tools; changed runtime copies are backed up before replacement.

**Windows CMD**, from the repository root:

```bat
src\app\dev.bat help
src\app\dev.bat setup
src\app\dev.bat check
```

**Windows PowerShell**, from the repository root:

```powershell
.\src\app\dev.bat help
.\src\app\dev.bat setup
.\src\app\dev.bat check
```

Both shells call the same native batch entrypoint; no `.ps1` script or execution-policy change is needed. Enable Windows features as administrator, then install Ubuntu and configure WSL under your normal development account. Follow prompts for any required restart.


**macOS:** Prepare an Ubuntu 24.04 VM, place the checkout inside the VM, and follow the Ubuntu instructions above. Native macOS setup is not provided.

<a id="version-commands"></a>

## 🏷️ Version Commands

The dv release version and installed tool versions are separate:

```bash
bash src/app/dev.sh --version  # dv release version
bash src/app/dev.sh versions   # Installed tool versions
# After installing the CLI:
dv --version
dv versions
```

`src/app/VERSION` is the single release-version source, initially `0.0.1`. Each successful ship increments the version with decimal carry (`0.0.9` → `0.1.0`, `0.9.9` → `1.0.0`) and writes the new value to both source and bundle (for example, `0.0.1` → `0.0.2`). `dv version` is an alias for `dv --version`.

`dv versions` reports Git, Python, Node.js, npm, Docker CLI, Docker Compose, VS Code, pyenv, and nvm. Executables are resolved in the current environment; missing tools or failed version queries are reported explicitly. This is an informational report, not a configuration-compliance check. Docker CLI version reporting does not require a running daemon. nvm is loaded in a subshell without selecting a Node.js version.

Run `dev.bat` without arguments to open a numbered Windows menu: Setup,
Check environment, Version, and Help. Actions return to the menu after a keypress;
use `B` to leave the setup submenu and `Q` to quit. Direct commands still work.
For automation, set `DV_NO_PAUSE=true` and supply a command (and a numbered step
for setup); no-argument calls show help in this mode. Exit codes are preserved.
See [Windows usage](docs/content/usage.md#windows-preparation) for CMD and PowerShell examples.

On Windows, use `src\app\dev.bat --version` in CMD or `.\src\app\dev.bat --version` in PowerShell. Check Linux tool versions with `dv versions` inside Ubuntu. On macOS, run these application commands inside the Ubuntu VM.


<a id="versioning-rules"></a>

### 🔢 Versioning Rules

- **Source of truth:** `src/app/VERSION` stores the dv release version, starting at `0.0.1`. Installed third-party tool versions are independent of this value.
- **Format:** Use `MAJOR.MINOR.PATCH`: `MAJOR` is an integer from `0` to `999999`; `MINOR` and `PATCH` are single digits from `0` to `9`. No leading zeros, `v` prefix, or prerelease/build suffix.
- **Increment:** Every successful ship increases `PATCH`. After `9`, it resets to `0` and increases `MINOR`: `0.0.8` → `0.0.9` → `0.1.0` → `0.1.1`.
- **Carry to major:** After `MINOR=9` and `PATCH=9`, both reset to `0` and `MAJOR` increases: `0.9.9` → `1.0.0`.
- **Compatibility:** These components form a release counter with decimal carry. Document CLI/configuration compatibility changes explicitly; the numbers alone do not describe compatibility.
- **Manual changes:** You may set a valid baseline manually when needed; shipping always increments it. Setting `1.0.0` means the next ship produces `1.0.1`.
- **Synchronization:** Bash and batch packagers write the new version to both `src/app/VERSION` and `dist/vX.X.X_yyMMdd_HHmmss/VERSION`. Entrypoints read that shared file rather than embedding a version string.
- **Failure handling:** Invalid versions and an exhausted counter at `999999.9.9` are rejected. Failed packaging copies do not advance the source version. Review the reported error and ship again before distributing the bundle.
- **Release workflow:** Run ship once per intended bundle, check the source and bundled `--version` output, then review and commit the updated `VERSION` with the release changes. Do not run concurrent ship operations against the same checkout.
- **CI:** CI packaging also increments the version in its temporary checkout. It does not automatically commit that change or create a Git tag/release. A version alone does not uniquely identify a build from separate checkouts; retain the commit SHA when tracking artifacts.

Cleanup can preview a managed-environment reset while keeping selected tools:
`dv cleanup all --keep dv,pyenv,nvm`. Use `--apply` to confirm and execute the plan.
For one tool, use `dv cleanup tools nvm`; for project dependencies, use
`dv cleanup project ./my-project`. See [Cleanup](docs/content/cleanup.md).

<a id="configuration"></a>

## ⚙️ Configuration

Edit `src/app/config.ini` before setup. Its sections cover Ubuntu setup values, WSL resource settings, SSH configuration, and VS Code recommendations. Editor recommendations require manual application in the appropriate Windows or WSL UI.

For a private override, keep a separate configuration file and point `DV_CONFIG` to it. For example, in Ubuntu:

```bash
DV_CONFIG="$HOME/.config/dv-dev-setup/config.ini" bash src/app/dev.sh setup --dry-run
```

Ubuntu setup values use the following precedence: environment variables, the `DV_CONFIG` file, then the bundled configuration. The parser accepts explicitly supported keys; adding a new key requires a parser change. Configuration is data and must never be executed with `source` or `eval`.

Do not store secrets in configuration. Local override files are not packaged. See [Configuration](docs/content/configuration.md) for details.

<a id="ship"></a>

## 📦 Ship

Ship creates a portable runtime bundle for developers who do not need the full checkout. It copies files without running setup.

Each bundle is named `vX.X.X_yyMMdd_HHmmss`, using the incremented version and the build machine’s local time. For example: `dist/v0.0.2_261115_143025/`. Ship prints the exact output path. Windows uses built-in Windows Script Host (`cscript`) for timestamp formatting.

Run from the repository root:

| Environment | Command |
| --- | --- |
| Ubuntu Bash | `bash src/scripts/ship/ship.sh` |
| Ubuntu with make | `make ship` |
| Windows CMD | `src\scripts\ship\ship.bat` |
| Windows PowerShell | `.\src\scripts\ship\ship.bat` |
| macOS Bash | `bash src/scripts/ship/ship.sh` |

Packaging does not require Python or PowerShell scripts. The Windows packager uses native Windows commands; the Bash packager uses standard command-line tools.

```text
dist/
└── v0.0.2_261115_143025/
    ├── internal/
    ├── config.ini
    ├── dev.bat
    ├── dev.sh
    ├── LICENSE
    ├── README.txt
    └── VERSION
```

Copy the **entire versioned bundle directory** from `dist/` to the target machine. From that directory, run `bash dev.sh setup` inside Ubuntu, `dev.bat setup` in Windows CMD, or `.\dev.bat setup` in Windows PowerShell. On macOS, run setup inside your Ubuntu VM.

Each ship operation creates a new `dist/vX.X.X_yyMMdd_HHmmss/` directory and preserves previous bundles. Keep persistent data and private overrides elsewhere. Only files listed in `src/scripts/ship/ship-files.txt`, plus the license and distribution instructions, are copied. Add new runtime files to the manifest or they will be missing from the bundle.

<a id="develop"></a>

## 🧑‍💻 Develop

<a id="clone-and-prepare"></a>

### 🌱 Clone and Prepare

```bash
git clone https://github.com/iamleodo/dv-dev-setup.git
cd dv-dev-setup
git switch -c feature/my-component
```

Read [AGENTS.md](AGENTS.md) and the relevant files under `src/app/` before editing.

**Ubuntu:** Install the optional validation tools if needed:

```bash
sudo apt-get update
sudo apt-get install -y make shellcheck
```

**Windows:** Clone with Git from CMD or PowerShell. Use Ubuntu under WSL for Bash development and linting, and validate batch changes in both Windows shells.

**macOS:** Use an Ubuntu VM for application development and installation checks. Packaging can run from Bash on the macOS host.

Run application commands directly from `src/app/` while developing. Regenerate `dist/` when checking distribution behavior. Do not edit generated bundle files.

### Bash Aliases

Edit `[aliases]` in `src/app/config.ini`, then run
`bash src/app/dev.sh setup --only aliases --dry-run` to preview or
`bash src/app/dev.sh setup --only aliases` to apply. The module lives in
`src/app/internal/linux/scripts/10-aliases.sh`. Open a new Bash shell for shortcuts
such as `dvc` (doctor), `dvv` (versions), `gs` (Git status), and `gd` (Git diff).
See [alias configuration](docs/content/configuration.md#bash-aliases-ubuntu--wsl).

<a id="add-an-ubuntu-setup-module"></a>

### 🧩 Add an Ubuntu Setup Module

For example, to introduce a `database` component:

1. Add a sourced module such as `src/app/internal/linux/scripts/11-database.sh`. Follow an existing module and reuse helpers such as `run`, `apt_install`, `log`, and `die`. Modules receive configuration and shared functions from the orchestrator; do not execute them directly.
2. Update `src/app/internal/linux/setup.sh`: add `database` to argument validation, the execution list, the module mapping, and help text. Choose execution order according to dependencies; the filename alone does not determine order.
3. If configuration is needed, add defaults to `src/app/config.ini` and explicitly allow and validate new keys in `src/app/internal/linux/lib/common.sh`. For an install toggle, support `DV_INSTALL_DATABASE` in the parser and boolean validation; the orchestrator already derives toggle names from module names.
4. Preserve existing installations and user data. Route mutations through dry-run-aware helpers and check third-party commands for side effects before invoking them.
5. Extend diagnostics in `src/app/internal/linux/tools/commands/doctor.sh` when the new component should appear in environment checks.
6. Add every new runtime file to `src/scripts/ship/ship-files.txt`, using paths relative to `src/app/`. Linux runtime files also belong in `src/app/internal/linux/install-files.txt` for setup/install copies.
7. Update usage and configuration documentation, then perform the checks below. Validate actual installation and reruns in a disposable Ubuntu environment.

<a id="add-a-cli-command"></a>

### ⌨️ Add a CLI Command

1. Add the implementation under `src/app/internal/linux/tools/commands/`.
2. Register the command in the explicit dispatch list and help text in `src/app/internal/linux/tools/dv`.
3. Validate arguments and return meaningful exit codes. Apply confirmation and data-preservation rules to destructive operations.
4. Add the implementation to the shipping manifest and document examples. Most commands can pass through `dev.sh` without another entrypoint change; update its help text when appropriate.

<a id="extend-windows-setup"></a>

### 🪟 Extend Windows Setup

1. Add or modify a native `.bat` module under `src/app/internal/windows/`.
2. Connect new steps to `setup.bat` or `check.bat` as appropriate. Update `dev.bat` validation and help if its public arguments change.
3. Resolve paths using `%~dp0`, quote paths, use `call` for child batch files, and return errors with `exit /b`.
4. Keep administrator-only operations separate from normal-account operations. Do not introduce `.ps1`, invoke PowerShell internally, or bypass security policy.
5. Register new runtime files in the shipping manifest and validate invocation from both CMD and PowerShell.

<a id="development-standards"></a>

### 📏 Development Standards

[AGENTS.md](AGENTS.md) defines the full standards. In particular:

- Keep changes focused and reuse platform-specific shared helpers.
- Follow `.editorconfig` and `.gitattributes`: LF for Bash and CRLF for batch.
- Keep source execution and packaged execution consistent.
- Preserve user configuration, keys, existing installations, and workspace data.
- Avoid unnecessary dependencies and do not log secrets.
- Update documentation, packaging, and CI alongside affected behavior.

<a id="testing-and-validation"></a>

## 🧪 Testing and Validation

There is currently no automated unit-test suite or `make test` target. `make check` runs ShellCheck only. Validate changes with static checks, packaging checks, and targeted runtime smoke tests.

<a id="static-checks"></a>

### 🔍 Static Checks

On Ubuntu, from Bash at the repository root:

```bash
# Check syntax for every Bash script, including the extensionless dv CLI.
find src -type f \( -name '*.sh' -o -name dv \) -print0 |
    while IFS= read -r -d '' file; do
        bash -n "$file" || exit 1
    done

# Requires make and ShellCheck.
make check
```

Without make, run the lint command directly if ShellCheck is installed:

```bash
find src -type f \( -name '*.sh' -o -name dv \) -print0 |
    xargs -0 shellcheck -x -e SC1091
```

<a id="packaging-smoke-tests"></a>

### 📦 Packaging Smoke Tests

In the examples below, replace `vX.X.X_yyMMdd_HHmmss` with the directory printed by ship.

On Ubuntu, run:

```bash
bash src/app/dev.sh help
bash src/scripts/ship/ship.sh
bash dist/vX.X.X_yyMMdd_HHmmss/dev.sh help
```

Check that every manifest entry exists in the generated versioned bundle, and that private configuration and unrelated files are excluded. Copy the bundle to a temporary location outside the checkout and run help again to check path independence. Bash packaging normalizes batch files to CRLF, so account for line endings when comparing content.

On Windows, run the following separately in **CMD**:

```bat
src\app\dev.bat help
src\scripts\ship\ship.bat
dist\vX.X.X_yyMMdd_HHmmss\dev.bat help
echo %ERRORLEVEL%
```

And in **PowerShell**:

```powershell
.\src\app\dev.bat help
.\src\scripts\ship\ship.bat
.\dist\vX.X.X_yyMMdd_HHmmss\dev.bat help
$LASTEXITCODE
```

Inspect each command's exit code immediately when investigating failures. Also check invalid arguments, paths containing spaces, execution from another working directory, and a copied bundle.

On macOS, run the Bash packaging command on the host and confirm that the manifest files are present. Run application help and installation checks inside an Ubuntu VM.

<a id="installation-smoke-tests"></a>

### 🧪 Installation Smoke Tests

Use a dedicated machine or VM for changes that install software or alter system settings. On Ubuntu 24.04, preview the affected module first, then validate installation and a second run:

```bash
bash src/app/dev.sh setup --only git --dry-run
# Run the next commands only in the intended test environment.
bash src/app/dev.sh setup --only git
bash src/app/dev.sh setup --only git
bash src/app/dev.sh check
```

Replace `git` with the affected module. Check existing installations, disabled modules, malformed configuration, failure handling, and preservation of user data. Validate WSL features, restarts, resource configuration, and account ownership on a Windows test machine when those paths change. Help and dry-run checks alone do not prove installation works.

<a id="ci-coverage"></a>

### 🔄 CI Coverage

The current workflow in [.github/workflows/test.yml](.github/workflows/test.yml) runs:

- **Ubuntu:** ShellCheck through `make check`, Bash packaging, and bundle artifact upload.
- **Windows:** Batch packaging from CMD.

CI does not currently verify PowerShell invocation or perform real installation tests. Report any checks you could not run and the tools or platforms that were unavailable.

<a id="further-documentation"></a>

## 📚 Further Documentation

- [Documentation index](docs/index.md)
- [Runtime usage](src/app/README.md)
- [Installation](docs/content/installation.md)
- [Configuration](docs/content/configuration.md)
- [CLI and daily workflows](docs/content/usage.md)
- [Architecture](docs/content/architecture.md)
- [Packaging](docs/content/ship.md)
- [Security](docs/content/security.md)
- [Troubleshooting](docs/content/troubleshooting.md)
- [Maintenance](docs/content/maintenance.md)
