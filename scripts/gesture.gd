extends Node
class_name Gesture

## Tap vs swipe. Mouse and touch both work (web + editor + phones).
## Swipe L/R = move. Swipe up = jump. No joystick / attack button.

signal tapped(screen_pos: Vector2)
signal swiped_horizontal(direction: float)
signal swiped_up

const SWIPE_PX := 56.0
const UP_BIAS := 0.82

var _pressing := false
var _origin := Vector2.ZERO
var _did_swipe := false
var _last_emit_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin(touch.position)
		else:
			_end(touch.position)
	elif event is InputEventScreenDrag:
		_drag((event as InputEventScreenDrag).position)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			_begin(mouse.position)
		else:
			_end(mouse.position)
	elif event is InputEventMouseMotion and _pressing:
		_drag((event as InputEventMouseMotion).position)


func _begin(pos: Vector2) -> void:
	_pressing = true
	_origin = pos
	_did_swipe = false


func _drag(pos: Vector2) -> void:
	if not _pressing or _did_swipe:
		return
	if (pos - _origin).length() >= SWIPE_PX:
		_did_swipe = true
		_emit_swipe(pos)


func _end(pos: Vector2) -> void:
	if not _pressing:
		return
	_pressing = false
	if _did_swipe:
		return
	if (pos - _origin).length() >= SWIPE_PX:
		_emit_swipe(pos)
	elif _debounce():
		tapped.emit(pos)


func _emit_swipe(pos: Vector2) -> void:
	if not _debounce():
		return
	var delta := pos - _origin
	if delta.y < 0.0 and absf(delta.y) >= absf(delta.x) * UP_BIAS:
		swiped_up.emit()
	else:
		swiped_horizontal.emit(1.0 if delta.x >= 0.0 else -1.0)


func _debounce() -> bool:
	var now := Time.get_ticks_msec()
	if now - _last_emit_ms < 40:
		return false
	_last_emit_ms = now
	return true
