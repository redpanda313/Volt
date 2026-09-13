extends CharacterBody2D
class_name Volt

signal died
signal hp_changed(current: int)
signal dashed(direction: Vector2)

const MAX_HP := 3
const GRAVITY := 2100.0
const DASH_SPEED := 820.0
const AIR_DASH_SPEED := 760.0
const DASH_SECS := 0.50
const DASH_SECS_LONG := 0.64
const LAUNCH_SPEED := 880.0
const GROUND_FRICTION := 2600.0
const AIR_FRICTION := 900.0
const MAX_FALL := 1100.0
const HURT_IFRAMES := 0.55
const STRIKE_RANGE := 118.0
const BOUNCE_UP := -340.0
const BOUNCE_BACK := 280.0
const MIN_X := 56.0
const MAX_X := 664.0
const LAUNCH_MIN_UP := -280.0

@onready var visual: Node2D = $Visual
@onready var idle: AnimatedSprite2D = $Visual/Idle
@onready var attack: AnimatedSprite2D = $Visual/Attack
@onready var dash: AnimatedSprite2D = $Visual/Dash
@onready var hurt: AnimatedSprite2D = $Visual/Hurt

var hp: int = MAX_HP
var invuln: float = 0.0
var pose_left: float = 0.0
var facing: float = 1.0
var arc_lash: bool = false
var long_dodge: bool = false
var rest_x: float = 230.0
var launching: bool = false
var dashing: bool = false
var dodge_left: float = 0.0
var launch_grace: float = 0.0
var dash_dir: Vector2 = Vector2.RIGHT
var dash_speed: float = DASH_SPEED


func _ready() -> void:
	motion_mode = MOTION_MODE_GROUNDED
	up_direction = Vector2.UP
	floor_snap_length = 8.0
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	_ensure_collider()
	_apply_art()
	_show_idle()


func _ensure_collider() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)
	var cap := CapsuleShape2D.new()
	cap.radius = 18.0
	cap.height = 78.0
	col.shape = cap
	col.position = Vector2(0, -39)


func _apply_art() -> void:
	var s := Art.ACTOR_SCALE
	Art.fit_animated(idle, Art.volt_idle_frames(), 252.0 * s, 0.46, &"idle", 10.0, true)
	Art.fit_animated(attack, Art.volt_frames("attack"), 236.0 * s, 0.46, &"attack", 14.0, false)
	Art.fit_animated(dash, Art.volt_frames("dash"), 228.0 * s, 0.46, &"dash", 14.0, true)
	Art.fit_animated(hurt, Art.volt_frames("hurt"), 228.0 * s, 0.46, &"hurt", 12.0, false)
	idle.position.x = 8.0
	attack.position.x = -6.0
	dash.position.x = 16.0
	hurt.position.x = 4.0


func _physics_process(delta: float) -> void:
	if invuln > 0.0:
		invuln = maxf(0.0, invuln - delta)
		modulate.a = 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.02))
	else:
		modulate.a = 1.0
	if pose_left > 0.0:
		pose_left = maxf(0.0, pose_left - delta)
		if pose_left <= 0.0 and not launching and not dashing:
			_show_idle()
	if dodge_left > 0.0:
		dodge_left = maxf(0.0, dodge_left - delta)
		if dodge_left <= 0.0:
			dashing = false
	if launch_grace > 0.0:
		launch_grace = maxf(0.0, launch_grace - delta)

	if dashing:
		velocity = dash_dir * dash_speed
		velocity.y += GRAVITY * 0.12 * delta
	elif launching:
		velocity.y += GRAVITY * 0.45 * delta
	else:
		velocity.y += GRAVITY * delta
		velocity.y = minf(velocity.y, MAX_FALL)
		var friction := GROUND_FRICTION if is_on_floor() else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	floor_snap_length = 0.0 if launching or dashing else 8.0
	move_and_slide()
	global_position.x = clampf(global_position.x, MIN_X, MAX_X)
	if launching and launch_grace <= 0.0 and is_on_floor() and velocity.y >= 0.0:
		launching = false
		_show_idle()


func is_invulnerable() -> bool:
	return invuln > 0.0


func is_launching() -> bool:
	return launching


func is_dashing() -> bool:
	return dashing or dodge_left > 0.0


func apply_dash(direction: Vector2) -> void:
	var dir := direction
	if dir.length() < 0.12:
		dir = Vector2(facing, 0.0)
	dir = dir.normalized()
	dash_dir = dir
	if absf(dir.x) >= 0.08:
		facing = 1.0 if dir.x >= 0.0 else -1.0
		visual.scale.x = facing
	var secs := DASH_SECS_LONG if long_dodge else DASH_SECS
	dash_speed = DASH_SPEED if is_on_floor() else AIR_DASH_SPEED
	if long_dodge:
		dash_speed *= 1.16
	velocity = dir * dash_speed
	launching = false
	dashing = true
	dodge_left = secs
	invuln = maxf(invuln, secs * 0.75)
	_show_pose(dash)
	if dash.sprite_frames and dash.sprite_frames.has_animation(&"dash"):
		dash.play(&"dash")
	pose_left = secs
	dashed.emit(dir)


func apply_dodge(direction: float) -> void:
	apply_dash(Vector2(direction, 0.0))


func apply_jump() -> bool:
	apply_dash(Vector2(0.0, -1.0))
	return true


func launch_at(world_target: Vector2) -> void:
	var to := world_target - global_position
	if to.length() < 8.0:
		to = Vector2(facing * 120.0, -40.0)
	facing = 1.0 if to.x >= 0.0 else -1.0
	visual.scale.x = facing
	var dir := to.normalized()
	velocity = dir * LAUNCH_SPEED
	velocity.y = minf(velocity.y, LAUNCH_MIN_UP)
	launching = true
	dashing = false
	launch_grace = 0.22
	dodge_left = 0.0
	invuln = maxf(invuln, 0.20)
	_show_pose(attack)
	if attack.sprite_frames and attack.sprite_frames.has_animation(&"attack"):
		attack.play(&"attack")
	pose_left = 0.55
	floor_snap_length = 0.0


func bounce_from(other: Vector2) -> void:
	var away := global_position.x - other.x
	var back := -facing
	if absf(away) > 6.0:
		back = signf(away)
	velocity = Vector2(back * BOUNCE_BACK, BOUNCE_UP)
	launching = false
	dashing = false
	pose_left = 0.18


func apply_knockback(from: Vector2, force: float, lift: float) -> void:
	var away := signf(global_position.x - from.x)
	if away == 0.0:
		away = -facing
	facing = -away
	visual.scale.x = facing
	velocity = Vector2(away * force, lift)
	launching = false
	dashing = false
	dodge_left = 0.0
	_show_pose(hurt)
	if hurt.sprite_frames and hurt.sprite_frames.has_animation(&"hurt"):
		hurt.play(&"hurt")
	pose_left = 0.38


func strikes(bot: Enemy) -> bool:
	if not launching:
		return false
	var my_chest := global_position + Vector2(0.0, -48.0)
	var chest := bot.global_position + Vector2(0.0, -bot.hit_size.y * 0.35)
	if my_chest.distance_to(chest) <= STRIKE_RANGE:
		return true
	return absf(global_position.x - bot.global_position.x) < 72.0 \
		and absf(global_position.y - bot.global_position.y) < 140.0


func take_hit() -> void:
	if is_invulnerable() or hp <= 0:
		return
	hp -= 1
	invuln = HURT_IFRAMES
	hp_changed.emit(hp)
	if hp <= 0:
		died.emit()


func _show_pose(which: CanvasItem) -> void:
	idle.visible = which == idle
	attack.visible = which == attack
	dash.visible = which == dash
	hurt.visible = which == hurt
	if which != idle and idle.sprite_frames:
		idle.pause()


func _show_idle() -> void:
	idle.visible = true
	attack.visible = false
	dash.visible = false
	hurt.visible = false
	visual.scale.x = facing
	if idle.sprite_frames and idle.sprite_frames.has_animation(&"idle"):
		idle.play(&"idle")
