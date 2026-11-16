extends Node

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var mix_rate := 22050.0
var voices: Array = []
var beat_timer := 0.0
var beat_step := 0
var combat_music_active := false

func _ready() -> void:
	player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = mix_rate
	gen.buffer_length = 0.1
	player.stream = gen
	add_child(player)
	player.play()
	playback = player.get_stream_playback()

func play_tone(freq: float, dur: float, amp: float = 0.25, slide: float = 0.0, wave: int = 0) -> void:
	voices.append({"freq": freq, "dur": dur, "t": 0.0, "amp": amp, "slide": slide, "wave": wave, "phase": 0.0})

func play_hit(heavy: bool = false) -> void:
	play_tone(110.0 if heavy else 185.0, 0.18 if heavy else 0.11, 0.38 if heavy else 0.28, -75.0, 1)

func play_parry() -> void:
	play_tone(920.0, 0.24, 0.30, 380.0, 0)
	play_tone(1380.0, 0.18, 0.22, 160.0, 0)

func play_whoosh() -> void:
	play_tone(320.0, 0.09, 0.12, -190.0, 0)

func play_ability(kind: String) -> void:
	# Distinct tone combo per ability kind, built on play_tone.
	match kind:
		"fire":
			play_tone(220.0, 0.30, 0.34, 420.0, 1)
			play_tone(110.0, 0.35, 0.30, -40.0, 0)
		"shadow":
			play_tone(880.0, 0.16, 0.20, -620.0, 0)
			play_tone(440.0, 0.22, 0.18, -300.0, 0)
		"counter":
			play_tone(660.0, 0.14, 0.30, 0.0, 0)
			play_tone(990.0, 0.20, 0.26, 120.0, 0)
		"blink":
			play_tone(1240.0, 0.12, 0.20, -900.0, 0)
			play_tone(620.0, 0.18, 0.20, -380.0, 0)
		"quake":
			play_tone(70.0, 0.42, 0.42, -25.0, 1)
			play_tone(140.0, 0.25, 0.28, -60.0, 0)
		"sand":
			play_tone(300.0, 0.35, 0.22, 260.0, 1)
			play_tone(520.0, 0.28, 0.16, 180.0, 0)
		"slam":
			play_tone(60.0, 0.45, 0.45, -18.0, 1)
			play_tone(180.0, 0.30, 0.30, -90.0, 0)
		"lunge":
			play_tone(500.0, 0.14, 0.26, 420.0, 0)
			play_tone(760.0, 0.18, 0.22, 260.0, 0)
		"cleave":
			play_tone(130.0, 0.34, 0.36, -55.0, 1)
			play_tone(260.0, 0.22, 0.24, 120.0, 0)
		"tide":
			play_tone(420.0, 0.26, 0.26, 300.0, 0)
			play_tone(210.0, 0.34, 0.24, -120.0, 0)
		_:
			play_tone(520.0, 0.20, 0.26, 240.0, 0)

func _process(delta: float) -> void:
	if playback == null and player != null and player.playing:
		playback = player.get_stream_playback()
	if combat_music_active:
		beat_timer += delta
		if beat_timer >= 0.22:
			beat_timer -= 0.22
			if beat_step % 4 == 0:
				play_tone(88.0, 0.13, 0.16, -32.0, 0)
			if beat_step % 4 == 2 or beat_step % 8 == 7:
				play_tone(215.0, 0.06, 0.09, -40.0, 1)
			beat_step += 1
	if playback == null:
		return
	var frames := playback.get_frames_available()
	for i in frames:
		var sample := 0.0
		for v_idx in range(voices.size() - 1, -1, -1):
			var v: Dictionary = voices[v_idx]
			var f: float = maxf(35.0, float(v["freq"]) + float(v["slide"]) * (float(v["t"]) / float(v["dur"])))
			v["phase"] = float(v["phase"]) + f / mix_rate
			var env: float = maxf(0.0, 1.0 - (float(v["t"]) / float(v["dur"])))
			var ph: float = float(v["phase"])
			var s: float = sin(ph * TAU) if int(v["wave"]) == 0 else (2.0 * fmod(ph, 1.0) - 1.0)
			sample += s * float(v["amp"]) * env
			v["t"] = float(v["t"]) + 1.0 / mix_rate
			if float(v["t"]) >= float(v["dur"]):
				voices.remove_at(v_idx)
		sample = clampf(sample, -0.85, 0.85)
		playback.push_frame(Vector2(sample, sample))
