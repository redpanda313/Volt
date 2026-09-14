extends CharacterBody2D
class_name Enemy

enum Kind { SCOUT, POPPER, WARDEN }

signal defeated(who: Enemy)
signal exploded(who: Enemy)
signal slammed(who: Enemy)

const KIND_SCORE := {
	Kind.SCOUT: 10,
	Kind.POPPER: 25,
	Kind.WARDEN: 40,
}

const GRAVITY := 2100.0
const MIN_X := 48.0
const MAX_X := 700.0
## Beat 8 walkers: Scout only. Popper hops, Warden stomps — not walkers.
const SCOUT_WALK := 215.0
const WALKER_SPEED_SCALE := 0.75
## Jump onto junk / steps. Walking must not auto-elevate (`_stick_to_pile` removed).
const CLIMB_JUMP := -680.0
const CLIMB_STEP := 22.0
const CLIMB_LOOK := 44.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var telegraph: Node2D = $Telegraph

var kind: Kind = Kind.SCOUT
var hp: int = 1
var max_hp: int = 1
var speed: float = 280.0
var stop_x: float = 430.0
var hit_size: Vector2 = Vector2(80, 128)
var contact_range: float = 56.0
var contact_cd: float = 0.0
var fuse: float = -1.0
var slam_cd: float = 1.4
var arriving := true
var from_right := true
var dead := false
var flash: float = 0.0
var knock_speed: float = 320.0
var knock_lift: float = -120.0
var hop_cd: float = 0.0
var hop_impulse: float = 0.0
var step_left: float = 0.0
var stepping := true
var hunt_time: float = 0.0
var arrive_left: float = 0.55
var roam_x: float = 0.0
var roam_cd: float = 0.0
var lunge_cd: float = 0.40
var attacking := false
var attack_left: float = 0.0
var threat: int = 0
var _lunge_range := 148.0
var _lunge_mult := 1.40
var _fuse_hunt := 5.4
var _fuse_near := 112.0
var _atk_scale := 1.05
var _pile: RobotPile
var _volt: Volt
var _base_scale := Vector2.ONE
var _visual_base := Vector2.ZERO
var _bob: float = 0.0
var _climb_cd: float = 0.0


func _ready() -> void:
	add_to_group("bots")
	motion_mode = MOTION_MODE_GROUNDED
	up_direction = Vector2.UP
	floor_snap_length = 22.0
	## Tight angle so junk mounds are jumped, not walked as a ramp.
	floor_max_angle = deg_to_rad(28.0)
	floor_constant_speed = true
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)
	_pile = get_tree().get_first_node_in_group("pile") as RobotPile


func setup(p_kind: Kind, spawn: Vector2, p_stop_x: float, p_from_right: bool = true, p_threat: int = 0) -> void:
	kind = p_kind
	from_right = p_from_right
	threat = maxi(0, p_threat)
	global_position = spawn
	stop_x = p_stop_x
	var ramp := minf(1.0 + 0.028 * float(threat), 1.70)
	var s := Art.ACTOR_SCALE
	match kind:
		Kind.SCOUT:
			hp = 1
			speed = SCOUT_WALK * WALKER_SPEED_SCALE * ramp
			hit_size = Vector2(88, 128)
			contact_range = 64.0
			knock_speed = 340.0
			knock_lift = -140.0
			Art.fit_animated(visual, Art.bot_frames("scout"), 198.0 * s, 0.46, &"walk", 12.0, true)
		Kind.POPPER:
			hp = 1
			speed = 118.0 * ramp
			hit_size = Vector2(96, 122)
			contact_range = 82.0
			knock_speed = 300.0
			knock_lift = -520.0
			hop_impulse = -320.0
			hop_cd = 0.28
			Art.fit_animated(visual, Art.bot_frames("popper"), 186.0 * s, 0.46, &"hop", 10.0, true)
		Kind.WARDEN:
			hp = 3
			speed = 54.0 * ramp
			hit_size = Vector2(110, 152)
			contact_range = 88.0
			knock_speed = 640.0
			knock_lift = -70.0
			step_left = 0.48
			stepping = true
			Art.fit_animated(visual, Art.bot_frames("warden"), 236.0 * s, 0.46, &"walk", 6.0, true)
	_lunge_range = minf(148.0 + 3.5 * float(threat), 215.0)
	_lunge_mult = minf(1.40 + 0.018 * float(threat), 1.90)
	_fuse_hunt = maxf(5.4 - 0.085 * float(threat), 3.2)
	_fuse_near = minf(112.0 + 2.5 * float(threat), 155.0)
	_atk_scale = minf(1.05 + 0.025 * float(threat), 1.50)
	lunge_cd = clampf(2.35 - 0.05 * float(threat), 1.00, 2.35)
	slam_cd = clampf(2.85 - 0.055 * float(threat), 1.70, 2.85)
	arrive_left = clampf(0.90 - 0.018 * float(threat), 0.42, 0.90)
	max_hp = hp
	name = kind_name()
	_base_scale = visual.scale
	_visual_base = visual.position
	_wire_attack_anim()
	_tune_collider()
	if telegraph:
		telegraph.visible = false
	_face(-1.0 if from_right else 1.0)


func _wire_attack_anim() -> void:
	var atk := Art.bot_attack_frames(kind_name().to_lower())
	if visual and visual.sprite_frames and not atk.is_empty():
		var loop := kind == Kind.POPPER
		Art.fill_animation(visual.sprite_frames, &"attack", atk, 14.0, loop)
	if visual and not visual.animation_finished.is_connected(_on_visual_finished):
		visual.animation_finished.connect(_on_visual_finished)


func _tune_collider() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)
	var cap := CapsuleShape2D.new()
	match kind:
		Kind.SCOUT:
			cap.radius = 12.0
			cap.height = 51.0
			col.position = Vector2(0, -26)
		Kind.POPPER:
			cap.radius = 16.5
			cap.height = 39.0
			col.position = Vector2(0, -20)
		Kind.WARDEN:
			cap.radius = 15.0
			cap.height = 63.0
			col.position = Vector2(0, -32)
	col.shape = cap


func kind_name() -> String:
	match kind:
		Kind.SCOUT:
			return "Scout"
		Kind.POPPER:
			return "Popper"
		Kind.WARDEN:
			return "Warden"
	return "Bot"


func is_walker() -> bool:
	## Normal ground walker. Scout only — not Popper (hop) or Warden (stomp).
	return kind == Kind.SCOUT


func score_value() -> int:
	return int(KIND_SCORE[kind])


func contains_world_point(world: Vector2) -> bool:
	var local := to_local(world)
	var rect := Rect2(Vector2(-hit_size.x * 0.5, -hit_size.y), hit_size)
	return rect.has_point(local)


func hurt(amount: int = 1) -> bool:
	if dead:
		return false
	hp -= amount
	flash = 0.12
	if hp <= 0:
		_die()
		return true
	return false


func _die() -> void:
	dead = true
	defeated.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
		visual.modulate = Color(1.6, 1.6, 1.6) if flash > 0.0 else Color.WHITE
	if contact_cd > 0.0:
		contact_cd = maxf(0.0, contact_cd - delta)
	if _climb_cd > 0.0:
		_climb_cd = maxf(0.0, _climb_cd - delta)
	if attack_left > 0.0:
		attack_left = maxf(0.0, attack_left - delta)
		if attack_left <= 0.0 and kind != Kind.POPPER:
			attacking = false
			if telegraph and (kind != Kind.WARDEN or slam_cd > 0.35):
				telegraph.visible = false
			_resume_move_anim()

	velocity.y += GRAVITY * delta
	_locomote(delta)
	_try_climb_jump()
	move_and_slide()
	global_position.x = clampf(global_position.x, MIN_X, MAX_X)
	if arriving:
		arrive_left -= delta
		if arrive_left <= 0.0 or absf(global_position.x - stop_x) <= 16.0:
			arriving = false
	if not arriving:
		hunt_time += delta
		if kind == Kind.POPPER:
			_tick_popper(delta)
		elif kind == Kind.WARDEN:
			_tick_warden(delta)


func _locomote(delta: float) -> void:
	match kind:
		Kind.SCOUT:
			_scout_walk(delta)
		Kind.POPPER:
			_popper_hop()
		Kind.WARDEN:
			_warden_stomp(delta)


func _hunt_x() -> float:
	if arriving:
		return stop_x
	var px := _player_pos().x
	var dist := absf(global_position.x - px)
	roam_cd -= get_physics_process_delta_time()
	if roam_cd <= 0.0:
		var roam := minf(80.0 + 4.0 * float(threat), 120.0)
		roam_x = randf_range(-roam, roam)
		roam_cd = randf_range(0.55, 1.20)
	if dist > 100.0:
		return clampf(px, MIN_X + 20.0, MAX_X - 20.0)
	return clampf(px + roam_x, MIN_X + 20.0, MAX_X - 20.0)


func _player_pos() -> Vector2:
	var v := _cache_volt()
	if v:
		return v.global_position
	return Vector2(stop_x, global_position.y)


func _cache_volt() -> Volt:
	if _volt != null and is_instance_valid(_volt):
		return _volt
	_volt = get_tree().get_first_node_in_group("volt") as Volt
	return _volt


func _scout_walk(delta: float) -> void:
	var target := _hunt_x()
	var dir := signf(target - global_position.x)
	var v := _cache_volt()
	if not arriving:
		lunge_cd -= delta
		if v and lunge_cd <= 0.0 and global_position.distance_to(v.global_position) < _lunge_range:
			play_attack()
			lunge_cd = clampf(2.05 - 0.04 * float(threat), 1.05, 2.05)
			dir = signf(v.global_position.x - global_position.x)
			if dir == 0.0:
				dir = -1.0 if from_right else 1.0
			velocity.x = dir * speed * _lunge_mult
			_face(dir)
			return
	if absf(global_position.x - target) < 6.0:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		if v:
			dir = signf(v.global_position.x - global_position.x)
		if dir == 0.0:
			dir = -1.0 if from_right else 1.0
	else:
		velocity.x = dir * speed
	_face(dir)
	_bob += 0.55
	visual.position = _visual_base + Vector2(0.0, sin(_bob) * 3.0)
	if not attacking and visual.sprite_frames and visual.sprite_frames.has_animation(&"walk"):
		visual.speed_scale = 1.35 * WALKER_SPEED_SCALE


func _popper_hop() -> void:
	var target := _hunt_x()
	var dir := signf(target - global_position.x)
	if dir == 0.0:
		dir = -1.0 if from_right else 1.0
	_face(dir)
	if is_on_floor():
		hop_cd -= get_physics_process_delta_time()
		if hop_cd <= 0.0:
			velocity.y = hop_impulse
			velocity.x = dir * speed
			hop_cd = 0.58 if arriving else clampf(0.62 - 0.008 * float(threat), 0.42, 0.62)
			if not attacking and visual.sprite_frames and visual.sprite_frames.has_animation(&"hop"):
				visual.play(&"hop")
		else:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * get_physics_process_delta_time())
	else:
		velocity.x = dir * speed * 0.85


func _warden_stomp(delta: float) -> void:
	var target := _hunt_x()
	var dir := signf(target - global_position.x)
	if dir == 0.0:
		dir = -1.0 if from_right else 1.0
	step_left -= delta
	if step_left <= 0.0:
		stepping = not stepping
		step_left = 0.46 if stepping else 0.32
		if stepping and is_on_floor() and not attacking:
			visual.scale = _flipped_scale(dir) * Vector2(1.06, 0.9)
	if stepping:
		velocity.x = dir * speed
		_face(dir)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_face(dir)
	if attacking:
		return
	visual.scale = visual.scale.lerp(_flipped_scale(dir), clampf(8.0 * delta, 0.0, 1.0))
	if visual.sprite_frames and visual.sprite_frames.has_animation(&"walk"):
		visual.speed_scale = 0.7 if stepping else 0.35


func play_attack() -> void:
	attacking = true
	attack_left = clampf(0.50 - 0.008 * float(threat), 0.34, 0.50)
	if visual and visual.sprite_frames and visual.sprite_frames.has_animation(&"attack"):
		visual.play(&"attack")
		visual.speed_scale = _atk_scale
	flash = maxf(flash, 0.08)
	if telegraph:
		telegraph.visible = true
		telegraph.modulate = Color(1.0, 0.42, 0.28, 0.55)


func _on_visual_finished() -> void:
	if visual == null:
		return
	if visual.animation != &"attack":
		return
	if kind == Kind.POPPER and fuse >= 0.0:
		visual.play(&"attack")
		return
	attacking = false
	if telegraph and kind != Kind.POPPER:
		telegraph.visible = false
	_resume_move_anim()


func _resume_move_anim() -> void:
	if visual == null or visual.sprite_frames == null:
		return
	var anim := &"hop" if kind == Kind.POPPER else &"walk"
	if visual.sprite_frames.has_animation(anim):
		visual.play(anim)


func _try_climb_jump() -> void:
	## Climb junk / steps by jumping only. Do not snap Y to the pile surface.
	if dead or _climb_cd > 0.0 or not is_on_floor():
		return
	if not _needs_climb_jump():
		return
	var dir := signf(velocity.x)
	if dir == 0.0:
		dir = -1.0 if from_right else 1.0
	velocity.y = CLIMB_JUMP
	if absf(velocity.x) < speed * 0.35:
		velocity.x = dir * speed
	_climb_cd = 0.42


func _needs_climb_jump() -> bool:
	if _pile == null:
		return is_on_wall()
	var dir := signf(velocity.x)
	if dir == 0.0:
		dir = -1.0 if from_right else 1.0
	var ahead := _pile.surface_y_at(global_position.x + dir * CLIMB_LOOK, 40.0)
	if ahead < global_position.y - CLIMB_STEP:
		return true
	var v := _cache_volt()
	if v and v.is_on_floor() and v.global_position.y < global_position.y - 56.0:
		return true
	return is_on_wall()


func _face(dir: float) -> void:
	if absf(dir) < 0.01 or visual == null:
		return
	visual.flip_h = dir < 0.0
	var punch := Vector2(1.14, 0.88) if attacking else Vector2.ONE
	visual.scale = Vector2(absf(_base_scale.x), absf(_base_scale.y)) * punch


func _flipped_scale(_dir: float) -> Vector2:
	return Vector2(absf(_base_scale.x), absf(_base_scale.y))


func _tick_popper(delta: float) -> void:
	if fuse < 0.0:
		var v := _cache_volt()
		var near := v != null and global_position.distance_to(v.global_position) <= _fuse_near
		if near or hunt_time >= _fuse_hunt:
			fuse = 1.05
			play_attack()
			if telegraph:
				telegraph.visible = true
		return
	fuse -= delta
	var pulse := 1.0 + 0.07 * sin(Time.get_ticks_msec() * 0.028)
	visual.scale = _flipped_scale(-1.0) * pulse * Vector2(1.08, 0.92)
	visual.modulate = Color(1.0, 0.72 + 0.28 * (1.0 - clampf(fuse / 1.05, 0.0, 1.0)), 0.55)
	if telegraph:
		telegraph.scale = Vector2.ONE * (1.15 + (1.05 - fuse) * 0.55)
		telegraph.modulate.a = 0.35 + 0.4 * (1.0 - clampf(fuse / 1.05, 0.0, 1.0))
	if fuse <= 0.0:
		exploded.emit(self)
		_die()


func _tick_warden(delta: float) -> void:
	slam_cd -= delta
	if slam_cd > 0.35:
		if telegraph and not attacking:
			telegraph.visible = false
		return
	if telegraph:
		telegraph.visible = true
		telegraph.modulate = Color(1.0, 0.35, 0.3, 0.55)
	if slam_cd <= 0.0:
		play_attack()
		slammed.emit(self)
		slam_cd = 1.85
		if telegraph:
			telegraph.visible = false


func can_contact() -> bool:
	return not dead and contact_cd <= 0.0


func mark_contact() -> void:
	contact_cd = 0.85
	if kind == Kind.SCOUT:
		play_attack()
