extends BaseManager
## Music and SFX playback with bus routing.
##
## WHY: Centralizes audio so volume settings, crossfades, and pooling apply globally.
## Responds to EventBus requests so gameplay never touches AudioStreamPlayer nodes directly.

@onready var _music_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8


func _initialize_manager() -> void:
	_setup_players()
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


func _apply_volume_settings() -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(&"Master"),
		linear_to_db(GameConfig.master_volume)
	)


func _on_music_change_requested(track_id: StringName) -> void:
	## Load track from data/audio lookup when audio content exists.
	_log("Music change requested: %s" % track_id)


func _on_sfx_play_requested(sfx_id: StringName, _position: Vector3) -> void:
	## 2.5D: position used for attenuation on spatial players later.
	_log("SFX requested: %s" % sfx_id)


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
