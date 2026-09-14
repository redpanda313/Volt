extends Node

## Scene-hosted bury / one-way check so Autoload Art is available.
##   godot --headless --path . res://tools/beat7_runtime.tscn

func _ready() -> void:
	var failed := 0
	failed += _bury()
	failed += _one_way()
	failed += await _one_way_physics()
	if failed > 0:
		push_error("beat7_runtime failed: %d" % failed)
		get_tree().quit(1)
	else:
		print("beat7_runtime ok")
		get_tree().quit(0)


func _bury() -> int:
	var pile: RobotPile = RobotPile.new()
	add_child(pile)
	var dummy := CharacterBody2D.new()
	dummy.name = "Volt"
	dummy.add_to_group("volt")
	dummy.global_position = Vector2(240.0, 1000.0)
	add_child(dummy)
	var before := dummy.global_position.y
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.7, 0.75, 0.85, 1.0))
	var tex := ImageTexture.create_from_image(img)
	for i in 6:
		var piece: DebrisPiece = DebrisPiece.spawn(pile, tex, Vector2(240.0 + float(i - 2) * 18.0, 960.0), 40.0)
		pile.register_piece(piece)
		piece.solidify()
	var after := dummy.global_position.y
	var lid := pile.seal_surface_y(240.0, before, before - 58.5, 14.0)
	var failed := 0
	failed += _expect(lid < INF, "lid detected over dummy")
	failed += _expect(after < before - 8.0, "harden-world unbury lifted dummy")
	failed += _expect(after <= lid + 1.0, "dummy feet at lid surface")
	print("  bury before=%.1f after=%.1f lid=%.1f" % [before, after, lid])
	return failed


func _one_way() -> int:
	var frames := Art.night7_platform_frames()
	var tex: Texture2D = frames[0] if not frames.is_empty() else Art.placeholder_platform_frames()[0]
	var pad := SkyPlatform.spawn(self, tex, Vector2(360.0, 700.0), "01_catwalk")
	var ok := _expect(pad.is_one_way() and pad.kind_id == "01_catwalk", "night7 pad is one-way")
	pad.queue_free()
	return ok


func _one_way_physics() -> int:
	var frames := Art.night7_platform_frames()
	var tex: Texture2D = frames[5] if frames.size() >= 6 else Art.placeholder_platform_frames()[0]
	var pad := SkyPlatform.spawn(self, tex, Vector2(160.0, 720.0), "06_step_pad")
	var volt_scene: PackedScene = load("res://scenes/volt.tscn")
	var volt: Volt = volt_scene.instantiate()
	add_child(volt)
	volt.global_position = Vector2(160.0, 820.0)
	volt.velocity = Vector2.ZERO
	await get_tree().physics_frame
	volt.velocity = Vector2(0.0, -1400.0)
	var min_y := volt.global_position.y
	var passed := false
	for _i in 36:
		await get_tree().physics_frame
		min_y = minf(min_y, volt.global_position.y)
		if volt.global_position.y < pad.stand_y - 8.0:
			passed = true
	var failed := 0
	failed += _expect(passed, "volt passed through pad from below")
	volt.velocity = Vector2(0.0, 0.0)
	volt.global_position = Vector2(160.0, pad.stand_y - 80.0)
	volt.velocity = Vector2(0.0, 400.0)
	var landed := false
	for _j in 40:
		await get_tree().physics_frame
		if volt.is_on_floor() and absf(volt.global_position.y - pad.stand_y) < 20.0:
			landed = true
			break
	failed += _expect(landed, "volt stands on pad from above")
	print("  one-way min_y=%.1f stand=%.1f volt_y=%.1f" % [min_y, pad.stand_y, volt.global_position.y])
	var bot_scene: PackedScene = load("res://scenes/enemy.tscn")
	var bot: Enemy = bot_scene.instantiate()
	add_child(bot)
	bot.setup(Enemy.Kind.SCOUT, Vector2(160.0, 820.0), 160.0, false, 0)
	bot.velocity = Vector2(0.0, -1400.0)
	var bot_passed := false
	for _k in 36:
		await get_tree().physics_frame
		if bot.global_position.y < pad.stand_y - 8.0:
			bot_passed = true
	failed += _expect(bot_passed, "bot passed through pad from below")
	bot.velocity = Vector2.ZERO
	bot.global_position = Vector2(160.0, pad.stand_y - 80.0)
	bot.velocity = Vector2(0.0, 400.0)
	var bot_landed := false
	for _m in 40:
		await get_tree().physics_frame
		if bot.is_on_floor() and absf(bot.global_position.y - pad.stand_y) < 24.0:
			bot_landed = true
			break
	failed += _expect(bot_landed, "bot stands on pad from above")
	return failed


func _expect(ok: bool, label: String) -> int:
	if ok:
		print("  pass  ", label)
		return 0
	push_error("  FAIL  " + label)
	return 1
