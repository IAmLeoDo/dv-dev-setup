# Development scripts

Run these commands from the repository root; make is not required.

Packaging defaults to summary-only preview. The commands below use `--apply` to
create bundles and increment `VERSION`; omit it or use `--dry-run` to preview.

| Purpose | Command |
| --- | --- |
| Bash syntax and ShellCheck | `bash src/scripts/check/check.sh` |
| Existing bundle validation | `bash src/scripts/check/bundle.sh dist/vX.X.X_yyMMdd_HHmmss` |
| Linux/macOS packaging | `bash src/scripts/ship/ship.sh --apply` |
| Windows CMD packaging | `src\scripts\ship\ship.bat --apply` |
| Windows PowerShell packaging | `.\src\scripts\ship\ship.bat --apply` |

`check/` contains development-only checks and is not shipped. Static checking
requires ShellCheck and does not change the system. Bundle checking compares
exact file membership and source/bundle versions, then copies the bundle into a
temporary directory outside the checkout. On Linux it also checks source and
copied-bundle help/version and rejection of an invalid command. Temporary files
are removed on exit. macOS checks packaging only, not the Ubuntu application.

`ship/` contains both packagers and their manifest/helpers. Packaging increments
`src/app/VERSION` after successful copies; it never runs installers. See
[packaging documentation](../../docs/content/ship.md) and
[CI coverage](../../README.md#ci-coverage).
