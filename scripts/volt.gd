extends Node2D
class_name Volt

signal died
signal hp_changed(current: int)

const MAX_HP := 3
const ATTACK_SECS := 0.22
const DODGE_SECS := 0.40
const DODGE_SECS_UP := 0.70
const HURT_IFRAMES := 0.55

@onready var visual: Node2D = $Visual
@onready var idle: Sprite2D = $Visual/Idle
@onready var attack: Sprite2D = $Visual/Attack
@onready var dodge: Sprite2D = $Visual/Dodge

var hp: int = MAX_HP
var invuln: float = 0.0
var pose_left: float = 0.0
var facing: float = 1.0
var arc_lash: bool = false
var long_dodge: bool = false
var rest_x: float = 230.0


func _ready() -> void:
	rest_x = position.x
	_apply_art()
	_show_idle()


func _apply_art() -> void:
	Art.fit_sprite(idle, Art.tex(Art.VOLT_IDLE), 252.0, 0.46)
	Art.fit_sprite(attack, Art.tex(Art.VOLT_ATTACK), 236.0, 0.46)
	Art.fit_sprite(dodge, Art.tex(Art.VOLT_DODGE), 228.0, 0.46)
	idle.position.x = 8.0
	attack.position.x = -6.0
	dodge.position.x = 16.0


func _process(delta: float) -> void:
	if invuln > 0.0:
		invuln = maxf(0.0, invuln - delta)
		modulate.a = 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.02))
	else:
		modulate.a = 1.0
	if pose_left > 0.0:
		pose_left = maxf(0.0, pose_left - delta)
		if pose_left <= 0.0:
			_show_idle()
			position.x = rest_x


func is_invulnerable() -> bool:
	return invuln > 0.0


func play_attack(toward: Vector2) -> void:
	facing = 1.0 if toward.x >= global_position.x else -1.0
	visual.scale.x = facing
	idle.visible = false
	dodge.visible = false
	attack.visible = true
	pose_left = ATTACK_SECS


func play_dodge(direction: Vector2) -> void:
	var secs := DODGE_SECS_UP if long_dodge else DODGE_SECS
	facing = 1.0 if direction.x >= 0.0 else -1.0
	visual.scale.x = facing
	idle.visible = false
	attack.visible = false
	dodge.visible = true
	pose_left = secs
	invuln = maxf(invuln, secs)
	var dash := 70.0 if long_dodge else 42.0
	position.x = rest_x + facing * dash
	var tween := create_tween()
	tween.tween_property(self, "position:x", rest_x, secs).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func take_hit() -> void:
	if is_invulnerable() or hp <= 0:
		return
	hp -= 1
	invuln = HURT_IFRAMES
	hp_changed.emit(hp)
	if hp <= 0:
		died.emit()


func _show_idle() -> void:
	idle.visible = true
	attack.visible = false
	dodge.visible = false
	visual.scale.x = 1.0
