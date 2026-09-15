extends SceneTree

## Headless beat-9 wiring check. Run:
##   godot --headless --path . -s tools/beat9_check.gd

func _init() -> void:
	var art: Node = load("res://scripts/art.gd").new()
	var failed := 0
	failed += _expect(is_equal_approx(art.ACTOR_SCALE, 0.516375), "ACTOR_SCALE 0.516375 locked")
	failed += _expect(art.has_night5_spin(), "has_night5_spin")
	failed += _expect(art.has_night6_junk(), "has_night6_junk")
	failed += _expect(art.has_night7_platforms(), "has_night7_platforms")
	failed += _expect(not art.placeholder_drone_frames().is_empty(), "placeholder drone")
	failed += _expect(art.placeholder_powerup_tex(0) != null, "placeholder shield orb")
	failed += _expect(art.placeholder_powerup_tex(6) != null, "placeholder score orb")
	failed += _expect(art.drone_frames().size() >= 1, "drone_frames usable")
	failed += _expect(art.powerup_tex(0) != null, "powerup_tex 0")
	failed += _expect(_const_is("res://scripts/art.gd", "NIGHT8_DRONES", "\"res://art/night8/carrier_drone/\""), "night8 drone path")
	failed += _expect(_const_is("res://scripts/art.gd", "NIGHT8_POWERUPS", "\"res://art/night8/powerups/\""), "night8 powerup path")
	failed += _expect(_text_has("res://scripts/art.gd", "carrier_04_drop_crate.png"), "drop crate filename")
	failed += _expect(_text_has("res://scripts/art.gd", "07_score_mult.png"), "score icon filename")
	failed += _expect(_const_is("res://scripts/main.gd", "CAM_PLAYER_OFFSET", "168.0"), "camera offset 168")
	failed += _expect(_const_is("res://scripts/main.gd", "DRONE_FIRST", "5.60"), "drone first 5.60")
	failed += _expect(_const_is("res://scripts/main.gd", "DRONE_EVERY", "8.20"), "drone every 8.20")
	failed += _expect(_const_is("res://scripts/main.gd", "DRONE_MIN", "6.40"), "drone min 6.40")
	failed += _expect(_const_is("res://scripts/main.gd", "PACK_EVERY", "2"), "pack every 2")
	failed += _expect(_const_is("res://scripts/enemy.gd", "WALKER_SPEED_SCALE", "0.75"), "walker scale 0.75")
	failed += _expect(_const_is("res://scripts/enemy.gd", "CLIMB_JUMP", "-680.0"), "climb jump")
	failed += _expect(_const_is("res://scripts/ledges.gd", "MIN_VERT", "1240.0"), "pad min vert 1240")
	failed += _expect(not _text_has("res://scripts/enemy.gd", "func _stick_to_pile"), "walk-surf helper stays gone")
	failed += _expect(_text_has("res://scripts/pile.gd", "func unbury_actors"), "unbury_actors stays")
	failed += _expect(_text_has("res://scripts/main.gd", "func camera_focus_y"), "camera_focus_y")
	failed += _expect(not _text_has("res://scripts/main.gd", "-1800.0"), "no -1800 camera cap")
	failed += _expect(_text_has("res://scripts/main.gd", "func _collect_drone"), "drone collect")
	failed += _expect(_text_has("res://scripts/main.gd", "func _spawn_drone"), "drone spawn")
	failed += _expect(_text_has("res://scripts/volt.gd", "func apply_powerup"), "apply_powerup")
	failed += _expect(_text_has("res://scripts/volt.gd", "func consume_shield"), "consume_shield")
	failed += _expect(_text_has("res://scripts/volt.gd", "func is_stealthed"), "is_stealthed")
	failed += _expect(_text_has("res://scripts/volt.gd", "func strike_power"), "strike_power")
	failed += _expect(_text_has("res://scripts/hud.gd", "func set_effects"), "HUD status cue")
	failed += _expect(_text_has("res://scripts/enemy.gd", "func _pace"), "bot slow pace")
	failed += _expect(_text_has("res://scripts/enemy.gd", "func _stealthed"), "bot stealth")
	failed += _expect(_text_has("res://scripts/powerup.gd", "enum Kind"), "7 powerup kinds")
	failed += _expect(_text_has("res://scripts/powerup.gd", "const COUNT := 7"), "kind count 7")
	failed += _expect(_text_has("res://scripts/powerup.gd", "5.5, 0.0, 5.0, 6.0, 8.0, 5.5, 8.0"), "durations")
	failed += _expect(Powerup.COUNT == 7, "Powerup.COUNT 7")
	failed += _expect(is_equal_approx(Powerup.duration(Powerup.Kind.SHIELD), 5.5), "shield 5.5")
	failed += _expect(is_equal_approx(Powerup.duration(Powerup.Kind.HEALTH), 0.0), "health instant")
	failed += _expect(is_equal_approx(Powerup.duration(Powerup.Kind.STEALTH), 5.0), "stealth 5.0")
	failed += _expect(is_equal_approx(Powerup.duration(Powerup.Kind.OVERCHARGE), 6.0), "overcharge 6.0")
	failed += _expect(is_equal_approx(Powerup.duration(Powerup.Kind.MAGNET), 8.0), "magnet 8.0")
	failed += _expect(is_equal_approx(Powerup.duration(Powerup.Kind.SLOW), 5.5), "slow 5.5")
	failed += _expect(is_equal_approx(Powerup.duration(Powerup.Kind.SCORE), 8.0), "score 8.0")
	failed += _expect(is_equal_approx(Powerup.SLOW_PACE, 0.42), "slow pace 0.42")
	failed += _expect(_text_has("res://PLAYTEST.md", "Beat 9"), "PLAYTEST beat 9")
	failed += _expect(_text_has("res://PLAYTEST.md", "SHIELD"), "PLAYTEST shield")
	failed += _expect(_text_has("res://PLAYTEST.md", "SCORE ×2"), "PLAYTEST score")
	failed += _expect(_text_has("res://art/night8/README.md", "carrier_01_hover.png"), "night8 readme drone")
	failed += _expect(art.has_night8_drones(), "night8 carrier 6 wired")
	failed += _expect(art.has_night8_powerups(), "night8 powerups 7 wired")
	failed += _expect(_png_exists("res://art/night8/carrier_drone/carrier_04_drop_crate.png"), "drop crate png")
	failed += _expect(_png_exists("res://art/night8/powerups/powerups_sheet_labeled.png"), "labeled sheet png")
	failed += _expect(_text_has("res://scripts/art.gd", "NIGHT8_POWERUP_RECTS"), "sheet crop rects")
	art.free()
	if failed > 0:
		push_error("beat9_check failed: %d" % failed)
		quit(1)
	else:
		print("beat9_check ok")
		quit(0)


func _expect(ok: bool, label: String) -> int:
	if ok:
		print("  pass  ", label)
		return 0
	push_error("  FAIL  " + label)
	return 1


func _const_is(path: String, name: String, value: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	return text.contains("const %s := %s" % [name, value])


func _text_has(path: String, needle: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	return f.get_as_text().contains(needle)


func _png_exists(path: String) -> bool:
	return FileAccess.file_exists(path)
