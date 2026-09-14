extends SceneTree

## Headless beat-7 wiring + anti-bury check. Run:
##   godot --headless --path . -s tools/beat7_check.gd

func _init() -> void:
	var art: Node = load("res://scripts/art.gd").new()
	var failed := 0
	failed += _expect(is_equal_approx(art.ACTOR_SCALE, 0.516375), "ACTOR_SCALE 0.516375 locked")
	failed += _expect(art.has_night5_spin(), "has_night5_spin")
	failed += _expect(art.has_night6_junk(), "has_night6_junk")
	failed += _expect(art.has_night6_micro(), "has_night6_micro")
	failed += _expect(art.has_night6_fg(), "has_night6_fg")
	failed += _expect(art.has_night7_platforms(), "has_night7_platforms")
	failed += _expect(art.night7_platform_frames().size() == 6, "night7 platform frames 6")
	failed += _expect(art.night7_platform_names().has("01_catwalk"), "01_catwalk named")
	failed += _expect(art.night7_platform_names().has("06_step_pad"), "06_step_pad named")
	failed += _expect(not art.placeholder_platform_frames().is_empty(), "placeholder slab exists")
	failed += _expect(_const_is("res://scripts/main.gd", "PACK_EVERY", "2"), "pack every 2")
	failed += _expect(_const_is("res://scripts/main.gd", "PACK_EVERY_MAGNET", "1"), "pack magnet every 1")
	failed += _expect(_const_is("res://scripts/main.gd", "PLATFORM_SPAWN_AFTER", "3"), "platform spawn after 3")
	failed += _expect(_const_is("res://scripts/main.gd", "SPAWN_FIRST", "1.40"), "spawn first 1.40")
	failed += _expect(_const_is("res://scripts/main.gd", "SOLO_UNTIL", "8"), "solo until 8")
	failed += _expect(_const_is("res://scripts/volt.gd", "ATTACK_DASH_MULT", "1.75"), "attack dash 1.75x")
	failed += _expect(_text_has("res://scripts/pile.gd", "func unbury_actors"), "unbury_actors")
	failed += _expect(_text_has("res://scripts/pile.gd", "func lift_out_of_junk"), "lift_out_of_junk")
	failed += _expect(_text_has("res://scripts/pile.gd", "func form_lid_at"), "form_lid_at")
	failed += _expect(_text_has("res://scripts/debris_piece.gd", "func _harden_world"), "harden after unbury")
	failed += _expect(_text_has("res://scripts/sky_platform.gd", "one_way_collision = true"), "one-way platforms")
	failed += _expect(_text_has("res://scripts/main.gd", "ledges.pick_spawn"), "bots spawn on pads")
	failed += _expect(_text_has("res://scripts/main.gd", "EXTRA JUMP"), "EXTRA JUMP pick")
	failed += _expect(_text_has("res://scripts/ledges.gd", "randf_range"), "random pad XY")
	failed += _expect(_text_has("res://scenes/main.tscn", "scripts/ledges.gd"), "Ledges in main.tscn")
	failed += _expect(_text_has("res://scripts/pile.gd", "func register_piece"), "register_piece")
	art.free()
	if failed > 0:
		push_error("beat7_check failed: %d" % failed)
		quit(1)
	else:
		print("beat7_check ok")
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
