# Volt jam — night5

On-model **screw spin** (jump-dash), **attack-dash**, bot attacks, health packs, upgrade icons.

Godot loads these through `Art` (`scripts/art.gd`). Drop replacement PNGs on the same paths to reskin.

## 1) Screw-attack spin (jump-dash)

`slices/volt/screw_attack/screw_01.png` … `screw_08.png`

Wired as `SpriteFrames` anim `spin` on `World/Volt/Visual/JumpDash`.

API: `Art.volt_spin_frames()`, `Art.has_night5_spin()`, `Art.volt_jump_dash_frames()`.

If this folder is empty, jump-dash falls back to night4 travel textures on the **JumpDash** node (still a separate state from attack-dash — never the Dash/AttackDash clip). Do not invent frames.

## 2) Attack-dash (ground tap-attack)

`slices/volt/attack_dash/attack_dash_01.png` … `attack_dash_06.png`

Same on-model kit as night4 dash (blue hex chest, brown pants, wrench-staff). Wired as anim `attack_dash` on `World/Volt/Visual/AttackDash`.

API: `Art.volt_attack_dash_frames()`. Fallback: `Art.volt_travel_frames()` (night4 dash).

**Do not** play screw frames for attack-dash, or attack-dash frames for jump-dash.

Ground swipe dash still uses night4 travel on `Visual/Run` + `Visual/Dash`.

## 3) Bot attack anims

- `slices/bots/scout_attack/scout_atk_01.png` … `_04.png`
- `slices/bots/popper_attack/popper_atk_01.png` … `_04.png`
- `slices/bots/warden_attack/warden_atk_01.png` … `_04.png`

Wired as `attack` on each enemy `Visual` (walk/hop stay night3). API: `Art.bot_attack_frames("scout"|"popper"|"warden")`.

Scout lunges, Popper fuse, Warden slam play `attack`.

## 4) Health packs

`pickups/health_01.png` … `health_03.png`

API: `Art.health_pack_frames()`. World pickups bob this loop.

## 5) Upgrade / ability icons

`icons/upgrade_01.png` … `upgrade_07.png` plus `icons/upgrades_sheet_labeled.png`

| File | Meaning |
| --- | --- |
| `upgrade_01` | ATK UP |
| `upgrade_02` | HP UP |
| `upgrade_03` | DASH RANGE |
| `upgrade_04` | SCREW SPIN |
| `upgrade_05` | SHIELD BREAK |
| `upgrade_06` | COMBO TIME |
| `upgrade_07` | spare (PACK PULL) |

API: `Art.upgrade_icon(1..7)`. Level-up buttons use the labeled sheet cells (the individual `upgrade_*.png` slices are empty frames / leftovers). Fallback: `upgrade_0N.png`.

## Sheets

Greenscreen masters in `sheets/` (`.gdignore`’d so they stay out of the HTML5 pack).

Godot 2D. Portrait 9:16. Volt + Scout / Popper / Warden only.
