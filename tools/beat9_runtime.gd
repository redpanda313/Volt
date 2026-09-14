extends Node

## Scene-hosted beat-9 checks (drones + all 7 powerups). Beat 8 feel stays.
##   godot --headless --path . res://tools/beat9_runtime.tscn

func _ready() -> void:
	var failed := 0
	failed += _beat8_feel()
	failed += await _drone_ferry()
	failed += await _all_seven()
	if failed > 0:
		push_error("beat9_runtime failed: %d" % failed)
		get_tree().quit(1)
	else:
		print("beat9_runtime ok")
		get_tree().quit(0)


func _beat8_feel() -> int:
	var scene: PackedScene = load("res://scenes/enemy.tscn")
	var scout: Enemy = scene.instantiate()
	add_child(scout)
	scout.setup(Enemy.Kind.SCOUT, Vector2(200.0, 1000.0), 400.0, false, 0)
	var failed := 0
	failed += _expect(is_equal_approx(Art.ACTOR_SCALE, 0.516375), "size lock")
	failed += _expect(scout.is_walker(), "scout is walker")
	failed += _expect(is_equal_approx(scout.speed, 161.25), "scout walk 161.25")
	scout.queue_free()
	return failed


func _drone_ferry() -> int:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Node = packed.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().physics_frame
	var failed := 0
	failed += _expect(is_equal_approx(main.get("CAM_PLAYER_OFFSET"), 168.0), "CAM_PLAYER_OFFSET 168")
	failed += _expect(is_equal_approx(main.get("DRONE_FIRST"), 5.60), "DRONE_FIRST")
	var drone: CarrierDrone = main.call("_spawn_drone", Powerup.Kind.OVERCHARGE, true)
	failed += _expect(drone != null and is_instance_valid(drone), "spawned drone")
	if drone:
		failed += _expect(drone.kind == Powerup.Kind.OVERCHARGE, "carries overcharge")
		var x0 := drone.global_position.x
		for _i in 8:
			await get_tree().process_frame
		failed += _expect(absf(drone.global_position.x - x0) > 4.0, "drone flies across")
		var volt: Volt = main.get_node("World/Volt")
		volt.global_position = drone.payload_position()
		main.call("_collect_drone", drone)
		await get_tree().process_frame
		failed += _expect(drone.taken, "collected on contact")
		failed += _expect(volt.overcharge_left > 5.0, "overcharge applied")
		failed += _expect(volt.strike_power() == volt.strike_damage + 1, "overcharge +1")
	main.queue_free()
	await get_tree().process_frame
	return failed


func _all_seven() -> int:
	var volt_scene: PackedScene = load("res://scenes/volt.tscn")
	var volt: Volt = volt_scene.instantiate()
	add_child(volt)
	await get_tree().process_frame
	var failed := 0
	volt.hp = 2
	volt.max_hp = 3
	var heal_msg := volt.apply_powerup(Powerup.Kind.HEALTH)
	failed += _expect(volt.hp == 3, "health heals 1")
	failed += _expect(heal_msg.begins_with("PACK"), "health toast")
	volt.apply_powerup(Powerup.Kind.SHIELD)
	failed += _expect(volt.has_shield(), "shield up")
	var hp := volt.hp
	failed += _expect(volt.consume_shield(), "shield blocks")
	failed += _expect(not volt.has_shield(), "shield consumed")
	failed += _expect(volt.hp == hp, "hp unchanged after block")
	volt.invuln = 0.0
	volt.take_hit()
	failed += _expect(volt.hp == hp - 1, "next hit lands")
	volt.apply_powerup(Powerup.Kind.STEALTH)
	failed += _expect(volt.is_stealthed(), "stealth on")
	var bot: Enemy = load("res://scenes/enemy.tscn").instantiate()
	add_child(bot)
	bot.setup(Enemy.Kind.SCOUT, Vector2(300.0, 1000.0), 400.0, false, 0)
	await get_tree().physics_frame
	failed += _expect(not bot.can_contact(), "stealth blocks contact")
	bot.play_attack()
	failed += _expect(not bot.attacking, "stealth blocks attack")
	volt.stealth_left = 0.0
	volt.apply_powerup(Powerup.Kind.OVERCHARGE)
	failed += _expect(volt.strike_power() == volt.strike_damage + 1, "overcharge damage")
	volt.apply_powerup(Powerup.Kind.MAGNET)
	failed += _expect(volt.has_magnet(), "magnet on")
	volt.apply_powerup(Powerup.Kind.SLOW)
	failed += _expect(volt.has_slow_field(), "slow field on")
	failed += _expect(is_equal_approx(bot._pace(), Powerup.SLOW_PACE), "bots paced 0.42")
	volt.apply_powerup(Powerup.Kind.SCORE)
	failed += _expect(is_equal_approx(volt.score_mult(), 2.0), "score ×2")
	var rows: Array = volt.effect_status()
	failed += _expect(rows.size() >= 4, "HUD rows for timed effects")
	var hud := HUD.new()
	add_child(hud)
	await get_tree().process_frame
	hud.set_effects(rows)
	var painted := 0
	if hud._effects:
		for child in hud._effects.get_children():
			if child is CanvasItem and (child as CanvasItem).visible:
				painted += 1
	failed += _expect(painted >= 4, "HUD paints status cues")
	print("  seven kinds applied hp=%d shield=%s stealth=%s atk=%d magnet=%s slow=%s score=%.1f" % [
		volt.hp, volt.has_shield(), volt.is_stealthed(), volt.strike_power(),
		volt.has_magnet(), volt.has_slow_field(), volt.score_mult()
	])
	return failed


func _expect(ok: bool, label: String) -> int:
	if ok:
		print("  pass  ", label)
		return 0
	push_error("  FAIL  " + label)
	return 1
