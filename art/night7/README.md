# Volt jam — night7 sky platforms

Side-view floating platforms for portrait climb. Top surface readable as stand-on.

Godot loads slices through `Art` (`scripts/art.gd`). Drop replacement PNGs on the same paths to reskin. Do not invent frames.

## Variants
`platforms/`
- `01_catwalk.png`
- `02_tech_slab.png` (cobalt underside glow)
- `03_girder.png`
- `04_scrap.png`
- `05_cloud_tech.png`
- `06_step_pad.png`
- `platforms_sheet_keyed.png` (atlas — excluded from Web export)

RGBA chroma-cut. Masters in `sheets/` (`.gdignore`’d).

API: `Art.night7_platform_frames()`, `Art.night7_platform_names()`, `Art.has_night7_platforms()`. Wired as one-way pads on `World/Ledges` (`scripts/ledges.gd`, `scripts/sky_platform.gd`). Pass from below, stand on top.

If the six variant PNGs are missing, `Art.placeholder_platform_frames()` is a flat readable slab — not Sable art.
