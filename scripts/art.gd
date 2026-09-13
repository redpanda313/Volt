extends Node

## Loads Sable night-1 slices. Swap PNG files in art/night1/slices/ to reskin.

const SLICE_DIR := "res://art/night1/slices/"

const VOLT_IDLE := "volt_idle"
const VOLT_ATTACK := "volt_attack"
const VOLT_DODGE := "volt_dodge"
const SCOUT_IDLE := "scout_idle"
const POPPER_IDLE := "popper_idle"
const WARDEN_IDLE := "warden_idle"


func tex(slice_name: String) -> Texture2D:
	var path := SLICE_DIR + slice_name + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("Missing night-1 slice: " + path)
	return null


func fit_sprite(sprite: Sprite2D, texture: Texture2D, target_height: float, feet_bias := 0.44) -> void:
	if sprite == null or texture == null:
		return
	sprite.texture = texture
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var th := float(texture.get_height())
	var fit: float = target_height / maxf(th, 1.0)
	sprite.scale = Vector2(fit, fit)
	sprite.position = Vector2(0.0, -target_height * feet_bias)
