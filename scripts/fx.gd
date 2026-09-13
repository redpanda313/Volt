extends CanvasLayer
class_name Juice

## Premium hit juice: camera trauma, damage pulse, impact bursts, punchy SFX.

const SHAKE_PX := 52.0
const TRAUMA_DECAY := 1.05

var camera: Camera2D
var world: Node2D
var trauma: float = 0.0
var _pulse: ColorRect
var _hitstop_until_ms: int = 0
var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pulse = ColorRect.new()
	_pulse.name = "DamagePulse"
	_pulse.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pulse.color = Color(1, 1, 1, 0)
	add_child(_pulse)
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_players.append(player)
	_build_sfx()


func bind(cam: Camera2D, world_node: Node2D) -> void:
	camera = cam
	world = world_node


func _process(delta: float) -> void:
	if _hitstop_until_ms > 0 and Time.get_ticks_msec() >= _hitstop_until_ms:
		Engine.time_scale = 1.0
		_hitstop_until_ms = 0
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - TRAUMA_DECAY * delta)
		var mag := pow(trauma, 1.2) * SHAKE_PX
		if camera:
			camera.offset = Vector2(randf_range(-mag, mag), randf_range(-mag, mag))
	elif camera:
		camera.offset = Vector2.ZERO


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func hitstop(seconds: float = 0.08) -> void:
	Engine.time_scale = 0.12
	_hitstop_until_ms = Time.get_ticks_msec() + int(seconds * 1000.0)


func pulse(color: Color, peak_a: float = 0.55, fade: float = 0.18) -> void:
	_pulse.color = Color(color.r, color.g, color.b, peak_a)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_pulse, "color:a", 0.0, fade)


func damage_pulse() -> void:
	pulse(Color(1.0, 0.08, 0.16), 0.78, 0.34)
	add_trauma(1.0)
	hitstop(0.09)
	play("hurt")


func attack_punch(world_pos: Vector2) -> void:
	add_trauma(0.78)
	hitstop(0.07)
	pulse(Color(0.65, 0.98, 1.0), 0.42, 0.20)
	burst(world_pos, Color(0.35, 0.95, 1.0), 34)
	burst(world_pos, Color(1.0, 0.95, 0.55), 16)
	ring(world_pos, Color(0.45, 1.0, 1.0, 0.95), 22.0, 190.0)
	_streak(world_pos)
	play("slash")
	play("hit")


func kill_burst(world_pos: Vector2) -> void:
	add_trauma(0.48)
	burst(world_pos, Color(1.0, 0.82, 0.35), 28)
	ring(world_pos, Color(1.0, 0.7, 0.25, 0.85), 20.0, 170.0)
	play("shatter")


func explode_burst(world_pos: Vector2) -> void:
	add_trauma(0.8)
	pulse(Color(1.0, 0.45, 0.15), 0.4, 0.2)
	burst(world_pos, Color(1.0, 0.55, 0.2), 34)
	play("explode")


func slam_burst(world_pos: Vector2) -> void:
	add_trauma(0.7)
	pulse(Color(0.7, 0.2, 0.15), 0.32, 0.16)
	burst(world_pos, Color(0.95, 0.35, 0.28), 20)
	play("slam")


func dash_whoosh() -> void:
	add_trauma(0.18)
	play("dash")


func layer_thump() -> void:
	add_trauma(0.42)
	pulse(Color(0.4, 0.75, 1.0), 0.22, 0.2)
	play("layer")


func burst(world_pos: Vector2, color: Color, amount: int = 18) -> void:
	if world == null:
		return
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 0.96
	particles.amount = amount
	particles.lifetime = 0.48
	particles.emitting = false
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 780)
	particles.initial_velocity_min = 260.0
	particles.initial_velocity_max = 620.0
	particles.scale_amount_min = 3.2
	particles.scale_amount_max = 7.5
	particles.color = color
	particles.z_index = 8
	world.add_child(particles)
	particles.global_position = world_pos
	particles.emitting = true
	var tween := world.create_tween()
	tween.tween_interval(0.55)
	tween.tween_callback(particles.queue_free)


func ring(world_pos: Vector2, color: Color, start_r: float, end_r: float) -> void:
	if world == null:
		return
	var poly := Polygon2D.new()
	poly.color = color
	poly.z_index = 7
	poly.polygon = _ring_pts(start_r)
	world.add_child(poly)
	poly.global_position = world_pos
	var tween := world.create_tween()
	tween.tween_method(func(r: float) -> void:
		if is_instance_valid(poly):
			poly.polygon = _ring_pts(r)
	, start_r, end_r, 0.22)
	tween.parallel().tween_property(poly, "modulate:a", 0.0, 0.22)
	tween.tween_callback(poly.queue_free)


func ghost(from: Node2D, color: Color = Color(0.45, 0.95, 1.0, 0.45)) -> void:
	if from == null or world == null:
		return
	var snap := from.duplicate() as Node2D
	if snap == null:
		return
	world.add_child(snap)
	snap.global_position = from.global_position
	snap.modulate = color
	var tween := world.create_tween()
	tween.tween_property(snap, "modulate:a", 0.0, 0.22)
	tween.tween_callback(snap.queue_free)


func _streak(world_pos: Vector2) -> void:
	if world == null:
		return
	var line := Line2D.new()
	line.width = 10.0
	line.default_color = Color(0.55, 1.0, 1.0, 0.95)
	line.z_index = 9
	line.points = PackedVector2Array([Vector2(-70, 18), Vector2(90, -40)])
	world.add_child(line)
	line.global_position = world_pos
	var tween := world.create_tween()
	tween.tween_property(line, "width", 0.0, 0.16)
	tween.parallel().tween_property(line, "modulate:a", 0.0, 0.16)
	tween.tween_callback(line.queue_free)


func play(sfx_name: String) -> void:
	var stream: AudioStream = _streams.get(sfx_name) as AudioStream
	if stream == null:
		return
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.volume_db = 0.0
			player.play()
			return
	_players[0].stream = stream
	_players[0].play()


func _ring_pts(radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func _build_sfx() -> void:
	_streams["hit"] = _tone(920.0, 90, 0.72, 0.22, 1.8)
	_streams["slash"] = _sweep(420.0, 1700.0, 120, 0.55, 0.08)
	_streams["dash"] = _tone(180.0, 140, 0.4, 0.72, 1.2)
	_streams["hurt"] = _tone(78.0, 180, 0.85, 0.45, 2.2)
	_streams["explode"] = _tone(62.0, 260, 0.9, 0.85, 1.6)
	_streams["slam"] = _tone(48.0, 220, 0.95, 0.35, 2.4)
	_streams["shatter"] = _sweep(1400.0, 280.0, 160, 0.5, 0.55)
	_streams["layer"] = _sweep(220.0, 640.0, 200, 0.45, 0.05)


func _tone(freq: float, ms: int, vol: float, noise: float, punch: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * ms / 1000.0)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var env := pow(1.0 - float(i) / float(maxi(n - 1, 1)), punch)
		var sine := sin(TAU * freq * t)
		var nse := randf() * 2.0 - 1.0
		var sample := (sine * (1.0 - noise) + nse * noise) * env * vol
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _wav(data, rate)


func _sweep(f0: float, f1: float, ms: int, vol: float, noise: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * ms / 1000.0)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var u := float(i) / float(maxi(n - 1, 1))
		var freq := lerpf(f0, f1, u)
		phase += TAU * freq / float(rate)
		var env := pow(1.0 - u, 1.35)
		var sample := (sin(phase) * (1.0 - noise) + (randf() * 2.0 - 1.0) * noise) * env * vol
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _wav(data, rate)


func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
