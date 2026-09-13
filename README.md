# Volt

Portrait **9:16** side-view climb. You are **Volt**. Swipe to move and jump. Tap a bot to launch. Robots break apart, pile up, and the fight lifts toward space. High score.

**This repo is Godot 4.x 2D only. There is no Unity project, no Narcalid, no Steam target.**

Tonight’s loop: Volt + Scout / Popper / Warden (Sable night-1 combat sprites + night-2 idle / debris / HUD), score + height meter, one mid-run level-up, game over + restart. Primary playable path is **HTML5 / GitHub Pages** so anyone can open a URL without installing Godot.

## Play (no Godot install)

After GitHub Pages is enabled (see below), the jam build is:

**https://redpanda313.github.io/Volt/**

Controls work in the browser:

- **Tap / click an enemy** — Volt launches at that bot, attacks on contact, then bounces up and back. Tap again to chain.
- **Swipe left / right** — physics dodge / move. A ground dash knocks loose pile pieces.
- **Swipe up** — physics jump.

On a keyboard: `A`/`D` or arrows move, `W` or up-arrow jump, `Space` launch at the nearest bot, `R` restart after death. No joystick. No on-screen ATTACK button.

## Open in the Godot Editor

1. Install **Godot 4.7** (standard / non-.NET) from [godotengine.org](https://godotengine.org/download).
2. **Import** this repository folder (the directory that contains `project.godot`).
3. Open the main scene `scenes/main.tscn`.
4. Press **F5** (or Play). The editor should launch a 9:16 window.

Node names are sprite-swap ready:

| Node | Art |
| --- | --- |
| `World/Volt/Visual/Idle` | `art/night2/slices/volt_idle/volt_idle_01.png` … `_04.png` (loop 01→02→03→04→01) |
| `World/Volt/Visual/Attack` | `art/night1/slices/volt_attack.png` |
| `World/Volt/Visual/Dodge` | `art/night1/slices/volt_dodge.png` |
| Enemy `Visual` | `scout_idle.png` / `popper_idle.png` / `warden_idle.png` |
| Debris | `art/night2/slices/debris/{scout,popper,warden}/*_chunk_XX.png` |
| HUD `ChromeTop` / `ChromeMeter` | `art/night2/hud/hud_top.png`, `hud_meter.png` (from the night-2 portrait / sheet) |

Drop replacement PNGs on those paths to reskin. Sheets and chroma-key notes live in `art/night1/` and `art/night2/`.

## Export HTML5 (local)

1. In Godot: **Editor → Manage Export Templates…** and install **4.7.stable** templates (or unzip `Godot_v4.7-stable_export_templates.tpz` into `~/.local/share/godot/export_templates/4.7.stable/`).
2. **Project → Export…** → preset **Web**.
3. Confirm **Thread Support is off** (required for GitHub Pages; no COOP/COEP headers).
4. Export to `export/web/index.html`.

CLI (same preset):

```bash
chmod +x tools/export_web.sh
GODOT=godot ./tools/export_web.sh
```

Serve the folder over HTTP (do not open `index.html` as a `file://` URL):

```bash
python3 -m http.server 8080 --directory export/web
```

Then open `http://localhost:8080/`.

## Publish a playable URL (GitHub Pages)

The workflow `.github/workflows/deploy-pages.yml` exports Godot **Web** (single-thread) and deploys to Pages on every push to `main`.

**After this branch merges, Pages redeploy is via workflow `Deploy HTML5 to GitHub Pages` on `main`.** You can also run it by hand: **Actions → Deploy HTML5 to GitHub Pages → Run workflow**.

One-time repo settings (Pete):

1. **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. Merge to `main` (or run the workflow above).
3. Wait for the workflow. The site is `https://<user>.github.io/Volt/` (this repo: `https://redpanda313.github.io/Volt/`).

Local alternative: export to `export/web/`, then upload that folder to any static host (itch.io, Netlify, Cloudflare Pages). Keep threads off unless the host sends `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.

## Playtest (this beat)

See **[PLAYTEST.md](PLAYTEST.md)** for the click-through against Pete’s notes, the Pages URL, and the Godot open path.

## Changelog vs first playable

- Volt and Scout / Popper / Warden are ~10% smaller.
- Volt idle uses the night-2 4-frame loop (`01→02→03→04→01`). Night-1 `volt_idle` is the fallback if those frames are missing.
- Controls: swipe L/R is a physics dodge/move (Volt stays where he slides). Swipe up is a physics jump. Tap a bot launches Volt; the hit lands on contact with a small bounce up+back. Repeat taps chain launches.
- Kills shatter that bot into night-2 debris chunks that pile on the ground. The top incomplete layer is knockable with a ground dash. A full layer welds (no longer moves) and raises the playable floor.
- HUD uses night-2 chrome (`hud_top`, `hud_meter`) with live 8-digit score, climb level, altitude band, and HP pips. Named `ChromeTop` / `ChromeMeter` / `ScoreLabel` / `LevelLabel` hooks stay ready for a later art swap. No joystick or ATTACK button.
- Score and height still drive the run. Scout / Popper / Warden only. Portrait 9:16. HTML5 Pages path unchanged (single-thread Web export).

## iOS / Android (later)

Export templates are **not** required in CI for tonight. When you are ready:

### Android

1. Install Android Studio + SDK / NDK / JDK as in the [Godot Android export docs](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html).
2. **Editor → Manage Export Templates** (same 4.7.stable pack).
3. **Project → Export → Add → Android**.
4. Create a debug keystore (editor can generate one) for jam builds; use a release keystore for stores.
5. Export **APK** (sideload) or **AAB** (Play).

### iOS

1. Export from **macOS** with Xcode installed ([Godot iOS docs](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html)).
2. **Project → Export → Add → iOS**.
3. Set bundle id + signing team. Godot writes an Xcode project.
4. Open that project in Xcode, pick a device/simulator, archive for TestFlight later.

Portrait orientation is already set (`window/handheld/orientation` = portrait). The same tap/swipe loop is the mobile control scheme.

## Out of scope (this cut)

Full 8-bot roster, roguelike unlocks, Steam, Narcalid, Unity.
