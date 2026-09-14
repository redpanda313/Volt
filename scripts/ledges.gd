extends Node2D
class_name SkyLedges

## Night7 sky pads. Random X/Y in climb bounds. Mountain rise can swallow a pad.

const COUNT := 12
const MIN_X := 96.0
const MAX_X := 624.0

var _pads: Array[SkyPlatform] = []
var _pile: RobotPile
var _rng := RandomNumberGenerator.new()


func bind_pile(pile: RobotPile) -> void:
	_pile = pile


func seed_sky() -> void:
	_rng.randomize()
	var frames := Art.night7_platform_frames()
	if frames.is_empty():
		frames = Art.placeholder_platform_frames()
	var names := Art.night7_platform_names()
	var floor_y := RobotPile.BASE_FLOOR
	if _pile:
		floor_y = _pile.playable_y()
	## Height bands the play area reaches as the pile lifts.
	var bands: Array[Vector2] = [
		Vector2(100.0, 170.0),
		Vector2(190.0, 280.0),
		Vector2(300.0, 420.0),
		Vector2(450.0, 620.0),
		Vector2(680.0, 900.0),
	]
	var placed: Array[Vector2] = []
	for i in COUNT:
		var tex: Texture2D = frames[i % frames.size()]
		var band: Vector2 = bands[i % bands.size()]
		var pos := _roll_pos(floor_y, band, placed)
		if pos == Vector2.ZERO:
			continue
		placed.append(pos)
		var kind := names[i % names.size()] if not names.is_empty() else "pad"
		_pads.append(SkyPlatform.spawn(self, tex, pos, kind))


func _roll_pos(floor_y: float, band: Vector2, placed: Array[Vector2]) -> Vector2:
	for _try in 16:
		var x := _rng.randf_range(MIN_X, MAX_X)
		var y := floor_y - _rng.randf_range(band.x, band.y)
		var ok := true
		for other in placed:
			if absf(other.x - x) < 118.0 and absf(other.y - y) < 70.0:
				ok = false
				break
		if ok:
			return Vector2(x, y)
	return Vector2.ZERO


func live_above(floor_y: float) -> Array[SkyPlatform]:
	var out: Array[SkyPlatform] = []
	for pad in _pads:
		if pad == null or not is_instance_valid(pad):
			continue
		if pad.visible and pad.stand_y < floor_y - 28.0:
			out.append(pad)
	return out


func pick_spawn(floor_y: float, cam_y: float) -> Vector2:
	var cands := live_above(floor_y)
	if cands.is_empty():
		return Vector2.ZERO
	var near: Array[SkyPlatform] = []
	for pad in cands:
		if pad.stand_y > cam_y - 480.0 and pad.stand_y < cam_y + 520.0:
			near.append(pad)
	var pool := near if not near.is_empty() else cands
	var pad: SkyPlatform = pool[_rng.randi() % pool.size()]
	var x := pad.global_position.x + _rng.randf_range(-pad.half_w * 0.35, pad.half_w * 0.35)
	return Vector2(clampf(x, 64.0, 656.0), pad.stand_y - 1.0)


func pad_count() -> int:
	return _pads.size()


func _physics_process(_delta: float) -> void:
	if _pile == null:
		return
	var floor_y := _pile.playable_y()
	for pad in _pads:
		if pad == null or not is_instance_valid(pad):
			continue
		pad.set_active(pad.global_position.y < floor_y - 30.0)
