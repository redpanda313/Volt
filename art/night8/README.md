# Volt jam — night8 (Beat 9)

Sable frames for **drones that ferry one of seven powerups** across the portrait climb.

Godot loads slices through `Art` (`scripts/art.gd`). Drop replacement PNGs on the same paths to reskin. **Do not invent frames.** If a slice is missing, `Art` uses a flat readable placeholder (colored orb / simple drone) — not Sable art.

## 1) Carrier drone

`carrier_drone/carrier_01_hover.png` … `carrier_06_hover_b.png`

- `carrier_01_hover.png`
- `carrier_02_fly_tilt.png`
- `carrier_03_bank.png`
- `carrier_04_drop_crate.png`
- `carrier_05_fly.png`
- `carrier_06_hover_b.png`

Sheet: `sheets/carrier-drone-keyed.png` (`.gdignore`’d).

API: `Art.night8_drone_frames()`, `Art.night8_drone_fly_frames()`, `Art.night8_drone_drop_tex()`, `Art.drone_frames()`, `Art.has_night8_drones()`.

Wired on `CarrierDrone` (`scripts/drone.gd`). Fly loop uses tilt / fly / bank. `carrier_04_drop_crate` plays when the player collects the cargo.

## 2) Powerup icons

Readable at portrait scale; Volt kit cobalt/copper UI.

`powerups/powerups_sheet_labeled.png` (1280×720) is the source of truth for in-world cargo. Individual slices:

| File | Kind | Effect |
| --- | --- | --- |
| `01_bubble_shield.png` | SHIELD | Temp bubble. Blocks one hit or expires. |
| `02_health.png` | HEALTH | Instant heal (`Volt.pack_heal`, MEDBAY still +2). |
| `03_stealth.png` | STEALTH | Bots do not attack for a short time. |
| `04_overcharge.png` | OVERCHARGE | Temp +1 strike damage. |
| `05_magnet.png` | MAGNET | Temp pull on packs + drones. |
| `06_slow_field.png` | SLOW | Temp: bots move / attack slower. |
| `07_score_mult.png` | SCORE | Temp score ×2. |

API: `Art.night8_powerup_tex(kind)`, `Art.powerup_tex(kind)`, `Art.has_night8_powerups()`, `Art.placeholder_powerup_tex(kind)`.

World cargo uses the labeled-sheet icon cells (no caption). Collect on contact or tap (see `PLAYTEST.md`). The labeled atlas stays in the Web pack so cargo can crop the seven tiles (same pattern as night5 upgrade icons).

## Sheets

Greenscreen masters in `sheets/` (`.gdignore`’d so they stay out of the HTML5 pack): `carrier-drone-green.png`, `carrier-drone-keyed.png`, `powerups-7-icons.png`.

Godot 2D. Portrait 9:16. Size lock stays on actors (`Art.ACTOR_SCALE = 0.516375`). Drones / orbs are props — do not retune Volt or bots to fit this pack.
