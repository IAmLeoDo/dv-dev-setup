# Development Guidelines

## Project Structure

- This repository prepares and checks development environments. Windows scripts prepare WSL2; Ubuntu scripts install tools and provide the `dv` CLI. Claim platform support only after validation.
- `src/app/` contains the runnable application: `dev.bat`, `dev.sh`, `config.ini`, and `internal/`. Running from source must not require packaging first.
- `src/scripts/` groups maintenance and development scripts by purpose. `src/scripts/ship/` contains packaging scripts, helpers, and the shipping manifest. Place future script groups in separate subdirectories.
- `dist/` contains generated distribution files. Modify source files and regenerate the bundle; do not edit generated files directly.
- `docs/` contains usage, architecture, and maintenance documentation. Update documentation whenever behavior, configuration, or paths change.
- Do not recreate `tests/` or introduce a test framework unless requested. Use appropriate linting, syntax checks, and smoke tests.

## Windows Compatibility

### Shell Support

- Windows entrypoints must be `.bat` files written in native CMD syntax and callable from both CMD and PowerShell.
- Do not create or depend on `.ps1` files. Do not invoke `powershell` or `pwsh`, including through `-Command` or `-EncodedCommand`. Corporate security policies may block PowerShell scripts.
- Do not change execution policies, use `ExecutionPolicy Bypass`, or instruct users to disable security controls.
- Document shell-specific invocation syntax:

  | Shell | From the repository root | Path containing spaces |
  | --- | --- | --- |
  | CMD | `src\app\dev.bat help` | `"C:\path with spaces\dev.bat" help` |
  | PowerShell | `.\src\app\dev.bat help` | `& 'C:\path with spaces\dev.bat' help` |

### Batch Conventions

- Resolve internal paths relative to `%~dp0`; do not depend on the caller's working directory.
- Quote paths, use `set "Name=value"` for assignments, and use `setlocal` to contain environment changes.
- Use `call` when invoking another batch file and execution must return to the caller.
- Return explicit exit codes with `exit /b`. Preserve child-command failures and check errors before continuing. Do not use plain `exit`, which closes the caller's shell.
- Account for variable expansion inside parenthesized blocks. Avoid delayed expansion where it could corrupt literal `!` characters in paths or data.
- Treat configuration as data. Do not construct executable commands from untrusted configuration values.
- Use CRLF line endings for batch files, as defined in `.gitattributes`. Avoid BOMs and code-page-dependent characters in batch commands and messages.
- Prefer built-in Windows tools. Windows setup and packaging must not require Python, Bash, make, or additional packages.
- Request administrator privileges only for the steps that require them; do not elevate the entire workflow.

## Bash and Code Quality

- Application Bash scripts target Ubuntu. The Bash packaging script must use tools available on Linux and macOS. Do not assume Bash runs directly in CMD or PowerShell.
- Resolve paths relative to the script location, quote variable expansions, and use `--` before path arguments where supported.
- Validate arguments and configuration before making system changes.
- Keep entrypoints small and place implementation in the appropriate platform modules. Reuse helpers in `internal/linux/lib/` instead of duplicating logic.
- Keep changes focused on the requested task. Avoid unrelated refactoring and unnecessary dependencies.
- Follow `.editorconfig`. Use UTF-8 and LF line endings for Bash files.
- Help and diagnostic commands must not install software or modify the system.
- Dry-run mode must not write data or install software. Repeated setup runs must preserve existing configuration and installations.
- Report actionable errors and return a nonzero exit code when required steps fail. Do not suppress failures and report success.

## Configuration and Data Safety

- `src/app/config.ini` is the shared configuration file. Preserve the existing `DV_CONFIG` override mechanism.
- Parse configuration as data. Do not use `source`, `eval`, or equivalent execution mechanisms to load configuration values.
- Never commit or expose secrets, private keys, passphrases, or tokens in sample configuration, logs, or diagnostic output.
- Preserve existing user keys, configuration, workspace data, and installations. Follow existing confirmation and backup flows for sensitive changes.
- Limit privilege escalation to operations that require it.
- Do not disable TLS verification, SSH host checking, firewalls, or security policies. Do not perform unsolicited bulk upgrades.
- Do not automatically reboot, shut down WSL, or stop services in ways that interrupt user work. Provide instructions for users to perform disruptive steps after saving their work.

## Packaging

- Packaging must only copy runtime files listed in `src/scripts/ship/ship-files.txt`; it must not execute installers.
- Exclude private configuration, keys, and development data from the bundle.
- The generated `dist/` bundle must run independently of the checkout after being copied to another machine.
- Keep Bash and batch packaging behavior consistent.

## Development Workflow

1. Read the relevant implementation and documentation, then inspect `git status`. Preserve existing user changes.
2. When changing structure or paths, update all affected Bash and batch scripts, shipping manifests, Makefile targets, CI workflows, ignore rules, and documentation.
3. Run `bash -n` on changed Bash files. Run `make check` for ShellCheck when the required tools are available. Fix lint failures introduced by the change.
4. For packaging or path changes, run `bash src/scripts/ship/ship.sh` or `src\scripts\ship\ship.bat` on the corresponding platform. Compare the bundle with the shipping manifest and run the help command from both source and `dist/`.
5. For Windows changes, validate the same `.bat` entrypoints from CMD and PowerShell. Check arguments, exit codes, paths containing spaces, and execution from a different working directory. Bash checks do not validate batch behavior.
6. Do not run actual setup on the development machine solely to validate code. Use dry-run where appropriate and a dedicated machine or VM for installation and administrator-level smoke tests.
7. Report what changed, what was verified, and any remaining limitations. Explicitly identify unavailable tools or platforms; never claim an unperformed check passed.
