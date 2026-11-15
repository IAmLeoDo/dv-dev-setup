# Troubleshooting

[Documentation index](../index.md)

## Ubuntu

- **systemd is unavailable:** Merge `[boot]` and `systemd=true` into `/etc/wsl.conf` for WSL. Save work, then run `wsl --shutdown` from Windows. Check `cat /proc/1/comm` after restarting Ubuntu.
- **Docker permission denied:** Use `sudo docker ...`. A stopped service is expected in on-demand mode; use `dv docker start`. `dv docker stop` stops the socket too, preventing socket activation.
- **Existing Docker packages or a different apt source:** Review the migration manually. The installer does not automatically remove Docker Desktop, distro packages, or conflicting sources.
- **pyenv/nvm is missing:** Open a new Bash shell and inspect `~/.bashrc` initialization. Configure other shells according to upstream instructions. Inspect existing installation directories before replacing anything.
- **GitHub SSH returns exit code 1:** GitHub's successful SSH authentication response also uses exit code 1. Verify the success message, loaded keys with `ssh-add -l`, registered public keys, and the host fingerprint before testing `ssh -T git@github.com`.
- **Configuration errors:** Remove inline comments, use exact boolean values, and check overriding environment variables. Do not run `source src/app/config.ini`.
- **Worktree removal is refused:** Inspect `git status --ignored`, preserve files, and retry from the primary development worktree. Do not bypass protection with `rm -rf`.

### Alias says command not found

Alias setup runs in a child Bash process, so it cannot define aliases in the
terminal that launched it. In your current interactive Ubuntu Bash, run:

```bash
source "$HOME/.config/dv/aliases.bash"
type dvh
dvh
```

If the file does not exist, return to the checkout's `src/app/` or the copied
bundle directory and run `bash dev.sh setup --only aliases`, without sudo and
without `--dry-run`. Keep `DV_INSTALL_ALIASES=true`. Then run the source command
above in your terminal. Windows setup alone does not install Linux aliases, and
full Ubuntu setup may have failed before reaching the aliases module.

If the file exists but `dvh` remains missing, check that the selected `[aliases]`
section contains `dvh=dv help`. A `DV_CONFIG` section replaces the entire alias
list. Rerun alias setup and reload the generated file after changing it.

A new interactive Bash shell normally loads the file through `~/.bashrc`; custom
login startup files must load `~/.bashrc` for this to happen. Other shells do not
load these Bash aliases. If the bundle has moved, rerun setup from its new path.

Use `dv doctor`, `dv doctor --github`, and `dv git status`. Diagnostics distinguish installed/configured/running/authenticated states where implemented; GitHub network checks are opt-in. Setup logs are in `~/.local/state/dv-dev-setup/setup.log`. Detailed apt output is not captured there; inspect terminal errors.

## Windows

- **WSL requests a restart:** Save work, restart manually, and rerun the interrupted step. Use `wsl --status` and `wsl -l -v` to distinguish the WSL runtime from distro state/version.
- **Virtualization is disabled:** Inspect BIOS/UEFI settings and setup step 4 diagnostics. Scripts do not modify firmware.
- **Ubuntu was registered under the wrong account:** Do not delete the distro. Return to the correct account and review manual export/import options. Bootstrap does not unregister distros.
- **`code` is unavailable inside WSL:** Install Windows VS Code, enable its PATH integration, install the WSL extension, and reopen WSL. Do not install Linux desktop VS Code through apt for this workflow.
- **PowerShell cannot locate a batch entrypoint:** Use an explicit relative path such as `.\src\app\dev.bat help`. For a quoted path with spaces, use the call operator: `& 'C:\path with spaces\dev.bat' help`. No execution-policy bypass is needed.

## macOS

Run application setup inside a separately prepared Ubuntu VM. Native macOS installation and automatic VM provisioning are not implemented. Diagnose guest-side issues using the Ubuntu guidance above.
