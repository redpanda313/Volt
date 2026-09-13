extends CanvasLayer
class_name HUD

## Night-2 chrome hooks. Swap ChromeTop / ChromeMeter textures when Sable slices again.
## Sources: art/night2/hud/hud_top.png, hud_meter.png, hud_portrait_9x16.png, hud_elements_sheet.png
## No joystick. No ATTACK button.

signal restart_pressed
signal upgrade_picked(id: String)

var _score: Label
var _level: Label
var _height: Label
var _meter: ProgressBar
var _hearts: HBoxContainer
var _hint: Label
var _toast: Label
var _level_up: Control
var _game_over: Control
var _over_body: Label
var _chrome_top: TextureRect
var _chrome_meter: TextureRect
var _best := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_chrome_top = TextureRect.new()
	_chrome_top.name = "ChromeTop"
	_chrome_top.texture = Art.hud_tex(Art.HUD_TOP)
	_chrome_top.position = Vector2(16, 10)
	_chrome_top.size = Vector2(688, 84)
	_chrome_top.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chrome_top.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_chrome_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_chrome_top)

	_chrome_meter = TextureRect.new()
	_chrome_meter.name = "ChromeMeter"
	_chrome_meter.texture = Art.hud_tex(Art.HUD_METER)
	_chrome_meter.position = Vector2(8, 108)
	_chrome_meter.size = Vector2(148, 236)
	_chrome_meter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chrome_meter.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_chrome_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_chrome_meter)

	_score = _label(Vector2(56, 22), 36, Color(0.96, 0.98, 1.0))
	_score.name = "ScoreLabel"
	_score.size = Vector2(400, 50)
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(_score)

	_level = _label(Vector2(548, 26), 28, Color(0.95, 0.98, 1.0))
	_level.name = "LevelLabel"
	_level.size = Vector2(80, 42)
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_level)

	_height = _label(Vector2(200, 102), 18, Color(0.55, 0.86, 1.0, 0.95))
	_height.name = "HeightLabel"
	_height.size = Vector2(280, 26)
	_height.text = "0 m   GROUND"
	root.add_child(_height)

	_meter = ProgressBar.new()
	_meter.name = "HeightFill"
	_meter.position = Vector2(24, 168)
	_meter.size = Vector2(18, 148)
	_meter.min_value = 0
	_meter.max_value = 400
	_meter.value = 0
	_meter.show_percentage = false
	_meter.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.08, 0.16, 0.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.28, 0.62, 1.0, 0.55)
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_left = 6
	fill.corner_radius_bottom_right = 6
	_meter.add_theme_stylebox_override("background", bg)
	_meter.add_theme_stylebox_override("fill", fill)
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_meter)

	_hearts = HBoxContainer.new()
	_hearts.name = "Hearts"
	_hearts.position = Vector2(520, 100)
	_hearts.add_theme_constant_override("separation", 7)
	_hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hearts)
	set_hp(3)

	_hint = _label(Vector2(36, 1188), 18, Color(0.92, 0.97, 1.0, 0.92))
	_hint.name = "Hint"
	_hint.size = Vector2(648, 56)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.text = "Tap a bot   ·   Swipe any direction to dash"
	root.add_child(_hint)

	_toast = _label(Vector2(160, 248), 26, Color(1, 0.92, 0.45))
	_toast.name = "Toast"
	_toast.size = Vector2(400, 40)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.12, 0.85))
	_toast.add_theme_constant_override("outline_size", 4)
	_toast.text = ""
	root.add_child(_toast)

	_level_up = _build_level_up()
	root.add_child(_level_up)

	_game_over = _build_game_over()
	root.add_child(_game_over)

	set_score(0)
	set_climb_level(1)


func _label(pos: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func set_score(value: int) -> void:
	_score.text = "%08d" % value


func set_climb_level(level: int) -> void:
	_level.text = "%02d" % clampi(level, 1, 99)


func set_height(meters: float) -> void:
	var band := "GROUND"
	if meters >= 280.0:
		band = "SPACE"
	elif meters >= 200.0:
		band = "ORBIT"
	elif meters >= 120.0:
		band = "SKY"
	elif meters >= 50.0:
		band = "PEAK"
	_height.text = "%d m   %s" % [int(meters), band]
	_meter.value = meters


func set_hp(hp: int) -> void:
	for child in _hearts.get_children():
		child.queue_free()
	for i in 3:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(18, 18)
		pip.color = Color(0.24, 0.94, 1.0) if i < hp else Color(0.18, 0.2, 0.28, 0.55)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hearts.add_child(pip)


func fade_hint() -> void:
	if _hint == null:
		return
	var tween := create_tween()
	tween.tween_property(_hint, "modulate:a", 0.0, 0.6).set_delay(6.5)


func toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_toast, "modulate:a", 0.0, 0.35).set_delay(0.9)


func show_level_up() -> void:
	_level_up.visible = true


func hide_modals() -> void:
	_level_up.visible = false
	_game_over.visible = false


func show_game_over(score: int, height_m: float, best: int) -> void:
	_best = best
	_over_body.text = "Score  %d\nHeight  %d m\nBest  %d" % [score, int(height_m), best]
	_game_over.visible = true


func _build_level_up() -> Control:
	var wrap := _modal("LEVEL UP", "The pile hits a thermal. Pick a beat.")
	var col := wrap.get_node("Panel/VBox") as VBoxContainer
	col.add_child(_choice_button("Arc Lash", "Swings also clip a nearby bot.", "arc"))
	col.add_child(_choice_button("Afterimage", "Longer dash. More i-frames.", "dodge"))
	wrap.visible = false
	return wrap


func _build_game_over() -> Control:
	var wrap := _modal("GAME OVER", "")
	var col := wrap.get_node("Panel/VBox") as VBoxContainer
	_over_body = Label.new()
	_over_body.add_theme_font_size_override("font_size", 26)
	_over_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_over_body.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	col.add_child(_over_body)
	var restart := _choice_button("Restart", "Same climb. New pile.", "restart")
	col.add_child(restart)
	wrap.visible = false
	return wrap


func _modal(title: String, subtitle: String) -> Control:
	var wrap := Control.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.08, 0.72)
	wrap.add_child(dim)
	var panel := Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(70, 340)
	panel.size = Vector2(580, 520)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.16, 0.96)
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.corner_radius_bottom_left = 22
	sb.corner_radius_bottom_right = 22
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.24, 0.94, 1.0, 0.45)
	panel.add_theme_stylebox_override("panel", sb)
	wrap.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.position = Vector2(28, 28)
	vbox.size = Vector2(524, 464)
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	var h := Label.new()
	h.text = title
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 40)
	h.add_theme_color_override("font_color", Color(0.24, 0.94, 1.0))
	vbox.add_child(h)
	if subtitle != "":
		var s := Label.new()
		s.text = subtitle
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.add_theme_font_size_override("font_size", 18)
		s.add_theme_color_override("font_color", Color(0.78, 0.82, 0.92))
		vbox.add_child(s)
	return wrap


func _choice_button(title: String, blurb: String, id: String) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [title, blurb]
	button.custom_minimum_size = Vector2(0, 96)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.16, 0.2, 0.34, 1)
	n.corner_radius_top_left = 14
	n.corner_radius_top_right = 14
	n.corner_radius_bottom_left = 14
	n.corner_radius_bottom_right = 14
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.22, 0.42, 0.55, 1)
	button.add_theme_stylebox_override("normal", n)
	button.add_theme_stylebox_override("hover", h)
	button.add_theme_stylebox_override("pressed", h)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(func () -> void:
		if id == "restart":
			restart_pressed.emit()
		else:
			upgrade_picked.emit(id)
	)
	return button
