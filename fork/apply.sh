#!/bin/bash
# Overlay this fork's patches on a checkout of shinchiro/mpv-winbuild-cmake.
# Run from the root of that checkout (the fork itself is checked out in ./_fork).
set -euo pipefail

fork_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy <package>-*.patch next to the package recipe and make the recipe apply them
# the same way upstream's own patched packages do (git am --3way).
add_patches() {
    local pkg="$1"
    local recipe="packages/$pkg.cmake"
    local glob="\${CMAKE_CURRENT_SOURCE_DIR}/$pkg-*.patch"

    cp "$fork_dir"/patches/"$pkg"-*.patch packages/

    if grep -qF "$glob" "$recipe"; then
        return # upstream already applies <package>-*.patch, ours is picked up by the glob
    fi
    if grep -q "PATCH_COMMAND" "$recipe"; then
        echo "error: $recipe has an unexpected PATCH_COMMAND, update fork/apply.sh" >&2
        exit 1
    fi
    sed -i "0,/^    UPDATE_COMMAND \"\"\$/s||&\n    PATCH_COMMAND \${EXEC} git am --3way $glob|" "$recipe"
    if ! grep -qF "git am --3way $glob" "$recipe"; then
        echo "error: could not add PATCH_COMMAND to $recipe" >&2
        exit 1
    fi
    echo "$recipe: applies $(ls packages/"$pkg"-*.patch | xargs -n1 basename | tr '\n' ' ')"
}

add_patches libplacebo
add_patches mpv-packaging
