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

@onready var visual: AnimatedSprite2D = $Visual
@onready var telegraph: Node2D = $Telegraph

var kind: Kind = Kind.SCOUT
var hp: int = 1
var max_hp: int = 1
var speed: float = 280.0
var stop_x: float = 430.0
var hit_size: Vector2 = Vector2(100, 170)
var contact_range: float = 70.0
var contact_cd: float = 0.0
var fuse: float = -1.0
var slam_cd: float = 1.4
var arriving := true
var dead := false
var flash: float = 0.0
var knock_speed: float = 320.0
var knock_lift: float = -120.0
var hop_cd: float = 0.0
var hop_impulse: float = 0.0
var step_left: float = 0.0
var stepping := true
var _pile: RobotPile
var _base_scale := Vector2.ONE
var _visual_base := Vector2.ZERO
var _bob: float = 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_GROUNDED
	up_direction = Vector2.UP
	floor_snap_length = 22.0
	floor_max_angle = deg_to_rad(70.0)
	floor_constant_speed = true
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)
	_pile = get_tree().get_first_node_in_group("pile") as RobotPile


func setup(p_kind: Kind, spawn: Vector2, p_stop_x: float) -> void:
	kind = p_kind
	global_position = spawn
	stop_x = p_stop_x
	var s := Art.ACTOR_SCALE
	match kind:
		Kind.SCOUT:
			hp = 1
			speed = 390.0
			hit_size = Vector2(105, 170)
			contact_range = 96.0
			knock_speed = 340.0
			knock_lift = -140.0
			Art.fit_animated(visual, Art.bot_frames("scout"), 198.0 * s, 0.46, &"walk", 12.0, true)
		Kind.POPPER:
			hp = 1
			speed = 210.0
			hit_size = Vector2(122, 162)
			contact_range = 122.0
			knock_speed = 300.0
			knock_lift = -520.0
			hop_impulse = -390.0
			hop_cd = 0.12
			Art.fit_animated(visual, Art.bot_frames("popper"), 186.0 * s, 0.46, &"hop", 10.0, true)
		Kind.WARDEN:
			hp = 3
			speed = 78.0
			hit_size = Vector2(146, 202)
			contact_range = 126.0
			knock_speed = 640.0
			knock_lift = -70.0
			step_left = 0.36
			stepping = true
			Art.fit_animated(visual, Art.bot_frames("warden"), 236.0 * s, 0.46, &"walk", 6.0, true)
	max_hp = hp
	name = kind_name()
	_base_scale = visual.scale
	_visual_base = visual.position
	_tune_collider()
	if telegraph:
		telegraph.visible = false
	_face(-1.0)


func _tune_collider() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)
	var cap := CapsuleShape2D.new()
	match kind:
		Kind.SCOUT:
			cap.radius = 16.0
			cap.height = 68.0
			col.position = Vector2(0, -34)
		Kind.POPPER:
			cap.radius = 22.0
			cap.height = 52.0
			col.position = Vector2(0, -26)
		Kind.WARDEN:
			cap.radius = 20.0
			cap.height = 84.0
			col.position = Vector2(0, -42)
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

	velocity.y += GRAVITY * delta
	_locomote(delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, MIN_X, MAX_X)
	_stick_to_pile()
	if arriving and absf(global_position.x - stop_x) <= 10.0:
		arriving = false
		if kind == Kind.POPPER:
			fuse = 1.05
			if telegraph:
				telegraph.visible = true
	if not arriving:
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


func _scout_walk(_delta: float) -> void:
	var target := stop_x if arriving else stop_x - 56.0
	var dir := signf(target - global_position.x)
	if absf(global_position.x - target) < 6.0:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		dir = -1.0
	else:
		velocity.x = dir * speed
	_face(dir)
	_bob += 0.55
	visual.position = _visual_base + Vector2(0.0, sin(_bob) * 3.0)
	if visual.sprite_frames and visual.sprite_frames.has_animation(&"walk"):
		visual.speed_scale = 1.35


func _popper_hop() -> void:
	var target := stop_x if arriving else stop_x
	var dir := signf(target - global_position.x)
	if absf(global_position.x - target) < 8.0:
		dir = -1.0
	_face(dir)
	if is_on_floor():
		hop_cd -= get_physics_process_delta_time()
		if hop_cd <= 0.0:
			velocity.y = hop_impulse
			velocity.x = dir * speed
			hop_cd = 0.40 if arriving else 0.48
			if visual.sprite_frames and visual.sprite_frames.has_animation(&"hop"):
				visual.play(&"hop")
		else:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * get_physics_process_delta_time())
	else:
		velocity.x = dir * speed * 0.85


func _warden_stomp(delta: float) -> void:
	var target := stop_x if arriving else stop_x - 28.0
	var dir := signf(target - global_position.x)
	if absf(global_position.x - target) < 8.0:
		dir = -1.0
	step_left -= delta
	if step_left <= 0.0:
		stepping = not stepping
		step_left = 0.38 if stepping else 0.26
		if stepping and is_on_floor():
			visual.scale = _flipped_scale(dir) * Vector2(1.06, 0.9)
	if stepping:
		velocity.x = dir * speed
		_face(dir)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	visual.scale = visual.scale.lerp(_flipped_scale(dir), clampf(8.0 * delta, 0.0, 1.0))
	if visual.sprite_frames and visual.sprite_frames.has_animation(&"walk"):
		visual.speed_scale = 0.7 if stepping else 0.35


func _stick_to_pile() -> void:
	if _pile == null:
		return
	var surf := _pile.surface_y_at(global_position.x)
	if global_position.y > surf + 14.0:
		global_position.y = surf


func _face(dir: float) -> void:
	if absf(dir) < 0.01:
		return
	var face := 1.0 if dir >= 0.0 else -1.0
	visual.scale = Vector2(absf(_base_scale.x) * face, _base_scale.y)


func _flipped_scale(dir: float) -> Vector2:
	var face := 1.0 if dir >= 0.0 else -1.0
	return Vector2(absf(_base_scale.x) * face, _base_scale.y)


func _tick_popper(delta: float) -> void:
	if fuse < 0.0:
		return
	fuse -= delta
	var pulse := 1.0 + 0.07 * sin(Time.get_ticks_msec() * 0.028)
	visual.scale = _flipped_scale(-1.0) * pulse
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
		if telegraph:
			telegraph.visible = false
		return
	if telegraph:
		telegraph.visible = true
		telegraph.modulate = Color(1.0, 0.35, 0.3, 0.55)
	if slam_cd <= 0.0:
		slammed.emit(self)
		slam_cd = 1.85
		if telegraph:
			telegraph.visible = false


func can_contact() -> bool:
	return not dead and contact_cd <= 0.0


func mark_contact() -> void:
	contact_cd = 0.85
