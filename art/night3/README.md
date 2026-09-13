# Volt jam — night3 animation pack

Sable night3 loops. Godot loads these first; night-2 idle / night-1 poses are fallbacks.

## Volt (6-frame loops)

`slices/volt/{idle,attack,dash,knockback}/`

Expected filenames (either pattern works):

- `idle/idle_01.png` … `idle_06.png`
- `attack/attack_01.png` … `attack_06.png`
- `dash/dash_01.png` … `dash_06.png`
- `knockback/knockback_01.png` … `knockback_06.png`

Also accepted: `volt_idle_01.png`, `volt_attack_01.png`, `volt_dash_01.png`, `volt_knockback_01.png` in those folders.

Wired as `SpriteFrames` on `World/Volt/Visual/{Idle,Attack,Dash,Hurt}`.
Hurt plays the **knockback** folder.

## Bots (4-frame loops)

`slices/bots/`

- `scout/scout_walk_01.png` … `_04.png`
- `popper/popper_hop_01.png` … `_04.png`
- `warden/warden_walk_01.png` … `_04.png`

Also accepted: `walk_01.png` / `hop_01.png` in the same folders.

Wired as `SpriteFrames` on each enemy `Visual` (`walk` or `hop`). Bots are `CharacterBody2D`s that stand on the pile / playable floor.

## Sheets

Put greenscreen masters in `sheets/` (`.gdignore`’d so they stay out of the HTML5 pack).

Godot 2D. Portrait 9:16. Volt + Scout / Popper / Warden only.
