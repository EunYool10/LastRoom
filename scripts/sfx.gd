extends Node
## 효과음과 반복음

const LOOPS := ["amb", "hum", "flies", "spray", "scrub"]
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _streams := {}
var _loops := {}
var volume := 0.8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(14):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	for n in LOOPS:
		var s: AudioStreamWAV = (load("res://assets/sfx/loop_%s.wav" % n) as AudioStreamWAV).duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate) - 1
		var p := AudioStreamPlayer.new()
		p.stream = s
		p.volume_db = -80.0
		add_child(p)
		_loops[n] = {"p": p, "level": 0.0, "target": 0.0}


func _stream(n: String) -> AudioStream:
	if not _streams.has(n):
		_streams[n] = load("res://assets/sfx/%s.wav" % n)
	return _streams[n]


func play(n: String, vol := 1.0, pitch := 1.0) -> void:
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _stream(n)
	p.volume_db = linear_to_db(max(0.0001, vol))
	p.pitch_scale = pitch
	p.play()


func step() -> void:
	play("step%d" % (randi() % 3), 0.55, randf_range(0.9, 1.1))


func breath(strength: float, inhale: bool) -> void:
	var n := ("breath_in%d" if inhale else "breath_out%d") % (randi() % 2)
	play(n, 0.25 + strength * 0.5, randf_range(0.95, 1.05))


func set_loop(n: String, level: float) -> void:
	if _loops.has(n):
		_loops[n].target = level


func stop_loops() -> void:
	for n in _loops:
		_loops[n].target = 0.0


func set_master(v: float) -> void:
	volume = clamp(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(max(0.0001, volume)))
	AudioServer.set_bus_mute(0, volume <= 0.001)


func _process(dt: float) -> void:
	for n in _loops:
		var L: Dictionary = _loops[n]
		L.level = move_toward(L.level, L.target, dt * 2.5)
		var p: AudioStreamPlayer = L.p
		if L.level > 0.002:
			if not p.playing:
				p.play()
			p.volume_db = linear_to_db(L.level)
		elif p.playing:
			p.stop()
