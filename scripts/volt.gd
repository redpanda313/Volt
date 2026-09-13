extends CharacterBody2D
class_name Volt

signal died
signal hp_changed(current: int)
signal dashed(direction: Vector2)

const MAX_HP := 3
const GRAVITY := 2100.0
const JUMP_VELOCITY := -760.0
const DODGE_SPEED := 560.0
const AIR_DODGE_SPEED := 420.0
const LAUNCH_SPEED := 880.0
const GROUND_FRICTION := 2600.0
const AIR_FRICTION := 900.0
const MAX_FALL := 1100.0
const ATTACK_SECS := 0.22
const DODGE_SECS := 0.40
const DODGE_SECS_UP := 0.70
const HURT_IFRAMES := 0.55
const STRIKE_RANGE := 88.0
const BOUNCE_UP := -340.0
const BOUNCE_BACK := 280.0
const MIN_X := 56.0
const MAX_X := 664.0

@onready var visual: Node2D = $Visual
@onready var idle: AnimatedSprite2D = $Visual/Idle
@onready var attack: Sprite2D = $Visual/Attack
@onready var dodge: Sprite2D = $Visual/Dodge

var hp: int = MAX_HP
var invuln: float = 0.0
var pose_left: float = 0.0
var facing: float = 1.0
var arc_lash: bool = false
var long_dodge: bool = false
var rest_x: float = 230.0
var launching: bool = false
var dodge_left: float = 0.0


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
	if get_node_or_null("CollisionShape2D") != null:
		return
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var cap := CapsuleShape2D.new()
	cap.radius = 20.0
	cap.height = 86.0
	col.shape = cap
	col.position = Vector2(0, -43)
	add_child(col)


func _apply_art() -> void:
	var idle_h := 252.0 * Art.ACTOR_SCALE
	Art.fit_animated(idle, Art.volt_idle_frames(), idle_h, 0.46)
	Art.fit_sprite(attack, Art.tex(Art.VOLT_ATTACK), 236.0 * Art.ACTOR_SCALE, 0.46)
	Art.fit_sprite(dodge, Art.tex(Art.VOLT_DODGE), 228.0 * Art.ACTOR_SCALE, 0.46)
	idle.position.x = 8.0
	attack.position.x = -6.0
	dodge.position.x = 16.0


func _physics_process(delta: float) -> void:
	if invuln > 0.0:
		invuln = maxf(0.0, invuln - delta)
		modulate.a = 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.02))
	else:
		modulate.a = 1.0
	if pose_left > 0.0:
		pose_left = maxf(0.0, pose_left - delta)
		if pose_left <= 0.0 and not launching:
			_show_idle()
	if dodge_left > 0.0:
		dodge_left = maxf(0.0, dodge_left - delta)

	if launching:
		velocity.y += GRAVITY * 0.55 * delta
	else:
		velocity.y += GRAVITY * delta
		velocity.y = minf(velocity.y, MAX_FALL)
		var friction := GROUND_FRICTION if is_on_floor() else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	floor_snap_length = 0.0 if launching else 8.0
	move_and_slide()
	global_position.x = clampf(global_position.x, MIN_X, MAX_X)
	if launching and is_on_floor() and velocity.y >= 0.0:
		launching = false
		_show_idle()


func is_invulnerable() -> bool:
	return invuln > 0.0


func is_launching() -> bool:
	return launching


func is_dashing() -> bool:
	return dodge_left > 0.0


func apply_dodge(direction: float) -> void:
	var dir := -1.0 if direction < 0.0 else 1.0
	facing = dir
	visual.scale.x = facing
	var secs := DODGE_SECS_UP if long_dodge else DODGE_SECS
	var speed := DODGE_SPEED if is_on_floor() else AIR_DODGE_SPEED
	if long_dodge:
		speed *= 1.18
	velocity.x = dir * speed
	launching = false
	dodge_left = secs
	invuln = maxf(invuln, secs * 0.85)
	_show_pose(dodge)
	pose_left = secs
	dashed.emit(Vector2(dir, 0.0))


func apply_jump() -> bool:
	if not is_on_floor():
		return false
	velocity.y = JUMP_VELOCITY
	launching = false
	if absf(velocity.x) > 12.0:
		facing = 1.0 if velocity.x >= 0.0 else -1.0
		visual.scale.x = facing
	_show_pose(dodge)
	pose_left = 0.28
	return true


func launch_at(world_target: Vector2) -> void:
	var to := world_target - global_position
	if to.length() < 8.0:
		to = Vector2(facing * 120.0, -40.0)
	facing = 1.0 if to.x >= 0.0 else -1.0
	visual.scale.x = facing
	var dir := to.normalized()
	velocity = dir * LAUNCH_SPEED
	if velocity.y > -80.0:
		velocity.y = minf(velocity.y, -80.0)
	launching = true
	dodge_left = 0.0
	invuln = maxf(invuln, 0.16)
	_show_pose(attack)
	pose_left = ATTACK_SECS + 0.12
	floor_snap_length = 0.0


func bounce_from(other: Vector2) -> void:
	var away := global_position.x - other.x
	var back := -facing
	if absf(away) > 6.0:
		back = signf(away)
	velocity = Vector2(back * BOUNCE_BACK, BOUNCE_UP)
	launching = false
	pose_left = 0.18


func strikes(bot: Enemy) -> bool:
	if not launching:
		return false
	var chest := bot.global_position + Vector2(0.0, -bot.hit_size.y * 0.35)
	return global_position.distance_to(chest) <= STRIKE_RANGE


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
	dodge.visible = which == dodge
	if which != idle and idle.sprite_frames:
		idle.pause()


func _show_idle() -> void:
	idle.visible = true
	attack.visible = false
	dodge.visible = false
	visual.scale.x = facing
	if idle.sprite_frames and idle.sprite_frames.has_animation(&"idle"):
		idle.play(&"idle")
