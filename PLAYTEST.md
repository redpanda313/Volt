# Playtest — Beat 7 (anti-bury + night7 sky platforms)

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

## Checklist vs Pete’s beat-7 notes

1. **Size locked** — `Art.ACTOR_SCALE = 0.516375` (beat 5). Volt + Scout / Popper / Warden, colliders included. **Do not shrink.**
2. **Ramp + layered junk stay** — easy 1-spawn start, slow threat/cadence curve, night6 junk + micro + FG. Do not flatten the pile feel.
3. **ANTI-BURY (highest priority)** — junk must **not** harden into floor on top of the player. If a new solidified debris layer would form over / around Volt and seal them, they are **pushed to the surface** of that lid (`RobotPile.unbury_actors` / `lift_out_of_junk`). Same lift for bots so they are not soft-locked under a weld. Layer-complete no longer yanks everyone to `playable_y` (that would pull bots off sky pads).
4. **Sky one-way platforms** — short night7 pads float above the floor. Pass **through from below**, **stand on top**. Works for **Volt and bots** (`CollisionShape2D.one_way_collision` on `World/Ledges`).
5. **Some bots spawn on pads** — after **3 kills**, **40%** of spawns land on a live pad (random pad in camera / play bounds) instead of a floor edge. Early 1-spawn start stays on the floor.
6. **Random X and Y** — pads roll X in **96–624** and Y in climb bands (about **100–900px** above the current floor) with overlap rejection. Mountain rise can swallow a pad (disabled when the pile reaches it).
7. **Health packs more often** — beat 5/6 was every **3rd** kill + every Warden (magnet: every **2nd**). Beat 7 is every **2nd** kill + every Warden (magnet: **every** kill). Still **one pack** on screen. See rule below.
8. **Night7 art wired** — `art/night7/platforms/01_catwalk.png` … `06_step_pad.png` via `Art.night7_platform_frames()`. `sheets/` is `.gdignore`’d. `platforms_sheet_keyed.png` is Web-export excluded. Placeholder slab exists only if those six frames are missing — **no invented Sable frames**.
9. **Keep** — jump → attack → jump chains, EXTRA JUMP, debris pile / solidify / raise, night5/6 art, portrait 9:16, Pages-safe single-thread Web export.

## Health pack drop rule (beat 7)

| | Beat 5/6 | Beat 7 |
| --- | --- | --- |
| Base | every **3rd** kill | every **2nd** kill |
| PACK PULL | every **2nd** kill | **every** kill |
| Warden | always (if no pack out) | always (if no pack out) |
| Cap | one on screen | one on screen |

Constants: `PACK_EVERY = 2`, `PACK_EVERY_MAGNET = 1` in `scripts/main.gd`.

## Difficulty / spawn curve (unchanged from beat 6)

| Kills | Live bots | Spawn wait (approx) | What you feel |
| --- | --- | --- | --- |
| 0 | 1 | first 1.40s, then 2.55s | One slow Scout. Easy to dodge. |
| 3 | 1 | ~2.32s | Poppers can appear. Still 1v1. **Platform spawns can start.** |
| 7 | 1 | ~2.02s | Warden can roll. Still solo. |
| 8 | 2 | ~1.95s | First overlap / both edges. |
| 16 | 3 | ~1.46s | Late pressure. |
| 24+ | 3 | **1.20s** floor | Fastest cadence. Speed cap 1.70×. |

Per-spawn aggression (index `t`):

- Speed: start Scout 215 / Popper 118 / Warden 54, × `(1 + 0.028t)` ≤ 1.70
- Scout lunge: range `148 + 3.5t` (max 215), cooldown starts ~2.35s → ~1.0s
- Popper fuse: hunt `5.4 − 0.085t` (min 3.2s) or near `112 + 2.5t`
- Warden slam CD: `2.85 − 0.055t` (min 1.70s)
- Attack clip speed: `1.05 + 0.025t` (max 1.50)

## Beat 6 → beat 7 (short)

Size, ramp, junk, jump-refresh, EXTRA JUMP stay. Critical feel fail: **do not get sealed under a new junk floor** — pop to the lid. Sky one-way pads (night7 art) sit in the climb path; some bots spawn on them. Packs drop more often.

## Night-7 expected paths

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
godot --headless --path . -s tools/beat7_check.gd
godot --headless --path . res://tools/beat7_runtime.tscn
```
