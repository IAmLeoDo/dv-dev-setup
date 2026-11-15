#!/usr/bin/env bash
# Verify an existing bundle on Linux/macOS without running setup or bumping VERSION.
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
if (($# != 1)) || [[ ! -d $1 ]]; then
    printf 'Usage: bash src/scripts/check/bundle.sh BUNDLE_DIRECTORY\n' >&2
    exit 2
fi
BUNDLE=$(cd -- "$1" && pwd)
TEMP_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEMP_ROOT"' EXIT

# Compare exact file membership, including the two packaging-only additions.
while IFS= read -r relative || [[ -n $relative ]]; do
    relative=${relative%$'\r'}
    [[ -n $relative && $relative != \#* ]] || continue
    printf '%s\n' "$relative"
done < "$ROOT/src/scripts/ship/ship-files.txt" > "$TEMP_ROOT/expected"
printf '%s\n' LICENSE README.txt >> "$TEMP_ROOT/expected"
LC_ALL=C sort "$TEMP_ROOT/expected" > "$TEMP_ROOT/expected.sorted"
(cd -- "$BUNDLE" && find . -type f | sed 's|^./||' | LC_ALL=C sort) > "$TEMP_ROOT/actual"
diff -u "$TEMP_ROOT/expected.sorted" "$TEMP_ROOT/actual"
cmp "$ROOT/src/app/VERSION" "$BUNDLE/VERSION"

# Relocation must work outside the checkout, in a path containing spaces.
mkdir -- "$TEMP_ROOT/copied bundle"
cp -R -- "$BUNDLE/." "$TEMP_ROOT/copied bundle/"
cd -- "$TEMP_ROOT"
if [[ $(uname -s) == Linux ]]; then
    bash "$ROOT/src/app/dev.sh" help
    bash "$TEMP_ROOT/copied bundle/dev.sh" help
    expected="dv $(cat -- "$BUNDLE/VERSION")"
    [[ $(bash "$ROOT/src/app/dev.sh" --version) == "$expected" ]]
    [[ $(bash "$TEMP_ROOT/copied bundle/dev.sh" --version) == "$expected" ]]
    if bash "$TEMP_ROOT/copied bundle/dev.sh" invalid-ci-command; then
        printf 'Invalid command unexpectedly succeeded.\n' >&2
        exit 1
    fi
fi
# macOS validates packaging only; the application targets Ubuntu.
printf 'Bundle validation passed.\n'
