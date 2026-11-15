# Security

[Documentation index](../index.md)

## Credentials and Configuration

Never put private keys, passphrases, or tokens in `config.ini`, logs, Git, or chat. SSH keys use Ed25519, directory mode 700, and private-key mode 600. Existing keys and configuration must not be overwritten. Public keys are printed to the terminal rather than the setup log. Enter passphrases interactively through `ssh-keygen`; creating an unprotected key requires a separate explicit setting.

Keychain reuses an SSH Agent across terminals. Lock your session when away and use `ssh-add -D` when loaded identities need to be removed.

Configuration is parsed as data without executing substitutions. Setup logs use mode 600 and contain progress/status rather than captured tool output. Diagnostics avoid printing identity/email and remote URLs that may contain tokens. Use only trusted checkouts and configuration files: the repository contains executable installation scripts.

Verify GitHub host fingerprints against [GitHub's documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints) before first acceptance. Do not trust `ssh-keyscan` output without independent verification.

## Ubuntu Privileges and Installation Sources

Do not run the entire bootstrap as root. Use sudo only for package installation, scoped apt keys, and service operations. Docker group membership grants root-equivalent privileges and is not added automatically. Do not expose Docker TCP, change firewalls, prune user data, or disable TLS/SSH verification.

The Docker signing-key fingerprint is checked before installing the keyring; apt uses `signed-by`. pyenv and nvm are cloned over HTTPS at pinned tags rather than using `curl | bash`. Tags can be changed upstream: review releases and consider commit pinning for stricter controls. pyenv checks Python source checksums; nvm checks Node.js downloads using its upstream mechanisms. Existing installations are not automatically upgraded.

Worktree removal requires terminal confirmation and a final Git safety check. Back up important data. The CLI does not automatically merge or delete branches.

Cleanup defaults to a read-only plan. Whole-environment removal supports an
explicit tool keep list and applies only after `--apply` plus confirmation.
APT removal is limited to selected development packages with simulation before
mutation; running Docker/containerd must be stopped manually after saving work.
Source code, SSH keys, persistent user config, tool backups and Docker data are
preserved. Exact managed `.bashrc` lines are removed only with a backup. See
[Cleanup](cleanup.md) for scope and ownership boundaries.

## Windows Account Boundaries

Install the Ubuntu distro and manage `.wslconfig` under the intended development account, not the administrator account used to enable Windows features. Do not add Windows filesystem sharing as part of bootstrap.

Windows entrypoints use native batch and must remain callable from CMD and PowerShell. Do not introduce `.ps1`, invoke PowerShell internally, change execution policy, or bypass security controls.

## macOS

Keep Ubuntu guest credentials and data protected according to the same rules. VM provisioning and host security remain outside this repository's implementation.
