extends CharacterBody2D
class_name Volt

signal died
signal hp_changed(current: int, maximum: int)
signal dashed(direction: Vector2)

const MAX_HP := 3
## Beat 3 was 2100 / 1100. Faster start + higher terminal.
const GRAVITY := 3000.0
const FALL_GRAVITY := 4200.0
const MAX_FALL := 1750.0
## Beat 3: 820 × 0.50 ground. Distance ×0.5 and speed ×1.3 → 1066 × 0.1923.
const DASH_SPEED := 1066.0
const AIR_DASH_SPEED := 988.0
const DASH_SECS := 0.1923
const DASH_SECS_LONG := 0.2462
## Beat 4 tap-attack used DASH_SPEED. Beat 5: 75% faster → ×1.75.
const ATTACK_DASH_MULT := 1.75
const GROUND_FRICTION := 2600.0
const AIR_FRICTION := 900.0
const HURT_IFRAMES := 0.55
const STRIKE_RANGE := 118.0
## Beat 4 rebound was 10% of that dash. Beat 5: 2× distance → 20%.
const REBOUND_FRAC := 0.20
const MIN_X := 56.0
const MAX_X := 664.0
const JUMP_DASH_Y := -0.28

@onready var visual: Node2D = $Visual
@onready var idle: AnimatedSprite2D = $Visual/Idle
@onready var attack: AnimatedSprite2D = $Visual/Attack
@onready var dash: AnimatedSprite2D = $Visual/Dash
@onready var hurt: AnimatedSprite2D = $Visual/Hurt
@onready var run: AnimatedSprite2D = $Visual/Run
@onready var attack_dash: AnimatedSprite2D = $Visual/AttackDash
@onready var jump_dash: AnimatedSprite2D = $Visual/JumpDash

var hp: int = MAX_HP
var max_hp: int = MAX_HP
var invuln: float = 0.0
var pose_left: float = 0.0
var facing: float = 1.0
var arc_lash: bool = false
var long_dodge: bool = false
var arc_radius: float = 150.0
var strike_damage: int = 1
var air_dash_mult: float = 1.0
var blink_iframes: bool = false
var pack_heal: int = 1
var pack_magnet: bool = false
var combo_window: float = 1.15
var combo_score_mult: float = 1.0
var rest_x: float = 230.0
var launching: bool = false
var dashing: bool = false
var seeking: bool = false
var jump_dashing: bool = false
var dodge_left: float = 0.0
var launch_grace: float = 0.0
var dash_dir: Vector2 = Vector2.RIGHT
var dash_speed: float = DASH_SPEED
var seek_bot: Enemy
var seek_target: Vector2 = Vector2.ZERO
var commit_distance: float = 0.0
var seek_left: float = 0.0
var rebound_left: float = 0.0
var rebound_vel: Vector2 = Vector2.ZERO
var _has_night5_spin := false
var extra_jumps: int = 0
var jumps_left: int = 0
var _was_airborne := false


func _ready() -> void:
	add_to_group("volt")
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
	cap.radius = 13.5
	cap.height = 58.5
	col.shape = cap
	col.position = Vector2(0, -29)


func _apply_art() -> void:
	var s := Art.ACTOR_SCALE
	var travel := Art.volt_travel_frames()
	var atk_dash := Art.volt_attack_dash_frames()
	var screw := Art.volt_jump_dash_frames()
	_has_night5_spin = Art.has_night5_spin()
	Art.fit_animated(idle, Art.volt_idle_frames(), 252.0 * s, 0.46, &"idle", 10.0, true)
	Art.fit_animated(attack, Art.volt_frames("attack"), 236.0 * s, 0.46, &"attack", 14.0, false)
	Art.fit_animated(dash, travel, 228.0 * s, 0.46, &"dash", 16.0, true)
	Art.fit_animated(run, travel, 228.0 * s, 0.46, &"run", 16.0, true)
	Art.fit_animated(hurt, Art.volt_frames("hurt"), 228.0 * s, 0.46, &"hurt", 12.0, false)
	Art.fit_animated(attack_dash, atk_dash, 228.0 * s, 0.46, &"attack_dash", 16.0, true)
	Art.fit_animated(jump_dash, screw, 228.0 * s, 0.46, &"spin", 18.0, true)
	idle.position.x = 8.0
	attack.position.x = -6.0
	dash.position.x = 16.0
	if run:
		run.position.x = 16.0
	if attack_dash:
		attack_dash.position.x = 16.0
	if jump_dash:
		jump_dash.position.x = 8.0
		jump_dash.rotation = 0.0
	hurt.position.x = 4.0


func _physics_process(delta: float) -> void:
	if invuln > 0.0:
		invuln = maxf(0.0, invuln - delta)
		modulate.a = 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.02))
	else:
		modulate.a = 1.0
	if pose_left > 0.0:
		pose_left = maxf(0.0, pose_left - delta)
		if pose_left <= 0.0 and not launching and not dashing and rebound_left <= 0.0:
			_show_idle()
	if dodge_left > 0.0:
		dodge_left = maxf(0.0, dodge_left - delta)
		if dodge_left <= 0.0:
			dashing = false
			jump_dashing = false
	if launch_grace > 0.0:
		launch_grace = maxf(0.0, launch_grace - delta)
	if rebound_left > 0.0:
		rebound_left = maxf(0.0, rebound_left - delta)
		if rebound_left <= 0.0:
			rebound_vel = Vector2.ZERO
	if seeking and seek_left > 0.0:
		seek_left = maxf(0.0, seek_left - delta)
		if seek_left <= 0.0:
			_clear_seek()
			if not dashing:
				_show_idle()
	_tick_spin(delta)

	if rebound_left > 0.0:
		velocity = rebound_vel
	elif seeking:
		_steer_seek(delta)
	elif dashing:
		velocity = dash_dir * dash_speed
		velocity.y += GRAVITY * 0.12 * delta
	else:
		if velocity.y < 0.0:
			velocity.y += GRAVITY * delta
		else:
			velocity.y += FALL_GRAVITY * delta
		velocity.y = minf(velocity.y, MAX_FALL)
		var friction := GROUND_FRICTION if is_on_floor() else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	floor_snap_length = 0.0 if launching or dashing or rebound_left > 0.0 else 8.0
	move_and_slide()
	global_position.x = clampf(global_position.x, MIN_X, MAX_X)
	var on_floor := is_on_floor()
	if on_floor and _was_airborne:
		jumps_left = extra_jumps
	_was_airborne = not on_floor
	if launching and not seeking and launch_grace <= 0.0 and on_floor and velocity.y >= 0.0:
		launching = false
		_show_idle()


func _tick_spin(delta: float) -> void:
	if jump_dash == null:
		return
	if jump_dashing and jump_dash.visible and not _has_night5_spin:
		jump_dash.rotation += 22.0 * delta
	elif not jump_dashing and absf(jump_dash.rotation) > 0.01:
		jump_dash.rotation = move_toward(jump_dash.rotation, 0.0, 20.0 * delta)


func _steer_seek(delta: float) -> void:
	if seek_bot != null and is_instance_valid(seek_bot) and not seek_bot.dead:
		seek_target = _bot_chest(seek_bot)
	var to := seek_target - global_position
	var dist := to.length()
	if dist >= 4.0:
		dash_dir = to.normalized()
		if absf(dash_dir.x) >= 0.08:
			facing = 1.0 if dash_dir.x >= 0.0 else -1.0
			visual.scale.x = facing
	var step := dash_speed * delta
	if dist <= maxf(step * 1.15, 10.0):
		velocity = dash_dir * minf(dash_speed, dist / maxf(delta, 0.001))
	else:
		velocity = dash_dir * dash_speed


func _bot_chest(bot: Enemy) -> Vector2:
	return bot.global_position + Vector2(0.0, -bot.hit_size.y * 0.4)


func is_invulnerable() -> bool:
	return invuln > 0.0


func is_launching() -> bool:
	return launching or seeking


func is_dashing() -> bool:
	return dashing or dodge_left > 0.0


func is_jump_dashing() -> bool:
	return jump_dashing


func can_jump_dash() -> bool:
	return is_on_floor() or jumps_left > 0


func grant_extra_jump(amount: int = 1) -> void:
	extra_jumps += amount
	if not is_on_floor():
		jumps_left += amount


func refresh_jump() -> void:
	jumps_left = maxi(jumps_left, 1)


func _consume_jump() -> void:
	if is_on_floor():
		jumps_left = extra_jumps
	else:
		jumps_left = maxi(0, jumps_left - 1)


func apply_dash(direction: Vector2) -> bool:
	var dir := direction
	if dir.length() < 0.12:
		dir = Vector2(facing, 0.0)
	dir = dir.normalized()
	var is_jump := not is_on_floor() or dir.y < JUMP_DASH_Y
	if is_jump and not can_jump_dash():
		return false
	if is_jump:
		_consume_jump()
	dash_dir = dir
	if absf(dir.x) >= 0.08:
		facing = 1.0 if dir.x >= 0.0 else -1.0
		visual.scale.x = facing
	var secs := DASH_SECS_LONG if long_dodge else DASH_SECS
	dash_speed = DASH_SPEED if is_on_floor() else AIR_DASH_SPEED
	if long_dodge:
		dash_speed *= 1.16
	if is_jump:
		secs *= air_dash_mult
	rebound_left = 0.0
	rebound_vel = Vector2.ZERO
	velocity = dir * dash_speed
	_clear_seek()
	dashing = true
	dodge_left = secs
	invuln = maxf(invuln, secs * 0.75)
	if blink_iframes:
		invuln = maxf(invuln, secs + 0.22)
	jump_dashing = is_jump
	if is_jump:
		_play_jump_dash_pose()
	else:
		_play_travel_pose()
	pose_left = secs
	dashed.emit(dir)
	return true


func apply_dodge(direction: float) -> bool:
	return apply_dash(Vector2(direction, 0.0))


func apply_jump() -> bool:
	return apply_dash(Vector2(0.0, -1.0))


func launch_at_bot(bot: Enemy) -> void:
	seek_bot = bot
	var chest := _bot_chest(bot) if bot != null else global_position + Vector2(facing * 120.0, -40.0)
	_begin_seek(chest)


func launch_at(world_target: Vector2) -> void:
	seek_bot = null
	_begin_seek(world_target)


func _begin_seek(world_target: Vector2) -> void:
	var to := world_target - global_position
	if to.length() < 8.0:
		to = Vector2(facing * 80.0, -30.0)
	commit_distance = to.length()
	seek_target = world_target
	dash_dir = to.normalized()
	dash_speed = DASH_SPEED * ATTACK_DASH_MULT
	if absf(dash_dir.x) >= 0.08:
		facing = 1.0 if dash_dir.x >= 0.0 else -1.0
		visual.scale.x = facing
	velocity = dash_dir * dash_speed
	seeking = true
	launching = true
	dashing = false
	jump_dashing = false
	dodge_left = 0.0
	rebound_left = 0.0
	launch_grace = 0.0
	var travel := commit_distance / maxf(dash_speed, 1.0)
	seek_left = travel + 0.28
	invuln = maxf(invuln, travel)
	if blink_iframes:
		invuln = maxf(invuln, travel + 0.22)
	_play_attack_dash_pose()
	pose_left = travel + 0.35
	floor_snap_length = 0.0


func bounce_from(other: Vector2) -> void:
	var away := global_position.x - other.x
	var back := -facing
	if absf(away) > 6.0:
		back = signf(away)
	var dist := commit_distance * REBOUND_FRAC
	var dir := Vector2(back, -1.0).normalized()
	var secs := clampf(dist / 420.0, 0.10, 0.28)
	if dist < 1.0:
		dist = 1.0
	rebound_vel = dir * (dist / secs)
	rebound_left = secs
	velocity = rebound_vel
	_clear_seek()
	dashing = false
	jump_dashing = false
	dodge_left = 0.0
	refresh_jump()
	invuln = maxf(invuln, secs + 0.06)
	_play_attack_pose()
	pose_left = maxf(0.28, secs)


func apply_knockback(from: Vector2, force: float, lift: float) -> void:
	var away := signf(global_position.x - from.x)
	if away == 0.0:
		away = -facing
	facing = -away
	visual.scale.x = facing
	velocity = Vector2(away * force, lift)
	_clear_seek()
	dashing = false
	jump_dashing = false
	dodge_left = 0.0
	rebound_left = 0.0
	_show_pose(hurt)
	if hurt.sprite_frames and hurt.sprite_frames.has_animation(&"hurt"):
		hurt.play(&"hurt")
	pose_left = 0.38


func strikes(bot: Enemy) -> bool:
	if not launching and not seeking and not jump_dashing:
		return false
	var my_chest := global_position + Vector2(0.0, -36.0)
	var chest := bot.global_position + Vector2(0.0, -bot.hit_size.y * 0.35)
	if my_chest.distance_to(chest) <= STRIKE_RANGE:
		return true
	return absf(global_position.x - bot.global_position.x) < 64.0 \
		and absf(global_position.y - bot.global_position.y) < 120.0


func take_hit() -> void:
	if is_invulnerable() or hp <= 0:
		return
	hp -= 1
	invuln = HURT_IFRAMES
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		died.emit()


func heal(amount: int) -> int:
	if hp <= 0 or amount <= 0:
		return 0
	var before := hp
	hp = mini(hp + amount, max_hp)
	if hp != before:
		hp_changed.emit(hp, max_hp)
	return hp - before


func grant_max_hp(extra: int = 1) -> void:
	max_hp += extra
	heal(extra)


func _clear_seek() -> void:
	seeking = false
	launching = false
	seek_bot = null
	seek_left = 0.0


func _play_travel_pose() -> void:
	jump_dashing = false
	var horiz := absf(dash_dir.x) >= absf(dash_dir.y) * 0.65
	if horiz and run and run.sprite_frames and run.sprite_frames.has_animation(&"run"):
		_show_pose(run)
		run.play(&"run")
		return
	_show_pose(dash)
	if dash.sprite_frames and dash.sprite_frames.has_animation(&"dash"):
		dash.play(&"dash")


func _play_attack_dash_pose() -> void:
	jump_dashing = false
	if attack_dash and attack_dash.sprite_frames and attack_dash.sprite_frames.has_animation(&"attack_dash"):
		_show_pose(attack_dash)
		attack_dash.play(&"attack_dash")
		return
	_play_travel_pose()


func _play_jump_dash_pose() -> void:
	jump_dashing = true
	if jump_dash:
		jump_dash.rotation = 0.0
		_show_pose(jump_dash)
		if jump_dash.sprite_frames and jump_dash.sprite_frames.has_animation(&"spin"):
			jump_dash.play(&"spin")
		return
	_play_travel_pose()
	jump_dashing = true


func _play_attack_pose() -> void:
	_show_pose(attack)
	if attack.sprite_frames and attack.sprite_frames.has_animation(&"attack"):
		attack.play(&"attack")


func _show_pose(which: CanvasItem) -> void:
	idle.visible = which == idle
	attack.visible = which == attack
	dash.visible = which == dash
	hurt.visible = which == hurt
	if run:
		run.visible = which == run
	if attack_dash:
		attack_dash.visible = which == attack_dash
	if jump_dash:
		jump_dash.visible = which == jump_dash
		if which != jump_dash:
			jump_dash.rotation = 0.0
	if which != idle and idle.sprite_frames:
		idle.pause()


func _show_idle() -> void:
	idle.visible = true
	attack.visible = false
	dash.visible = false
	hurt.visible = false
	if run:
		run.visible = false
	if attack_dash:
		attack_dash.visible = false
	if jump_dash:
		jump_dash.visible = false
		jump_dash.rotation = 0.0
	jump_dashing = false
	visual.scale.x = facing
	if idle.sprite_frames and idle.sprite_frames.has_animation(&"idle"):
		idle.play(&"idle")
