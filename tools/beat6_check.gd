extends SceneTree

## Headless beat-6 wiring check. Run:
##   godot --headless --path . -s tools/beat6_check.gd

func _init() -> void:
	var art: Node = load("res://scripts/art.gd").new()
	var failed := 0
	failed += _expect(is_equal_approx(art.ACTOR_SCALE, 0.516375), "ACTOR_SCALE 0.516375 locked")
	failed += _expect(art.has_night5_spin(), "has_night5_spin")
	failed += _expect(art.has_night5_attack_dash(), "has_night5_attack_dash")
	failed += _expect(art.has_night6_junk(), "has_night6_junk")
	failed += _expect(art.has_night6_micro(), "has_night6_micro")
	failed += _expect(art.has_night6_fg(), "has_night6_fg")
	failed += _expect(art.night6_kind_junk("scout").size() == 16, "scout junk 16")
	failed += _expect(art.night6_kind_junk("popper").size() == 16, "popper junk 16")
	failed += _expect(art.night6_kind_junk("warden").size() == 16, "warden junk 16")
	failed += _expect(art.night6_micro_frames().size() == 48, "micro 48")
	failed += _expect(art.night6_fg_frames().size() == 17, "fg 17")
	failed += _expect(art.debris_chunks("scout").size() >= 16, "debris_chunks includes night6")
	failed += _expect(art.volt_spin_frames().size() == 8, "screw frames 8")
	failed += _expect(art.health_pack_frames().size() == 3, "health frames 3")
	failed += _expect(art.upgrade_icon(4) != null, "upgrade icon 4 (EXTRA JUMP)")
	failed += _expect(_const_is("res://scripts/volt.gd", "ATTACK_DASH_MULT", "1.75"), "attack dash 1.75x")
	failed += _expect(_const_is("res://scripts/volt.gd", "REBOUND_FRAC", "0.20"), "rebound 0.20")
	failed += _expect(_const_is("res://scripts/fx.gd", "SHAKE_PX", "13.0"), "shake 13px")
	failed += _expect(_const_is("res://scripts/main.gd", "SPAWN_FIRST", "1.40"), "spawn first 1.40")
	failed += _expect(_const_is("res://scripts/main.gd", "SPAWN_START", "2.55"), "spawn start 2.55")
	failed += _expect(_const_is("res://scripts/main.gd", "SPAWN_DECAY", "0.965"), "spawn decay 0.965")
	failed += _expect(_const_is("res://scripts/main.gd", "SOLO_UNTIL", "8"), "solo until 8")
	failed += _expect(_text_has("res://scripts/volt.gd", "func refresh_jump"), "refresh_jump")
	failed += _expect(_text_has("res://scripts/volt.gd", "var extra_jumps"), "extra_jumps")
	failed += _expect(_text_has("res://scripts/main.gd", "EXTRA JUMP"), "EXTRA JUMP pick")
	failed += _expect(_text_has("res://scripts/main.gd", "grant_extra_jump"), "grant_extra_jump wired")
	failed += _expect(_text_has("res://scripts/pile.gd", "night6_micro_frames"), "pile micro fill")
	failed += _expect(_text_has("res://scripts/foreground.gd", "night6_fg_frames"), "fg layer")
	art.free()
	if failed > 0:
		push_error("beat6_check failed: %d" % failed)
		quit(1)
	else:
		print("beat6_check ok")
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
