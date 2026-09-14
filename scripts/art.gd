extends Node

## Night-7 sky one-way platforms (beat 8: sparse endless spawn, same frames).
## Night-6 denser debris / micro fill / foreground junk.
## Night-5 screw / attack-dash / bot attacks / packs / icons.
## Night-4 on-model run/dash. Night-3 idle / attack / hurt + bot walk/hop.
## Night-2 debris / HUD. Night-1 fallbacks.

const SLICE_DIR := "res://art/night1/slices/"
const NIGHT2_IDLE_DIR := "res://art/night2/slices/volt_idle/"
const NIGHT2_DEBRIS := "res://art/night2/slices/debris/"
const NIGHT3_VOLT := "res://art/night3/slices/volt/"
const NIGHT3_BOTS := "res://art/night3/slices/bots/"
const NIGHT4_VOLT := "res://art/night4/slices/volt/"
const NIGHT5_VOLT := "res://art/night5/slices/volt/"
const NIGHT5_BOTS := "res://art/night5/slices/bots/"
const NIGHT5_PICKUPS := "res://art/night5/pickups/"
const NIGHT5_ICONS := "res://art/night5/icons/"
const NIGHT6_DEBRIS := "res://art/night6/debris/"
const NIGHT6_FG := "res://art/night6/fg_junk/"
const NIGHT7_PLATFORMS := "res://art/night7/platforms/"
const NIGHT7_PLATFORM_FILES: Array[String] = [
	"01_catwalk.png",
	"02_tech_slab.png",
	"03_girder.png",
	"04_scrap.png",
	"05_cloud_tech.png",
	"06_step_pad.png",
]

const HUD_TOP := "res://art/night2/hud/hud_top.png"
const HUD_METER := "res://art/night2/hud/hud_meter.png"
const HUD_PORTRAIT := "res://art/night2/hud/hud_portrait_9x16.png"
const HUD_SHEET := "res://art/night2/hud/hud_elements_sheet.png"

## Beat 5 set 0.516375. Beat 6/7 lock size — do not shrink.
const ACTOR_SCALE := 0.516375

const VOLT_IDLE := "volt_idle"
const VOLT_ATTACK := "volt_attack"
const VOLT_DODGE := "volt_dodge"
const SCOUT_IDLE := "scout_idle"
const POPPER_IDLE := "popper_idle"
const WARDEN_IDLE := "warden_idle"

var _spin_cached := false
var _has_spin := false


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


## Night4 dash is the on-model swipe travel. Dedicated run/ wins if present.
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


## Night5 tap-attack travel. Distinct from jump-dash screw.
func volt_attack_dash_frames() -> Array[Texture2D]:
	var night5 := sequence_frames(NIGHT5_VOLT + "attack_dash/", [
		"attack_dash_",
		"dash_",
	], 8)
	if not night5.is_empty():
		return night5
	return volt_travel_frames()


func has_night5_attack_dash() -> bool:
	return not sequence_frames(NIGHT5_VOLT + "attack_dash/", ["attack_dash_", "dash_"], 8).is_empty()


## Night5 screw-attack spin. Empty until frames exist — do not invent art.
func volt_spin_frames() -> Array[Texture2D]:
	return sequence_frames(NIGHT5_VOLT + "screw_attack/", [
		"screw_",
		"screw_attack_",
		"spin_",
		"jump_dash_",
	], 8)


func has_night5_spin() -> bool:
	if _spin_cached:
		return _has_spin
	_has_spin = not volt_spin_frames().is_empty()
	_spin_cached = true
	return _has_spin


## Jump-dash clip. Night5 screw wins; else travel textures on the JumpDash node only.
func volt_jump_dash_frames() -> Array[Texture2D]:
	var night5 := volt_spin_frames()
	if not night5.is_empty():
		return night5
	return volt_travel_frames()


func volt_frames(anim: String) -> Array[Texture2D]:
	if anim == "run" or anim == "dash":
		return volt_travel_frames()
	if anim == "attack_dash":
		return volt_attack_dash_frames()
	if anim == "spin" or anim == "jump_dash" or anim == "screw":
		return volt_jump_dash_frames()
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


func bot_attack_frames(kind_name: String) -> Array[Texture2D]:
	var night5 := sequence_frames("%s%s_attack/" % [NIGHT5_BOTS, kind_name], [
		"%s_atk_" % kind_name,
		"%s_attack_" % kind_name,
		"atk_",
		"attack_",
	], 8)
	if not night5.is_empty():
		return night5
	var nested := sequence_frames("%s%s/attack/" % [NIGHT3_BOTS, kind_name], [
		"%s_attack_" % kind_name,
		"attack_",
	], 8)
	if not nested.is_empty():
		return nested
	var move := bot_frames(kind_name)
	if move.size() >= 3:
		var punch: Array[Texture2D] = []
		punch.append(move[1])
		punch.append(move[mini(2, move.size() - 1)])
		punch.append(move[move.size() - 1])
		punch.append(move[1])
		return punch
	return move


func health_pack_frames() -> Array[Texture2D]:
	var raw := sequence_frames(NIGHT5_PICKUPS, ["health_"], 4)
	if raw.size() >= 2:
		var ordered: Array[Texture2D] = []
		ordered.append(raw[1])
		if raw.size() >= 3:
			ordered.append(raw[2])
		ordered.append(raw[0])
		return ordered
	return raw


## Labeled sheet cells (1280×720). Individual upgrade_*.png slices are empty frames.
const UPGRADE_SHEET_RECTS: Array[Rect2i] = [
	Rect2i(686, 80, 164, 160),
	Rect2i(886, 80, 164, 160),
	Rect2i(1086, 80, 164, 160),
	Rect2i(686, 352, 164, 160),
	Rect2i(886, 352, 164, 160),
	Rect2i(1086, 352, 164, 160),
	Rect2i(392, 196, 200, 200),
]

var _upgrade_cache: Dictionary = {}
var _n6_scout: Array[Texture2D] = []
var _n6_popper: Array[Texture2D] = []
var _n6_warden: Array[Texture2D] = []
var _n6_kind_ready := false
var _n6_micro: Array[Texture2D] = []
var _n6_micro_ready := false
var _n6_fg: Array[Texture2D] = []
var _n6_fg_ready := false
var _n7_plats: Array[Texture2D] = []
var _n7_ready := false


func upgrade_icon(index: int) -> Texture2D:
	if index <= 0:
		return null
	if _upgrade_cache.has(index):
		return _upgrade_cache[index] as Texture2D
	var from_sheet := _upgrade_from_sheet(index)
	if from_sheet:
		_upgrade_cache[index] = from_sheet
		return from_sheet
	var path := "%supgrade_%02d.png" % [NIGHT5_ICONS, index]
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		_upgrade_cache[index] = tex
		return tex
	return null


func _upgrade_from_sheet(index: int) -> Texture2D:
	if index < 1 or index > UPGRADE_SHEET_RECTS.size():
		return null
	var sheet_path := NIGHT5_ICONS + "upgrades_sheet_labeled.png"
	if not ResourceLoader.exists(sheet_path):
		return null
	var sheet := load(sheet_path) as Texture2D
	if sheet == null:
		return null
	var img := sheet.get_image()
	if img == null:
		return null
	var rect: Rect2i = UPGRADE_SHEET_RECTS[index - 1]
	rect = rect.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if rect.size.x < 8 or rect.size.y < 8:
		return null
	var crop := img.get_region(rect)
	return ImageTexture.create_from_image(crop)


func night6_kind_junk(kind_name: String) -> Array[Texture2D]:
	if not _n6_kind_ready:
		_n6_scout = sequence_frames(NIGHT6_DEBRIS + "scout/", ["scout_junk_", "junk_"], 16)
		_n6_popper = sequence_frames(NIGHT6_DEBRIS + "popper/", ["popper_junk_", "junk_"], 16)
		_n6_warden = sequence_frames(NIGHT6_DEBRIS + "warden/", ["warden_junk_", "junk_"], 16)
		_n6_kind_ready = true
	match kind_name:
		"popper":
			return _n6_popper
		"warden":
			return _n6_warden
		_:
			return _n6_scout


func night6_micro_frames() -> Array[Texture2D]:
	if _n6_micro_ready:
		return _n6_micro
	_n6_micro = sequence_frames(NIGHT6_DEBRIS + "micro/", ["micro_"], 48)
	_n6_micro_ready = true
	return _n6_micro


func night6_fg_frames() -> Array[Texture2D]:
	if _n6_fg_ready:
		return _n6_fg
	_n6_fg = sequence_frames(NIGHT6_FG, ["fg_"], 17)
	_n6_fg_ready = true
	return _n6_fg


func has_night6_junk() -> bool:
	return night6_kind_junk("scout").size() >= 8


func has_night6_micro() -> bool:
	return night6_micro_frames().size() >= 24


func has_night6_fg() -> bool:
	return night6_fg_frames().size() >= 8


func night7_platform_names() -> Array[String]:
	var names: Array[String] = []
	for file_name in NIGHT7_PLATFORM_FILES:
		names.append(file_name.get_basename())
	return names


func night7_platform_frames() -> Array[Texture2D]:
	if _n7_ready:
		return _n7_plats
	_n7_plats.clear()
	for file_name in NIGHT7_PLATFORM_FILES:
		var path := NIGHT7_PLATFORMS + file_name
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		if texture:
			_n7_plats.append(texture)
	_n7_ready = true
	return _n7_plats


func has_night7_platforms() -> bool:
	return night7_platform_frames().size() >= 6


func placeholder_platform_frames() -> Array[Texture2D]:
	## Readable slab only. Not a Sable frame.
	var frames: Array[Texture2D] = []
	var img := Image.create(168, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.18, 0.42, 0.58, 0.92))
	for x in 168:
		img.set_pixel(x, 0, Color(0.75, 0.92, 1.0, 1.0))
		img.set_pixel(x, 1, Color(0.45, 0.78, 0.95, 1.0))
	frames.append(ImageTexture.create_from_image(img))
	return frames


func _night2_chunks(kind_name: String) -> Array[Texture2D]:
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


## Night6 kind junk first, then night2 chunks that still read. No invented frames.
func debris_chunks(kind_name: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for texture in night6_kind_junk(kind_name):
		frames.append(texture)
	for texture in _night2_chunks(kind_name):
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
