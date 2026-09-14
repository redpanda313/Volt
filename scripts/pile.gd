extends Node2D
class_name RobotPile

## Killed bots shatter. Loose top-layer chunks can be dashed; a full layer welds and lifts the floor.
## Beat 6: denser night6 junk + micro fill. Foreground props live on ForegroundJunk.

signal layer_completed(layer_index: int, playable_y: float)

const LAYER_HEIGHT := 54.0
const FILL_COUNT := 12
const BASE_FLOOR := 1000.0
const MAX_PIECES := 110
const MAX_MICRO := 42
const PHYSICS_PER_KILL := 9
const MICRO_PER_KILL := 8
const FG_PER_KILL := 2

var completed_layers: int = 0
var _pieces: Array[DebrisPiece] = []
var _micros: Array[Sprite2D] = []
var _fg: ForegroundJunk


func _ready() -> void:
	add_to_group("pile")


func bind_foreground(fg: ForegroundJunk) -> void:
	_fg = fg


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


func seed_floor() -> void:
	var floor_y := playable_y()
	var kinds := ["scout", "popper", "warden"]
	for i in 8:
		var kind := kinds[i % 3]
		var chunks := Art.debris_chunks(kind)
		if chunks.is_empty():
			continue
		var tex: Texture2D = chunks[i % chunks.size()]
		var x := 70.0 + float(i) * 78.0 + randf_range(-14.0, 14.0)
		var pos := Vector2(clampf(x, 48.0, 672.0), floor_y - randf_range(4.0, 16.0))
		var piece := DebrisPiece.spawn(self, tex, pos, 70.0)
		piece.rest_on_floor()
		_pieces.append(piece)
	_sprinkle_micro(Vector2(360.0, floor_y), 14)
	if _fg:
		_fg.seed_props(floor_y)


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
	var drop: Array[Texture2D] = []
	for texture in chunks:
		drop.append(texture)
	_shuffle_tex(drop)
	var n := mini(PHYSICS_PER_KILL, drop.size())
	if n < PHYSICS_PER_KILL and drop.size() >= 1:
		while drop.size() < PHYSICS_PER_KILL:
			drop.append(drop[randi() % n])
		n = PHYSICS_PER_KILL
	for i in n:
		var jitter := Vector2(randf_range(-22.0, 22.0), randf_range(-28.0, 10.0))
		var piece := DebrisPiece.spawn(self, drop[i], origin + jitter, 70.0)
		var dir := Vector2(randf_range(-0.8, 0.95), randf_range(-1.25, -0.2)).normalized()
		piece.burst(dir * randf_range(200.0, 400.0))
		_pieces.append(piece)
	_sprinkle_micro(origin, MICRO_PER_KILL)
	if _fg:
		for _i in FG_PER_KILL:
			_fg.toss(origin, playable_y())
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
		if not piece.counts_for_layer:
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
	_lift_decor(-LAYER_HEIGHT)
	layer_completed.emit(completed_layers, playable_y())


func _lift_decor(delta_y: float) -> void:
	for spr in _micros:
		if spr != null and is_instance_valid(spr):
			spr.position.y += delta_y
	if _fg:
		_fg.lift(delta_y)


func _sprinkle_micro(origin: Vector2, amount: int) -> void:
	var micros := Art.night6_micro_frames()
	if micros.is_empty():
		return
	var floor_y := playable_y()
	for _i in amount:
		_prune_micro()
		if _micros.size() >= MAX_MICRO:
			var oldest := _micros[0]
			_micros.remove_at(0)
			if oldest != null and is_instance_valid(oldest):
				oldest.queue_free()
		var tex: Texture2D = micros[randi() % micros.size()]
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = true
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var long_side := maxf(float(tex.get_width()), float(tex.get_height()))
		var fit := 22.0 / maxf(long_side, 1.0)
		spr.scale = Vector2(fit, fit) * randf_range(0.78, 1.2)
		spr.rotation = randf_range(-0.55, 0.55)
		spr.z_index = -1 if randf() < 0.6 else 1
		spr.position = Vector2(
			clampf(origin.x + randf_range(-130.0, 130.0), 36.0, 684.0),
			floor_y - randf_range(2.0, 22.0)
		)
		add_child(spr)
		_micros.append(spr)


func _shuffle_tex(list: Array[Texture2D]) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var tmp: Texture2D = list[i]
		list[i] = list[j]
		list[j] = tmp


func _prune() -> void:
	var live: Array[DebrisPiece] = []
	for piece in _pieces:
		if piece != null and is_instance_valid(piece):
			live.append(piece)
	_pieces = live
	while _pieces.size() > MAX_PIECES:
		var oldest := _pieces[0]
		_pieces.remove_at(0)
		if oldest and is_instance_valid(oldest):
			oldest.queue_free()


func _prune_micro() -> void:
	var live: Array[Sprite2D] = []
	for spr in _micros:
		if spr != null and is_instance_valid(spr):
			live.append(spr)
	_micros = live
