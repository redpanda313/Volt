# Volt jam — night4 anim pack

On-model **run/dash** for Volt. Locked to the idle kit: blue hex chest, brown pants, blue greaves, goggles, wrench-staff.

Night3 `dash/` is **off-model** (vest / olive pants) and must not play for run or dash.

## Volt travel (in repo)

- `slices/volt/dash/dash_01..06.png` — on-model run **and** dash (same 6-frame loop)
- `slices/volt/run/run_01..06.png` — optional dedicated run. If present, `Art.volt_travel_frames()` prefers this over `dash/`

Godot loads night4 travel via `Art.volt_travel_frames()` onto `World/Volt/Visual/Run` and `Visual/Dash` (ground swipe). Beat 5 tap-attack uses night5 `attack_dash/` on `Visual/AttackDash`. Jump-dash uses night5 `screw_attack/` on `Visual/JumpDash`.

If this folder is empty, travel falls back to night-1 `volt_dodge.png` — **not** night3 dash.

## Idle / attack / knockback stay night3 (canonical)

Do **not** replace these with night4 copies unless night3 is missing:

- idle → `art/night3/slices/volt/idle/idle_01..06.png`
- attack → `art/night3/slices/volt/attack/attack_01..06.png`
- hurt / knockback → `art/night3/slices/volt/knockback/knockback_01..06.png`

Night4 idle/attack/knockback folders are unused while those night3 files exist.

Also accepted in each Volt folder: `volt_dash_01.png`, `dash1.png`, `run_01.png`.

## Sheets

Greenscreen masters in `sheets/` (`.gdignore`’d so they stay out of the HTML5 pack).

Godot 2D. Portrait 9:16. Volt + Scout / Popper / Warden only.
