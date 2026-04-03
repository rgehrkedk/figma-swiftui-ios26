#!/usr/bin/env python3
"""
SF Symbol SVG exporter — cross-platform wrapper.

On macOS with Xcode CLT: compiles and uses the Swift CLI for pixel-perfect Apple vector glyphs.
Fallback: uses pre-cached SVGs from symbol-cache/ directory.

Usage:
    python3 sf_symbol_svg.py export <name> [--weight <w>] [--size <n>]
    python3 sf_symbol_svg.py search <query>
    python3 sf_symbol_svg.py export-for-figma <name> [--weight <w>] --display-width <w> --display-height <h> --color <hex>

The export-for-figma command returns a ready-to-use figma.createNodeFromSvg() JavaScript snippet.
"""

import subprocess
import sys
import os
import json
import platform

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CLI_SRC = os.path.join(SCRIPT_DIR, "sf_symbol_cli.swift")
CLI_BIN = os.path.join(SCRIPT_DIR, ".sf-symbol-cli")
CACHE_DIR = os.path.join(SCRIPT_DIR, "symbol-cache")


def ensure_cli():
    """Compile the Swift CLI if needed. Returns True if available."""
    if os.path.exists(CLI_BIN):
        # Recompile if source is newer
        if os.path.exists(CLI_SRC) and os.path.getmtime(CLI_SRC) > os.path.getmtime(CLI_BIN):
            return compile_cli()
        return True
    return compile_cli()


def compile_cli():
    """Compile the Swift CLI. Returns True on success."""
    if platform.system() != "Darwin":
        return False
    if not os.path.exists(CLI_SRC):
        return False
    try:
        result = subprocess.run(
            ["swiftc", CLI_SRC, "-o", CLI_BIN, "-framework", "AppKit", "-framework", "CoreText"],
            capture_output=True, timeout=60
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def export_via_cli(name, weight="regular", size=24):
    """Export SVG using the Swift CLI."""
    if not ensure_cli():
        return None
    try:
        result = subprocess.run(
            [CLI_BIN, "export", name, "--weight", weight, "--size", str(size)],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip().startswith("<?xml"):
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def export_via_cache(name):
    """Look up a pre-cached SVG."""
    filename = name.replace(".", "-") + ".svg"
    path = os.path.join(CACHE_DIR, filename)
    if os.path.exists(path):
        with open(path) as f:
            return f.read().strip()
    return None


def search_via_cli(query):
    """Search symbols using the Swift CLI."""
    if not ensure_cli():
        return search_via_cache(query)
    try:
        result = subprocess.run(
            [CLI_BIN, "search", query],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
    except (subprocess.TimeoutExpired, FileNotFoundError, json.JSONDecodeError):
        pass
    return search_via_cache(query)


def search_via_cache(query):
    """Search cached SVG filenames."""
    if not os.path.exists(CACHE_DIR):
        return {"query": query, "count": 0, "symbols": [], "source": "cache"}
    q = query.lower()
    matches = []
    for f in sorted(os.listdir(CACHE_DIR)):
        if f.endswith(".svg") and q in f:
            matches.append(f.replace("-", ".").replace(".svg", ""))
    return {"query": query, "count": len(matches), "symbols": matches, "source": "cache"}


def export_symbol(name, weight="regular", size=24):
    """Export an SF Symbol as SVG. Tries CLI first, falls back to cache."""
    svg = export_via_cli(name, weight, size)
    if svg:
        return svg
    svg = export_via_cache(name)
    if svg:
        return svg
    return None


def export_for_figma(name, weight="regular", display_width=12, display_height=12, color=None):
    """Return a ready-to-use JavaScript snippet for figma.createNodeFromSvg()."""
    svg = export_symbol(name, weight)
    if not svg:
        return json.dumps({"error": f"Symbol '{name}' not found"})

    # Modify the SVG width/height to the desired display size
    import re
    svg = re.sub(r'width="\d+"', f'width="{display_width}"', svg)
    svg = re.sub(r'height="\d+"', f'height="{display_height}"', svg)

    # Build the JS snippet
    color_js = ""
    if color:
        # Parse hex color
        c = color.lstrip("#")
        r = int(c[0:2], 16) / 255
        g = int(c[2:4], 16) / 255
        b = int(c[4:6], 16) / 255
        color_js = f"""
// Recolor
const vectors = node.findAll(n => n.type === "VECTOR");
for (const v of vectors) {{
  v.fills = [{{ type: "SOLID", color: {{ r: {r:.3f}, g: {g:.3f}, b: {b:.3f} }} }}];
}}"""

    js = f"""// SF Symbol: {name} ({weight})
const svg = `{svg}`;
const node = figma.createNodeFromSvg(svg);
node.name = "{name}";
node.resize({display_width}, {display_height});{color_js}"""

    return json.dumps({"symbol": name, "weight": weight, "js": js, "svg": svg})


def main():
    args = sys.argv[1:]
    if not args:
        print(json.dumps({
            "usage": "sf_symbol_svg.py <command> [args]",
            "commands": {
                "export <name> [--weight <w>] [--size <n>]": "Export symbol as SVG",
                "search <query>": "Search symbol names",
                "export-for-figma <name> [--weight <w>] --display-width <w> --display-height <h> [--color <hex>]": "Get Figma JS snippet",
            },
            "note": "On macOS with Xcode CLT, exports pixel-perfect Apple vectors. Otherwise uses pre-cached SVGs."
        }, indent=2))
        return

    cmd = args[0]

    if cmd == "export":
        if len(args) < 2:
            print(json.dumps({"error": "Usage: export <name> [--weight <w>] [--size <n>]"}))
            sys.exit(1)
        name = args[1]
        weight = "regular"
        size = 24
        i = 2
        while i < len(args):
            if args[i] == "--weight" and i + 1 < len(args):
                weight = args[i + 1]; i += 2
            elif args[i] == "--size" and i + 1 < len(args):
                size = int(args[i + 1]); i += 2
            else:
                i += 1
        svg = export_symbol(name, weight, size)
        if svg:
            print(svg)
        else:
            print(json.dumps({"error": f"Symbol '{name}' not found"}))
            sys.exit(1)

    elif cmd == "search":
        query = " ".join(args[1:]) if len(args) > 1 else ""
        result = search_via_cli(query) if query else {"error": "Usage: search <query>"}
        print(json.dumps(result, indent=2))

    elif cmd == "export-for-figma":
        if len(args) < 2:
            print(json.dumps({"error": "Usage: export-for-figma <name> [--weight <w>] --display-width <w> --display-height <h> [--color <hex>]"}))
            sys.exit(1)
        name = args[1]
        weight = "regular"
        dw, dh = 12, 12
        color = None
        i = 2
        while i < len(args):
            if args[i] == "--weight" and i + 1 < len(args):
                weight = args[i + 1]; i += 2
            elif args[i] == "--display-width" and i + 1 < len(args):
                dw = int(args[i + 1]); i += 2
            elif args[i] == "--display-height" and i + 1 < len(args):
                dh = int(args[i + 1]); i += 2
            elif args[i] == "--color" and i + 1 < len(args):
                color = args[i + 1]; i += 2
            else:
                i += 1
        print(export_for_figma(name, weight, dw, dh, color))

    else:
        print(json.dumps({"error": f"Unknown command: {cmd}"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
