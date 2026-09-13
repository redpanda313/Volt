extends CanvasLayer
class_name HUD

signal restart_pressed
signal upgrade_picked(id: String)

var _score: Label
var _height: Label
var _meter: ProgressBar
var _hearts: HBoxContainer
var _hint: Label
var _toast: Label
var _level_up: Control
var _game_over: Control
var _over_body: Label
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

	_score = _label(Vector2(28, 22), 34, Color(0.95, 0.97, 1.0))
	_score.text = "0"
	root.add_child(_score)

	var title := _label(Vector2(28, 62), 16, Color(0.24, 0.94, 1.0, 0.85))
	title.text = "VOLT"
	root.add_child(title)

	_height = _label(Vector2(520, 28), 18, Color(0.78, 0.86, 1.0, 0.9))
	_height.size = Vector2(170, 28)
	_height.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_height.text = "0 m"
	root.add_child(_height)

	_meter = ProgressBar.new()
	_meter.position = Vector2(676, 120)
	_meter.size = Vector2(18, 720)
	_meter.min_value = 0
	_meter.max_value = 400
	_meter.value = 0
	_meter.show_percentage = false
	_meter.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.09, 0.16, 0.7)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.24, 0.94, 1.0, 0.85)
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8
	_meter.add_theme_stylebox_override("background", bg)
	_meter.add_theme_stylebox_override("fill", fill)
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_meter)

	_hearts = HBoxContainer.new()
	_hearts.position = Vector2(24, 92)
	_hearts.add_theme_constant_override("separation", 8)
	_hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hearts)
	set_hp(3)

	_hint = _label(Vector2(40, 1168), 22, Color(0.92, 0.97, 1.0, 0.92))
	_hint.size = Vector2(640, 48)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = "TAP to hit   ·   SWIPE to dodge"
	root.add_child(_hint)

	_toast = _label(Vector2(80, 240), 28, Color(1, 0.92, 0.45))
	_toast.size = Vector2(560, 40)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.text = ""
	root.add_child(_toast)

	_level_up = _build_level_up()
	root.add_child(_level_up)

	_game_over = _build_game_over()
	root.add_child(_game_over)


func _label(pos: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func set_score(value: int) -> void:
	_score.text = str(value)


func set_height(meters: float) -> void:
	_height.text = "%d m" % int(meters)
	_meter.value = meters


func set_hp(hp: int) -> void:
	for child in _hearts.get_children():
		child.queue_free()
	for i in 3:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(22, 22)
		pip.color = Color(0.24, 0.94, 1.0) if i < hp else Color(0.18, 0.2, 0.28, 0.8)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hearts.add_child(pip)


func fade_hint() -> void:
	if _hint == null:
		return
	var tween := create_tween()
	tween.tween_property(_hint, "modulate:a", 0.0, 0.6).set_delay(5.5)


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
	col.add_child(_choice_button("Afterimage", "Longer dodge. More i-frames.", "dodge"))
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
