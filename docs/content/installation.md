# Installation

[Documentation index](../index.md)

Open a terminal in `src/app/`, or in a versioned bundle directory under `dist/` after [packaging](ship.md). Review `config.ini` before installation.

## Ubuntu

Use Ubuntu 24.04 on x86_64 or aarch64, a regular development account with sudo access, and Internet access. Docker requires systemd. Do not run the entire setup with sudo.

```bash
bash dev.sh setup --dry-run
bash dev.sh setup
# Open a new Bash shell to load pyenv/nvm, then return to this directory.
bash dev.sh check
```

Keep the checkout in the Linux filesystem, such as `~/workspace/`. In WSL, avoid `/mnt/c/` for development workspaces.

Additional commands:

```bash
bash dev.sh setup --only git
bash dev.sh setup --verify
bash dev.sh check --github
bash dev.sh help
bash dev.sh install --dry-run  # Preview copying/registering tools only.
```

Every setup invocation (except `--verify`) first installs a Linux runtime copy
in `~/.local/share/dv-dev-setup/app`, registers `~/.local/bin/dv`, and then runs
the selected modules from that copy. `setup --only tools` or `install` installs
just these tools without packages. `--dry-run` writes nothing. User settings are
initialized in `~/.config/dv/config.ini` and preserved on later runs. After setup,
the original source or bundle can be moved; aliases and CLI use the installed copy. `check` uses `dv doctor`; it checks key tools and configuration but is not a complete system inventory or a strict version-compliance gate.

SSH key registration and editor configuration require manual steps. See [Usage](usage.md).

## Windows

From CMD:

```bat
dev.bat
```

From PowerShell:

```powershell
.\dev.bat
```

Both invoke native batch; no `.ps1` or execution-policy change is required. The setup menu provides these steps:

1. **Enable WSL features:** Run `dev.bat setup 1` from an administrator CMD, or `.\dev.bat setup 1` from an administrator PowerShell. Save work and restart manually if requested.
2. **Install Ubuntu:** Run step `2` under your normal development account. Existing distro registrations are preserved. Run `wsl -d Ubuntu-24.04` to create the initial Linux user and password.
3. **Configure WSL:** Run step `3` under the same development account. The script requests confirmation and backs up an existing `.wslconfig`. Save work before manually running `wsl --shutdown` to apply changes.
4. **Check readiness:** Run `dev.bat check` in CMD or `.\dev.bat check` in PowerShell.

Once Ubuntu is ready, place the source or bundle in its Linux filesystem and follow the Ubuntu instructions above. Windows setup does not run Ubuntu setup automatically.

## macOS

Provision an Ubuntu 24.04 VM separately and follow the Ubuntu instructions inside it. The repository does not create VMs or install development tools natively on macOS. Other Linux distributions also require a separately prepared Ubuntu environment if the same supported runtime is needed.

Running `dev.bat` without arguments opens the Windows main menu. Select `1` for
setup, select a step, then press a key after viewing the result to return. Use
`B` to go back and `Q` to quit. `dev.bat setup` opens the setup submenu directly.
Direct numbered setup commands remain available.
