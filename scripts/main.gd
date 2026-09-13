extends Node2D

enum State { PLAYING, LEVEL_UP, GAME_OVER }

const LEVEL_UP_KILLS := 5
const VOLT_X := 230.0
const VOLT_Y := 900.0
const SPAWN_X := 820.0
const LANE_Y := 900.0
const SAVE_PATH := "user://volt.cfg"

@onready var camera: Camera2D = $Camera2D
@onready var sky: ClimbSky = $World/Sky
@onready var pile: RobotPile = $World/Pile
@onready var volt: Volt = $World/Volt
@onready var enemies: Node2D = $World/Enemies
@onready var hud: HUD = $HUD
@onready var gesture: Gesture = $Gesture

var _enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

var state: State = State.PLAYING
var score: int = 0
var best: int = 0
var height_m: float = 0.0
var kills: int = 0
var leveled := false
var spawn_in: float = 0.40
var shake: float = 0.0
var combo_left: float = 0.0
var combo: int = 0


func _ready() -> void:
	best = _load_best()
	volt.position = Vector2(VOLT_X, VOLT_Y)
	volt.rest_x = VOLT_X
	volt.hp_changed.connect(hud.set_hp)
	volt.died.connect(_on_volt_died)
	gesture.tapped.connect(_on_tapped)
	gesture.swiped.connect(_on_swiped)
	hud.restart_pressed.connect(_restart)
	hud.upgrade_picked.connect(_on_upgrade)
	hud.set_score(0)
	hud.set_height(0.0)
	hud.set_hp(volt.hp)
	hud.fade_hint()
	camera.position = Vector2(360, 640)
	volt.invuln = 0.75


func _process(delta: float) -> void:
	if state != State.PLAYING:
		camera.offset = Vector2.ZERO
		return
	combo_left = maxf(0.0, combo_left - delta)
	if combo_left <= 0.0:
		combo = 0
	spawn_in -= delta
	if spawn_in <= 0.0 and enemies.get_child_count() < 4:
		_spawn_bot()
		var pace := clampf(1.25 * pow(0.86, float(kills)), 0.70, 1.35)
		spawn_in = pace
	_tick_contacts()
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 18.0)
		camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	else:
		camera.offset = Vector2.ZERO


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
			_attack_nearest()
		KEY_A, KEY_LEFT:
			_dodge(Vector2.LEFT)
		KEY_D, KEY_RIGHT:
			_dodge(Vector2.RIGHT)


func _on_tapped(screen_pos: Vector2) -> void:
	if state != State.PLAYING:
		return
	var world := _screen_to_world(screen_pos)
	var target := _enemy_at(world)
	if target == null:
		target = _nearest_enemy(world, 160.0)
	if target == null:
		target = _nearest_enemy(volt.global_position + Vector2(170, -20), 560.0)
	if target == null:
		return
	_strike(target)


func _on_swiped(direction: Vector2) -> void:
	if state != State.PLAYING:
		return
	_dodge(direction)


func _dodge(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	volt.play_dodge(direction)
	hud.toast("DODGE")


func _attack_nearest() -> void:
	var target := _nearest_enemy(volt.global_position + Vector2(140, -40), 420.0)
	if target:
		_strike(target)


func _strike(primary: Enemy) -> void:
	volt.play_attack(primary.global_position)
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
	shake = maxf(shake, 7.0)
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
	var slice := Art.SCOUT_IDLE
	var pile_scale := 0.85
	match enemy.kind:
		Enemy.Kind.POPPER:
			slice = Art.POPPER_IDLE
			pile_scale = 0.95
		Enemy.Kind.WARDEN:
			slice = Art.WARDEN_IDLE
			pile_scale = 1.15
	pile.add_bot(Art.tex(slice), pile_scale)
	_float_pts(enemy.global_position + Vector2(0, -120), "+%d" % gain)
	if not leveled and kills >= LEVEL_UP_KILLS:
		_offer_level_up()


func _spawn_bot() -> void:
	var bot := _enemy_scene.instantiate() as Enemy
	enemies.add_child(bot)
	var kind := _pick_kind()
	var stop_x := 318.0 + randf_range(-8.0, 18.0)
	if kind == Enemy.Kind.POPPER:
		stop_x = 348.0 + randf_range(-8.0, 16.0)
	if kind == Enemy.Kind.WARDEN:
		stop_x = 336.0
	bot.setup(kind, Vector2(SPAWN_X, LANE_Y), stop_x)
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
			bot.mark_contact()
			_hurt_volt()


func _on_popper_exploded(bot: Enemy) -> void:
	shake = 12.0
	if volt.global_position.distance_to(bot.global_position) <= 260.0:
		_hurt_volt()


func _on_warden_slam(bot: Enemy) -> void:
	shake = 10.0
	if volt.global_position.distance_to(bot.global_position) <= 250.0:
		_hurt_volt()


func _hurt_volt() -> void:
	if volt.is_invulnerable():
		return
	volt.take_hit()
	shake = 14.0
	hud.toast("HIT")


func _offer_level_up() -> void:
	leveled = true
	state = State.LEVEL_UP
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
	if score > best:
		best = score
		_save_best(best)
	hud.show_game_over(score, height_m, best)


func _restart() -> void:
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
