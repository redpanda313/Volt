# Volt jam — night4 anim pack

On-model **run/dash** for Volt. Locked to the idle kit: blue hex chest, brown pants, blue greaves, goggles, wrench-staff.

Night3 `dash/` is **off-model** (vest / olive pants) and must not play for run or dash.

## Volt travel (wire these first)

- `slices/volt/dash/dash_01..06.png` — on-model run **and** dash (same loop until a dedicated run pack lands)
- `slices/volt/run/run_01..06.png` — optional dedicated run. If present, `Art.volt_travel_frames()` prefers this over `dash/`

Godot loads night4 travel via `Art.volt_travel_frames()` / `Art.volt_frames("run"|"dash")` onto `World/Volt/Visual/Run` and `Visual/Dash`.

If this folder is empty, travel falls back to night-1 `volt_dodge.png` — **not** night3 dash.

## Idle / attack / knockback

Night3 remains canonical:

- idle → `art/night3/slices/volt/idle/`
- attack → `art/night3/slices/volt/attack/`
- hurt → `art/night3/slices/volt/knockback/`

Night4 copies of those folders are used only when the night3 file is missing (canonical carries).

Also accepted in each Volt folder: `volt_dash_01.png`, `dash1.png`, `run_01.png`.

## Sheets

Greenscreen masters in `sheets/` (`.gdignore`’d so they stay out of the HTML5 pack).

Godot 2D. Portrait 9:16. Volt + Scout / Popper / Warden only.
