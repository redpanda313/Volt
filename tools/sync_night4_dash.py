#!/usr/bin/env python3
"""Copy landed night4 Volt dash frames into art/night4/ and write Godot .import stubs."""
from __future__ import annotations

import hashlib
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "art/night4/slices/volt/dash"
SOURCES = [
    Path("/workspace/volt/export/night4/slices/volt/dash"),
    ROOT / "volt/export/night4/slices/volt/dash",
    Path.home() / "volt/export/night4/slices/volt/dash",
]

IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{uid}"
path="res://.godot/imported/{stem}.png-{digest}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://art/night4/slices/volt/dash/{stem}.png"
dest_files=["res://.godot/imported/{stem}.png-{digest}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""


def uid_for(stem: str) -> str:
    raw = hashlib.md5(f"volt-night4-{stem}".encode()).hexdigest()
    return f"c{raw[:12]}"


def write_import(png: Path) -> None:
    digest = hashlib.md5(f"res://art/night4/slices/volt/dash/{png.name}".encode()).hexdigest()
    text = IMPORT.format(uid=uid_for(png.stem), stem=png.stem, digest=digest)
    png.with_suffix(".png.import").write_text(text)


def main() -> int:
    DEST.mkdir(parents=True, exist_ok=True)
    copied = 0
    for src in SOURCES:
        if not src.is_dir():
            continue
        for png in sorted(src.glob("dash_*.png")):
            dest = DEST / png.name
            shutil.copy2(png, dest)
            write_import(dest)
            keep = DEST / ".gitkeep"
            if keep.exists():
                keep.unlink()
            copied += 1
        if copied:
            print(f"copied {copied} frames from {src}")
            return 0
    print("no night4 dash frames found in drop paths")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
