extends Node
## Combat system smoke — types, catalog, combatant build, director flow, NFC record.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("COMBAT_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 4:
		return
	_done = true
	var ok := true

	if not CreatureManager.select_partner(&"emberling", "Battlebuddy"):
		push_error("select_partner failed")
		ok = false

	## Type chart
	var ember_vs_nature := CombatTypes.affinity(CombatTypes.Element.EMBER, CombatTypes.Element.NATURE)
	var ember_vs_tide := CombatTypes.affinity(CombatTypes.Element.EMBER, CombatTypes.Element.TIDE)
	if ember_vs_nature < 1.2 or ember_vs_tide > 0.85:
		push_error("affinity chart broken")
		ok = false
	if CombatTypes.species_element(&"emberling") != CombatTypes.Element.EMBER:
		push_error("emberling element wrong")
		ok = false
	if CombatTypes.species_element(&"hollow_warden") != CombatTypes.Element.HEX:
		push_error("warden element wrong")
		ok = false

	## Catalog moves + rewards
	var moves: Array = CombatCatalog.moves_for_companion(&"emberling", CreatureManager.get_battle_style())
	if moves.size() < 2:
		push_error("companion moves too few")
		ok = false
	var boss_moves: Array = CombatCatalog.moves_for_enemy(&"hollow_warden", &"boss")
	if boss_moves.size() < 2:
		push_error("boss moves missing uniqueness")
		ok = false
	var reward: Dictionary = CombatCatalog.reward_for(&"boss", 5)
	if int(reward.get("xp", 0)) < 20 or int(reward.get("bits", 0)) < 50:
		push_error("boss reward too small")
		ok = false

	## Combatant from companion
	var ally := CombatantState.from_companion()
	if not ally.is_companion or ally.max_hp < 20.0:
		push_error("ally combatant invalid")
		ok = false
	ally.apply_status(&"shock", 2)
	if not ally.has_status(&"shock"):
		push_error("status apply failed")
		ok = false
	ally.tick_statuses()
	var dmg := ally.apply_damage(10.0)
	if dmg <= 0.0:
		push_error("damage failed")
		ok = false
	ally.dodging = true
	var reduced := ally.apply_damage(20.0)
	if reduced >= 20.0:
		push_error("dodge did not reduce damage")
		ok = false

	## Fake world enemy node → combatant (plain node hits wild fallback)
	var dummy := Node3D.new()
	dummy.name = "DummyHostile"
	add_child(dummy)
	var enemy := CombatantState.from_world_enemy(dummy)
	if enemy.tier != &"wild" or enemy.max_hp <= 0.0:
		push_error("fallback enemy combatant invalid")
		ok = false
	enemy.species_id = &"glitchmite"
	enemy.moves = CombatCatalog.moves_for_enemy(&"glitchmite", &"wild")
	if enemy.moves.is_empty():
		push_error("enemy moves empty")
		ok = false

	## Typed hostile via MiniBoss-like property bag on RegionBossActor path
	var mite := HostileCreatureActor.new()
	add_child(mite)
	mite.species_id = &"glitchmite"
	mite.display_name = "Test Mite"
	mite.max_hp = 28.0
	mite.hp = 28.0
	mite.damage = 6
	var typed := CombatantState.from_world_enemy(mite)
	if typed.species_id != &"glitchmite":
		push_error("typed hostile combatant failed")
		ok = false
	mite.queue_free()

	## NFC record schema
	var record := CombatCatalog.make_battle_record(true, &"glitchmite", &"wild", 3)
	if int(record.get(&"schema", 0)) != 1:
		push_error("battle record schema missing")
		ok = false
	if String(record.get(&"companion_id", "")) == "":
		push_error("battle record missing companion")
		ok = false
	print("nfc_record_keys=", record.keys())

	## Director exists + idle
	var director := BattleDirector.new()
	director.name = "SmokeBattleDirector"
	add_child(director)
	if director.is_active():
		push_error("director should start idle")
		ok = false

	## Level-gated progression
	var inst := CreatureManager.get_active_instance()
	inst.level = 10
	var advanced: Array = CombatCatalog.moves_for_companion(&"emberling", &"aggressive")
	var has_finale := false
	for m in advanced:
		if m is CombatMove and (m as CombatMove).id == &"partner_finale":
			has_finale = true
	if not has_finale:
		push_error("level 10 finale missing")
		ok = false

	## Grant battle XP path used by director
	var before_xp := CreatureManager.get_level()
	CreatureManager.grant_adventure_experience(int(CombatCatalog.reward_for(&"wild", before_xp).get("xp", 8)))
	CreatureManager.record_companion_battle(true, &"glitchmite", false)
	var hist := CreatureManager.get_battle_history()
	if int(hist.get("wins", 0)) < 1:
		push_error("battle history not updated")
		ok = false

	dummy.queue_free()
	director.queue_free()

	if ok:
		print("COMBAT_SMOKE_OK")
	else:
		print("COMBAT_SMOKE_FAIL")
		get_tree().quit(1)
		return
	get_tree().quit(0)
