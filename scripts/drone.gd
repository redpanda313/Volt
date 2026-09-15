extends Node2D
class_name CarrierDrone

## Night8 ferry. Carries one powerup across the 9:16 view. Collect on contact / tap.

signal collected(drone: CarrierDrone, kind: Powerup.Kind)

const SPEED := 212.0
const BOB := 7.0
const MAGNET_RANGE := 280.0
const MAGNET_PULL := 190.0
const EXIT_PAD := 90.0

var kind: Powerup.Kind = Powerup.Kind.SHIELD
var taken := false
var vel_x := SPEED
var _lane_y := 0.0
var _sprite: AnimatedSprite2D
var _payload: Sprite2D
var _life := 6.5
var _drop_left := 0.0


static func spawn(parent: Node, p_kind: Powerup.Kind, from_right: bool, lane_y: float) -> CarrierDrone:
	var drone := CarrierDrone.new()
	parent.add_child(drone)
	drone.kind = p_kind
	drone.vel_x = -SPEED if from_right else SPEED
	drone._lane_y = lane_y
	var start_x := 770.0 if from_right else -50.0
	drone.global_position = Vector2(start_x, lane_y)
	drone._build()
	return drone


func _build() -> void:
	z_index = 8
	add_to_group("drones")
	name = "Drone_%s" % Powerup.id_of(kind)
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Visual"
	var fly := Art.drone_frames()
	if not fly.is_empty():
		Art.fit_animated(_sprite, fly, 92.0, 0.0, &"fly", 8.0, true)
		_sprite.position = Vector2.ZERO
	var drop := Art.night8_drone_drop_tex()
	if drop and _sprite.sprite_frames:
		Art.fill_animation(_sprite.sprite_frames, &"drop", [drop], 8.0, false)
	_sprite.flip_h = vel_x < 0.0
	add_child(_sprite)
	_payload = Sprite2D.new()
	_payload.name = "Cargo"
	var cargo := Art.powerup_tex(int(kind))
	if cargo:
		Art.fit_sprite(_payload, cargo, 56.0, 0.0)
	_payload.position = Vector2(0.0, 40.0)
	add_child(_payload)
	queue_redraw()


func _draw() -> void:
	if taken:
		return
	var tint := Powerup.tint(kind)
	draw_circle(Vector2(0.0, 40.0), 22.0, Color(tint.r, tint.g, tint.b, 0.18))
	draw_line(Vector2(0.0, 10.0), Vector2(0.0, 28.0), Color(0.75, 0.88, 1.0, 0.55), 2.0)


func payload_position() -> Vector2:
	if _payload and is_instance_valid(_payload):
		return _payload.global_position
	return global_position + Vector2(0.0, 40.0)


func contains_world_point(world: Vector2) -> bool:
	var local := to_local(world)
	return Rect2(Vector2(-46.0, -40.0), Vector2(92.0, 100.0)).has_point(local)


func take() -> Powerup.Kind:
	if taken:
		return kind
	taken = true
	_drop_left = 0.28
	_life = 1.35
	if _payload:
		_payload.visible = false
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"drop"):
		_sprite.play(&"drop")
	queue_redraw()
	collected.emit(self, kind)
	return kind


func park_at(pos: Vector2) -> void:
	global_position = pos
	_lane_y = pos.y


func attract_toward(target: Vector2, delta: float) -> void:
	if taken:
		return
	var to := target - global_position
	if to.length() > MAGNET_RANGE:
		return
	global_position = global_position.move_toward(target + Vector2(0.0, -36.0), MAGNET_PULL * delta)
	_lane_y = move_toward(_lane_y, target.y - 36.0, 90.0 * delta)


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if _drop_left > 0.0:
		_drop_left = maxf(0.0, _drop_left - delta)
		if _drop_left <= 0.0 and _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"fly"):
			_sprite.play(&"fly")
	var t := Time.get_ticks_msec() * 0.001
	var drift := 1.25 if taken else 1.0
	global_position.x += vel_x * drift * delta
	if not taken:
		global_position.y = _lane_y + sin(t * 3.2) * BOB
	if global_position.x < -EXIT_PAD or global_position.x > 720.0 + EXIT_PAD:
		queue_free()
