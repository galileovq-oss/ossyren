class_name Sfx
extends RefCounted
## Procedural PLACEHOLDER sound effects (no audio files needed): short synthesised sounds, generated
## once and cached. Real audio replaces this in the polish phase; call sites stay the same.
## Sfx.enabled = false mutes everything.

const MIX_RATE: int = 22050

static var enabled: bool = true
static var _cache: Dictionary = {}


## Plays `sound` once. `context` is any node inside the tree (used to find the scene).
static func play(context: Node, sound: StringName, volume_db: float = -10.0) -> void:
	if not enabled or context == null or not context.is_inside_tree():
		return
	var stream: AudioStreamWAV = _get_stream(sound)
	if stream == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.92, 1.08)
	context.get_tree().current_scene.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func _get_stream(sound: StringName) -> AudioStreamWAV:
	if _cache.has(sound):
		return _cache[sound]
	var duration: float = _duration(sound)
	if duration <= 0.0:
		return null
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(String(sound))
	var count: int = int(duration * MIX_RATE)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var value: float = clampf(_sample(sound, float(i) / MIX_RATE, rng), -1.0, 1.0)
		bytes.encode_s16(i * 2, int(value * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	_cache[sound] = stream
	return stream


static func _duration(sound: StringName) -> float:
	match sound:
		&"hit": return 0.12
		&"miss": return 0.15
		&"shot": return 0.18
		&"cast": return 0.35
		&"boom": return 0.45
		&"warn": return 0.5
		&"pickup": return 0.18
		&"drink": return 0.3
		&"death": return 0.4
		&"chest": return 0.35
		&"dash": return 0.22
	return 0.0


static func _sample(sound: StringName, t: float, rng: RandomNumberGenerator) -> float:
	var noise: float = rng.randf_range(-1.0, 1.0)
	match sound:
		&"hit":
			return (noise * 0.9 + sin(TAU * 120.0 * t) * 0.5) * exp(-t * 40.0)
		&"miss":
			return noise * 0.25 * minf(t * 60.0, 1.0) * exp(-t * 16.0)
		&"shot":
			return (noise * 0.8 + sin(TAU * (200.0 - 400.0 * t) * t) * 0.6) * exp(-t * 26.0)
		&"cast":
			return sin(TAU * (300.0 + 900.0 * t) * t) * 0.35 * minf(t * 12.0, 1.0) * exp(-t * 2.5)
		&"boom":
			return (noise * 0.6 + sin(TAU * (70.0 - 60.0 * t) * t) * 0.9) * exp(-t * 7.0)
		&"warn":
			var gate: float = 1.0 if fmod(t, 0.18) < 0.09 else 0.0
			return sin(TAU * 660.0 * t) * 0.3 * gate * exp(-t * 2.5)
		&"pickup":
			return sin(TAU * (880.0 if t < 0.07 else 1320.0) * t) * 0.35 * exp(-t * 9.0)
		&"drink":
			return sin(TAU * (420.0 + 260.0 * sin(t * 40.0)) * t) * 0.3 * exp(-t * 6.0)
		&"death":
			return (noise * 0.4 + sin(TAU * (200.0 - 150.0 * t) * t) * 0.7) * exp(-t * 5.0)
		&"chest":
			return sin(TAU * (523.0 if t < 0.12 else 784.0) * t) * 0.3 * exp(-t * 7.0)
		&"dash":
			return noise * 0.35 * minf(t * 40.0, 1.0) * exp(-t * 11.0) + sin(TAU * (500.0 - 1500.0 * t) * t) * 0.15 * exp(-t * 10.0)
	return 0.0
