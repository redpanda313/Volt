# Playtest — Beat 5 (night5 screw + packs + paths)

## Where to play

| Path | How |
| --- | --- |
| **GitHub Pages** | https://redpanda313.github.io/Volt/ — live after `main` runs **Actions → Deploy HTML5 to GitHub Pages** |
| **Godot editor** | Import the repo folder (the one with `project.godot`) in **Godot 4.7**. Open `scenes/main.tscn`. Press **F5**. |

Pages does **not** update from this PR branch. After merge, redeploy is the `Deploy HTML5 to GitHub Pages` workflow on `main` (push or **Run workflow**).

Local HTML5: `GODOT=godot ./tools/export_web.sh` then `python3 -m http.server 8080 --directory export/web`.

## Controls (no joystick, no ATTACK button)

- Tap / click **on an enemy** → Volt **dashes all the way** to that bot (night5 `attack_dash` frames). Attack on contact. Rebound is **20% of that dash distance** (2× beat 4), up and away. Tap another (or the same Warden) to chain.
- Swipe **any direction** on the ground → short travel dash (night4 run/dash).
- Swipe **up or in the air** → **jump-dash screw spin** (night5 `screw_attack` / `JumpDash`). A separate anim from attack-dash.
- Keyboard: `A`/`D`/`W`/`S` or arrows dash, `Space` strike nearest, `R` restart after death.

Empty taps do nothing. Do not look for a virtual stick or an ATTACK button.

## Checklist vs Pete’s beat-5 notes

1. **Scale** — another ~25% shrink on top of beat 4: `Art.ACTOR_SCALE = 0.516375` (0.6885 × 0.75). Volt + Scout / Popper / Warden, colliders included.
2. **Both sides** — bots spawn from the **left** (`x≈58`) and the **right** (`x≈662`), then walk in and hunt.
3. **Attack dash** — tap-attack speed ×**1.75** (`DASH_SPEED * ATTACK_DASH_MULT`, 1865.5 px/s). Rebound **2×** (`REBOUND_FRAC` 0.10 → 0.20). Still: dash to chest, strike on contact, rebound = fraction of **that** commit, up + away. Swipe dash timing unchanged.
4. **Jump-dash screw** — `art/night5/slices/volt/screw_attack/screw_01..08.png` on `Visual/JumpDash` (`spin`). `Art.has_night5_spin()` / `Art.volt_spin_frames()` / `Art.volt_jump_dash_frames()`. If those files are missing, JumpDash falls back to travel textures and a code spin — still **not** the AttackDash clip.
5. **Bot attacks** — night5 `scout_atk` / `popper_atk` / `warden_atk` play as `attack`. Scout lunge, Popper fuse, Warden slam, and Scout contact all fire the clip. Walk/hop stay night3.
6. **Shake** — `Juice.SHAKE_PX` 52 → **13** (×0.25). `add_trauma` **replaces** (ignores a weaker shake while one is live). `kick` replaces, never `+=`. No stacked pile-up.
7. **Distinct Volt travel** — tap-attack = `AttackDash` + night5 `attack_dash_01..06`. Jump-dash = `JumpDash` + screw. Ground swipe = night4 travel on Run/Dash. Three states.
8. **Bot AI** — after a short approach, bots **chase the player** and **roam** nearby. Scouts lunge. Poppers hop in, then fuse when close (or after ~3.4s). Wardens stomp toward you, then slam.
9. **Health packs** — `art/night5/pickups/health_01..03.png`. **Rule:** every **3rd kill** drops a pack at the corpse; **every Warden** also drops. Only **one** pack on screen (skip if one is live). Sits on the pile, lasts **10s**, heals **1** (no overheal). Piles do not drop packs. **Medbay** → heal 2. **PACK PULL** → every 2nd kill + magnet.
10. **Level-up paths** — **5 kills:** ATK UP / HP UP / DASH RANGE. **11 kills:** a branch ability (SHIELD BREAK, SCREW SPIN, COMBO TIME, MEDBAY, PACK PULL). Icons come from `icons/upgrades_sheet_labeled.png` cells via `Art.upgrade_icon` (the loose `upgrade_*.png` slices are empty frames). Picks change combat (arc, +1 heart, longer dash, 2-damage, farther jump-dash, combo window, pack heal/pull).

Still in: debris pile / solidify / raise, per-type knockback, bot walk/hop on the pile, Scout / Popper / Warden only, portrait 9:16, score + height, game over + restart, Pages-safe single-thread Web export.

## Beat 4 → beat 5 (short)

Actors shrink ~25% more. Bots enter from both edges and hunt. Tap-attack is 75% faster with a double rebound. Jump-dash is a screw spin; tap-attack is a different clip. Shake is quieter and never stacks. Packs drop on a published rule. Two-step level-up uses Sable’s icons.

## Night-5 expected paths

```
art/night5/slices/volt/screw_attack/screw_01.png … screw_08.png
art/night5/slices/volt/attack_dash/attack_dash_01.png … attack_dash_06.png
art/night5/slices/bots/scout_attack/scout_atk_01.png … _04.png
art/night5/slices/bots/popper_attack/popper_atk_01.png … _04.png
art/night5/slices/bots/warden_attack/warden_atk_01.png … _04.png
art/night5/pickups/health_01.png … health_03.png
art/night5/icons/upgrade_01.png … upgrade_07.png
```

See `art/night5/README.md` and `Art` in `scripts/art.gd`. Night3 idle / swing / knockback and bot walk/hop stay at `art/night3/`. Night4 travel stays the ground swipe loop.
