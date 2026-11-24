# Contributing

Contributions to code, documentation, diagnostics and issue reports are welcome.
Read [AGENTS.md](AGENTS.md) for development rules and the
[architecture guide](docs/content/architecture.md) before changing runtime code.
The project is licensed under the [MIT License](LICENSE).

## Report a problem or propose a change

Search existing issues and pull requests first. Use the bug report or feature
request template when opening an issue. A useful bug report includes the release
or commit, operating system, shell, exact command, expected/actual behavior and
redacted output. State whether the problem occurs from source, a copied bundle
or the installed CLI.

For larger changes, discuss the intended behavior in an issue before investing in
implementation. Small fixes and documentation improvements can go straight to a
pull request. Keep discussions respectful and focused on the technical problem.

Never include credentials, private keys, private configuration or unredacted logs
in issues or PRs. See the [security guide](docs/content/security.md). For a
suspected vulnerability, use the repository's private vulnerability reporting
option if available, or an existing private contact with the maintainer; avoid
publishing sensitive details in a public issue.

## Prepare a checkout

Use a fork if you do not have write access. In the example below, replace
`YOUR-USERNAME` with your GitHub username. Run these Git commands from your
development shell:

```text
git clone https://github.com/YOUR-USERNAME/dv-dev-setup.git
cd dv-dev-setup
git remote add upstream https://github.com/iamleodo/dv-dev-setup.git
git fetch upstream
git switch -c feature/my-change upstream/develop
```

Open ordinary contribution PRs against `develop`. Changes targeting `main` should
be coordinated with the maintainer for a release or hotfix. Use a descriptive
branch name such as `fix/windows-paths` or `docs/setup-guide`.

Check `git status` before editing and preserve any work already present. Keep
commits focused and give them descriptive titles, for example
`Fix bundle paths containing spaces`. Push your branch to your fork and open a
PR with the provided template. A draft PR is appropriate while work or platform
validation is incomplete.

## Development environment and layout

No build step or make installation is required to run from source.

| Area | Location / requirements |
| --- | --- |
| Runnable application | `src/app/`; Ubuntu Bash and native Windows batch entrypoints |
| Ubuntu modules and CLI | `src/app/internal/linux/`; develop and validate inside Ubuntu |
| Windows host preparation | `src/app/internal/windows/`; validate on Windows from CMD and PowerShell |
| Developer checks | `src/scripts/check/`; Bash and ShellCheck for static checks |
| Packaging | `src/scripts/ship/`; Bash on Linux/macOS or native batch on Windows |
| Topic documentation | `docs/content/`; update behavior, paths and configuration together |
| Generated bundles | `dist/`; ignored by Git, never edited by hand |

On Ubuntu, install ShellCheck if it is missing:

```bash
sudo apt-get update
sudo apt-get install -y shellcheck
```

Follow [.editorconfig](.editorconfig) and [.gitattributes](.gitattributes): UTF-8,
LF for Bash and CRLF without a BOM for batch. Windows runtime and packaging must
remain native CMD, callable from CMD and PowerShell, without `.ps1` files or
internal PowerShell invocation. macOS hosts can validate packaging; application
installation belongs inside an Ubuntu VM.

Keep entrypoints small and reuse the shared helpers in
`src/app/internal/linux/lib/`. Preserve `DV_CONFIG` and parse configuration as
data. Dry-run must not write data or install software. Reruns must preserve user
configuration, keys, workspace data and existing installations. Follow existing
confirmation and backup flows for sensitive changes. Do not introduce a test
framework or a `tests/` tree unless explicitly requested.

Every command that changes files, installs software, opens an editor, controls a
service or packages a release must preview by default and require `--apply` to
execute. Keep `--dry-run` as an explicit preview flag and reject conflicting
modes. Confirmations and backups remain required where applicable. When adding
a command, validate default/explicit preview without mutations as well as its
apply path in an isolated environment.

For implementation walkthroughs, see
[adding a setup module](README.md#add-an-ubuntu-setup-module),
[adding a CLI command](README.md#add-a-cli-command) and
[extending Windows setup](README.md#extend-windows-setup).

## Validate the change

Choose checks for the affected behavior and record the commands, environment and
results in the PR. State which checks were not run and why. For documentation-only
changes, check links, paths and examples; installation smoke tests are unnecessary.

From the repository root on Ubuntu:

```bash
bash src/scripts/check/check.sh
bash src/app/dev.sh help
bash src/app/dev.sh --version
```

The shared script runs Bash syntax checks and ShellCheck. If an unrelated check
already fails, compare with the base branch and describe the existing failure;
fix new failures introduced by your change. Do not silently suppress diagnostics
or claim a failed check passed.

For packaging or runtime-path changes:

```bash
bash src/scripts/ship/ship.sh --apply
# Replace this directory with the exact path printed by ship.
bash src/scripts/check/bundle.sh dist/vX.X.X_yyMMdd_HHmmss
```

Shipping increments `src/app/VERSION` and creates a new bundle. Use a disposable
checkout for packaging validation when possible. Before committing, inspect the
diff and exclude incidental local version bumps; include and explain intentional
version changes only when preparing a release. Do not commit `dist/`.

Add or move runtime files in `src/scripts/ship/ship-files.txt`, using paths
relative to `src/app/`. Linux runtime files must also be registered in
`src/app/internal/linux/install-files.txt` so installed copies remain complete.
Check source and bundled behavior after copying the bundle outside the checkout.

For Windows changes, validate the same `.bat` entrypoints in both shells:

| Shell | Source help | Packaging |
| --- | --- | --- |
| CMD | `src\app\dev.bat help` | `src\scripts\ship\ship.bat --apply` |
| PowerShell | `.\src\app\dev.bat help` | `.\src\scripts\ship\ship.bat --apply` |

Also check invalid arguments and exit codes, execution from another working
directory, and paths containing spaces and literal `!`. Quote a batch path with
spaces as `"C:\path with spaces\dev.bat" help` in CMD, or
`& 'C:\path with spaces\dev.bat' help` in PowerShell. Set `DV_NO_PAUSE=true` in
the environment when automating batch entrypoints.

Do not run setup on your development machine just to validate a PR. Preview
affected operations with dry-run, then use a dedicated machine or VM for actual
installation, administrator operations and rerun checks. See
[Testing and Validation](README.md#testing-and-validation) for detailed commands
and [CI coverage](README.md#ci-coverage) for automation limits.

## Prepare the pull request

Explain the problem, resulting behavior and any compatibility impact. Link the
related issue when one exists. Complete the validation table in the
[PR template](.github/pull_request_template.md), including unavailable platforms
and follow-up checks. Update documentation and command help with behavior changes.

Before requesting review, inspect `git diff` and run `git diff --check`. Keep
private/local configuration, generated files and unrelated edits out of the PR.
Respond to review feedback with focused updates and rerun the affected checks.
CI validates static checks, packaging and safe entrypoints; a green run alone
does not demonstrate successful installation on real Windows/WSL or Ubuntu hosts.
