# Volt jam — night2 playtest art

## 1) Volt idle loop
`slices/volt_idle/volt_idle_01.png` … `_04.png` (RGBA, chroma-cut)
Loop order 01→02→03→04→01. Greenscreen master: `sheets/volt-idle-loop-green.png`

## 2) Break-apart debris
`slices/debris/{scout,popper,warden}/` — `*_chunk_XX.png` plus `*_pile.png` overview
Keyed master: `sheets/bots-breakapart-keyed.png`

## 3) HUD refine (portrait 9:16)
`hud/hud_portrait_9x16.png` — score, height altitude meter (ground→space), level-up
`hud/hud_elements_sheet.png` — source sheet for slicing UI chrome

Derived HUD overlays (do not replace the Sable sources):

- `hud/hud_top.png` — score / level capsule, placeholder digits recessed
- `hud/hud_meter.png` — altitude rail (GROUND → SPACE)

Regenerate with `python3 tools/extract_hud_chrome.py` if the sheet or portrait changes.

Godot 2D. No joystick / ATTACK button.
