extends Node2D
class_name RobotPile

## Defeated bots stack under Volt and sell the climb.

const MAX_VISIBLE := 8


func add_bot(texture: Texture2D, kind_scale: float) -> void:
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var th := float(texture.get_height())
	var fit: float = (120.0 * kind_scale) / maxf(th, 1.0)
	sprite.scale = Vector2(fit, fit)
	var count := get_child_count()
	sprite.position = Vector2(randf_range(-40.0, 42.0), -6.0 + count * 12.0)
	sprite.rotation = randf_range(-0.18, 0.18)
	sprite.modulate = Color(0.62, 0.68, 0.82, 0.92)
	sprite.z_index = -1
	add_child(sprite)
	if get_child_count() > MAX_VISIBLE:
		get_child(0).queue_free()
