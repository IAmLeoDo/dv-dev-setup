#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
command=${1:-help}; (($# == 0)) || shift
case $command in
    setup) exec bash "$ROOT/internal/linux/setup.sh" "$@" ;;
    check) exec bash "$ROOT/internal/linux/tools/dv" doctor "$@" ;;
    help|--help|-h)
        printf '%s\n' \
            'Usage: bash dev.sh COMMAND [OPTIONS]' \
            '  --version                                  Show the dv release version' \
            '  versions                                   Show installed tool versions' \
            '  setup [--all|--only MODULE|--verify] [--apply|--dry-run]  Preview/apply Ubuntu setup' \
            '  check [--github]                              Inspect environment' \
            '  install [--apply|--dry-run]                  Preview/apply runtime copy and CLI registration' \
            '  cleanup [cache|project DIR|python VERSION|node VERSION|all|tools|packages] [--apply]  Preview or clean selected dependencies' \
            '  workspace|docker|git|worktree                  Daily commands' \
            'Changes default to summary only. Add --apply to execute; --dry-run explicitly previews.' ;;
    *) exec bash "$ROOT/internal/linux/tools/dv" "$command" "$@" ;;
esac
