extends Node2D
class_name ForegroundJunk

## Night6 `fg_junk/` parallax layer. Sits in front of Volt / bots. No collision.

const SCROLL := 0.11
const MAX_BITS := 14
const FIT_H := 168.0

var _cam: Camera2D
var _rest_cam_y := 832.0
var _bits: Array[Sprite2D] = []


func _ready() -> void:
	z_index = 20
	z_as_relative = false


func bind_camera(cam: Camera2D) -> void:
	_cam = cam
	if cam:
		_rest_cam_y = cam.position.y


func _process(_delta: float) -> void:
	if _cam == null:
		return
	position.x = (_cam.position.x - 360.0) * SCROLL
	position.y = (_rest_cam_y - _cam.position.y) * SCROLL


func seed_props(floor_y: float) -> void:
	var frames := Art.night6_fg_frames()
	if frames.is_empty():
		return
	var spots: Array[Vector2] = [
		Vector2(92.0, floor_y + 30.0),
		Vector2(628.0, floor_y + 32.0),
		Vector2(44.0, floor_y + 10.0),
		Vector2(676.0, floor_y + 8.0),
		Vector2(118.0, floor_y - 200.0),
		Vector2(602.0, floor_y - 184.0),
	]
	var idxs: Array[int] = [0, 16, 4, 8, 6, 13]
	for i in spots.size():
		var tex: Texture2D = frames[mini(idxs[i], frames.size() - 1)]
		_place(tex, spots[i], 1.0)


func toss(origin: Vector2, floor_y: float) -> void:
	var frames := Art.night6_fg_frames()
	if frames.is_empty():
		return
	var tex: Texture2D = frames[randi() % frames.size()]
	var x := clampf(origin.x + randf_range(-70.0, 70.0), 36.0, 684.0)
	if x > 210.0 and x < 510.0:
		x = 78.0 if randf() < 0.5 else 642.0
	var rest := Vector2(x, floor_y + randf_range(12.0, 38.0))
	var spr := _place(tex, rest + Vector2(0.0, -90.0), randf_range(0.70, 0.96))
	if spr == null:
		return
	var tween := create_tween()
	tween.tween_property(spr, "position", rest, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func lift(delta_y: float) -> void:
	for bit in _bits:
		if bit != null and is_instance_valid(bit):
			bit.position.y += delta_y


func _place(texture: Texture2D, pos: Vector2, scale_mul: float) -> Sprite2D:
	if texture == null:
		return null
	_prune()
	if _bits.size() >= MAX_BITS:
		var oldest := _bits[0]
		_bits.remove_at(0)
		if oldest != null and is_instance_valid(oldest):
			oldest.queue_free()
	var spr := Sprite2D.new()
	spr.texture = texture
	spr.centered = true
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var th := float(texture.get_height())
	var fit := FIT_H / maxf(th, 1.0)
	spr.scale = Vector2(fit, fit) * scale_mul
	spr.position = pos
	add_child(spr)
	_bits.append(spr)
	return spr


func _prune() -> void:
	var live: Array[Sprite2D] = []
	for bit in _bits:
		if bit != null and is_instance_valid(bit):
			live.append(bit)
	_bits = live
