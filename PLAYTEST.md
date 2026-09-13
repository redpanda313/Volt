# Playtest — Beat 3 (night-3 anims + juice)

## Where to play

| Path | How |
| --- | --- |
| **GitHub Pages** | https://redpanda313.github.io/Volt/ — live after `main` runs **Actions → Deploy HTML5 to GitHub Pages** |
| **Godot editor** | Import the repo folder (the one with `project.godot`) in **Godot 4.7**. Open `scenes/main.tscn`. Press **F5**. |

Pages does **not** update from this PR branch. After merge, redeploy is the `Deploy HTML5 to GitHub Pages` workflow on `main` (push or **Run workflow**).

Local HTML5: `GODOT=godot ./tools/export_web.sh` then `python3 -m http.server 8080 --directory export/web`.

## Controls (no joystick, no ATTACK button)

- Tap / click **on an enemy** → launch Volt. Attack on contact. Small bounce up+back. Tap another (or the same Warden) to chain.
- Swipe **any direction** → dash that way (longer travel than beat 2). A ground dash still knocks loose top-layer debris.
- Keyboard: `A`/`D`/`W`/`S` or arrows dash, `Space` launch nearest, `R` restart after death.

Empty taps do nothing. Do not look for a virtual stick or an ATTACK button.

## Checklist vs Pete’s beat-3 notes

1. **Scale** — Volt, Scout, Popper, Warden are ~10% smaller **again** (`Art.ACTOR_SCALE = 0.81` = 0.90 × 0.90). Do not confuse with beat 2’s first shrink.
2. **Bot locomotion** — bots are `CharacterBody2D`s. They stand on the playable floor / welded pile (`RobotPile.surface_y_at`) and walk it as layers raise.
   - **Scout** — faster skitter (`speed` 390, walk fps 12).
   - **Popper** — hoppy (`hop_impulse` −390, 4-frame hop).
   - **Warden** — heavier / slower steps (`speed` 78, walk fps 6, stomp cadence).
3. **Omni dash** — swipe vector is the dash vector. Distance is up (`DASH_SPEED` 820 × `DASH_SECS` 0.50 vs beat 2’s 560 × 0.40).
4. **Knockback** — every bot attack shoves Volt. Unique attributes:
   - Scout jab: `knock_speed` 340 / `knock_lift` −140
   - Popper blast: 300 / −520
   - Warden shove: 640 / −70
5. **Night-3 Volt + bot loops** — `SpriteFrames` on `Visual/Idle|Attack|Dash|Hurt` and enemy `Visual`. Paths under `art/night3/` (see `art/night3/README.md`). If a folder is empty, night-2 idle / night-1 poses still loop as placeholders.
6. **AAA juice** — attack camera trauma + hitstop + cyan burst/ring; damage red screen pulse; layered SFX (slash/hit/hurt/explode/slam/shatter/dash/layer). Not subtle on purpose.
7. **Debris pile** — same shatter → knockable top layer → weld → raise playable height. Do not regress this.

Still in: Scout / Popper / Warden only, portrait 9:16, score + height, one mid-run level-up, game over + restart.

## Beat 2 → beat 3 (short)

Actors shrink another ~10%. Swipe-up jump is now an upward dash; any swipe dashes. Bots walk/hop on the rising pile with distinct gaits and shove Volt on hit. Night-3 `SpriteFrames` are wired. Hits punch the screen.

## Night-3 expected paths

```
art/night3/slices/volt/idle/idle_01.png … idle_06.png
art/night3/slices/volt/attack/attack_01.png … attack_06.png
art/night3/slices/volt/dash/dash_01.png … dash_06.png
art/night3/slices/volt/knockback/knockback_01.png … knockback_06.png
art/night3/slices/bots/scout/scout_walk_01.png … _04.png
art/night3/slices/bots/popper/popper_hop_01.png … _04.png
art/night3/slices/bots/warden/warden_walk_01.png … _04.png
```
