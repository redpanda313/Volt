extends Node2D
class_name RobotPile

## Killed bots shatter. Loose top-layer chunks can be dashed; a full layer welds and lifts the floor.

signal layer_completed(layer_index: int, playable_y: float)

const LAYER_HEIGHT := 54.0
const FILL_COUNT := 8
const BASE_FLOOR := 1000.0
const MAX_PIECES := 72

var completed_layers: int = 0
var _pieces: Array[DebrisPiece] = []


func _ready() -> void:
	add_to_group("pile")


func playable_y() -> float:
	return BASE_FLOOR - float(completed_layers) * LAYER_HEIGHT


func surface_y_at(x: float, search_radius: float = 52.0) -> float:
	var y := playable_y()
	for piece in _pieces:
		if piece == null or not is_instance_valid(piece):
			continue
		if not piece.settled and not piece.solid:
			continue
		if absf(piece.global_position.x - x) > search_radius:
			continue
		var top := piece.global_position.y - 18.0
		if top < y:
			y = top
	return y


func shatter(enemy: Enemy) -> void:
	if enemy == null:
		return
	var kind := enemy.kind_name().to_lower()
	var chunks := Art.debris_chunks(kind)
	if chunks.is_empty():
		var fallback := Art.tex(Art.SCOUT_IDLE)
		if fallback:
			var one: Array[Texture2D] = []
			one.append(fallback)
			chunks = one
	var origin := enemy.global_position + Vector2(0.0, -enemy.hit_size.y * 0.35)
	for texture in chunks:
		var jitter := Vector2(randf_range(-18.0, 18.0), randf_range(-24.0, 8.0))
		var piece := DebrisPiece.spawn(self, texture, origin + jitter)
		var dir := Vector2(randf_range(-0.75, 0.9), randf_range(-1.2, -0.25)).normalized()
		piece.burst(dir * randf_range(210.0, 390.0))
		_pieces.append(piece)
	_prune()


func knock_top_layer(origin: Vector2, direction: Vector2) -> void:
	var band_top := playable_y() - LAYER_HEIGHT - 20.0
	var band_bot := playable_y() + 24.0
	for piece in _pieces:
		if piece == null or not is_instance_valid(piece) or piece.solid:
			continue
		if not piece.settled:
			continue
		if piece.global_position.y < band_top or piece.global_position.y > band_bot:
			continue
		if piece.global_position.distance_to(origin) > 140.0:
			continue
		piece.knock(direction)


func _physics_process(_delta: float) -> void:
	_try_complete_layer()


func _try_complete_layer() -> void:
	var band_top := playable_y() - LAYER_HEIGHT - 8.0
	var band_bot := playable_y() + 18.0
	var settled: Array[DebrisPiece] = []
	for piece in _pieces:
		if piece == null or not is_instance_valid(piece) or piece.solid:
			continue
		if not piece.settled:
			continue
		if piece.global_position.y >= band_top and piece.global_position.y <= band_bot:
			settled.append(piece)
	if settled.size() < FILL_COUNT:
		return
	var weld_y := playable_y() - LAYER_HEIGHT * 0.42
	for piece in settled:
		piece.global_position.y = weld_y + randf_range(-6.0, 8.0)
		piece.solidify()
	completed_layers += 1
	layer_completed.emit(completed_layers, playable_y())


func _prune() -> void:
	var live: Array[DebrisPiece] = []
	for piece in _pieces:
		if piece != null and is_instance_valid(piece):
			live.append(piece)
	_pieces = live
	while _pieces.size() > MAX_PIECES:
		var oldest := _pieces[0]
		_pieces.remove_at(0)
		if oldest and is_instance_valid(oldest) and oldest.solid:
			oldest.queue_free()
		elif oldest and is_instance_valid(oldest):
			oldest.queue_free()
