# Playtest — Beat 9 (drone-carried powerups)

## Where to play

| Path | How |
| --- | --- |
| **GitHub Pages** | https://redpanda313.github.io/Volt/ — live after `main` runs **Actions → Deploy HTML5 to GitHub Pages** |
| **Godot editor** | Import the repo folder (the one with `project.godot`) in **Godot 4.7**. Open `scenes/main.tscn`. Press **F5**. |

Pages does **not** update from this PR branch. After merge, redeploy is the `Deploy HTML5 to GitHub Pages` workflow on `main` (push or **Run workflow**).

Local HTML5: `GODOT=godot ./tools/export_web.sh` then `python3 -m http.server 8080 --directory export/web`.

## Controls (no joystick, no ATTACK button)

- Tap / click **on an enemy** → Volt **dashes all the way** to that bot (night5 `attack_dash` frames). Attack on contact. Rebound is **20% of that dash distance**. Tap another (or the same Warden) to chain.
- Tap / click **on a drone or its cargo** → collect that powerup. Empty taps still do nothing.
- Swipe **any direction** on the ground → short travel dash (night4 run/dash).
- Swipe **up or in the air** → **jump-dash screw spin** (night5 `screw_attack` / `JumpDash`). **Base: 1 jump.** Landing a strike (attack-dash or jump-dash hit) **refreshes that jump** so jump → attack → jump → attack works. No free double-jump until **EXTRA JUMP**.
- Keyboard: `A`/`D`/`W`/`S` or arrows dash, `Space` strike nearest, `R` restart after death.

## Checklist vs Pete’s beat-9 notes

1. **Drones ferry powerups** — A carrier flies left↔right across the 9:16 view with **one** of the seven pickups hanging under it. Night8 `carrier_drone/` + `powerups/` frames when present; otherwise a flat drone body and a colored orb (not Sable).
2. **Collect on contact / tap** — Touch the drone or cargo, or tap it. Magnet (temp or PACK PULL) widens the grab and pulls the ferry in.
3. **Readable cadence** — One drone on screen. First ferry at **5.60s**. Then every **8.20s**, easing toward **6.40s** as kills rise (`DRONE_DECAY = 0.985`). A shuffle bag deals all **7** kinds before a repeat, so a normal climb sees each effect. Does not change the beat-6 bot spawn curve.
4. **All 7 effects** — See table below. Timed ones show a HUD cue under the hearts (`SHIELD 4.2`). Same kind collected again **refreshes** the clock.
5. **Night8 hook** — `art/night8/carrier_drone/` and `art/night8/powerups/` (plus `sheets/` `.gdignore`, labeled sheet excluded from Web). API: `Art.night8_drone_frames`, `Art.drone_frames`, `Art.powerup_tex`, `Art.has_night8_drones`, `Art.has_night8_powerups`.
6. **Keep beat 8 feel** — Camera offset **168**, Scout walk **161.25**, jump-climb (no walk-surf), anti-bury, sparse pads, endless climb, size lock `Art.ACTOR_SCALE = 0.516375`. Health-pack drop rule unchanged. Do **not** shrink actors to fit drones.

## Powerups (beat 9)

| # | Kind | Duration | What to check |
| --- | --- | --- | --- |
| 1 | **SHIELD** | **5.5s** or until a hit | Cyan bubble on Volt. Next Scout/Popper/Warden contact pops it (`BLOCK`) — no HP loss, no knockback. Expires if unused. |
| 2 | **HEALTH** | instant | Heals `pack_heal` (1, or 2 with MEDBAY). At full HP: toast `FULL` and **+10** score (× score mult). Night5 pack drop rule still runs on its own. |
| 3 | **STEALTH** | **5.0s** | Volt fades. Scouts do not lunge, Poppers do not start/continue fuse, Wardens do not slam, contact damage is off. Bots still **walk / hop / jump-climb**. |
| 4 | **OVERCHARGE** | **6.0s** | Strike damage **+1** (`strike_power`). SHIELD BREAK 2 → 3 while it lasts. HUD `OVERCHARGE`. |
| 5 | **MAGNET** | **8.0s** | Pulls health packs (same attract as PACK PULL) and nearby drones. Pack drop uses the magnet table (every kill) while it is up. Stacks with the permanent PACK PULL pick. |
| 6 | **SLOW** | **5.5s** | Bots move and tick attacks at **0.42×**. Gravity / climb jump impulse unchanged so they can still jump junk. Slight blue tint on walkers. |
| 7 | **SCORE ×2** | **8.0s** | Kill payouts (base + combo) × **2**. HUD `SCORE ×2`. |

Constants live in `scripts/powerup.gd` (`Powerup.SECS`, `Powerup.SLOW_PACE`, `Powerup.SCORE_POWER`). Spawn cadence in `scripts/main.gd`.

## Drone spawn cadence (fits the climb)

| Kills | Next drone wait | What you feel |
| --- | --- | --- |
| 0 | first **5.60s**, then **8.20s** | Easy 1v1 Scout is already out. First ferry is a readable cross, not a pile-on. |
| 8 | ~**7.25s** | First overlaps. Still one drone. |
| 16 | ~**6.45s** | Late pressure. Floor **6.40s**. |
| 24+ | **6.40s** | Same floor. Shuffle bag still walks all 7. |

One live drone. Crossing takes ~3.5s at **212 px/s**. Lane sits in the action band (`camera.y + 36…176`, above the pile). Miss it and it leaves; the next bag entry comes on the cadence.

## Beat 8 keep (do not regress)

1. **Camera centering** — `CAM_PLAYER_OFFSET = 168`. Player ~63% down a 1280px 9:16 view.
2. **Walkers −25%** — Scout **161.25**. Popper 118 / Warden 54 unchanged.
3. **Jump-climb** — bots jump junk. No `_stick_to_pile`. Lid unbury only when a chunk sits **over** the body.
4. **Anti-bury stays.**
5. **Air pads sparse** — 1240–1860px gap, endless generate.
6. **Endless vertical climb** — no `y = −1800` camera cap.
7. **Size lock** `Art.ACTOR_SCALE = 0.516375`. Night5/6/7 art, packs, level-ups, Volt + Scout / Popper / Warden, Pages-safe single-thread Web export.

## Health pack drop rule (unchanged from beat 7)

| | Beat 5/6 | Beat 7/8/9 |
| --- | --- | --- |
| Base | every **3rd** kill | every **2nd** kill |
| PACK PULL / temp MAGNET | every **2nd** kill | **every** kill |
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

## Night-8 expected paths

```
art/night8/carrier_drone/carrier_01_hover.png
art/night8/carrier_drone/carrier_02_fly_tilt.png
art/night8/carrier_drone/carrier_03_bank.png
art/night8/carrier_drone/carrier_04_drop_crate.png
art/night8/carrier_drone/carrier_05_fly.png
art/night8/carrier_drone/carrier_06_hover_b.png
art/night8/powerups/01_bubble_shield.png
art/night8/powerups/02_health.png
art/night8/powerups/03_stealth.png
art/night8/powerups/04_overcharge.png
art/night8/powerups/05_magnet.png
art/night8/powerups/06_slow_field.png
art/night8/powerups/07_score_mult.png
art/night8/powerups/powerups_sheet_labeled.png
```

See `art/night8/README.md`. Night7 pads, night6 junk / FG, night5 screw / packs / icons stay.

## Headless check

```
godot --headless --path . -s tools/beat9_check.gd
godot --headless --path . res://tools/beat9_runtime.tscn
```

Beat 8 scripts remain for regression:

```
godot --headless --path . -s tools/beat8_check.gd
godot --headless --path . res://tools/beat8_runtime.tscn
```
