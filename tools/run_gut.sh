#!/usr/bin/env sh
set -eu

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

if [ -z "${GODOT_BIN:-}" ]; then
    if command -v godot >/dev/null 2>&1; then
        GODOT_BIN="$(command -v godot)"
    elif command -v godot4 >/dev/null 2>&1; then
        GODOT_BIN="$(command -v godot4)"
    elif command -v Godot >/dev/null 2>&1; then
        GODOT_BIN="$(command -v Godot)"
    else
        echo "Set GODOT_BIN to a Godot 4.7 executable or add godot/godot4 to PATH." >&2
        exit 127
    fi
fi

HOME=/private/tmp "$GODOT_BIN" \
    --headless \
    -d \
    --path "$PROJECT_ROOT" \
    -s addons/gut/gut_cmdln.gd \
    -gdir=res://tests/unit \
    -ginclude_subdirs \
    -gexit
