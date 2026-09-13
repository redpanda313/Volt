# Playtest — Beat 4 (night4 dash + feel)

## Where to play

| Path | How |
| --- | --- |
| **GitHub Pages** | https://redpanda313.github.io/Volt/ — live after `main` runs **Actions → Deploy HTML5 to GitHub Pages** |
| **Godot editor** | Import the repo folder (the one with `project.godot`) in **Godot 4.7**. Open `scenes/main.tscn`. Press **F5**. |

Pages does **not** update from this PR branch. After merge, redeploy is the `Deploy HTML5 to GitHub Pages` workflow on `main` (push or **Run workflow**).

Local HTML5: `GODOT=godot ./tools/export_web.sh` then `python3 -m http.server 8080 --directory export/web`.

## Controls (no joystick, no ATTACK button)

- Tap / click **on an enemy** → Volt **dashes all the way** to that bot. Attack on contact. Rebound is **10% of that dash distance**, up and away (not a fixed bounce). Tap another (or the same Warden) to chain.
- Swipe **any direction** → shorter, faster dash than beat 3 (distance ×0.5, speed ×1.3). A ground dash still knocks loose top-layer debris.
- Keyboard: `A`/`D`/`W`/`S` or arrows dash, `Space` strike nearest, `R` restart after death.

Empty taps do nothing. Do not look for a virtual stick or an ATTACK button.

## Checklist vs Pete’s beat-4 notes

1. **Juice polish** — same trauma / hitstop / pulse / burst / ring / SFX base. Added camera zoom punch + rotation + directional kick, `WorldEnvironment` 2D glow (canvas max layer 0 so HUD stays clean), hit bloom flash, additive impact halo, dash afterimage trail. Must feel more premium, not quieter.
2. **Night4 on-model run/dash** — `art/night4/slices/volt/dash/dash_01..06.png` is the travel loop (blue hex chest, brown pants, blue greaves, wrench-staff). Optional `art/night4/slices/volt/run/` wins if it lands. **Night3 dash is off-model and is not used.** Idle / attack / hurt stay night3 unless a night4 copy is the only file present. Missing night4 travel falls back to night-1 `volt_dodge.png`.
3. **Scale** — another ~15% shrink on top of beat 3: `Art.ACTOR_SCALE = 0.6885` (0.81 × 0.85).
4. **Dash** — vs beat 3 (820 × 0.50): speed ×1.3 (`DASH_SPEED` 1066), distance ×0.5 (`DASH_SECS` 0.1923). Air dash 988 × same duration. Afterimage upgrade still lengthens the dash.
5. **Gravity** — faster start (`GRAVITY` 3000) + higher fall terminal (`FALL_GRAVITY` 4200, `MAX_FALL` 1750). Bot gravity stays 2100 so pile locomotion does not regress.
6. **Tap attack** — full dash to the bot (tracks chest). Strike on contact, then rebound = 10% of **that** commit distance, up + away.

Still in: debris pile / solidify / raise, per-type knockback, bot walk/hop on the pile, Scout / Popper / Warden only, portrait 9:16, score + height, one mid-run level-up, game over + restart, Pages-safe single-thread Web export.

## Beat 3 → beat 4 (short)

Actors shrink ~15% more. Swipe dash is half as far and 1.3× faster. Jumps/falls snap harder. Tap is a commit dash into the bot with a proportional rebound. Night4 on-model dash replaces the off-model night3 run. Juice keeps the beat-3 punch and adds camera + bloom.

## Night-4 expected paths

```
art/night4/slices/volt/dash/dash_01.png … dash_06.png
art/night4/slices/volt/run/run_01.png … run_06.png   (optional)
```

Night3 idle / attack / knockback and bot loops stay at `art/night3/` (see `art/night3/README.md`).
