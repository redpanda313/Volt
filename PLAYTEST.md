# Playtest — Pete beat (night-2 art)

## Where to play

| Path | How |
| --- | --- |
| **GitHub Pages** | https://redpanda313.github.io/Volt/ — live after `main` runs **Actions → Deploy HTML5 to GitHub Pages** |
| **Godot editor** | Import the repo folder (the one with `project.godot`) in **Godot 4.7**. Open `scenes/main.tscn`. Press **F5**. |

Pages does **not** update from this PR branch. After merge, redeploy is the `Deploy HTML5 to GitHub Pages` workflow on `main` (push or **Run workflow**).

Local HTML5: `GODOT=godot ./tools/export_web.sh` then `python3 -m http.server 8080 --directory export/web`.

## Controls (no joystick, no ATTACK button)

- Tap / click **on an enemy** → launch Volt. Attack on contact. Small bounce up+back. Tap another (or the same Warden) to chain.
- Swipe **left / right** → physics dodge / move. On the ground this also knocks loose top-layer debris.
- Swipe **up** → physics jump.
- Keyboard: `A`/`D` or arrows, `W`/up jump, `Space` launch nearest, `R` restart after death.

Empty taps do nothing. Do not look for a virtual stick or an ATTACK button.

## Checklist vs Pete’s notes

1. **Scale** — Volt, Scout, Popper, Warden read ~10% smaller than the first playable.
2. **Idle** — standing Volt loops night-2 `volt_idle_01`…`_04` (01→02→03→04→01).
3. **Controls** — swipe L/R moves with slide/friction; swipe up jumps; tap-enemy launches and chains.
4. **Debris pile** — a kill pops night-2 chunks. They settle. Ground-dash knocks the **top incomplete** layer. When that layer fills it welds (tint + frozen) and the floor / spawn lane steps up.
5. **HUD** — night-2 top bar + height rail, 8-digit score, climb level, altitude band (GROUND→SPACE), HP pips. `ChromeTop` / `ChromeMeter` are the art-swap hooks.

Still in: Scout / Popper / Warden only, portrait 9:16, score + height, one mid-run level-up, game over + restart.

## First-playable → this beat (short)

Instant tap-to-hit and “dodge then snap home” are gone. Combat is launch-on-contact. The old faded stack sprites are gone; bots break into real pieces and climb by welding layers. Night-2 idle + HUD chrome are wired.
