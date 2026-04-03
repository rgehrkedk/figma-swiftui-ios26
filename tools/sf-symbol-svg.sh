#!/bin/bash
# SF Symbol SVG exporter — auto-compiles on first use
# Usage: sf-symbol-svg.sh export <name> [--weight <w>] [--size <n>]
#        sf-symbol-svg.sh search <query>
#        sf-symbol-svg.sh info <name>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLI="$SCRIPT_DIR/.sf-symbol-cli"
SRC="$SCRIPT_DIR/sf_symbol_cli.swift"

# Auto-compile if binary missing or source is newer
if [ ! -f "$CLI" ] || [ "$SRC" -nt "$CLI" ]; then
  if ! command -v swiftc &>/dev/null; then
    echo '{"error": "swiftc not found. Install Xcode Command Line Tools: xcode-select --install"}' >&2
    exit 1
  fi
  swiftc "$SRC" -o "$CLI" -framework AppKit -framework CoreText 2>/dev/null
  if [ $? -ne 0 ]; then
    echo '{"error": "Failed to compile sf_symbol_cli.swift"}' >&2
    exit 1
  fi
fi

exec "$CLI" "$@"
