# Volt jam — night3 anim pack

Godot 2D SpriteFrames-ready RGBA frames (chroma-cut `#00FF00`).
Godot loads these first; night-2 idle / night-1 poses are fallbacks.

## Volt (6-frame loops)

- `slices/volt/idle/idle_01..06.png` — breathing idle loop
- `slices/volt/attack/attack_01..06.png` — wind-up → swing → recover
- `slices/volt/dash/dash_01..06.png` — **off-model** (vest / olive pants). Beat 4 plays night4 dash instead.
- `slices/volt/knockback/knockback_01..06.png` — hit → recoil → recover

Wired as `SpriteFrames` on `World/Volt/Visual/{Idle,Attack,Dash,Hurt}`.
Hurt plays the **knockback** folder.

Also accepted: `volt_idle_01.png`, `volt_attack_01.png`, `volt_dash_01.png`, `volt_knockback_01.png` in those folders.

## Bots (4-frame loops)

- `slices/bots/scout/scout_walk_01..04.png`
- `slices/bots/popper/popper_hop_01..04.png`
- `slices/bots/warden/warden_walk_01..04.png`

Wired as `SpriteFrames` on each enemy `Visual` (`walk` or `hop`). Bots are `CharacterBody2D`s that stand on the pile / playable floor.

Also accepted: `walk_01.png` / `hop_01.png` in the same folders.

## Sheets

Greenscreen masters in `sheets/` (`.gdignore`’d so they stay out of the HTML5 pack).

Godot 2D. Portrait 9:16. Volt + Scout / Popper / Warden only.
