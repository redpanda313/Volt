extends Node

## Night-4 on-model run/dash. Night-3 idle / attack / hurt + bots. Night-2 debris / HUD. Night-1 fallbacks.

const SLICE_DIR := "res://art/night1/slices/"
const NIGHT2_IDLE_DIR := "res://art/night2/slices/volt_idle/"
const NIGHT2_DEBRIS := "res://art/night2/slices/debris/"
const NIGHT3_VOLT := "res://art/night3/slices/volt/"
const NIGHT3_BOTS := "res://art/night3/slices/bots/"
const NIGHT4_VOLT := "res://art/night4/slices/volt/"

const HUD_TOP := "res://art/night2/hud/hud_top.png"
const HUD_METER := "res://art/night2/hud/hud_meter.png"
const HUD_PORTRAIT := "res://art/night2/hud/hud_portrait_9x16.png"
const HUD_SHEET := "res://art/night2/hud/hud_elements_sheet.png"

## Beat 3 was 0.81 (0.90 × 0.90). Beat 4 shrinks ~15% more: 0.81 * 0.85.
const ACTOR_SCALE := 0.6885

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


func hud_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func sequence_frames(dir: String, prefixes: Array[String], max_n: int = 8) -> Array[Texture2D]:
	for prefix in prefixes:
		var frames: Array[Texture2D] = []
		for i in range(1, max_n + 1):
			var found: Texture2D = null
			for path in [
				"%s%s%02d.png" % [dir, prefix, i],
				"%s%s%d.png" % [dir, prefix, i],
			]:
				if not ResourceLoader.exists(path):
					continue
				var texture := load(path) as Texture2D
				if texture:
					found = texture
					break
			if found == null:
				break
			frames.append(found)
		if frames.size() >= 1:
			return frames
	return []


func _volt_dir_frames(root: String, anim: String) -> Array[Texture2D]:
	var folder := "knockback" if anim == "hurt" else anim
	var dir := "%s%s/" % [root, folder]
	return sequence_frames(dir, [
		"%s_" % folder,
		"%s_" % anim,
		"volt_%s_" % folder,
		"volt_%s_" % anim,
	], 8)


func volt_idle_frames() -> Array[Texture2D]:
	var night3 := _volt_dir_frames(NIGHT3_VOLT, "idle")
	if not night3.is_empty():
		return night3
	var night4 := _volt_dir_frames(NIGHT4_VOLT, "idle")
	if not night4.is_empty():
		return night4
	var frames: Array[Texture2D] = []
	for i in range(1, 5):
		var path := "%svolt_idle_%02d.png" % [NIGHT2_IDLE_DIR, i]
		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			if texture:
				frames.append(texture)
	if frames.is_empty():
		var fallback := tex(VOLT_IDLE)
		if fallback:
			frames.append(fallback)
	return frames


## Night4 dash is the on-model run/dash. Dedicated run/ wins if Sable drops it.
## Night3 dash is off-model and is never used here.
func volt_travel_frames() -> Array[Texture2D]:
	var night4_run := _volt_dir_frames(NIGHT4_VOLT, "run")
	if not night4_run.is_empty():
		return night4_run
	var night4_dash := _volt_dir_frames(NIGHT4_VOLT, "dash")
	if not night4_dash.is_empty():
		return night4_dash
	var dodge := tex(VOLT_DODGE)
	var frames: Array[Texture2D] = []
	if dodge:
		frames.append(dodge)
	return frames


func has_night4_travel() -> bool:
	return not _volt_dir_frames(NIGHT4_VOLT, "run").is_empty() \
		or not _volt_dir_frames(NIGHT4_VOLT, "dash").is_empty()


func volt_frames(anim: String) -> Array[Texture2D]:
	if anim == "run" or anim == "dash":
		return volt_travel_frames()
	var night3 := _volt_dir_frames(NIGHT3_VOLT, anim)
	if not night3.is_empty():
		return night3
	var night4 := _volt_dir_frames(NIGHT4_VOLT, anim)
	if not night4.is_empty():
		return night4
	var frames: Array[Texture2D] = []
	if anim == "idle":
		return []
	if anim == "attack":
		var attack := tex(VOLT_ATTACK)
		if attack:
			frames.append(attack)
	elif anim == "hurt":
		var hurt := tex(VOLT_DODGE)
		if hurt:
			frames.append(hurt)
	return frames


func bot_frames(kind_name: String) -> Array[Texture2D]:
	var move := "hop" if kind_name == "popper" else "walk"
	var dir := "%s%s/" % [NIGHT3_BOTS, kind_name]
	var frames := sequence_frames(dir, [
		"%s_%s_" % [kind_name, move],
		"%s_" % move,
		"%s_idle_" % kind_name,
	], 8)
	if frames.is_empty():
		var fallback := tex("%s_idle" % kind_name)
		if fallback:
			frames.append(fallback)
	return frames


func debris_chunks(kind_name: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for i in range(1, 9):
		var path := "%s%s/%s_chunk_%02d.png" % [NIGHT2_DEBRIS, kind_name, kind_name, i]
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		if texture == null:
			continue
		if texture.get_width() * texture.get_height() < 900:
			continue
		frames.append(texture)
	return frames


func fill_animation(frames: SpriteFrames, anim: StringName, textures: Array[Texture2D], fps: float, loop: bool) -> void:
	if not frames.has_animation(anim):
		frames.add_animation(anim)
	frames.clear(anim)
	frames.set_animation_loop_mode(anim, SpriteFrames.LOOP_LINEAR if loop else SpriteFrames.LOOP_NONE)
	frames.set_animation_speed(anim, fps)
	for texture in textures:
		frames.add_frame(anim, texture)


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


func fit_animated(sprite: AnimatedSprite2D, textures: Array[Texture2D], target_height: float, feet_bias := 0.44, anim: StringName = &"idle", fps: float = 7.0, loop := true) -> void:
	if sprite == null or textures.is_empty():
		return
	var frames := sprite.sprite_frames
	if frames == null:
		frames = SpriteFrames.new()
		frames.clear_all()
	if frames.has_animation(&"default") and anim != &"default":
		frames.rename_animation(&"default", anim)
	fill_animation(frames, anim, textures, fps, loop)
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var th := float(textures[0].get_height())
	var fit: float = target_height / maxf(th, 1.0)
	sprite.scale = Vector2(fit, fit)
	sprite.position = Vector2(0.0, -target_height * feet_bias)
	sprite.animation = anim
	if loop:
		sprite.play(anim)
