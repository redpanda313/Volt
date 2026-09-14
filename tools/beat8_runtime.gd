extends Node

## Scene-hosted beat-8 checks (camera, walker, jump-climb, pads, anti-bury).
##   godot --headless --path . res://tools/beat8_runtime.tscn

func _ready() -> void:
	var failed := 0
	failed += _walker_speeds()
	failed += _bury()
	failed += await _camera_and_endless()
	failed += await _walk_surf_jump()
	failed += _sparse_pads()
	if failed > 0:
		push_error("beat8_runtime failed: %d" % failed)
		get_tree().quit(1)
	else:
		print("beat8_runtime ok")
		get_tree().quit(0)


func _walker_speeds() -> int:
	var scene: PackedScene = load("res://scenes/enemy.tscn")
	var scout: Enemy = scene.instantiate()
	add_child(scout)
	scout.setup(Enemy.Kind.SCOUT, Vector2(200.0, 1000.0), 400.0, false, 0)
	var pop: Enemy = scene.instantiate()
	add_child(pop)
	pop.setup(Enemy.Kind.POPPER, Vector2(240.0, 1000.0), 400.0, false, 0)
	var ward: Enemy = scene.instantiate()
	add_child(ward)
	ward.setup(Enemy.Kind.WARDEN, Vector2(280.0, 1000.0), 400.0, false, 0)
	var failed := 0
	failed += _expect(scout.is_walker(), "scout is walker")
	failed += _expect(not pop.is_walker(), "popper is not walker")
	failed += _expect(not ward.is_walker(), "warden is not walker")
	failed += _expect(is_equal_approx(scout.speed, 161.25), "scout walk 161.25")
	failed += _expect(is_equal_approx(pop.speed, 118.0), "popper hop 118")
	failed += _expect(is_equal_approx(ward.speed, 54.0), "warden stomp 54")
	scout.queue_free()
	pop.queue_free()
	ward.queue_free()
	return failed


func _bury() -> int:
	var pile: RobotPile = RobotPile.new()
	add_child(pile)
	var dummy := CharacterBody2D.new()
	dummy.name = "Volt"
	dummy.add_to_group("volt")
	dummy.global_position = Vector2(240.0, 1000.0)
	add_child(dummy)
	var before := dummy.global_position.y
	var tex := _dot()
	for i in 6:
		var piece: DebrisPiece = DebrisPiece.spawn(pile, tex, Vector2(240.0 + float(i - 2) * 18.0, 960.0), 40.0)
		pile.register_piece(piece)
		piece.solidify()
	var after := dummy.global_position.y
	var lid := pile.seal_surface_y(240.0, before, before - 58.5, 14.0)
	var failed := 0
	failed += _expect(lid < INF, "lid detected over dummy")
	failed += _expect(after < before - 8.0, "anti-bury still lifts")
	failed += _expect(after <= lid + 1.0, "dummy feet at lid surface")
	print("  bury before=%.1f after=%.1f lid=%.1f" % [before, after, lid])
	return failed


func _camera_and_endless() -> int:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Node = packed.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().physics_frame
	var cam := main.get_node("Camera2D") as Camera2D
	var volt: Volt = main.get_node("World/Volt")
	var pile: RobotPile = main.get_node("World/Pile")
	var screen_t := (640.0 + volt.global_position.y - cam.position.y) / 1280.0
	var failed := 0
	failed += _expect(screen_t > 0.58 and screen_t < 0.70, "player ~63% down the view")
	failed += _expect(is_equal_approx(main.get("CAM_PLAYER_OFFSET"), 168.0), "CAM_PLAYER_OFFSET 168")
	var high: float = main.call("camera_focus_y", -5000.0, -4000.0)
	failed += _expect(high < -1800.0, "camera follows past old -1800 cap")
	failed += _expect(high < -4100.0, "camera tracks a high floor")
	print("  camera screen_t=%.3f high_focus=%.1f pile=%.1f cam=%.1f" % [screen_t, high, pile.playable_y(), cam.position.y])
	main.queue_free()
	return failed


func _walk_surf_jump() -> int:
	var world := Node2D.new()
	add_child(world)
	var floor := StaticBody2D.new()
	floor.collision_layer = 0
	floor.collision_mask = 0
	floor.set_collision_layer_value(1, true)
	floor.position = Vector2(360.0, 1040.0)
	var gshape := CollisionShape2D.new()
	var grect := RectangleShape2D.new()
	grect.size = Vector2(2000, 80)
	gshape.shape = grect
	floor.add_child(gshape)
	world.add_child(floor)
	var pile: RobotPile = RobotPile.new()
	world.add_child(pile)
	var tex := _dot()
	for i in 8:
		var piece: DebrisPiece = DebrisPiece.spawn(pile, tex, Vector2(400.0 + float(i) * 16.0, 948.0), 50.0)
		pile.register_piece(piece)
		piece.solidify()
	var bot: Enemy = load("res://scenes/enemy.tscn").instantiate()
	world.add_child(bot)
	bot.setup(Enemy.Kind.SCOUT, Vector2(220.0, 1000.0), 520.0, false, 0)
	for _warm in 8:
		await get_tree().physics_frame
	var prev_y := bot.global_position.y
	var snapped := false
	var jumped := false
	var max_up := 0.0
	for _i in 140:
		await get_tree().physics_frame
		var dy := prev_y - bot.global_position.y
		max_up = maxf(max_up, dy)
		if bot.velocity.y < -180.0:
			jumped = true
		## Teleport onto the mound without a climb jump (walk-surf).
		if dy > 28.0 and bot.velocity.y > -120.0:
			snapped = true
		prev_y = bot.global_position.y
		if jumped and bot.global_position.y < 980.0:
			break
	var failed := 0
	failed += _expect(not snapped, "no walk-surf Y snap onto mound")
	failed += _expect(jumped, "scout jumped to climb mound")
	print("  climb jumped=%s snapped=%s max_up=%.1f y=%.1f x=%.1f" % [jumped, snapped, max_up, bot.global_position.y, bot.global_position.x])
	world.queue_free()
	return failed


func _sparse_pads() -> int:
	var host := Node2D.new()
	add_child(host)
	var ledges := SkyLedges.new()
	host.add_child(ledges)
	var cam := Camera2D.new()
	cam.position = Vector2(360.0, 832.0)
	host.add_child(cam)
	ledges.bind_camera(cam)
	ledges.seed_sky()
	cam.position.y = -2800.0
	ledges.ensure_ahead()
	ledges.ensure_ahead()
	var ys := ledges.live_stand_ys()
	ys.sort()
	var failed := 0
	failed += _expect(ys.size() >= 2, "generated multiple pads")
	var min_gap := 1.0e9
	for i in range(ys.size() - 1):
		min_gap = minf(min_gap, ys[i + 1] - ys[i])
	failed += _expect(min_gap >= ledges.min_vertical_gap() - 0.5, "pads spaced >= 1240")
	var two := 0
	var samples := 0
	var y := 900.0
	while y > -3200.0:
		var n := 0
		for stand in ys:
			if stand >= y - 640.0 and stand <= y + 640.0:
				n += 1
		if n >= 2:
			two += 1
		samples += 1
		y -= 160.0
	failed += _expect(two <= 2, "rarely two pads in a 1280 view")
	print("  pads=%d min_gap=%.1f two_on_screen_samples=%d/%d" % [ys.size(), min_gap, two, samples])
	host.queue_free()
	return failed


func _dot() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.7, 0.75, 0.85, 1.0))
	return ImageTexture.create_from_image(img)


func _expect(ok: bool, label: String) -> int:
	if ok:
		print("  pass  ", label)
		return 0
	push_error("  FAIL  " + label)
	return 1
