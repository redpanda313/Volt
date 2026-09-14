extends RigidBody2D
class_name DebrisPiece

## One break-apart chunk. Loose until the current layer solidifies.

var solid := false
var settled := false
var counts_for_layer := true
var _settle_time := 0.0
var _sprite: Sprite2D


static func spawn(parent: Node, texture: Texture2D, pos: Vector2, fit_px: float = 64.0) -> DebrisPiece:
	var piece := DebrisPiece.new()
	parent.add_child(piece)
	piece.global_position = pos
	piece._build(texture, fit_px)
	return piece


func _build(texture: Texture2D, fit_px: float = 64.0) -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(4, true)
	can_sleep = true
	mass = 0.7
	gravity_scale = 1.15
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.14
	mat.friction = 0.88
	physics_material_override = mat
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var long_side := maxf(float(texture.get_width()), float(texture.get_height()))
	var fit := fit_px / maxf(long_side, 1.0)
	_sprite.scale = Vector2(fit, fit)
	add_child(_sprite)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(
		maxf(14.0, float(texture.get_width()) * fit * 0.72),
		maxf(14.0, float(texture.get_height()) * fit * 0.72)
	)
	col.shape = rect
	add_child(col)


func burst(impulse: Vector2) -> void:
	settled = false
	solid = false
	freeze = false
	sleeping = false
	apply_central_impulse(impulse)


func knock(direction: Vector2) -> void:
	if solid:
		return
	var dir := direction
	if dir.length() < 0.1:
		dir = Vector2.RIGHT
	settled = false
	_settle_time = 0.0
	freeze = false
	sleeping = false
	collision_layer = 0
	set_collision_layer_value(4, true)
	apply_central_impulse(dir.normalized() * 340.0 + Vector2(0, -90))


func solidify() -> void:
	solid = true
	settled = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(1, true)
	sleeping = true
	modulate = Color(0.78, 0.84, 0.94)


func _physics_process(delta: float) -> void:
	if solid or freeze:
		return
	if linear_velocity.length() < 40.0 and absf(angular_velocity) < 1.4:
		_settle_time += delta
		if _settle_time >= 0.30:
			_mark_settled()
	else:
		_settle_time = 0.0


func rest_on_floor() -> void:
	_mark_settled()


func _mark_settled() -> void:
	if solid:
		return
	settled = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	collision_layer = 0
	set_collision_layer_value(1, true)
