extends SceneTree

## Headless beat-8 wiring check. Run:
##   godot --headless --path . -s tools/beat8_check.gd

func _init() -> void:
	var art: Node = load("res://scripts/art.gd").new()
	var failed := 0
	failed += _expect(is_equal_approx(art.ACTOR_SCALE, 0.516375), "ACTOR_SCALE 0.516375 locked")
	failed += _expect(art.has_night5_spin(), "has_night5_spin")
	failed += _expect(art.has_night6_junk(), "has_night6_junk")
	failed += _expect(art.has_night7_platforms(), "has_night7_platforms")
	failed += _expect(art.night7_platform_frames().size() == 6, "night7 platform frames 6")
	failed += _expect(_const_is("res://scripts/main.gd", "CAM_PLAYER_OFFSET", "168.0"), "camera offset 168")
	failed += _expect(_const_is("res://scripts/main.gd", "PACK_EVERY", "2"), "pack every 2")
	failed += _expect(_const_is("res://scripts/main.gd", "SPAWN_FIRST", "1.40"), "spawn first 1.40")
	failed += _expect(_const_is("res://scripts/main.gd", "SOLO_UNTIL", "8"), "solo until 8")
	failed += _expect(_const_is("res://scripts/enemy.gd", "WALKER_SPEED_SCALE", "0.75"), "walker scale 0.75")
	failed += _expect(_const_is("res://scripts/enemy.gd", "SCOUT_WALK", "215.0"), "scout walk base 215")
	failed += _expect(_const_is("res://scripts/enemy.gd", "CLIMB_JUMP", "-680.0"), "climb jump")
	failed += _expect(_const_is("res://scripts/ledges.gd", "MIN_VERT", "1240.0"), "pad min vert 1240")
	failed += _expect(_text_has("res://scripts/enemy.gd", "func is_walker"), "is_walker")
	failed += _expect(_text_has("res://scripts/enemy.gd", "func _try_climb_jump"), "try_climb_jump")
	failed += _expect(not _text_has("res://scripts/enemy.gd", "_stick_to_pile()"), "walk-surf snap not called")
	failed += _expect(not _text_has("res://scripts/enemy.gd", "func _stick_to_pile"), "walk-surf helper removed")
	failed += _expect(_text_has("res://scripts/pile.gd", "func unbury_actors"), "unbury_actors stays")
	failed += _expect(_text_has("res://scripts/pile.gd", "func lift_out_of_junk"), "lift_out_of_junk stays")
	failed += _expect(_text_has("res://scripts/main.gd", "func camera_focus_y"), "camera_focus_y")
	failed += _expect(not _text_has("res://scripts/main.gd", "-1800.0"), "no -1800 camera cap")
	failed += _expect(_text_has("res://scripts/ledges.gd", "func ensure_ahead"), "endless pad generate")
	failed += _expect(_text_has("res://scripts/sky.gd", "func follow_view"), "sky follows climb")
	failed += _expect(_text_has("res://scripts/main.gd", "EXTRA JUMP"), "EXTRA JUMP pick")
	failed += _expect(_text_has("res://scripts/volt.gd", "func refresh_jump"), "jump refresh")
	failed += _expect(_text_has("res://scripts/sky_platform.gd", "one_way_collision = true"), "one-way platforms")
	art.free()
	if failed > 0:
		push_error("beat8_check failed: %d" % failed)
		quit(1)
	else:
		print("beat8_check ok")
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
