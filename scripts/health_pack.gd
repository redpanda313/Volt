extends Node2D
class_name HealthPack

## Night5 pickup. Rule lives in PLAYTEST.md: every 3rd kill + every Warden, one on screen.

const LIFE := 10.0

var life := LIFE
var _rest_y := 0.0
var _sprite: AnimatedSprite2D


static func spawn(parent: Node, pos: Vector2, floor_y: float) -> HealthPack:
	var pack := HealthPack.new()
	parent.add_child(pack)
	pack.global_position = Vector2(clampf(pos.x, 64.0, 656.0), minf(pos.y, floor_y - 22.0))
	pack._rest_y = pack.global_position.y
	pack._build()
	return pack


func _build() -> void:
	z_index = 6
	add_to_group("health_packs")
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Visual"
	var frames := Art.health_pack_frames()
	if not frames.is_empty():
		Art.fit_animated(_sprite, frames, 56.0, 0.0, &"idle", 6.0, true)
		_sprite.position = Vector2.ZERO
	add_child(_sprite)


func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var t := Time.get_ticks_msec() * 0.001
	global_position.y = _rest_y + sin(t * 3.4) * 5.0
	modulate.a = 1.0 if life > 1.2 else maxf(0.25, life / 1.2)


func attract_toward(target: Vector2, delta: float) -> void:
	var to := target - global_position
	if to.length() > 220.0:
		return
	global_position = global_position.move_toward(target, 160.0 * delta)
	_rest_y = move_toward(_rest_y, target.y - 20.0, 80.0 * delta)
