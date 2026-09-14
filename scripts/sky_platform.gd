extends StaticBody2D
class_name SkyPlatform

## Short night7 sky pad. One-way: pass from below, stand on top.

var half_w := 70.0
var stand_y := 0.0
var kind_id := ""

var _sprite: Sprite2D
var _col: CollisionShape2D


static func spawn(parent: Node, texture: Texture2D, pos: Vector2, kind: String = "") -> SkyPlatform:
	var pad := SkyPlatform.new()
	parent.add_child(pad)
	pad.kind_id = kind
	pad._build(texture)
	pad.global_position = pos
	pad.stand_y = pos.y
	return pad


func _build(texture: Texture2D) -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(1, true)
	z_index = -1
	var native_w := 168.0
	var native_h := 28.0
	if texture:
		native_w = float(texture.get_width())
		native_h = float(texture.get_height())
	var target_w := clampf(native_w, 108.0, 236.0)
	var sc := target_w / maxf(native_w, 1.0)
	var drawn_w := native_w * sc
	var drawn_h := native_h * sc
	half_w = drawn_w * 0.39
	_sprite = Sprite2D.new()
	_sprite.name = "Visual"
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if texture:
		_sprite.texture = texture
	_sprite.scale = Vector2(sc, sc)
	# Origin is the stand surface; art hangs below with a 3px lip.
	_sprite.position = Vector2(0.0, drawn_h * 0.5 - 3.0)
	add_child(_sprite)
	_col = CollisionShape2D.new()
	_col.name = "Deck"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(maxf(72.0, drawn_w * 0.78), 18.0)
	_col.shape = rect
	_col.position = Vector2(0.0, 9.0)
	_col.one_way_collision = true
	_col.one_way_collision_margin = 4.0
	add_child(_col)
	if texture == null:
		queue_redraw()


func _draw() -> void:
	if _sprite != null and _sprite.texture != null:
		return
	draw_rect(Rect2(-half_w, 0.0, half_w * 2.0, 16.0), Color(0.42, 0.78, 0.98, 0.88))
	draw_rect(Rect2(-half_w, 0.0, half_w * 2.0, 3.0), Color(0.85, 0.95, 1.0, 0.95))


func set_active(on: bool) -> void:
	visible = on
	if _col:
		_col.disabled = not on
	if on:
		stand_y = global_position.y


func is_one_way() -> bool:
	return _col != null and _col.one_way_collision
