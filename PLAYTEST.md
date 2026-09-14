# Playtest — Beat 8 (camera, walkers, jump-climb, sparse pads, endless)

## Where to play

| Path | How |
| --- | --- |
| **GitHub Pages** | https://redpanda313.github.io/Volt/ — live after `main` runs **Actions → Deploy HTML5 to GitHub Pages** |
| **Godot editor** | Import the repo folder (the one with `project.godot`) in **Godot 4.7**. Open `scenes/main.tscn`. Press **F5**. |

Pages does **not** update from this PR branch. After merge, redeploy is the `Deploy HTML5 to GitHub Pages` workflow on `main` (push or **Run workflow**).

Local HTML5: `GODOT=godot ./tools/export_web.sh` then `python3 -m http.server 8080 --directory export/web`.

## Controls (no joystick, no ATTACK button)

- Tap / click **on an enemy** → Volt **dashes all the way** to that bot (night5 `attack_dash` frames). Attack on contact. Rebound is **20% of that dash distance**. Tap another (or the same Warden) to chain.
- Swipe **any direction** on the ground → short travel dash (night4 run/dash).
- Swipe **up or in the air** → **jump-dash screw spin** (night5 `screw_attack` / `JumpDash`). **Base: 1 jump.** Landing a strike (attack-dash or jump-dash hit) **refreshes that jump** so jump → attack → jump → attack works. No free double-jump until **EXTRA JUMP**.
- Keyboard: `A`/`D`/`W`/`S` or arrows dash, `Space` strike nearest, `R` restart after death.

Empty taps do nothing. Do not look for a virtual stick or an ATTACK button.

## Checklist vs Pete’s beat-8 notes

1. **Camera centering** — Volt sits **~15% higher on screen** in portrait 9:16. Beat 7 used `camera.y = player.y - 360` (player ~78% down a 1280px view). Beat 8 uses `CAM_PLAYER_OFFSET = 168` (`360 - 0.15 * 1280`) so the player sits ~63% down. Same bias vs the pile floor. Verify on a 9:16 window.
2. **Walkers −25%** — **Scout only** is a normal walker. Ground walk **215 → 161.25**. Walk anim rate scales with it. **Not walkers:** Popper (hop 118), Warden (stomp 54). Those speeds are unchanged.
3. **CRITICAL jump-climb** — bots **jump** onto rising junk. Walk-forward auto-elevate is gone. Root cause was `Enemy._stick_to_pile()` snapping Y to `pile.surface_y_at(x)` whenever a bot walked onto a taller column. That snap is **removed**. `floor_max_angle` is **28°** so junk mounds are not walked as ramps. All three kinds use `_try_climb_jump` (Scout / Warden newly jump; Popper’s hop gets a taller climb impulse when a step is ahead, the player is above, or they hit a wall).
4. **Anti-bury stays** — `RobotPile.unbury_actors` / `lift_out_of_junk` still pops anyone a new lid would seal. Never stuck under junk. Able to jump the rest of the way up. Layer-complete still lifts a seal; it does **not** walk-surf a bot onto a mound they are only walking toward.
5. **Air pads sparse** — night7 frames reused. Pads spawn as height rises (`SkyLedges.ensure_ahead`). Vertical gap **1240–1860px** (viewport is 1280), so **two pads on screen at once is very unlikely**. Random X in **96–624**. Mountain rise still swallows a pad.
6. **Endless vertical climb** — no run-ending height cap. Camera no longer clamps at **y = −1800**. Walls / sky backdrop / stars follow the view. Pads keep generating above the camera. Pile layers were already uncapped. HUD climb level is not clamped at 99; height meter grows with the run.
7. **Keep** — size lock `Art.ACTOR_SCALE = 0.516375`, ramp, night6 junk, jump → attack → jump, EXTRA JUMP, night5/7 art, health packs, level-ups, Volt + Scout / Popper / Warden, portrait 9:16, Pages-safe single-thread Web export.

## Walkers (document)

| Bot | Locomotion | Beat 8 speed | Counts as walker? |
| --- | --- | --- | --- |
| **Scout** | ground walk + lunge | **161.25** × ramp (was 215) | **Yes** |
| Popper | hop | 118 × ramp | No |
| Warden | stomp | 54 × ramp | No |

Constant: `Enemy.WALKER_SPEED_SCALE = 0.75`, `Enemy.SCOUT_WALK = 215`. `Enemy.is_walker()` is Scout-only.

## Health pack drop rule (unchanged from beat 7)

| | Beat 5/6 | Beat 7/8 |
| --- | --- | --- |
| Base | every **3rd** kill | every **2nd** kill |
| PACK PULL | every **2nd** kill | **every** kill |
| Warden | always (if no pack out) | always (if no pack out) |
| Cap | one on screen | one on screen |

Constants: `PACK_EVERY = 2`, `PACK_EVERY_MAGNET = 1` in `scripts/main.gd`.

## Difficulty / spawn curve (unchanged from beat 6)

| Kills | Live bots | Spawn wait (approx) | What you feel |
| --- | --- | --- | --- |
| 0 | 1 | first 1.40s, then 2.55s | One slower Scout. Easy to dodge. |
| 3 | 1 | ~2.32s | Poppers can appear. Still 1v1. **Platform spawns can start.** |
| 7 | 1 | ~2.02s | Warden can roll. Still solo. |
| 8 | 2 | ~1.95s | First overlap / both edges. |
| 16 | 3 | ~1.46s | Late pressure. |
| 24+ | 3 | **1.20s** floor | Fastest cadence. Speed cap 1.70×. |

Per-spawn aggression (index `t`):

- Speed: start Scout **161.25** / Popper 118 / Warden 54, × `(1 + 0.028t)` ≤ 1.70
- Scout lunge: range `148 + 3.5t` (max 215), cooldown starts ~2.35s → ~1.0s
- Popper fuse: hunt `5.4 − 0.085t` (min 3.2s) or near `112 + 2.5t`
- Warden slam CD: `2.85 − 0.055t` (min 1.70s)
- Attack clip speed: `1.05 + 0.025t` (max 1.50)

## Beat 7 → beat 8 (short)

Size, ramp, junk, anti-bury, jump-refresh, EXTRA JUMP, night7 pad **art** stay. Feel changes: player framed higher, Scouts walk slower, bots **jump** the pile (walk-surf snap gone), pads are sparse and keep coming, climb does not hit a ceiling.

## Night-7 expected paths (unchanged)

```
art/night7/platforms/01_catwalk.png
art/night7/platforms/02_tech_slab.png
art/night7/platforms/03_girder.png
art/night7/platforms/04_scrap.png
art/night7/platforms/05_cloud_tech.png
art/night7/platforms/06_step_pad.png
```

API: `Art.night7_platform_frames`, `Art.night7_platform_names`, `Art.has_night7_platforms`, `Art.placeholder_platform_frames` (non-Sable fallback only).

`art/night7/sheets/` is `.gdignore`’d. `platforms_sheet_keyed.png` is in the Web `exclude_filter`.

See `art/night7/README.md`. Night6 junk / FG and night5 screw / packs / icons stay.

## Headless check

```
godot --headless --path . -s tools/beat8_check.gd
godot --headless --path . res://tools/beat8_runtime.tscn
```

Beat 7 scripts remain for regression:

```
godot --headless --path . -s tools/beat7_check.gd
godot --headless --path . res://tools/beat7_runtime.tscn
```
