#!/usr/bin/env bash
# Package scripts and configuration templates; never run the installers.
set -Eeuo pipefail
SHIP_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SOURCE=$(cd -- "$SHIP_ROOT/../../app" && pwd)
ROOT=$(cd -- "$SHIP_ROOT/../../.." && pwd)
DIST_ROOT="$ROOT/dist"
OUTPUT="$DIST_ROOT"
[[ ! -L $OUTPUT ]] || { printf 'Refusing to replace a symlink at dist/\n' >&2; exit 1; }
version=$(cat -- "$SOURCE/VERSION")
version=${version%$'\r'}
[[ $version =~ ^(0|[1-9][0-9]{0,5})\.([0-9])\.([0-9])$ ]] || {
    printf 'VERSION must contain major.minor.patch (major 0-999999, minor/patch 0-9; no leading zeros).\n' >&2
    exit 1
}
major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}; patch=${BASH_REMATCH[3]}
patch=$((patch + 1))
if ((patch == 10)); then
    patch=0
    minor=$((minor + 1))
    if ((minor == 10)); then
        minor=0
        ((major < 999999)) || { printf 'Version limit reached (999999.9.9).\n' >&2; exit 1; }
        major=$((major + 1))
    fi
fi
next_version="$major.$minor.$patch"
timestamp=$(date '+%y%m%d_%H%M%S')
OUTPUT="$DIST_ROOT/v${next_version}_${timestamp}"
mkdir -p -- "$DIST_ROOT"
mkdir -- "$OUTPUT"
while IFS= read -r relative || [[ -n $relative ]]; do
    relative=${relative%$'\r'}
    [[ -n $relative && $relative != \#* ]] || continue
    target="$OUTPUT/$relative"
    mkdir -p -- "$(dirname -- "$target")"
    case $relative in
        *.bat) awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "$SOURCE/$relative" > "$target" ;;
        *) cp -- "$SOURCE/$relative" "$target" ;;
    esac
    case $relative in
        *.sh|*/dv) chmod 755 "$target" ;;
        *) chmod 644 "$target" ;;
    esac
done < "$SHIP_ROOT/ship-files.txt"
cp -- "$ROOT/LICENSE" "$OUTPUT/LICENSE"
cp -- "$SHIP_ROOT/ship-readme.txt" "$OUTPUT/README.txt"
# Commit the new source version only after all packaging copies succeed.
printf '%s\n' "$next_version" > "$OUTPUT/VERSION"
printf '%s\n' "$next_version" > "$SOURCE/VERSION"
printf 'Version: %s\n' "$next_version"
printf 'Shipped %s\n' "$OUTPUT"
