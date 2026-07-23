class_name BattleDirector
extends Node
## In-world companion battle mode — Digimon soul, handheld buttons, world stays visible.
##
## Encounter → intro → choose action → resolve → rewards → autosave.

signal battle_finished(won: bool)

enum Phase {
	IDLE,
	INTRO,
	CHOOSE,
	RESOLVE,
	RESULT,
}

enum Command {
	ATTACK,
	DODGE,
	ABILITY,
	ITEM,
	ESCAPE,
}

const COMMAND_LABELS := ["Attack", "Dodge", "Ability", "Item", "Escape"]

var _phase: Phase = Phase.IDLE
var _player: Node3D = null
var _companion_actor: Node3D = null
var _camera: Node3D = null
var _hud: CombatHud = null
var _ally: CombatantState = null
var _enemy: CombatantState = null
var _enemy_node: Node3D = null
var _command_index: int = 0
var _busy: float = 0.0
var _turns: int = 0
var _won: bool = false
var _escaped: bool = false
var _arena_center: Vector3 = Vector3.ZERO
var _saved_companion_pos: Vector3 = Vector3.ZERO
var _saved_enemy_pos: Vector3 = Vector3.ZERO
var _player_was_processing: bool = true
var _battle_records: Array = []  ## NFC-ready history this session
var _resolving: bool = false


func is_active() -> bool:
	return _phase != Phase.IDLE


func setup(player: Node3D, companion: Node3D, camera: Node3D) -> void:
	_player = player
	_companion_actor = companion
	_camera = camera


func try_start_from_target(target: Node3D, forced: bool = false) -> bool:
	if is_active() or target == null or not is_instance_valid(target):
		return false
	if not forced and UIManager.has_open_modal():
		return false
	if not CreatureManager.has_chosen_partner():
		EventBus.ui_notification_requested.emit("Choose a partner before battling!", 2.2)
		return false
	_enemy_node = target
	_enemy = CombatantState.from_world_enemy(target)
	_ally = CombatantState.from_companion()
	if _companion_actor:
		_ally.source_node = _companion_actor as Node3D
	_begin()
	return true


func _begin() -> void:
	_phase = Phase.INTRO
	_turns = 0
	_won = false
	_escaped = false
	_resolving = false
	_command_index = 0
	_busy = 1.1
	_arena_center = _enemy_node.global_position if _enemy_node else _player.global_position
	if _player:
		_arena_center = _arena_center.lerp(_player.global_position, 0.35)
	InputManager.push_context(InputManager.Context.COMBAT)
	UIManager.push_modal(&"battle")
	_freeze_world(true)
	_stage_fighters()
	_ensure_hud()
	_hud.open_battle(_ally, _enemy)
	_hud.set_prompt("Battle start!")
	if _camera and _camera.has_method("enter_battle_mode"):
		_camera.call("enter_battle_mode", _arena_center, _player, _companion_actor, _enemy_node)
	EventBus.battle_started.emit(_enemy.species_id, _enemy.tier)
	EventBus.sfx_play_requested.emit(&"battle_start", _arena_center)
	EventBus.ui_notification_requested.emit("%s vs %s!" % [_ally.display_name, _enemy.display_name], 2.2)
	_play_companion_anim(CompanionVisual.Anim.HAPPY)


func _process(delta: float) -> void:
	if _phase == Phase.IDLE:
		return
	if _resolving:
		return
	if _busy > 0.0:
		_busy -= delta
		if _busy > 0.0:
			return
	match _phase:
		Phase.INTRO:
			_phase = Phase.CHOOSE
			_hud.set_phase_choose(_command_index)
		Phase.CHOOSE:
			_poll_choose()
		Phase.RESOLVE:
			pass
		Phase.RESULT:
			_poll_result()


func _poll_result() -> void:
	## Hold the victory/defeat beat until the player confirms (premium feel).
	if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact") or InputManager.is_action_just_pressed(&"ui_cancel"):
		_finish()


func _poll_choose() -> void:
	var ui := InputManager.get_ui_vector_just()
	if ui.x != 0:
		_command_index = posmod(_command_index + int(sign(ui.x)), COMMAND_LABELS.size())
		_hud.set_phase_choose(_command_index)
		EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
	if InputManager.is_action_just_pressed(&"creature_action"):
		_command_index = Command.ABILITY
		_confirm_command()
		return
	if InputManager.is_action_just_pressed(&"device_cycle"):
		_command_index = Command.ITEM
		_confirm_command()
		return
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		_command_index = Command.ESCAPE
		_confirm_command()
		return
	if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
		_confirm_command()


func _confirm_command() -> void:
	if _resolving or _phase != Phase.CHOOSE:
		return
	_phase = Phase.RESOLVE
	_resolve_player_command(_command_index)


func _resolve_player_command(cmd: int) -> void:
	_resolving = true
	_turns += 1
	_ally.clear_guards()
	match cmd:
		Command.ATTACK:
			await _do_attack(_ally, _enemy, _ally.moves[0] if not _ally.moves.is_empty() else CombatCatalog.basic_strike())
		Command.DODGE:
			_ally.dodging = true
			_hud.flash_action("%s prepares to dodge!" % _ally.display_name)
			_play_companion_anim(CompanionVisual.Anim.CURIOUS)
			EventBus.sfx_play_requested.emit(&"ui_confirm", _arena_center)
			await get_tree().create_timer(0.45).timeout
		Command.ABILITY:
			var move: CombatMove = _pick_special(_ally)
			await _do_attack(_ally, _enemy, move)
		Command.ITEM:
			await _use_item()
		Command.ESCAPE:
			await _try_escape()
			if _escaped or _phase == Phase.RESULT:
				_resolving = false
				return
	if not _enemy.is_alive():
		_won = true
		_phase = Phase.RESULT
		_busy = 0.85
		_hud.set_result(true, _build_reward_summary(true))
		_play_companion_anim(CompanionVisual.Anim.HAPPY)
		_resolving = false
		return
	await _enemy_turn()
	if not _ally.is_alive():
		_won = false
		_phase = Phase.RESULT
		_busy = 0.9
		_hud.set_result(false, "%s needs rest at Home…" % _ally.display_name)
		_play_companion_anim(CompanionVisual.Anim.SAD)
		_resolving = false
		return
	_ally.tick_statuses()
	_enemy.tick_statuses()
	_phase = Phase.CHOOSE
	_hud.refresh(_ally, _enemy)
	_hud.set_phase_choose(_command_index)
	_resolving = false


func _pick_special(fighter: CombatantState) -> CombatMove:
	var best: CombatMove = null
	for m in fighter.moves:
		if m is CombatMove and (m as CombatMove).category == CombatMove.Category.SPECIAL:
			var cm := m as CombatMove
			if best == null or cm.power > best.power:
				best = cm
	if best:
		return best
	if not fighter.moves.is_empty() and fighter.moves[0] is CombatMove:
		return fighter.moves[0] as CombatMove
	return CombatCatalog.basic_strike(fighter.element)


func _do_attack(attacker: CombatantState, defender: CombatantState, move: CombatMove) -> void:
	if move == null:
		move = CombatCatalog.basic_strike(attacker.element)
	if move.category == CombatMove.Category.DEFEND:
		attacker.defending = true
		var healed := attacker.heal(move.heal_self)
		_hud.flash_action("%s uses %s%s" % [
			attacker.display_name,
			move.display_name,
			(" · +%d HP" % int(healed)) if healed > 0.0 else "",
		])
		if attacker.is_companion:
			_play_companion_anim(CompanionVisual.Anim.HAPPY)
		EventBus.sfx_play_requested.emit(&"creature_heal", _arena_center)
		await get_tree().create_timer(0.55).timeout
		_hud.refresh(_ally, _enemy)
		return
	if randf() > move.accuracy:
		_hud.flash_action("%s's %s missed!" % [attacker.display_name, move.display_name])
		EventBus.sfx_play_requested.emit(&"ui_cancel", _arena_center)
		await get_tree().create_timer(0.5).timeout
		return
	var power := move.power + attacker.attack * 0.85 - defender.defense * 0.35
	power *= CombatTypes.affinity(move.element, defender.element)
	if attacker.is_companion:
		match CreatureManager.get_battle_style():
			&"aggressive":
				power *= 1.12
			&"swift":
				power *= 1.06
			&"opportunist":
				power *= 1.08
	power = maxf(3.0, power + randf_range(-2.0, 2.0))
	await _play_lunge(attacker, defender)
	var dealt := defender.apply_damage(power)
	attacker.energy = maxf(0.0, attacker.energy - move.energy_cost)
	var aff := CombatTypes.affinity(move.element, defender.element)
	var tag := ""
	if aff > 1.1:
		tag = " · Super!"
	elif aff < 0.85:
		tag = " · Weak…"
	_hud.flash_action("%s used %s! −%d%s" % [attacker.display_name, move.display_name, int(dealt), tag])
	_hud.refresh(_ally, _enemy)
	if attacker.is_companion:
		_play_companion_anim(CompanionVisual.Anim.HAPPY)
	elif not defender.is_alive():
		_play_companion_anim(CompanionVisual.Anim.HAPPY)
	_play_hit_react(defender)
	EventBus.sfx_play_requested.emit(&"battle_hit", _arena_center)
	EventBus.combat_hit.emit(attacker.source_node, defender.source_node, dealt)
	if move.status_id != &"" and randf() < move.status_chance:
		defender.apply_status(move.status_id, 2)
		_hud.flash_action("%s inflicted %s!" % [move.display_name, String(move.status_id)])
	_sync_enemy_node_hp()
	await get_tree().create_timer(0.55).timeout


func _enemy_turn() -> void:
	_enemy.clear_guards()
	if _enemy.has_status(&"shock") or _enemy.has_status(&"root"):
		_hud.flash_action("%s is hindered…" % _enemy.display_name)
		await get_tree().create_timer(0.4).timeout
		if randf() < 0.35:
			_hud.flash_action("%s can't move!" % _enemy.display_name)
			await get_tree().create_timer(0.4).timeout
			return
	var move: CombatMove = _pick_special(_enemy)
	if _enemy.tier == &"boss" and randf() < 0.2:
		for m in _enemy.moves:
			if m is CombatMove and (m as CombatMove).category == CombatMove.Category.DEFEND:
				move = m as CombatMove
				break
	await _do_attack(_enemy, _ally, move)
	if _player and _ally.hp < _ally.max_hp * 0.35:
		var health := _player.get_node_or_null("PlayerHealth")
		if health and health.has_method("apply_damage"):
			health.call("apply_damage", 4.0, _enemy_node)


func _use_item() -> void:
	if not InventoryManager.has_item(&"heal_field_salve", 1):
		_hud.flash_action("No Field Salve in the Pack!")
		EventBus.sfx_play_requested.emit(&"ui_cancel", Vector3.ZERO)
		await get_tree().create_timer(0.45).timeout
		return
	InventoryManager.remove_item(&"heal_field_salve", 1)
	var healed := _ally.heal(28.0)
	_ally.energy = minf(100.0, _ally.energy + 12.0)
	_hud.flash_action("Field Salve! %s +%d HP" % [_ally.display_name, int(healed)])
	_play_companion_anim(CompanionVisual.Anim.HAPPY)
	EventBus.sfx_play_requested.emit(&"creature_heal", _arena_center)
	if _player:
		var health := _player.get_node_or_null("PlayerHealth")
		if health and health.has_method("heal"):
			health.call("heal", 20.0)
	await get_tree().create_timer(0.55).timeout
	_hud.refresh(_ally, _enemy)


func _try_escape() -> void:
	var chance := 0.55
	if _enemy.tier == &"boss":
		chance = 0.15
	elif _enemy.tier == &"mini_boss":
		chance = 0.3
	chance += (_ally.speed - _enemy.speed) * 0.01
	if randf() < clampf(chance, 0.1, 0.9):
		_escaped = true
		_won = false
		_phase = Phase.RESULT
		_busy = 0.6
		_hud.set_result(false, "Escaped! Live to explore another trail.")
		EventBus.sfx_play_requested.emit(&"ui_cancel", _arena_center)
	else:
		_hud.flash_action("Couldn't escape!")
		EventBus.sfx_play_requested.emit(&"ui_blip", _arena_center)
		await get_tree().create_timer(0.4).timeout


func _build_reward_summary(won: bool) -> String:
	if not won:
		return "Defeat… comfort your partner at Home."
	var reward: Dictionary = CombatCatalog.reward_for(_enemy.tier, CreatureManager.get_level())
	return "Victory! +%d XP · +%d Bits · Bond +%.0f" % [
		int(reward.get("xp", 0)),
		int(reward.get("bits", 0)),
		float(reward.get("bond", 0.0)),
	]


func _finish() -> void:
	if _resolving or _phase != Phase.RESULT:
		return
	_resolving = true
	var victory := _won and not _escaped
	var enemy_id := _enemy.species_id if _enemy else &""
	var record := CombatCatalog.make_battle_record(victory, enemy_id, _enemy.tier if _enemy else &"wild", _turns)
	_battle_records.append(record)
	_sync_companion_vitals(victory)
	if victory:
		var reward: Dictionary = CombatCatalog.reward_for(_enemy.tier, CreatureManager.get_level())
		CreatureManager.grant_adventure_experience(int(reward.get("xp", 8)))
		InventoryManager.add_bits(int(reward.get("bits", 10)), true, "Battle reward", "battle")
		CreatureManager.grant_adventure_bond(float(reward.get("bond", 1.0)), "")
		CreatureManager.record_companion_battle(true, enemy_id, _enemy.tier == &"boss" or _enemy.tier == &"mini_boss")
		CreatureManager.record_memory(
			StringName("battle_%s_%d" % [String(enemy_id), int(Time.get_unix_time_from_system()) % 100000]),
			CompanionMemory.Kind.BATTLE,
			"Won a battle vs %s" % _enemy.display_name,
			PackedStringArray(["battle", String(_enemy.tier)]),
		)
		_resolve_world_enemy_defeat()
		EventBus.sfx_play_requested.emit(&"battle_win", _arena_center)
		_play_companion_anim(CompanionVisual.Anim.HAPPY)
	elif not _escaped:
		CreatureManager.record_companion_battle(false, enemy_id, false)
		_play_companion_anim(CompanionVisual.Anim.SAD)
	EventBus.battle_ended.emit(victory, enemy_id, record)
	SaveManager.request_autosave()
	_cleanup()
	battle_finished.emit(victory)


func _sync_companion_vitals(victory: bool) -> void:
	## Adventure battles feed the same Digi-Pet vitals used on Home.
	var inst := CreatureManager.get_active_instance()
	if inst == null or _ally == null:
		return
	if victory:
		var ratio := clampf(_ally.get_hp_ratio(), 0.35, 1.0)
		inst.health = maxf(inst.health * 0.25 + ratio * 75.0, 25.0)
		inst.energy = clampf(_ally.energy * 0.85, 15.0, 100.0)
	else:
		inst.health = maxf(20.0, minf(inst.health, 35.0) - 10.0)
		inst.energy = maxf(10.0, minf(inst.energy, 40.0) - 8.0)


func _resolve_world_enemy_defeat() -> void:
	## Avoid calling apply_damage(9999) — that would double-grant XP/Bits from actor death hooks.
	var pos := _arena_center
	var sid := _enemy.species_id
	if is_instance_valid(_enemy_node):
		pos = _enemy_node.global_position
		if _enemy.tier == &"mini_boss":
			WorldManager.set_world_flag(&"mini_boss_glitch_alpha_down", true)
			CollectionManager.record_rare_find(_enemy.display_name, "mini_boss")
		elif _enemy.tier == &"boss":
			WorldManager.set_world_flag(&"boss_hollow_warden_down", true)
			## BossData item rewards once (unique spoils, not scaled trash loot).
			var boss_def: BossData = null
			if ResourceRegistry.has_id(&"boss", sid):
				boss_def = ResourceRegistry.get_boss(sid)
			elif ResourceRegistry.has_id(&"boss", &"hollow_warden"):
				boss_def = ResourceRegistry.get_boss(&"hollow_warden")
			if boss_def and not boss_def.reward_item_ids.is_empty():
				var rewards: Array = []
				for i in boss_def.reward_item_ids.size():
					var qty := 1
					if i < boss_def.reward_quantities.size():
						qty = int(boss_def.reward_quantities[i])
					rewards.append({"item_id": StringName(boss_def.reward_item_ids[i]), "quantity": qty})
				InventoryManager.grant_rewards(rewards, 0, "Boss spoils")
			CollectionManager.record_rare_find(_enemy.display_name, "boss")
		QuestManager.notify_objective(&"defeat", sid, 1)
		QuestManager.notify_objective(&"defeat", &"any", 1)
		if _enemy.tier == &"boss":
			QuestManager.notify_objective(&"defeat", &"boss", 1)
		CollectionManager.record_creature_battle(sid, true)
		EventBus.hostile_defeated.emit(sid, pos)
		_enemy_node.queue_free()
		_enemy_node = null


func _cleanup() -> void:
	_phase = Phase.IDLE
	_resolving = false
	_restore_fighters()
	_freeze_world(false)
	if _camera and _camera.has_method("exit_battle_mode"):
		_camera.call("exit_battle_mode")
	if _hud:
		_hud.close_battle()
	if UIManager.get_top_modal() == &"battle":
		UIManager.pop_modal()
	if InputManager.get_context() == InputManager.Context.COMBAT:
		InputManager.pop_context()
	_enemy_node = null
	_ally = null
	_enemy = null


func _stage_fighters() -> void:
	if _companion_actor and is_instance_valid(_companion_actor):
		_saved_companion_pos = _companion_actor.global_position
		var side := _arena_center + Vector3(-2.2, 0.1, 1.2)
		if _player:
			var toward := _arena_center - _player.global_position
			toward.y = 0.0
			if toward.length_squared() < 0.01:
				toward = Vector3(0, 0, 1)
			side = _player.global_position + toward.normalized() * 1.5
			side.y = _player.global_position.y + 0.1
		_companion_actor.global_position = side


func _restore_fighters() -> void:
	if _companion_actor and is_instance_valid(_companion_actor):
		if _companion_actor.has_method("warp_near_player"):
			_companion_actor.call("warp_near_player", _player)


func _freeze_world(frozen: bool) -> void:
	get_tree().call_group(HostileCreatureActor.GROUP, "set_physics_process", not frozen)
	get_tree().call_group(EcosystemCreature.GROUP, "set_physics_process", not frozen)
	if _player:
		_player.set_physics_process(not frozen)
	if _companion_actor:
		_companion_actor.set_physics_process(not frozen)


func _sync_enemy_node_hp() -> void:
	if not is_instance_valid(_enemy_node) or _enemy == null:
		return
	if "hp" in _enemy_node:
		_enemy_node.set("hp", _enemy.hp)


func _ensure_hud() -> void:
	if _hud and is_instance_valid(_hud):
		return
	_hud = CombatHud.new()
	_hud.name = "CombatHud"
	var host := get_tree().current_scene
	if host == null:
		host = self
	host.add_child(_hud)


func _play_companion_anim(anim: CompanionVisual.Anim) -> void:
	if _companion_actor == null or not is_instance_valid(_companion_actor):
		return
	var vis := _companion_actor.get_node_or_null("Visual")
	if vis is CompanionVisual:
		(vis as CompanionVisual).set_anim(anim)


func _play_lunge(attacker: CombatantState, defender: CombatantState) -> void:
	var node := attacker.source_node
	if node == null or not is_instance_valid(node):
		if attacker.is_companion:
			node = _companion_actor
		elif not attacker.is_companion:
			node = _enemy_node
	var toward: Node3D = defender.source_node
	if toward == null or not is_instance_valid(toward):
		toward = _enemy_node if attacker.is_companion else _companion_actor
	if node == null or toward == null or not is_instance_valid(node) or not is_instance_valid(toward):
		await get_tree().create_timer(0.12).timeout
		return
	var origin := node.global_position
	var dir := toward.global_position - origin
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		dir = Vector3(0, 0, 1)
	var tip := origin + dir.normalized() * 0.55
	var tw := create_tween()
	tw.tween_property(node, "global_position", tip, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "global_position", origin, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


func _play_hit_react(defender: CombatantState) -> void:
	var node := defender.source_node
	if node == null or not is_instance_valid(node):
		node = _enemy_node if not defender.is_companion else _companion_actor
	if node == null or not is_instance_valid(node):
		return
	var origin := node.global_position
	var knock := origin + Vector3(randf_range(-0.2, 0.2), 0.12, randf_range(-0.15, 0.15))
	var tw := create_tween()
	tw.tween_property(node, "global_position", knock, 0.08)
	tw.tween_property(node, "global_position", origin, 0.12)


func get_session_records() -> Array:
	return _battle_records.duplicate(true)
