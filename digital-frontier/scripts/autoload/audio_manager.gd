extends BaseManager
## Music and SFX playback with bus routing + placeholder synthesized beds/beeps.

@onready var _music_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _current_music_id: StringName = &""
const SFX_POOL_SIZE := 8


func _initialize_manager() -> void:
	_setup_players()
	_build_placeholder_sfx()
	_build_placeholder_music()
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
	_sfx_streams[&"ui_blip"] = _make_beep(520.0, 0.045, 0.22)
	_sfx_streams[&"ui_confirm"] = _make_beep(660.0, 0.07, 0.26)
	_sfx_streams[&"ui_cancel"] = _make_beep(320.0, 0.06, 0.22)
	_sfx_streams[&"ui_purchase"] = _make_chord([523.25, 659.25, 784.0], 0.22, 0.28)
	_sfx_streams[&"quest"] = _make_beep(392.0, 0.14, 0.28)
	_sfx_streams[&"boot_chime"] = _make_chord([392.0, 523.25, 659.25, 784.0], 0.42, 0.3)
	_sfx_streams[&"menu_beep"] = _make_beep(587.0, 0.055, 0.24)
	_sfx_streams[&"partner_select"] = _make_chord([523.25, 659.25, 784.0], 0.4, 0.32)
	_sfx_streams[&"battle_start"] = _make_beep(220.0, 0.18, 0.35)
	_sfx_streams[&"battle_hit"] = _make_beep(180.0, 0.07, 0.4)
	_sfx_streams[&"battle_win"] = _make_chord([523.25, 659.25, 880.0], 0.45, 0.3)
	_sfx_streams[&"evolve"] = _make_chord([349.23, 440.0, 554.37, 698.46], 0.55, 0.28)
	_sfx_streams[&"creature_feed"] = _make_beep(600.0, 0.08, 0.22)
	_sfx_streams[&"creature_pet"] = _make_beep(720.0, 0.07, 0.2)
	_sfx_streams[&"creature_interact"] = _make_beep(720.0, 0.07, 0.2)
	_sfx_streams[&"creature_train"] = _make_beep(340.0, 0.1, 0.25)
	_sfx_streams[&"creature_rest"] = _make_beep(280.0, 0.14, 0.2)
	_sfx_streams[&"creature_heal"] = _make_beep(760.0, 0.12, 0.22)
	_sfx_streams[&"creature_play"] = _make_beep(640.0, 0.09, 0.22)
	_sfx_streams[&"creature_status"] = _make_beep(500.0, 0.06, 0.18)
	_sfx_streams[&"vehicle_launch"] = _make_beep(160.0, 0.22, 0.32)
	_sfx_streams[&"vehicle_land"] = _make_beep(140.0, 0.18, 0.3)
	_sfx_streams[&"vehicle_engine"] = _make_beep(110.0, 0.1, 0.18)


func _build_placeholder_music() -> void:
	## Soft looping beds so music_change_requested is never silent.
	_music_streams[&"home_night"] = _make_music_bed([196.0, 246.94, 293.66], 4.0, 0.11)
	_music_streams[&"adventure_day"] = _make_music_bed([261.63, 329.63, 392.0], 3.2, 0.1)
	_music_streams[&"adventure"] = _music_streams[&"adventure_day"]
	_music_streams[&"adventure_night"] = _make_music_bed([174.61, 220.0, 261.63], 4.5, 0.09)
	_music_streams[&"combat"] = _make_music_bed([146.83, 185.0, 220.0, 277.18], 2.4, 0.12)
	_music_streams[&"battle"] = _music_streams[&"combat"]
	_music_streams[&"shop"] = _make_music_bed([293.66, 349.23, 440.0], 3.6, 0.1)


func _apply_volume_settings() -> void:
	_set_bus_linear(&"Master", GameConfig.master_volume)
	_set_bus_linear(&"Music", GameConfig.music_volume)
	_set_bus_linear(&"SFX", GameConfig.sfx_volume)


func _set_bus_linear(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))


func refresh_volumes() -> void:
	_apply_volume_settings()


func _on_music_change_requested(track_id: StringName) -> void:
	var stream: AudioStream = _music_streams.get(track_id)
	if stream == null:
		## Soft fallback — still play something rather than silence.
		stream = _music_streams.get(&"adventure_day")
	if stream == null:
		_log("Music change requested (no bed): %s" % track_id)
		return
	if _current_music_id == track_id and _music_player and _music_player.playing:
		return
	_current_music_id = track_id
	_log("Music change requested: %s" % track_id)
	play_music(stream, true)


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
	if _music_player == null or stream == null:
		return
	_music_player.volume_db = 0.0
	if crossfade and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, 0.35)
		await tween.finished
	_music_player.stream = stream
	_music_player.volume_db = 0.0
	_music_player.play()


func stop_music(fade: bool = true) -> void:
	if _music_player == null or not _music_player.playing:
		return
	_current_music_id = &""
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


func _make_music_bed(freqs: Array, duration: float, amp: float) -> AudioStreamWAV:
	## Soft looping pad — placeholder until authored music lands.
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		## Gentle attack + release so the loop seam is less clicky.
		var env := 1.0
		var edge := 0.12
		if t < edge:
			env = t / edge
		elif t > duration - edge:
			env = (duration - t) / edge
		var mix := 0.0
		for fi in freqs.size():
			var f := float(freqs[fi])
			mix += sin(TAU * f * t) * (1.0 - float(fi) * 0.12)
		mix /= float(maxi(freqs.size(), 1))
		## Slow tremolo for life.
		mix *= 0.85 + 0.15 * sin(TAU * 0.35 * t)
		var sample := int(clamp(amp * env * mix, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream
