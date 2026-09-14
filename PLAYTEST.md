# Playtest — Beat 6 (easy start + jump chains + night6 junk)

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

## Checklist vs Pete’s beat-6 notes

1. **Size locked** — `Art.ACTOR_SCALE = 0.516375` (beat 5). Volt + Scout / Popper / Warden, colliders included. **Do not shrink.**
2. **Easy start, 1 spawn** — first bot after **1.40s**. Exactly **one live bot** until 8 kills. Left **or** right edge (`x≈58` / `x≈662`), never both at once early. First bots are slow (Scout **215**, Popper **118**, Warden **54**) with long telegraphs / late lunges.
3. **Slow ramp per bot** — each spawn gets `threat` = spawn index. Speed × `(1 + 0.028 × threat)`, cap **1.70×**. Lunges, fuse, slam, and attack playback ease in on the same index. See curve below.
4. **Spawn rate climbs slowly** — still 1-at-a-time at first. Cadence `2.55 × 0.965^kills`, clamped **1.20–2.70s**. During the solo window a kill **resets** that wait (no instant next bot). At **8 kills** a second bot can overlap. At **16** a third. Never 4.
5. **One jump + attack-refresh** — ground jump (or air swipe) spends the jump. `Volt.refresh_jump()` on strike / rebound. Jump-dash that overlaps a bot also strikes and refreshes. Landing on the floor restores extras only (ground jump is implicit).
6. **EXTRA JUMP** — level-up path at 5 kills, and an ascend pick if you skipped it. Grants **+1 true air jump** (`volt.extra_jumps`). Attack-refresh still works. Icon: sheet cell 4 (same jump/screw cell as SCREW SPIN).
7. **Night6 junk** — floor drops night6 `scout/popper/warden_junk_*` plus night2 chunks + `micro_*` fill. `World/Foreground` plays `fg_junk/fg_01..17` as a parallax FG layer. `sheets/` and `debris_night2_reuse/` are `.gdignore`’d; keyed atlases are Web-export excluded. No invented night6 frames.

Still in: debris pile / solidify / raise, per-type knockback, bot walk/hop on the pile, Scout / Popper / Warden only, night5 anims, health packs, branching level-ups, shake ×0.25 no-stack, portrait 9:16, score + height, game over + restart, Pages-safe single-thread Web export.

## Difficulty / spawn curve

| Kills | Live bots | Spawn wait (approx) | What you feel |
| --- | --- | --- | --- |
| 0 | 1 | first 1.40s, then 2.55s | One slow Scout. Easy to dodge. |
| 3 | 1 | ~2.32s | Poppers can appear. Still 1v1. |
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

## Beat 5 → beat 6 (short)

Size stays. Early fight is one slow bot, not dual-side pressure. Difficulty and cadence climb gently. One jump unless a strike refreshes it; EXTRA JUMP is a real extra. Pile is denser with night6 junk + micro + FG props.

## Night-6 expected paths

```
art/night6/debris/scout/scout_junk_01.png … scout_junk_16.png
art/night6/debris/popper/popper_junk_01.png … popper_junk_16.png
art/night6/debris/warden/warden_junk_01.png … warden_junk_16.png
art/night6/debris/micro/micro_01.png … micro_48.png
art/night6/fg_junk/fg_01.png … fg_17.png
```

API: `Art.night6_kind_junk`, `Art.night6_micro_frames`, `Art.night6_fg_frames`, `Art.has_night6_junk` / `_micro` / `_fg`. `Art.debris_chunks` = night6 kind junk + night2 chunks.

`sheets/` and `debris_night2_reuse/` are `.gdignore`’d (Godot ignores those whole folders). The three keyed atlases next to the slices are listed in the Web `exclude_filter` so Pages does not pack them twice.

See `art/night6/README.md`. Night5 screw / attack-dash / packs / icons stay. Night2 chunks still drop.
