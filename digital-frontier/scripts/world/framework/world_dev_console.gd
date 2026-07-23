class_name WorldDevConsole
extends CanvasLayer
## Development-only world tools — time, weather, spawn, events, teleport, save inspect.
## Gated by GameConfig.enable_cheats. Toggle: F6.


signal command_ran(command: String, args: PackedStringArray)

const TOGGLE_ACTION_HINT := "F6"

var _coordinator: WorldCoordinator = null
var _player: Node3D = null
var _atmosphere: WorldAtmosphere = null
var _panel: PanelContainer = null
var _log: RichTextLabel = null
var _input: LineEdit = null
var _visible_ui: bool = false


func setup(coordinator: WorldCoordinator, player: Node3D, atmosphere: WorldAtmosphere) -> void:
	_coordinator = coordinator
	_player = player
	_atmosphere = atmosphere
	layer = 90
	name = "WorldDevConsole"
	_build_ui()
	visible = false
	_visible_ui = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not EventBus.debug_command_executed.is_connected(_on_bus_command):
		EventBus.debug_command_executed.connect(_on_bus_command)


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_left = 12
	_panel.offset_top = 12
	_panel.offset_right = -12
	_panel.offset_bottom = 220
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 0.92)
	style.border_color = WorldPalette.UI_CYAN
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	var title := Label.new()
	title.text = "World Dev Console · F6 hide · help"
	title.add_theme_color_override("font_color", WorldPalette.UI_CYAN)
	v.add_child(title)
	_log = RichTextLabel.new()
	_log.fit_content = false
	_log.scroll_active = true
	_log.custom_minimum_size = Vector2(0, 120)
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.bbcode_enabled = true
	v.add_child(_log)
	_input = LineEdit.new()
	_input.placeholder_text = "time morning | weather rain | spawn wildlife | event meteor_window | tp park | save"
	_input.text_submitted.connect(_on_submit)
	v.add_child(_input)
	_append("Ready. Type [b]help[/b].")


func _unhandled_input(event: InputEvent) -> void:
	if not GameConfig.enable_cheats:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F6:
			_toggle()
			get_viewport().set_input_as_handled()


func _toggle() -> void:
	_visible_ui = not _visible_ui
	visible = _visible_ui
	if _visible_ui and _input:
		_input.grab_focus()


func _on_bus_command(command: String, args: PackedStringArray) -> void:
	## External emitters (inspect overlays) — don't re-broadcast.
	_execute(command, args, false)


func _on_submit(text: String) -> void:
	var t := text.strip_edges()
	if t.is_empty():
		return
	_input.text = ""
	var parts := t.split(" ", false)
	var cmd := String(parts[0]).to_lower()
	var args := PackedStringArray()
	for i in range(1, parts.size()):
		args.append(parts[i])
	_execute(cmd, args, true)


func _execute(command: String, args: PackedStringArray, broadcast: bool) -> void:
	command_ran.emit(command, args)
	if broadcast:
		EventBus.debug_command_executed.emit(command, args)
	match command:
		"help", "?":
			_append("Commands: time <morning|day|evening|night> · weather <clear|rain|fog|storm>")
			_append("spawn <wildlife|hostile|npc> · event <id> · events · tp <park|mere|fields|reels>")
			_append("phase · save · discover · pop · regions · biome")
		"time", "phase":
			_cmd_time(args)
		"weather":
			_cmd_weather(args)
		"spawn":
			_cmd_spawn(args)
		"event":
			_cmd_event(args)
		"events":
			if _coordinator and _coordinator.events:
				_append("Events: %s" % ", ".join(_coordinator.events.list_event_ids()))
		"tp", "teleport":
			_cmd_tp(args)
		"save":
			_append("Save inspect: schema=%d region=%s discoveries=%d" % [
				WorldSaveSchema.CURRENT_VERSION,
				String(WorldManager.get_active_region_id()),
				WorldManager.get_discovery_count(),
			])
			_append(str(DiscoveryFramework.completion_snapshot()))
		"discover":
			_append(DiscoveryFramework.journal_blurb())
		"pop":
			if _coordinator:
				_append(str(_coordinator.spawn_broker.population_snapshot()))
		"regions":
			if _coordinator:
				_append(str(_coordinator.list_region_ids()))
		"biome":
			if _coordinator and _coordinator.active_biome():
				_append(str(_coordinator.active_biome().to_dict()))
		_:
			_append("[color=#f55]Unknown:[/color] %s" % command)


func _cmd_time(args: PackedStringArray) -> void:
	if _atmosphere == null:
		_append("No atmosphere")
		return
	if args.is_empty():
		_append("Phase: %s" % WorldAtmosphere.phase_label(WorldAtmosphere.current_phase_index()))
		return
	match String(args[0]).to_lower():
		"morning":
			_atmosphere.apply_phase(WorldAtmosphere.Phase.MORNING)
		"day", "afternoon":
			_atmosphere.apply_phase(WorldAtmosphere.Phase.AFTERNOON)
		"evening":
			_atmosphere.apply_phase(WorldAtmosphere.Phase.EVENING)
		"night":
			_atmosphere.apply_phase(WorldAtmosphere.Phase.NIGHT)
		_:
			_append("Unknown phase")
			return
	_append("Time → %s" % String(args[0]))


func _cmd_weather(args: PackedStringArray) -> void:
	if _atmosphere == null:
		_append("No atmosphere")
		return
	if args.is_empty():
		_append("Weather: %s" % String(WorldAtmosphere.current_weather_id()))
		return
	match String(args[0]).to_lower():
		"clear":
			_atmosphere.apply_weather(WorldAtmosphere.Weather.CLEAR)
		"rain":
			_atmosphere.apply_weather(WorldAtmosphere.Weather.RAIN)
		"fog":
			_atmosphere.apply_weather(WorldAtmosphere.Weather.FOG)
		"storm":
			_atmosphere.apply_weather(WorldAtmosphere.Weather.STORM)
		_:
			_append("Unknown weather")
			return
	_append("Weather → %s" % String(args[0]))


func _cmd_spawn(args: PackedStringArray) -> void:
	if _coordinator == null or _player == null:
		return
	var kind := String(args[0]).to_lower() if not args.is_empty() else "wildlife"
	var n: Node = null
	match kind:
		"wildlife", "wild":
			n = _coordinator.spawn_broker.spawn_wildlife_near(_player.global_position)
		"hostile", "enemy":
			n = _coordinator.spawn_broker.spawn_hostile_near(_player.global_position)
		"npc":
			var def := LivingWorldCatalog.pick_weighted(LivingWorldCatalog.grassland_npcs(), RandomNumberGenerator.new())
			n = _coordinator.spawn_broker.spawn_npc_def(def, _player.global_position + Vector3(4, 0, 2))
		_:
			_append("spawn wildlife|hostile|npc")
			return
	_append("Spawned %s: %s" % [kind, n.name if n else "failed"])


func _cmd_event(args: PackedStringArray) -> void:
	if _coordinator == null or _coordinator.events == null:
		return
	if args.is_empty():
		_append("Usage: event <id>")
		return
	var ok := _coordinator.events.trigger(StringName(args[0]))
	_append("Event %s → %s" % [args[0], "ok" if ok else "fail"])


func _cmd_tp(args: PackedStringArray) -> void:
	if _player == null:
		return
	var dest := Vector3.ZERO
	var key := String(args[0]).to_lower() if not args.is_empty() else "park"
	match key:
		"park":
			dest = GrasslandLayout.PLEASANT_PARK + Vector3(0, 0.15, 8)
		"mere":
			dest = GrasslandLayout.MIRROR_MERE + Vector3(0, 0.15, 8)
		"fields":
			dest = GrasslandLayout.FATAL_FIELDS + Vector3(0, 0.15, 8)
		"reels":
			dest = GrasslandLayout.RISKY_REELS + Vector3(0, 0.15, 8)
		"mile":
			dest = GrasslandLayout.MARKET_MILE + Vector3(0, 0.15, 8)
		_:
			_append("tp park|mere|fields|reels|mile")
			return
	_player.global_position = dest
	_append("Teleported → %s" % key)


func _append(line: String) -> void:
	if _log:
		_log.append_text(line + "\n")
