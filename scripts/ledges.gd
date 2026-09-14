extends Node2D
class_name SkyLedges

## Beat 8: night7 pads spawn as the climb rises. Sparse vertical gap so two
## pads are very unlikely to share a 1280px portrait view.

const MIN_X := 96.0
const MAX_X := 624.0
const MIN_VERT := 1240.0
const MAX_VERT := 1860.0
const FIRST_MIN := 640.0
const FIRST_MAX := 1100.0
const AHEAD := 2400.0
const RETIRE_BELOW := 1700.0
const MAX_LIVE := 6
const VIEW_H := 1280.0

var _pads: Array[SkyPlatform] = []
var _pile: RobotPile
var _camera: Camera2D
var _rng := RandomNumberGenerator.new()
var _next_stand_y := 0.0
var _frame_i := 0
var _seeded := false


func bind_pile(pile: RobotPile) -> void:
	_pile = pile


func bind_camera(cam: Camera2D) -> void:
	_camera = cam


func seed_sky() -> void:
	_rng.randomize()
	_pads.clear()
	_frame_i = 0
	var floor_y := _floor_y()
	_next_stand_y = floor_y - _rng.randf_range(FIRST_MIN, FIRST_MAX)
	_seeded = true
	_spawn_next()
	ensure_ahead()


func ensure_ahead() -> void:
	if not _seeded:
		return
	var top := _view_top() - AHEAD
	var guard := 0
	while _next_stand_y > top and _live_visible() < MAX_LIVE and guard < 8:
		_spawn_next()
		guard += 1


func _spawn_next() -> void:
	var floor_y := _floor_y()
	if _next_stand_y >= floor_y - 48.0:
		_next_stand_y = floor_y - _rng.randf_range(MIN_VERT, MAX_VERT)
	var frames := Art.night7_platform_frames()
	if frames.is_empty():
		frames = Art.placeholder_platform_frames()
	if frames.is_empty():
		_next_stand_y -= _rng.randf_range(MIN_VERT, MAX_VERT)
		return
	var names := Art.night7_platform_names()
	var tex: Texture2D = frames[_frame_i % frames.size()]
	var kind := names[_frame_i % names.size()] if not names.is_empty() else "pad"
	var x := _rng.randf_range(MIN_X, MAX_X)
	var pos := Vector2(x, _next_stand_y)
	_pads.append(SkyPlatform.spawn(self, tex, pos, kind))
	_frame_i += 1
	_next_stand_y -= _rng.randf_range(MIN_VERT, MAX_VERT)


func _floor_y() -> float:
	if _pile:
		return _pile.playable_y()
	return RobotPile.BASE_FLOOR


func _view_top() -> float:
	if _camera:
		return _camera.position.y - VIEW_H * 0.5
	return _floor_y() - VIEW_H


func _live_visible() -> int:
	var n := 0
	for pad in _pads:
		if pad != null and is_instance_valid(pad) and pad.visible:
			n += 1
	return n


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


func min_vertical_gap() -> float:
	return MIN_VERT


func live_stand_ys() -> Array[float]:
	var ys: Array[float] = []
	for pad in _pads:
		if pad == null or not is_instance_valid(pad) or not pad.visible:
			continue
		ys.append(pad.stand_y)
	return ys


func _physics_process(_delta: float) -> void:
	if _pile == null:
		return
	var floor_y := _pile.playable_y()
	var cam_y := _camera.position.y if _camera else floor_y
	var keep: Array[SkyPlatform] = []
	for pad in _pads:
		if pad == null or not is_instance_valid(pad):
			continue
		pad.set_active(pad.global_position.y < floor_y - 30.0)
		if not pad.visible or pad.stand_y > cam_y + RETIRE_BELOW:
			pad.queue_free()
			continue
		keep.append(pad)
	_pads = keep
	ensure_ahead()
