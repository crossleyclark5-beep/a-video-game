extends BaseManager
## Music and SFX playback with bus routing + placeholder synthesized beeps.

@onready var _music_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}
const SFX_POOL_SIZE := 8


func _initialize_manager() -> void:
	_setup_players()
	_build_placeholder_sfx()
	EventBus.music_change_requested.connect(_on_music_change_requested)
	EventBus.sfx_play_requested.connect(_on_sfx_play_requested)
	_apply_volume_settings()
	_log("AudioManager initialized")


func _setup_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		player.name = "SFXPlayer_%d" % i
		add_child(player)
		_sfx_pool.append(player)


func _build_placeholder_sfx() -> void:
	## Tiny procedural tones until real audio assets exist.
	_sfx_streams[&"chest_open"] = _make_beep(520.0, 0.12, 0.35)
	_sfx_streams[&"discover"] = _make_beep(660.0, 0.16, 0.3)
	_sfx_streams[&"bits_gain"] = _make_beep(880.0, 0.08, 0.25)
	_sfx_streams[&"achievement"] = _make_chord([523.25, 659.25, 783.99], 0.28, 0.28)
	_sfx_streams[&"ui_blip"] = _make_beep(440.0, 0.05, 0.2)
	_sfx_streams[&"quest"] = _make_beep(392.0, 0.14, 0.28)
	_sfx_streams[&"boot_chime"] = _make_chord([392.0, 523.25, 659.25], 0.35, 0.3)
	_sfx_streams[&"menu_beep"] = _make_beep(494.0, 0.06, 0.22)
	_sfx_streams[&"partner_select"] = _make_chord([523.25, 659.25, 784.0], 0.4, 0.32)
	_sfx_streams[&"battle_start"] = _make_beep(220.0, 0.18, 0.35)
	_sfx_streams[&"battle_hit"] = _make_beep(180.0, 0.07, 0.4)
	_sfx_streams[&"battle_win"] = _make_chord([523.25, 659.25, 880.0], 0.45, 0.3)
	_sfx_streams[&"evolve"] = _make_chord([349.23, 440.0, 554.37, 698.46], 0.55, 0.28)
	_sfx_streams[&"creature_feed"] = _make_beep(600.0, 0.08, 0.22)
	_sfx_streams[&"creature_pet"] = _make_beep(720.0, 0.07, 0.2)
	_sfx_streams[&"creature_train"] = _make_beep(340.0, 0.1, 0.25)
	_sfx_streams[&"creature_rest"] = _make_beep(280.0, 0.14, 0.2)
	_sfx_streams[&"creature_heal"] = _make_beep(760.0, 0.12, 0.22)
	_sfx_streams[&"creature_play"] = _make_beep(640.0, 0.09, 0.22)
	_sfx_streams[&"creature_status"] = _make_beep(500.0, 0.06, 0.18)


func _apply_volume_settings() -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(&"Master"),
		linear_to_db(GameConfig.master_volume)
	)


func _on_music_change_requested(track_id: StringName) -> void:
	_log("Music change requested: %s" % track_id)


func _on_sfx_play_requested(sfx_id: StringName, _position: Vector3) -> void:
	play_sfx(sfx_id)


func play_sfx(sfx_id: StringName) -> void:
	var stream: AudioStream = _sfx_streams.get(sfx_id)
	if stream == null:
		_log("SFX requested (no stream): %s" % sfx_id)
		return
	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	## All busy — steal first.
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()


func play_music(stream: AudioStream, crossfade: bool = true) -> void:
	if _music_player == null:
		return
	if crossfade and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, 0.5)
		await tween.finished
	_music_player.stream = stream
	_music_player.play()


func stop_music(fade: bool = true) -> void:
	if _music_player == null or not _music_player.playing:
		return
	if fade:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, 0.5)
		await tween.finished
	_music_player.stop()


func _make_beep(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var envelope := 1.0 - (t / duration)
		var sample := int(clamp(amp * envelope * sin(TAU * freq * t), -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


func _make_chord(freqs: Array, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var envelope := 1.0 - (t / duration)
		var mix := 0.0
		for f in freqs:
			mix += sin(TAU * float(f) * t)
		mix /= float(maxi(freqs.size(), 1))
		var sample := int(clamp(amp * envelope * mix, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
