# Tooling Review

[Documentation index](../index.md)

## Scope and Current State

The repository provides an Ubuntu installer and daily CLI. It does not yet provide a single end-to-end setup workflow across all three host platforms: Ubuntu support targets 24.04, Windows requires multiple preparation steps, and macOS has no provisioning adapter.

This review is based on repository code and documentation, not installation results from physical machines. Source organization and packaging have since been consolidated under `src/app/` and `src/scripts/`. The proposals below remain design targets unless explicitly described as implemented.

## Findings and Proposed Improvements

| Priority | Evidence | Impact / proposed action |
| --- | --- | --- |
| P0 | `src/app/dev.sh setup --all` does not install the CLI or run final verification | Combine modules, CLI installation, and final reporting while preserving a side-effect-free dry-run. |
| P0 | `src/app/dev.bat setup` offers steps 1–4 without invoking Ubuntu setup | Add host orchestration with state detection and safe resumption after restart. |
| P0 | No macOS adapter; Linux detection accepts Ubuntu 24.04 only | Select and validate an Ubuntu VM approach before claiming automated macOS support. |
| P1 | Doctor produces text output, tolerates several failures, and does not enforce requested versions | Distinguish missing tools, version mismatches, inactive tools, service failures, and optional components. |
| P1 | Doctor does not inventory system packages; Python/Node.js depend on PATH and nvm detection checks files | Add inventory with source, version, path, and JSON output; distinguish installed from active. |
| P1 | `DV_NODE_VERSION=lts/*` changes over time | Pin an explicit version or manage a release baseline for consistent machines. |
| P1 | The VS Code module provides Windows-oriented guidance | Separate host editor preparation from guest setup and document Remote WSL/SSH per host. |
| P2 | Onboarding, operations, and maintenance previously overlapped in the README | Keep clear entrypoints and cross-links; maintain consistency as documentation evolves. |
| P2 | Personal account/machine details appeared in onboarding | Use development/administrator roles in generic instructions and keep personal configuration separate. |

## Shared Environment Model

| Host | Tools and source location | Host-specific responsibilities |
| --- | --- | --- |
| Ubuntu 24.04 | Existing Linux environment | Validate OS version, architecture, and systemd. |
| Windows | Ubuntu 24.04 on WSL2 | WSL, account-specific distro registration, editor UI, Remote WSL. |
| macOS | Separately prepared Ubuntu 24.04 VM | VM provisioning, SSH, and Remote SSH; automation is not implemented. |
| Other Linux distributions | Separately prepared Ubuntu 24.04 VM if a common runtime is required | VM and editor connection; automation is not implemented. |

Align OS versions, tool definitions, configuration, and verification. Validate x86_64 and aarch64 separately; binaries and container images are not automatically interchangeable.

## Current Source Organization

Start Ubuntu setup with `bash src/app/dev.sh setup` and inspect it with `bash src/app/dev.sh check`. On Windows use `src\app\dev.bat setup` / `check` from CMD, or prefix paths with `.\` in PowerShell. Configuration is in `src/app/config.ini`; implementation is under `src/app/internal/`.

There is no separate launcher directory or PowerShell-script dependency. Bash and batch packagers preserve the runtime layout in `dist/`; see [Ship](ship.md). Organization and packaging do not remove the orchestration limitations above.

## Proposed Command Contract

These are target behaviors, not a list of currently available features.

| Command | Proposed responsibility |
| --- | --- |
| `dev.sh setup` / `dev.bat setup` | Detect host → prepare Linux → run modules → install CLI → verify → report remaining actions. |
| `dv doctor` | Compare the environment with tool definitions and return failure for missing required capabilities. |
| `dv inventory` | List managed tools, versions, paths, and installation sources; support `--json`. |
| `dv inventory --system` | Include system packages without claiming to discover every executable or project dependency. |

Setup and doctor already exist with simpler behavior; inventory is not implemented. Inventory observes state; doctor evaluates it against requirements. Both should share tool definitions with installation logic.

A single entrypoint must still allow UAC/sudo prompts, restarts, initial Linux user creation, and SSH key registration. It should skip completed steps safely, explain how to resume, and recheck actual state after interruption.

## Implementation Sequence and Acceptance Criteria

1. Complete Ubuntu orchestration: modules, CLI installation, and verification in one flow; preserve user configuration on reruns and avoid changes during dry-run.
2. Standardize tool definitions and diagnostics: cover missing tools, version mismatches, tools outside PATH, and disabled modules; define machine-readable output and meaningful exit codes.
3. Add Windows orchestration: smoke-test existing WSL installations and restart-required paths; preserve development-account ownership and support resumption.
4. Implement and validate macOS provisioning for explicitly supported Intel/Apple Silicon environments. Check systemd, Docker, SSH, source paths, and editor connectivity.
5. Keep the consolidated runtime and shipping layout. Claim support only for OS/architecture combinations that have been validated.
