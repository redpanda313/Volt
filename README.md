# Volt

Portrait **9:16** side-view climb. You are **Volt**. Tap bots to hit them. Swipe to dodge. Robots pile up and the fight lifts toward space. High score.

**This repo is Godot 4.x 2D only. There is no Unity project, no Narcalid, no Steam target.**

Tonight’s loop: Volt + Scout / Popper / Warden (Sable night-1 sprites), score + height meter, one mid-run level-up, game over + restart. Primary playable path is **HTML5 / GitHub Pages** so anyone can open a URL without installing Godot.

## Play (no Godot install)

After GitHub Pages is enabled (see below), the jam build is:

**https://redpanda313.github.io/Volt/**

Controls work in the browser: tap/click an enemy to swing, swipe/drag to dodge. On a keyboard: `Space` attack nearest, `A`/`D` or arrows dodge, `R` restart after death.

## Open in the Godot Editor

1. Install **Godot 4.7** (standard / non-.NET) from [godotengine.org](https://godotengine.org/download).
2. **Import** this repository folder (the directory that contains `project.godot`).
3. Open the main scene `scenes/main.tscn`.
4. Press **F5** (or Play). The editor should launch a 9:16 window.

Node names are sprite-swap ready:

| Node | Night-1 PNG |
| --- | --- |
| `World/Volt/Visual/Idle` | `art/night1/slices/volt_idle.png` |
| `World/Volt/Visual/Attack` | `art/night1/slices/volt_attack.png` |
| `World/Volt/Visual/Dodge` | `art/night1/slices/volt_dodge.png` |
| Enemy `Visual` | `scout_idle.png` / `popper_idle.png` / `warden_idle.png` |

Drop replacement PNGs on those paths to reskin. Sheets and the chroma-key notes live in `art/night1/`.

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

One-time repo settings (Pete):

1. **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. Merge this branch (or run **Actions → Deploy HTML5 to GitHub Pages → Run workflow**).
3. Wait for the workflow. The site is `https://<user>.github.io/Volt/` (this repo: `https://redpanda313.github.io/Volt/`).

Local alternative: export to `export/web/`, then upload that folder to any static host (itch.io, Netlify, Cloudflare Pages). Keep threads off unless the host sends `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.

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
