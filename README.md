# Volt

Portrait **9:16** side-view climb. You are **Volt**. Swipe any direction to dash. Tap a bot to launch. Robots break apart, pile up, and the fight lifts toward space. High score.

**This repo is Godot 4.x 2D only. There is no Unity project, no Narcalid, no Steam target.**

Tonight’s loop: Volt + Scout / Popper / Warden (Sable night-3 loops when present, night-2 idle / debris / HUD, night-1 fallbacks), score + height meter, one mid-run level-up, game over + restart. Primary playable path is **HTML5 / GitHub Pages** so anyone can open a URL without installing Godot.

## Play (no Godot install)

After GitHub Pages is enabled (see below), the jam build is:

**https://redpanda313.github.io/Volt/**

Controls work in the browser:

- **Tap / click an enemy** — Volt launches at that bot, attacks on contact, then bounces up and back. Tap again to chain.
- **Swipe any direction** — dash that way (longer than beat 2). A ground dash knocks loose pile pieces.

On a keyboard: `A`/`D`/`W`/`S` or arrows dash, `Space` launch at the nearest bot, `R` restart after death. No joystick. No on-screen ATTACK button.

## Open in the Godot Editor

1. Install **Godot 4.7** (standard / non-.NET) from [godotengine.org](https://godotengine.org/download).
2. **Import** this repository folder (the directory that contains `project.godot`).
3. Open the main scene `scenes/main.tscn`.
4. Press **F5** (or Play). The editor should launch a 9:16 window.

Node names are sprite-swap ready:

| Node | Art |
| --- | --- |
| `World/Volt/Visual/Idle` | night3 `art/night3/slices/volt/idle/idle_01`…`_06` (fallback night-2 `volt_idle_01`…`_04`) |
| `World/Volt/Visual/Attack` | night3 `volt/attack/attack_01`…`_06` (fallback night-1 `volt_attack.png`) |
| `World/Volt/Visual/Dash` | night3 `volt/dash/dash_01`…`_06` (fallback night-1 `volt_dodge.png`) |
| `World/Volt/Visual/Hurt` | night3 `volt/knockback/knockback_01`…`_06` (fallback night-1 dodge) |
| Enemy `Visual` | night3 `bots/scout/scout_walk_01`…`_04`, `popper_hop_01`…`_04`, `warden_walk_01`…`_04` |
| Debris | `art/night2/slices/debris/{scout,popper,warden}/*_chunk_XX.png` |
| HUD `ChromeTop` / `ChromeMeter` | `art/night2/hud/hud_top.png`, `hud_meter.png` (from the night-2 portrait / sheet) |

Drop replacement PNGs on those paths to reskin. Expected night-3 layout is in `art/night3/README.md`. Sheets live in `art/night1/`, `art/night2/`, `art/night3/sheets/`.

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

## Changelog vs beat 2

- Actors shrink ~10% again (`Art.ACTOR_SCALE` 0.90 → **0.81**).
- Swipe is an **omni dash** (any direction, longer travel). Swipe-up jump is gone; up-swipe dashes up.
- Scout / Popper / Warden walk on the rising pile as `CharacterBody2D`s: Scout faster, Popper hoppier, Warden heavier/slower.
- Enemy hits apply **per-type knockback** to Volt (Scout jab, Popper blast, Warden shove).
- Night-3 `SpriteFrames` for Volt idle / attack / dash / hurt and bot walk / hop. Missing files fall back to night-2 / night-1 so the loop still runs.
- AAA juice: attack shake + hitstop + VFX rings/bursts, damage screen pulse, punchy procedural SFX.
- Debris pile / solidify / raise playable height is unchanged on purpose.
- HTML5 Pages path unchanged (single-thread Web export).

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
