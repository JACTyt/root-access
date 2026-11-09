extends Node
## All audio is synthesized at runtime. The drone gains layers as Trace rises;
## swap _fill_buffer for real stems later without touching callers.

const MIX_RATE := 22050.0
const BUFFER_SECONDS := 0.2
const BASS_HZ := 55.0
const PAD_HZ := 82.4
const PULSE_HZ := 220.0

var _player: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _intensity := 0.0
var _sounds := {}


func _ready() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = BUFFER_SECONDS
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	add_child(_player)
	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	_sounds = {
		"click": _tone(900.0, 0.04, 0.0),
		"chirp": _tone(1200.0, 0.14, 1400.0),
		"alarm": _tone(520.0, 0.5, -200.0),
		"win": _tone(440.0, 0.35, 440.0),
	}
	EventBus.trace_changed.connect(func(value: int, _previous: int): _intensity = value / 100.0)
	EventBus.threshold_crossed.connect(func(_t: int): play_sfx("alarm"))
	EventBus.settings_changed.connect(_apply_volume)
	_apply_volume()
	if DisplayServer.get_name() != "headless":
		_player.play()
		_playback = _player.get_stream_playback()


func _process(_delta: float) -> void:
	if _playback != null:
		_fill_buffer()


func play_sfx(sound: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	_sfx.stream = _sounds[sound]
	_sfx.play()


func _apply_volume() -> void:
	var db := linear_to_db(maxf(SaveManager.volume(), 0.001))
	_player.volume_db = db
	_sfx.volume_db = db


func _fill_buffer() -> void:
	for i in _playback.get_frames_available():
		_phase += 1.0 / MIX_RATE
		var sample := sin(TAU * BASS_HZ * _phase) * 0.14
		sample += sin(TAU * PAD_HZ * _phase) * 0.06 * clampf(_intensity * 4.0, 0.0, 1.0)
		if _intensity >= 0.5:
			var gate := 1.0 if fmod(_phase, 0.5) < 0.12 else 0.0
			sample += sin(TAU * PULSE_HZ * _phase) * 0.07 * gate
		if _intensity >= 0.75:
			sample += sin(TAU * PULSE_HZ * 1.5 * _phase) * 0.05 * (0.5 + 0.5 * sin(TAU * 4.0 * _phase))
		_playback.push_frame(Vector2(sample, sample))


func _tone(freq: float, seconds: float, sweep: float) -> AudioStreamWAV:
	var count := int(MIX_RATE * seconds)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase += (freq + sweep * t) / MIX_RATE
		var value := sin(TAU * phase) * (1.0 - t) * 0.5
		bytes.encode_s16(i * 2, int(value * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(MIX_RATE)
	wav.data = bytes
	return wav
