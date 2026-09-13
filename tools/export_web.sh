#!/usr/bin/env bash
# Export the Godot 4.7 Web (HTML5) build locally.
# Requires matching export templates in ~/.local/share/godot/export_templates/4.7.stable/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  if [[ -x /home/ubuntu/godot/godot ]]; then
    GODOT=/home/ubuntu/godot/godot
  fi
fi
mkdir -p "$ROOT/export/web"
"$GODOT" --headless --path "$ROOT" --import
"$GODOT" --headless --path "$ROOT" --export-release "Web" "$ROOT/export/web/index.html"
echo "Wrote $ROOT/export/web/index.html"
