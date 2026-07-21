extends BaseManager
## Hardware bridge for the custom handheld: haptics, gyro, LED, speaker hooks.
##
## On PC / editor these are safe stubs. Gameplay should call DeviceService so
## real firmware can plug in later without rewriting systems.

signal haptic_played(pattern: StringName, intensity: float)
signal led_changed(color: Color, mode: StringName)
signal gyro_sample(angular_velocity: Vector3)


var _gyro_enabled: bool = false
var _haptics_enabled: bool = true
var _led_color: Color = Color(0.2, 0.55, 0.5)
var _simulated_gyro: Vector3 = Vector3.ZERO


func _initialize_manager() -> void:
	_log("DeviceService initialized (stub — handheld firmware later)")


func has_gyro() -> bool:
	return _gyro_enabled


func set_gyro_enabled(enabled: bool) -> void:
	_gyro_enabled = enabled


func get_gyro() -> Vector3:
	## Firmware replaces this. Stub returns simulated / zero.
	return _simulated_gyro


func simulate_gyro(angular_velocity: Vector3) -> void:
	_simulated_gyro = angular_velocity
	gyro_sample.emit(angular_velocity)


func play_haptic(pattern: StringName, intensity: float = 0.5) -> void:
	if not _haptics_enabled:
		return
	intensity = clampf(intensity, 0.0, 1.0)
	haptic_played.emit(pattern, intensity)
	## PC stub: short audio tick doubles as feedback when no motor.
	match pattern:
		&"chest", &"discover", &"reward", &"battle":
			EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
		&"creature_happy":
			EventBus.sfx_play_requested.emit(&"bits_gain", Vector3.ZERO)
		&"creature_sad", &"warning":
			EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
		_:
			pass
	_log("Haptic: %s @ %.2f" % [String(pattern), intensity])


func set_haptics_enabled(enabled: bool) -> void:
	_haptics_enabled = enabled


func set_led(color: Color, mode: StringName = &"solid") -> void:
	_led_color = color
	led_changed.emit(color, mode)
	_log("LED: %s mode=%s" % [color, String(mode)])


func pulse_led_for_mood(mood_label: String) -> void:
	var c := Color(0.25, 0.55, 0.5)
	var ml := mood_label.to_lower()
	if "happy" in ml or "play" in ml:
		c = Color(0.35, 0.85, 0.55)
	elif "tired" in ml or "sleep" in ml:
		c = Color(0.25, 0.35, 0.7)
	elif "hungry" in ml:
		c = Color(0.9, 0.55, 0.25)
	elif "sad" in ml or "lonely" in ml:
		c = Color(0.45, 0.35, 0.7)
	set_led(c, &"pulse")


func notify_event(event_id: StringName) -> void:
	## High-level convenience used by gameplay systems.
	match event_id:
		&"chest_open":
			play_haptic(&"chest", 0.65)
			set_led(Color(0.95, 0.75, 0.25), &"flash")
		&"location_discovered":
			play_haptic(&"discover", 0.45)
			set_led(Color(0.4, 0.8, 0.95), &"flash")
		&"quest_complete":
			play_haptic(&"reward", 0.7)
			set_led(Color(0.55, 0.95, 0.55), &"flash")
		&"achievement":
			play_haptic(&"reward", 0.8)
			set_led(Color(0.95, 0.85, 0.35), &"pulse")
		&"creature_care":
			play_haptic(&"creature_happy", 0.35)
			pulse_led_for_mood(CreatureManager.get_mood_label())
		&"battle":
			play_haptic(&"battle", 0.55)
			set_led(Color(0.95, 0.35, 0.35), &"flash")
		_:
			play_haptic(&"ui", 0.2)


## NFC / link stub for digi-pet device battles (firmware later).
func begin_nfc_link() -> String:
	play_haptic(&"ui", 0.25)
	set_led(Color(0.35, 0.55, 0.95), &"pulse")
	_log("NFC link stub — searching for nearby Field Unit")
	return "Hold devices together…\n(NFC stub — press A to simulate link)"


func exchange_creature_snapshot() -> Dictionary:
	## Payload a real NFC stack would send/receive.
	return {
		&"species_id": CreatureManager.get_companion_id(),
		&"nickname": CreatureManager.get_companion_nickname(),
		&"level": CreatureManager.get_level(),
		&"stage": CreatureManager.get_evolution_stage(),
		&"friendship": CreatureManager.get_friendship(),
	}


func exchange_profile_snapshot() -> Dictionary:
	## Future NFC: battle / trade / event unlock between Field Units — offline.
	var rec := SaveManager.get_active_profile()
	return {
		&"schema": 1,
		&"profile_id": SaveManager.get_active_profile_id(),
		&"display_name": str(rec.get("display_name", "")),
		&"avatar_id": str(rec.get("avatar_id", "ember")),
		&"creature": exchange_creature_snapshot(),
	}
