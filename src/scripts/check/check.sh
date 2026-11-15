#!/usr/bin/env bash
# Shared local/CI static checks. Never run installers or modify configuration.
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
if (($#)); then
    printf 'Usage: bash src/scripts/check/check.sh\n' >&2
    exit 2
fi
command -v shellcheck >/dev/null 2>&1 || {
    printf 'ShellCheck is required. On Ubuntu: sudo apt-get install shellcheck\n' >&2
    exit 1
}
cd -- "$ROOT"
# Include the extensionless CLI, and use NUL separators for paths with spaces.
files=()
while IFS= read -r -d '' file; do
    files+=("$file")
done < <(find src -type f \( -name '*.sh' -o -name dv \) -print0)
for file in "${files[@]}"; do
    bash -n "$file"
done
# Match the previous lint policy: follow sources, excluding unresolved imports.
shellcheck -x -e SC1091 "${files[@]}"
printf 'Bash syntax and ShellCheck passed.\n'
