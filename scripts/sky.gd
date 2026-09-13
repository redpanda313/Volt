extends Node2D
class_name ClimbSky

@export var height_t: float = 0.0:
	set(value):
		height_t = clampf(value, 0.0, 1.0)
		_apply_height()

var _backdrop: ColorRect
var _material: ShaderMaterial
var _stars: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 13
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.size = Vector2(720, 3600)
	_backdrop.position = Vector2(0, -2200)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.z_index = -2
	var shader := load("res://shaders/sky.gdshader") as Shader
	_material = ShaderMaterial.new()
	_material.shader = shader
	_backdrop.material = _material
	add_child(_backdrop)
	z_as_relative = true
	_stars.clear()
	for i in 70:
		_stars.append({
			"pos": Vector2(_rng.randf_range(10.0, 710.0), _rng.randf_range(-1800.0, 900.0)),
			"size": _rng.randf_range(1.1, 2.6),
			"tw": _rng.randf_range(0.0, TAU),
		})
	_apply_height()
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _apply_height() -> void:
	if _material:
		_material.set_shader_parameter("height_t", height_t)


func _draw() -> void:
	# Stars brighten toward space.
	var star_a := 0.25 + height_t * 0.7
	for star in _stars:
		var tw := 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.001 + star.tw))
		draw_circle(star.pos, star.size, Color(0.85, 0.95, 1.0, star_a * tw))
	# Moon / station glow.
	var moon := Vector2(560.0, 160.0 + height_t * 40.0)
	draw_circle(moon, 22.0, Color(0.82, 0.88, 1.0, 0.55 + height_t * 0.3))
	draw_circle(moon + Vector2(7, -4), 16.0, Color(0.05, 0.07, 0.14, 0.35))
	_draw_city()
	_draw_ground()


func _draw_city() -> void:
	var fade := 1.0 - height_t
	if fade <= 0.02:
		return
	var base_y := 980.0 + height_t * 220.0
	var col := Color(0.04, 0.035, 0.08, 0.92 * fade)
	var windows := Color(1.0, 0.72, 0.35, 0.35 * fade)
	var x := -20.0
	var i := 0
	while x < 740.0:
		var w := 36.0 + float((i * 17) % 40)
		var h := 70.0 + float((i * 31) % 120)
		draw_rect(Rect2(x, base_y - h, w, h), col)
		var wy := base_y - h + 10.0
		while wy < base_y - 12.0:
			var wx := x + 6.0
			while wx < x + w - 8.0:
				if ((i + int(wy)) % 3) != 0:
					draw_rect(Rect2(wx, wy, 4.0, 5.0), windows)
				wx += 10.0
			wy += 14.0
		x += w + 6.0
		i += 1


func _draw_ground() -> void:
	var y := 1008.0
	draw_rect(Rect2(-20, y, 760, 300), Color(0.06, 0.055, 0.10, 1.0))
	draw_rect(Rect2(-20, y, 760, 10), Color(0.18, 0.22, 0.34, 1.0))
	# Combat lane edge.
	draw_line(Vector2(40, 990), Vector2(680, 990), Color(0.24, 0.85, 1.0, 0.18), 2.0)
