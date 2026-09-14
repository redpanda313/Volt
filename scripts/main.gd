extends Node2D

enum State { PLAYING, LEVEL_UP, GAME_OVER }

const LEVEL_AT := 5
const ASCEND_AT := 11
const VOLT_X := 230.0
const SPAWN_LEFT := 58.0
const SPAWN_RIGHT := 662.0
const SAVE_PATH := "user://volt.cfg"
const ARENA_LEFT := 8.0
const ARENA_RIGHT := 712.0

@onready var camera: Camera2D = $Camera2D
@onready var sky: ClimbSky = $World/Sky
@onready var pile: RobotPile = $World/Pile
@onready var volt: Volt = $World/Volt
@onready var enemies: Node2D = $World/Enemies
@onready var hud: HUD = $HUD
@onready var gesture: Gesture = $Gesture
@onready var juice: Juice = $Juice

var _enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

var state: State = State.PLAYING
var score: int = 0
var best: int = 0
var height_m: float = 0.0
var kills: int = 0
var level_picks: int = 0
var path_id := ""
var spawn_in: float = 0.40
var combo_left: float = 0.0
var combo: int = 0
var _ground: StaticBody2D
var _pack: HealthPack
var _kill_drops: int = 0
var _spawn_right := true


func _ready() -> void:
	best = _load_best()
	_build_arena()
	juice.bind(camera, $World)
	volt.global_position = Vector2(VOLT_X, pile.playable_y())
	volt.rest_x = VOLT_X
	volt.hp_changed.connect(hud.set_hp)
	volt.died.connect(_on_volt_died)
	volt.dashed.connect(_on_volt_dashed)
	gesture.tapped.connect(_on_tapped)
	gesture.swiped.connect(_on_swiped)
	pile.layer_completed.connect(_on_layer_completed)
	hud.restart_pressed.connect(_restart)
	hud.upgrade_picked.connect(_on_upgrade)
	hud.set_score(0)
	hud.set_height(0.0)
	hud.set_hp(volt.hp, volt.max_hp)
	hud.set_climb_level(1)
	hud.fade_hint()
	camera.position = Vector2(360, 640)
	volt.invuln = 0.75
	if OS.get_environment("VOLT_DEMO") == "1":
		_run_demo()


func _build_arena() -> void:
	pile.position = Vector2.ZERO
	_ground = StaticBody2D.new()
	_ground.name = "Ground"
	_ground.collision_layer = 0
	_ground.collision_mask = 0
	_ground.set_collision_layer_value(1, true)
	_ground.position = Vector2(360, RobotPile.BASE_FLOOR + 40.0)
	var gshape := CollisionShape2D.new()
	var grect := RectangleShape2D.new()
	grect.size = Vector2(2000, 80)
	gshape.shape = grect
	_ground.add_child(gshape)
	$World.add_child(_ground)
	_add_wall("LeftWall", Vector2(ARENA_LEFT - 20.0, 0.0))
	_add_wall("RightWall", Vector2(ARENA_RIGHT + 20.0, 0.0))


func _add_wall(wall_name: String, pos: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.collision_layer = 0
	wall.collision_mask = 0
	wall.set_collision_layer_value(1, true)
	wall.position = pos
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 6000)
	shape.shape = rect
	wall.add_child(shape)
	$World.add_child(wall)


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	combo_left = maxf(0.0, combo_left - delta)
	if combo_left <= 0.0:
		combo = 0
	spawn_in -= delta
	if spawn_in <= 0.0 and enemies.get_child_count() < 4:
		_spawn_bot()
		var pace := clampf(1.25 * pow(0.86, float(kills)), 0.70, 1.35)
		spawn_in = pace


func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	_tick_launch_hits()
	_tick_contacts()
	_tick_packs(delta)
	_follow_camera(delta)


func _follow_camera(delta: float) -> void:
	var focus_y := minf(volt.global_position.y - 360.0, pile.playable_y() - 360.0)
	focus_y += clampf(volt.velocity.y * 0.05, -42.0, 42.0)
	var target := Vector2(360.0, clampf(focus_y, -1800.0, 640.0))
	camera.position = camera.position.lerp(target, clampf(8.0 * delta, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_R and state == State.GAME_OVER:
		_restart()
		return
	if state != State.PLAYING:
		return
	match key.physical_keycode:
		KEY_SPACE:
			_launch_nearest()
		KEY_A, KEY_LEFT:
			_dash(Vector2.LEFT)
		KEY_D, KEY_RIGHT:
			_dash(Vector2.RIGHT)
		KEY_W, KEY_UP:
			_dash(Vector2.UP)
		KEY_S, KEY_DOWN:
			_dash(Vector2.DOWN)


func _on_tapped(screen_pos: Vector2) -> void:
	if state != State.PLAYING:
		return
	var world := _screen_to_world(screen_pos)
	var target := _enemy_at(world)
	if target == null:
		target = _nearest_enemy(world, 90.0)
	if target == null:
		return
	_launch_at(target)


func _on_swiped(direction: Vector2) -> void:
	if state != State.PLAYING:
		return
	_dash(direction)


func _dash(direction: Vector2) -> void:
	volt.apply_dash(direction)
	juice.dash_whoosh()
	juice.start_trail(volt.visual, 0.22)
	hud.toast("DASH")


func _on_volt_dashed(direction: Vector2) -> void:
	if volt.is_on_floor() or absf(volt.global_position.y - pile.playable_y()) < 48.0:
		pile.knock_top_layer(volt.global_position, direction)


func _launch_nearest() -> void:
	var target := _nearest_enemy(volt.global_position + Vector2(140, -40), 420.0)
	if target:
		_launch_at(target)


func _launch_at(target: Enemy) -> void:
	volt.launch_at_bot(target)
	juice.dash_whoosh()
	juice.start_trail(volt.visual, 0.34)
	hud.toast("STRIKE")


func _tick_launch_hits() -> void:
	if not volt.is_launching():
		return
	if volt.seek_bot != null and is_instance_valid(volt.seek_bot) and not volt.seek_bot.dead:
		if volt.strikes(volt.seek_bot):
			_strike_on_contact(volt.seek_bot)
			return
	for child in enemies.get_children():
		var bot := child as Enemy
		if bot == null or bot.dead:
			continue
		if volt.strikes(bot):
			_strike_on_contact(bot)
			return


func _strike_on_contact(primary: Enemy) -> void:
	volt.bounce_from(primary.global_position)
	_hit_enemy(primary)
	if volt.arc_lash:
		for child in enemies.get_children():
			var other := child as Enemy
			if other == null or other == primary or other.dead:
				continue
			if other.global_position.distance_to(primary.global_position) <= volt.arc_radius:
				_hit_enemy(other)


func _hit_enemy(enemy: Enemy) -> void:
	var slain := enemy.hurt(volt.strike_damage)
	var chest := enemy.global_position + Vector2(0.0, -enemy.hit_size.y * 0.35)
	juice.attack_punch(chest)
	if slain:
		_on_kill(enemy)


func _on_kill(enemy: Enemy) -> void:
	kills += 1
	combo = combo + 1 if combo_left > 0.0 else 1
	combo_left = volt.combo_window
	var gain := enemy.score_value() + int(float(maxi(0, combo - 1) * 2) * volt.combo_score_mult)
	score += gain
	height_m += 14.0 + float(enemy.kind) * 4.0
	sky.height_t = clampf(height_m / 360.0, 0.0, 1.0)
	hud.set_score(score)
	hud.set_height(height_m)
	pile.shatter(enemy)
	juice.kill_burst(enemy.global_position + Vector2(0, -80))
	_float_pts(enemy.global_position + Vector2(0, -120), "+%d" % gain)
	_maybe_drop_pack(enemy)
	_maybe_level_up()


func _on_layer_completed(layer_index: int, playable_y: float) -> void:
	height_m += 18.0
	sky.height_t = clampf(height_m / 360.0, 0.0, 1.0)
	hud.set_height(height_m)
	hud.set_climb_level(1 + layer_index)
	hud.toast("LAYER UP")
	juice.layer_thump()
	if is_instance_valid(_ground):
		_ground.position.y = playable_y + 40.0
	if volt.global_position.y > playable_y:
		volt.global_position.y = playable_y
	for child in enemies.get_children():
		var bot := child as Enemy
		if bot and not bot.dead:
			bot.global_position.y = playable_y


func _spawn_bot() -> void:
	var bot := _enemy_scene.instantiate() as Enemy
	enemies.add_child(bot)
	var kind := _pick_kind()
	var from_right := randf() < 0.5
	if randf() < 0.30:
		from_right = _spawn_right
	_spawn_right = not from_right
	var spawn_x := SPAWN_RIGHT if from_right else SPAWN_LEFT
	var stop_x := 330.0 + randf_range(-12.0, 18.0)
	if not from_right:
		stop_x = 390.0 + randf_range(-16.0, 16.0)
	if kind == Enemy.Kind.POPPER:
		stop_x += 12.0
	if kind == Enemy.Kind.WARDEN:
		stop_x = 360.0 if from_right else 400.0
	var lane_y := pile.surface_y_at(spawn_x)
	bot.setup(kind, Vector2(spawn_x, lane_y), stop_x, from_right)
	bot.exploded.connect(_on_popper_exploded)
	bot.slammed.connect(_on_warden_slam)


func _pick_kind() -> Enemy.Kind:
	if kills < 1:
		return Enemy.Kind.SCOUT
	if kills < 3:
		return Enemy.Kind.SCOUT if randf() < 0.55 else Enemy.Kind.POPPER
	var roll := randf()
	if roll < 0.48:
		return Enemy.Kind.SCOUT
	if roll < 0.78:
		return Enemy.Kind.POPPER
	return Enemy.Kind.WARDEN


func _tick_contacts() -> void:
	for child in enemies.get_children():
		var bot := child as Enemy
		if bot == null or bot.dead or not bot.can_contact():
			continue
		if bot.global_position.distance_to(volt.global_position) <= bot.contact_range:
			if volt.is_launching():
				continue
			bot.mark_contact()
			_hurt_volt(bot)


func _on_popper_exploded(bot: Enemy) -> void:
	juice.explode_burst(bot.global_position + Vector2(0, -40))
	if volt.global_position.distance_to(bot.global_position) <= 260.0:
		_hurt_volt(bot)


func _on_warden_slam(bot: Enemy) -> void:
	juice.slam_burst(bot.global_position + Vector2(0, -20))
	if volt.global_position.distance_to(bot.global_position) <= 250.0:
		_hurt_volt(bot)


func _hurt_volt(bot: Enemy) -> void:
	if volt.is_invulnerable():
		return
	volt.apply_knockback(bot.global_position, bot.knock_speed, bot.knock_lift)
	volt.take_hit()
	juice.damage_pulse()
	hud.toast("HIT")


func _maybe_drop_pack(enemy: Enemy) -> void:
	if _pack != null and is_instance_valid(_pack):
		return
	_kill_drops += 1
	var every := 2 if volt.pack_magnet else 3
	var drop := enemy.kind == Enemy.Kind.WARDEN or (_kill_drops % every == 0)
	if not drop:
		return
	var origin := enemy.global_position + Vector2(0.0, -24.0)
	_pack = HealthPack.spawn($World, origin, pile.surface_y_at(origin.x))


func _tick_packs(delta: float) -> void:
	if _pack == null or not is_instance_valid(_pack):
		_pack = null
		return
	if volt.pack_magnet:
		_pack.attract_toward(volt.global_position, delta)
	if volt.hp >= volt.max_hp:
		return
	var rad := 96.0 if volt.pack_magnet else 50.0
	if _pack.global_position.distance_to(volt.global_position) <= rad:
		var gained := volt.heal(volt.pack_heal)
		if gained > 0:
			juice.bloom_flash(0.45)
			hud.toast("PACK +%d" % gained)
			_pack.queue_free()
			_pack = null


func _maybe_level_up() -> void:
	if level_picks == 0 and kills >= LEVEL_AT:
		_offer_level_up(1)
	elif level_picks == 1 and kills >= ASCEND_AT:
		_offer_level_up(2)


func _offer_level_up(tier: int) -> void:
	state = State.LEVEL_UP
	Engine.time_scale = 1.0
	get_tree().paused = true
	if tier == 1:
		hud.show_level_up("LEVEL UP", "Pick a path. A second unlock comes later.", [
			{"id": "atk", "title": "ATK UP", "blurb": "Arc Lash: swings also clip a nearby bot.", "icon": 1},
			{"id": "hp", "title": "HP UP", "blurb": "+1 max heart. Survive a longer climb.", "icon": 2},
			{"id": "dash", "title": "DASH RANGE", "blurb": "Afterimage: longer dash and more i-frames.", "icon": 3},
		])
		return
	var choices: Array = []
	match path_id:
		"atk":
			choices = [
				{"id": "shield", "title": "SHIELD BREAK", "blurb": "Strikes deal 2 damage. Wardens fold faster.", "icon": 5},
				{"id": "combo", "title": "COMBO TIME", "blurb": "Combo window stretches. Chain payouts grow.", "icon": 6},
			]
		"dash":
			choices = [
				{"id": "screw", "title": "SCREW SPIN", "blurb": "Jump-dash travels farther. Stay in the air.", "icon": 4},
				{"id": "combo", "title": "COMBO TIME", "blurb": "Combo window stretches. Chain payouts grow.", "icon": 6},
			]
		_:
			choices = [
				{"id": "medbay", "title": "MEDBAY", "blurb": "Health packs restore 2 HP.", "icon": 2},
				{"id": "magnet", "title": "PACK PULL", "blurb": "Packs drop more often and pull toward you.", "icon": 7},
			]
	hud.show_level_up("ASCEND", "Path locked. Unlock an ability.", choices)


func _on_upgrade(id: String) -> void:
	match id:
		"atk":
			path_id = "atk"
			volt.arc_lash = true
			hud.toast("ATK UP")
		"hp":
			path_id = "hp"
			volt.grant_max_hp(1)
			hud.toast("HP UP")
		"dash":
			path_id = "dash"
			volt.long_dodge = true
			hud.toast("DASH RANGE")
		"shield":
			volt.strike_damage = 2
			hud.toast("SHIELD BREAK")
		"combo":
			volt.combo_window = 1.85
			volt.combo_score_mult = 2.0
			hud.toast("COMBO TIME")
		"screw":
			volt.air_dash_mult = 1.35
			hud.toast("SCREW SPIN")
		"medbay":
			volt.pack_heal = 2
			hud.toast("MEDBAY")
		"magnet":
			volt.pack_magnet = true
			hud.toast("PACK PULL")
		"arc":
			path_id = "atk"
			volt.arc_lash = true
			hud.toast("ATK UP")
		"dodge":
			path_id = "dash"
			volt.long_dodge = true
			hud.toast("DASH RANGE")
	level_picks += 1
	hud.hide_modals()
	state = State.PLAYING
	get_tree().paused = false


func _on_volt_died() -> void:
	state = State.GAME_OVER
	Engine.time_scale = 1.0
	if score > best:
		best = score
		_save_best(best)
	hud.show_game_over(score, height_m, best)


func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func _enemy_at(world: Vector2) -> Enemy:
	var best_bot: Enemy = null
	var best_d := 1.0e9
	for child in enemies.get_children():
		var bot := child as Enemy
		if bot == null or bot.dead:
			continue
		if bot.contains_world_point(world):
			var d := bot.global_position.distance_to(world)
			if d < best_d:
				best_d = d
				best_bot = bot
	return best_bot


func _nearest_enemy(world: Vector2, radius: float) -> Enemy:
	var best_bot: Enemy = null
	var best_d := radius
	for child in enemies.get_children():
		var bot := child as Enemy
		if bot == null or bot.dead:
			continue
		var d := bot.global_position.distance_to(world)
		if d < best_d:
			best_d = d
			best_bot = bot
	return best_bot


func _screen_to_world(screen: Vector2) -> Vector2:
	var canvas := get_viewport().get_canvas_transform()
	return canvas.affine_inverse() * screen


func _float_pts(world: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	label.position = world + Vector2(-20, -30)
	$World.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 70.0, 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(label.queue_free)


func _load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return int(cfg.get_value("run", "best", 0))


func _save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("run", "best", value)
	cfg.save(SAVE_PATH)


func _run_demo() -> void:
	await get_tree().create_timer(0.85).timeout
	await _shot("01_idle_hud")
	var bot := _nearest_enemy(volt.global_position + Vector2(140, -40), 640.0)
	if bot == null:
		await get_tree().create_timer(0.7).timeout
		bot = _nearest_enemy(volt.global_position + Vector2(140, -40), 640.0)
	if bot:
		_launch_at(bot)
		await get_tree().create_timer(0.32).timeout
		await _shot("02_launch_attack")
		await get_tree().create_timer(0.55).timeout
		await _shot("03_bounce_debris")
	_dash(Vector2(-0.85, -0.45))
	await get_tree().create_timer(0.22).timeout
	await _shot("04_omni_dash")
	var knocker := _nearest_enemy(volt.global_position, 900.0)
	volt.invuln = 0.0
	if knocker:
		_hurt_volt(knocker)
	else:
		volt.apply_knockback(volt.global_position + Vector2(90, 0), 640.0, -70.0)
		volt.take_hit()
		juice.damage_pulse()
	await get_tree().create_timer(0.10).timeout
	await _shot("05_knockback_pulse")
	volt.dashing = false
	volt.global_position.y = pile.playable_y()
	var warden := _enemy_scene.instantiate() as Enemy
	enemies.add_child(warden)
	warden.setup(Enemy.Kind.WARDEN, Vector2(500.0, pile.playable_y()), 380.0)
	await get_tree().create_timer(0.45).timeout
	await _shot("06_warden_on_pile")
	_dash(Vector2(0.15, -1.0))
	await get_tree().create_timer(0.18).timeout
	await _shot("07_jump_dash_spin")
	var lefty := _enemy_scene.instantiate() as Enemy
	enemies.add_child(lefty)
	lefty.setup(Enemy.Kind.SCOUT, Vector2(SPAWN_LEFT, pile.playable_y()), 390.0, false)
	await get_tree().create_timer(0.35).timeout
	await _shot("08_left_spawn")
	if OS.get_environment("VOLT_DEMO_QUIT") == "1":
		await get_tree().create_timer(0.35).timeout
		get_tree().quit()


func _shot(slug: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img == null:
		return
	var dir := OS.get_environment("VOLT_SHOT_DIR")
	if dir == "":
		dir = "/opt/cursor/artifacts/screenshots"
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png("%s/%s.png" % [dir, slug])
