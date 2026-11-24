# Ship

[Documentation index](../index.md)

Packaging creates a runtime bundle for distribution. It is optional: a checkout can run directly from `src/app/` without packaging.

## Package

Run from the repository root, using the appropriate shell:

Without `--apply`, both packagers only summarize the destination, files and next
version. No bundle directory is created and `VERSION` is unchanged. `--dry-run`
explicitly requests this default; it cannot be combined with `--apply`.

| Platform | Command |
| --- | --- |
| Ubuntu Bash | `bash src/scripts/ship/ship.sh --apply` |
| Windows CMD | `src\scripts\ship\ship.bat --apply` |
| Windows PowerShell | `.\src\scripts\ship\ship.bat --apply` |
| macOS Bash | `bash src/scripts/ship/ship.sh --apply` |

The scripts copy files listed in `src/scripts/ship/ship-files.txt`; they do not execute installers. Python and PowerShell scripts are not required. make is not required.

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

Each successful ship increments the release counter in `src/app/VERSION` using decimal carry (`0.0.9` → `0.1.0`, `0.9.9` → `1.0.0`) and writes the same version to `dist/vX.X.X_yyMMdd_HHmmss/VERSION`. The starting version is `0.0.1`, so the first ship produces `0.0.2`. Failed file copies do not advance the source version. Packaging changes the checkout; review and commit the version change when preparing a release. Avoid concurrent ship operations on the same checkout.

Minor and patch are single digits (`0`–`9`); major is `0`–`999999`, without leading zeros. Shipping from `999999.9.9` fails without updating the source version. The numbers are a release counter; document compatibility changes separately.

Directory names use the bumped version and the build machine's local time: `vX.X.X_yyMMdd_HHmmss`. For example, version `0.0.2` built on November 15, 2026 at 14:30:25 produces `dist/v0.0.2_261115_143025/`. Existing output directories are never overwritten. The script prints the exact bundle path on success.

Windows uses the built-in `cscript` host and `src/scripts/ship/ship-timestamp.js` to format timestamps independently of date-display settings; PowerShell and Python are not required. If Windows Script Host is unavailable, packaging fails without advancing the source version.

## Run the Bundle

Copy the entire directory, including `internal/`, to the destination. From that directory:

- **Ubuntu:** `bash dev.sh setup --apply`, then `bash dev.sh check`.
- **Windows CMD:** `dev.bat setup`, then `dev.bat check`.
- **Windows PowerShell:** `.\dev.bat setup`, then `.\dev.bat check`.
- **macOS:** Run setup inside a separately prepared Ubuntu VM.

### Where Tools Are Installed

An extracted bundle can be used from a temporary Linux directory such as
`~/Downloads/<bundle-directory>/`. Ubuntu setup with `--apply` copies its Linux
runtime into a stable user-owned tools directory before running selected modules:

```text
~/.local/share/dv-dev-setup/
├── app/                 # Active Linux runtime copy
└── backups/             # Previous runtime, created only when content changes
~/.local/bin/dv          # Symlink into app/internal/linux/tools/dv
~/.config/dv/config.ini  # Persistent user settings
~/.config/dv/aliases.bash
```

From the extracted bundle inside Ubuntu/WSL:

```bash
bash dev.sh setup --only aliases --dry-run
bash dev.sh setup --only aliases --apply
source "$HOME/.config/dv/aliases.bash"
dvc
```

Use `bash dev.sh setup --only tools --apply` or `bash dev.sh install --apply` to copy/register
just the CLI runtime. These do not install Git, Python, Node, or Docker. Full setup
also installs the tool copy before running package modules. `--dry-run` never
copies files. No sudo is required for the tools copy.

`DV_TOOLS_ROOT` in `[setup]` selects the tools storage root before installation;
it must be an absolute Linux filesystem path outside `/mnt/`. The installed
copy infers its own storage root unless explicitly overridden in the environment.
The default is `~/.local/share/dv-dev-setup`, with the active runtime in `app/`.
Setup copies only `internal/linux/install-files.txt` entries, not private files,
Windows scripts, or workspace data. Keep new runtime files in both the Linux
install allowlist and the shipping manifest.

The first run initializes `~/.config/dv/config.ini`; later runs preserve it.
Installed tools use that file automatically, or use explicit `DV_CONFIG` instead.
Keep `DV_CONFIG` exported if you want subsequent CLI/alias invocations to use an
external private override. Changed runtime trees are backed up under `backups/`;
identical reinstalls do not create backups. Existing unmanaged destinations and
unrelated `~/.local/bin/dv` files are preserved and cause an actionable error.
Recognized legacy dv symlinks are migrated to the copy; a link to a different source/bundle is backed up before replacement. Unrelated tools are never overwritten.

After alias setup succeeds, the source checkout or extracted bundle can be moved
or removed without breaking installed commands. For shortcuts created by older
source-based versions, run `setup --only aliases --apply` once; `install --apply`/`--only tools`
refreshes the CLI copy but does not regenerate existing aliases. `dvc` begins with **TOOL PATHS**,
showing the actual active runtime, CLI and config paths. A direct diagnostic
command run from source still reports the source path; it does not install tools.

Project checkouts remain in the configured workspace, for example
`~/workspace/devimony/my-project/sources/my-project-dev/`. For Windows preparation,
keep a complete bundle in an accessible Windows directory and run `dev.bat` there;
the copy/install workflow described here runs inside Ubuntu/WSL.

The bundled `README.txt` includes alias scenarios: setup and activation, environment
and workspace shortcuts, Git review, Docker on demand, customization with
`config.ini`/`DV_CONFIG`, and recovery after moving the bundle. Commands use paths
relative to the copied bundle, so the source checkout is not required.

See [Installation](installation.md) for permissions and platform requirements. The destination does not need Python to run the bundle.

## Configuration and Validation

The current `config.ini` is packaged beside the entrypoints. Never place secrets in it. Only allowlisted runtime files are copied; private overrides and keys are excluded unless someone explicitly adds them to the manifest. Use `DV_CONFIG` to reference a private file outside the bundle.

Each packaging run creates a new versioned directory under `dist/` and preserves older bundles; do not keep persistent data there. Add new runtime files to the manifest when extending the application.

Run `bash src/scripts/check/check.sh` for Bash syntax and ShellCheck, then `bash src/scripts/ship/ship.sh --apply` for packaging. Validate a generated bundle with `bash src/scripts/check/bundle.sh dist/vX.X.X_yyMMdd_HHmmss` (replace the directory with the actual output). Validate source and bundled help commands, manifest contents, and execution after copying the bundle outside the checkout. See [Testing and Validation](../../README.md#testing-and-validation) for commands and CI coverage. Perform installation smoke tests on dedicated machines before release.
