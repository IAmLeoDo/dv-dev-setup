# Maintenance

[Documentation index](../index.md)

Inspect `git status` before updating. With a clean working tree on the intended branch, use `git pull --ff-only` and review script/configuration changes before running setup again. Installed tools are a copy, so checkout updates do not change them automatically.
Run `bash src/app/dev.sh install` or `setup --only tools` to refresh that copy.
When migrating older source-based aliases, use `setup --only aliases` once to
retarget the shortcuts too.
User settings in `~/.config/dv/config.ini` are preserved; edit that file instead
of editing the installed runtime's default template. Previous runtime trees are
retained in `DV_TOOLS_ROOT/backups` when content changes.

## Ubuntu

From the repository root:

```bash
make check
bash src/app/dev.sh setup --dry-run
bash src/app/dev.sh setup --verify
dv doctor --github
```

Use an intentional apt maintenance process for OS updates. Bootstrap installs missing packages and does not force a full upgrade. Select explicit Python/Node.js versions, review release notes, and test projects before changing `.python-version` or `.nvmrc`. Existing pyenv/nvm installations are preserved; update them separately after review.

Reference releases and upstream documentation: [Python 3.13.12](https://www.python.org/downloads/release/python-31312/), [pyenv](https://github.com/pyenv/pyenv/releases), [nvm](https://github.com/nvm-sh/nvm/releases), and [Docker on Ubuntu](https://docs.docker.com/engine/install/ubuntu/). Default versions are a configuration baseline, not a guarantee of project dependency compatibility.

Use `dv cleanup tools dv` to preview removal of the installed CLI/runtime and
managed aliases, or `dv cleanup all --keep dv,pyenv,nvm` to clean selected caches
and managed packages while keeping those tools. Add `--apply` and confirm the
plan to execute it. User configuration, source code, SSH keys, tool update backups,
and Docker data are preserved. See [Cleanup](cleanup.md) for full removal,
package ownership tracking, keep selections, and project-library cleanup.

## Windows

Restore `.wslconfig` from its backup if needed. Save work before manually shutting down WSL to apply changes. Review [WSL configuration](https://learn.microsoft.com/en-us/windows/wsl/wsl-config) when changing resource settings.

## macOS

Maintain the Ubuntu guest using the Ubuntu process above. Manage VM lifecycle and host updates separately; the repository does not provision or maintain the VM.

## Release Version

`src/app/VERSION` starts at `0.0.1`. Each successful ship increments the counter and updates both source and bundle. Patch rolls over after 9: `0.0.9` → `0.1.0`; minor also rolls over after 9: `0.9.9` → `1.0.0`. Review and commit the resulting version change with the release. Major must be an integer from 0 to 999999; minor and patch must be single digits from 0 to 9, without leading zeros. The maximum `999999.9.9` is rejected before packaging. These are release counters; document compatibility changes explicitly. Bash and batch entrypoints read this shared value with `--version`; the shipping manifest includes it. Verify that source and bundled versions match. Use `dv versions` inside Ubuntu to inspect installed tool versions separately.

## Release Validation

Run ShellCheck and packaging checks on Ubuntu, then batch packaging and entrypoint checks in Windows CMD and PowerShell. Smoke-test clean and existing Windows 11 + Ubuntu 24.04 WSL2 environments. Cover reruns, restarts, key passphrases, network failures, and Docker on-demand behavior. CI does not validate firmware, real WSL installation, or full setup. See [Testing and Validation](../../README.md#testing-and-validation).

To remove managed Bash shortcuts, remove the source line referencing
`$HOME/.config/dv/aliases.bash` from `~/.bashrc` and remove that generated file.
Open a new shell afterward. To update shortcuts, edit `[aliases]` in `config.ini`
and rerun `setup --only aliases`; the install toggle only skips future setup.
