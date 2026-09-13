extends Node2D
class_name Enemy

enum Kind { SCOUT, POPPER, WARDEN }

signal defeated(who: Enemy)
signal exploded(who: Enemy)
signal slammed(who: Enemy)

const KIND_SCORE := {
	Kind.SCOUT: 10,
	Kind.POPPER: 25,
	Kind.WARDEN: 40,
}

@onready var visual: Sprite2D = $Visual
@onready var telegraph: Node2D = $Telegraph

var kind: Kind = Kind.SCOUT
var hp: int = 1
var max_hp: int = 1
var speed: float = 280.0
var stop_x: float = 430.0
var hit_size: Vector2 = Vector2(120, 210)
var contact_range: float = 78.0
var contact_cd: float = 0.0
var fuse: float = -1.0
var slam_cd: float = 1.4
var arriving := true
var dead := false
var flash: float = 0.0


func setup(p_kind: Kind, spawn: Vector2, p_stop_x: float) -> void:
	kind = p_kind
	position = spawn
	stop_x = p_stop_x
	match kind:
		Kind.SCOUT:
			hp = 1
			speed = 310.0
			hit_size = Vector2(118, 200)
			contact_range = 74.0
			Art.fit_sprite(visual, Art.tex(Art.SCOUT_IDLE), 198.0, 0.46)
		Kind.POPPER:
			hp = 1
			speed = 175.0
			hit_size = Vector2(132, 186)
			contact_range = 96.0
			Art.fit_sprite(visual, Art.tex(Art.POPPER_IDLE), 186.0, 0.46)
		Kind.WARDEN:
			hp = 3
			speed = 96.0
			hit_size = Vector2(168, 236)
			contact_range = 110.0
			Art.fit_sprite(visual, Art.tex(Art.WARDEN_IDLE), 236.0, 0.46)
	max_hp = hp
	name = kind_name()
	if telegraph:
		telegraph.visible = false


func kind_name() -> String:
	match kind:
		Kind.SCOUT:
			return "Scout"
		Kind.POPPER:
			return "Popper"
		Kind.WARDEN:
			return "Warden"
	return "Bot"


func score_value() -> int:
	return int(KIND_SCORE[kind])


func contains_world_point(world: Vector2) -> bool:
	var local := to_local(world)
	var rect := Rect2(-hit_size * 0.5 + Vector2(0, -hit_size.y * 0.35), hit_size)
	return rect.has_point(local)


func hurt(amount: int = 1) -> bool:
	if dead:
		return false
	hp -= amount
	flash = 0.12
	if hp <= 0:
		_die()
		return true
	return false


func _die() -> void:
	dead = true
	defeated.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	if dead:
		return
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
		visual.modulate = Color(1.6, 1.6, 1.6) if flash > 0.0 else Color.WHITE
	if contact_cd > 0.0:
		contact_cd = maxf(0.0, contact_cd - delta)
	if arriving:
		position.x = move_toward(position.x, stop_x, speed * delta)
		if is_equal_approx(position.x, stop_x):
			arriving = false
			if kind == Kind.POPPER:
				fuse = 1.05
				if telegraph:
					telegraph.visible = true
	else:
		if kind == Kind.SCOUT:
			position.x = move_toward(position.x, stop_x - 80.0, speed * 0.35 * delta)
		elif kind == Kind.POPPER:
			_tick_popper(delta)
		elif kind == Kind.WARDEN:
			_tick_warden(delta)


func _tick_popper(delta: float) -> void:
	if fuse < 0.0:
		return
	fuse -= delta
	if not visual.has_meta("base_scale"):
		visual.set_meta("base_scale", visual.scale)
	var pulse := 1.0 + 0.07 * sin(Time.get_ticks_msec() * 0.028)
	visual.scale = (visual.get_meta("base_scale") as Vector2) * pulse
	visual.modulate = Color(1.0, 0.72 + 0.28 * (1.0 - clampf(fuse / 1.05, 0.0, 1.0)), 0.55)
	if telegraph:
		telegraph.scale = Vector2.ONE * (1.15 + (1.05 - fuse) * 0.55)
		telegraph.modulate.a = 0.35 + 0.4 * (1.0 - clampf(fuse / 1.05, 0.0, 1.0))
	if fuse <= 0.0:
		exploded.emit(self)
		_die()


func _tick_warden(delta: float) -> void:
	slam_cd -= delta
	if slam_cd > 0.35:
		if telegraph:
			telegraph.visible = false
		return
	if telegraph:
		telegraph.visible = true
		telegraph.modulate = Color(1.0, 0.35, 0.3, 0.55)
	if slam_cd <= 0.0:
		slammed.emit(self)
		slam_cd = 1.85
		if telegraph:
			telegraph.visible = false


func can_contact() -> bool:
	return not dead and contact_cd <= 0.0


func mark_contact() -> void:
	contact_cd = 0.85
