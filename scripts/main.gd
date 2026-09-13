extends Node2D

enum State { PLAYING, LEVEL_UP, GAME_OVER }

const LEVEL_UP_KILLS := 5
const VOLT_X := 230.0
const SPAWN_X := 820.0
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
var leveled := false
var spawn_in: float = 0.40
var combo_left: float = 0.0
var combo: int = 0
var _ground: StaticBody2D


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
	hud.set_hp(volt.hp)
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
	_follow_camera(delta)


func _follow_camera(delta: float) -> void:
	var focus_y := minf(volt.global_position.y - 360.0, pile.playable_y() - 360.0)
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
	juice.ghost(volt.visual)
	hud.toast("DASH")


func _on_volt_dashed(direction: Vector2) -> void:
	if volt.is_on_floor() or absf(volt.global_position.y - pile.playable_y()) < 48.0:
		pile.knock_top_layer(volt.global_position, direction)


func _launch_nearest() -> void:
	var target := _nearest_enemy(volt.global_position + Vector2(140, -40), 420.0)
	if target:
		_launch_at(target)


func _launch_at(target: Enemy) -> void:
	var chest := target.global_position + Vector2(0.0, -target.hit_size.y * 0.4)
	volt.launch_at(chest)
	hud.toast("LAUNCH")


func _tick_launch_hits() -> void:
	if not volt.is_launching():
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
			if other.global_position.distance_to(primary.global_position) <= 150.0:
				_hit_enemy(other)


func _hit_enemy(enemy: Enemy) -> void:
	var slain := enemy.hurt(1)
	var chest := enemy.global_position + Vector2(0.0, -enemy.hit_size.y * 0.35)
	juice.attack_punch(chest)
	if slain:
		_on_kill(enemy)


func _on_kill(enemy: Enemy) -> void:
	kills += 1
	combo = combo + 1 if combo_left > 0.0 else 1
	combo_left = 1.15
	var gain := enemy.score_value() + maxi(0, combo - 1) * 2
	score += gain
	height_m += 14.0 + float(enemy.kind) * 4.0
	sky.height_t = clampf(height_m / 360.0, 0.0, 1.0)
	hud.set_score(score)
	hud.set_height(height_m)
	pile.shatter(enemy)
	juice.kill_burst(enemy.global_position + Vector2(0, -80))
	_float_pts(enemy.global_position + Vector2(0, -120), "+%d" % gain)
	if not leveled and kills >= LEVEL_UP_KILLS:
		_offer_level_up()


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
	var stop_x := 318.0 + randf_range(-8.0, 18.0)
	if kind == Enemy.Kind.POPPER:
		stop_x = 348.0 + randf_range(-8.0, 16.0)
	if kind == Enemy.Kind.WARDEN:
		stop_x = 336.0
	var lane_y := pile.surface_y_at(SPAWN_X)
	bot.setup(kind, Vector2(SPAWN_X, lane_y), stop_x)
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


func _offer_level_up() -> void:
	leveled = true
	state = State.LEVEL_UP
	Engine.time_scale = 1.0
	get_tree().paused = true
	hud.show_level_up()


func _on_upgrade(id: String) -> void:
	if id == "arc":
		volt.arc_lash = true
		hud.toast("ARC LASH")
	elif id == "dodge":
		volt.long_dodge = true
		hud.toast("AFTERIMAGE")
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
		await get_tree().create_timer(0.18).timeout
		await _shot("02_launch_attack")
		await get_tree().create_timer(0.70).timeout
		await _shot("03_bounce_debris")
	_dash(Vector2(-0.85, -0.45))
	await get_tree().create_timer(0.22).timeout
	await _shot("04_omni_dash")
	if bot and is_instance_valid(bot) and not bot.dead:
		_hurt_volt(bot)
		await get_tree().create_timer(0.16).timeout
		await _shot("05_knockback_pulse")
	else:
		_dash(Vector2(0.2, -1.0))
		await get_tree().create_timer(0.20).timeout
		await _shot("05_dash_up")
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
