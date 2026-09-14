extends SceneTree

## Headless beat-5 wiring check. Run:
##   godot --headless --path . -s tools/beat5_check.gd

func _init() -> void:
	var art: Node = load("res://scripts/art.gd").new()
	var failed := 0
	failed += _expect(is_equal_approx(art.ACTOR_SCALE, 0.516375), "ACTOR_SCALE 0.516375")
	failed += _expect(art.has_night5_spin(), "has_night5_spin")
	failed += _expect(art.has_night5_attack_dash(), "has_night5_attack_dash")
	failed += _expect(art.volt_spin_frames().size() == 8, "screw frames 8")
	failed += _expect(art.volt_attack_dash_frames().size() == 6, "attack_dash frames 6")
	var spin0: Texture2D = art.volt_jump_dash_frames()[0]
	var dash0: Texture2D = art.volt_attack_dash_frames()[0]
	failed += _expect(spin0 != dash0, "spin != attack-dash")
	failed += _expect(art.bot_attack_frames("scout").size() == 4, "scout atk 4")
	failed += _expect(art.bot_attack_frames("popper").size() == 4, "popper atk 4")
	failed += _expect(art.bot_attack_frames("warden").size() == 4, "warden atk 4")
	failed += _expect(art.health_pack_frames().size() == 3, "health frames 3")
	failed += _expect(art.upgrade_icon(1) != null and art.upgrade_icon(7) != null, "upgrade icons 1..7")
	failed += _expect(_const_is("res://scripts/volt.gd", "ATTACK_DASH_MULT", "1.75"), "attack dash 1.75x")
	failed += _expect(_const_is("res://scripts/volt.gd", "REBOUND_FRAC", "0.20"), "rebound 0.20")
	failed += _expect(_const_is("res://scripts/fx.gd", "SHAKE_PX", "13.0"), "shake 13px")
	art.free()
	if failed > 0:
		push_error("beat5_check failed: %d" % failed)
		quit(1)
	else:
		print("beat5_check ok")
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
