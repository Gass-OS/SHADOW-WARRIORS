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
