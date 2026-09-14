# Volt jam — night6 debris / FG junk

Size locked — no character shrink.

Godot loads slices through `Art` (`scripts/art.gd`). Drop replacement PNGs on the same paths to reskin. Do not invent frames.

## Extra pile debris (night2 style+)
- `debris/scout/scout_junk_*.png`
- `debris/popper/popper_junk_*.png`
- `debris/warden/warden_junk_*.png`
- `debris/density_sheet_keyed.png` (full atlas — excluded from Web export; masters in `sheets/`)
- `debris_night2_reuse/` — prior night2 chunks still valid (ignored in export; packed from `art/night2/`)

API: `Art.night6_kind_junk("scout"|"popper"|"warden")`, `Art.debris_chunks` (night6 junk + night2 chunks).

## Micro fill (density particles)
- `debris/micro/micro_*.png` + `micro_sheet_keyed.png` (atlas excluded from Web export)

API: `Art.night6_micro_frames()`, `Art.has_night6_micro()`. Sprinkled on the pile (no extra physics).

## Foreground parallax junk
- `fg_junk/fg_*.png` — pipes, railings, scrap heaps, barriers, cables
- `fg_junk/fg_sheet_keyed.png` (atlas excluded from Web export)

Wired on `World/Foreground` (`scripts/foreground.gd`). API: `Art.night6_fg_frames()`, `Art.has_night6_fg()`.

## Sheets

Greenscreen masters in `sheets/` (`.gdignore`’d so they stay out of the HTML5 pack).

Godot 2D. Portrait 9:16. Volt + Scout / Popper / Warden only.
