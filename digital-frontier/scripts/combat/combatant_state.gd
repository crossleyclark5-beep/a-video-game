class_name CombatantState
extends RefCounted
## Runtime fighter in a BattleDirector session.


enum Side { ALLY, ENEMY }

var side: int = Side.ALLY
var display_name: String = "Fighter"
var species_id: StringName = &""
var element: int = CombatTypes.Element.NEUTRAL
var tier: StringName = &"wild"  ## wild | elite | mini_boss | boss | rival

var max_hp: float = 40.0
var hp: float = 40.0
var attack: float = 8.0
var defense: float = 6.0
var speed: float = 10.0
var energy: float = 100.0

var dodging: bool = false
var defending: bool = false
var statuses: Dictionary = {}  ## status_id -> turns_remaining
var moves: Array = []  ## Array[CombatMove]
var source_node: Node3D = null
var is_companion: bool = false
var is_player_guard: bool = false  ## player can take chip damage as trainer


func is_alive() -> bool:
	return hp > 0.0


func get_hp_ratio() -> float:
	return hp / maxf(max_hp, 1.0)


func apply_damage(amount: float) -> float:
	var dmg := maxf(0.0, amount)
	if dodging:
		dmg *= 0.35
		dodging = false
	elif defending:
		dmg *= 0.55
		defending = false
	hp = maxf(0.0, hp - dmg)
	return dmg


func heal(amount: float) -> float:
	var before := hp
	hp = minf(max_hp, hp + amount)
	return hp - before


func clear_guards() -> void:
	dodging = false
	defending = false


func tick_statuses() -> PackedStringArray:
	var expired := PackedStringArray()
	var keys := statuses.keys()
	for key in keys:
		var turns := int(statuses[key]) - 1
		if turns <= 0:
			statuses.erase(key)
			expired.append(String(key))
		else:
			statuses[key] = turns
	return expired


func has_status(status_id: StringName) -> bool:
	return statuses.has(String(status_id)) or statuses.has(status_id)


func apply_status(status_id: StringName, turns: int = 2) -> void:
	statuses[String(status_id)] = turns


static func from_companion() -> CombatantState:
	var c := CombatantState.new()
	c.side = Side.ALLY
	c.is_companion = true
	c.display_name = CreatureManager.get_companion_nickname()
	c.species_id = CreatureManager.get_companion_id()
	c.element = CombatTypes.species_element(c.species_id)
	var stats := CreatureManager.get_stats()
	c.max_hp = maxf(30.0, float(stats.get("hp", 45.0)) + float(CreatureManager.get_level()) * 2.5)
	c.hp = c.max_hp * clampf(CreatureManager.get_health() / 100.0, 0.45, 1.0)
	c.attack = float(stats.get("attack", 8.0))
	c.defense = float(stats.get("defense", 6.0))
	c.speed = float(stats.get("speed", 10.0))
	c.energy = CreatureManager.get_energy()
	c.moves = CombatCatalog.moves_for_companion(c.species_id, CreatureManager.get_battle_style())
	c.tier = &"partner"
	return c


static func from_world_enemy(node: Node3D) -> CombatantState:
	var c := CombatantState.new()
	c.side = Side.ENEMY
	c.source_node = node
	if node is MiniBossActor:
		var m := node as MiniBossActor
		c.display_name = m.display_name
		c.species_id = m.species_id
		c.max_hp = m.max_hp
		c.hp = m.hp
		c.attack = float(m.damage) * 1.1
		c.defense = 10.0
		c.speed = 11.0
		c.tier = &"mini_boss"
	elif node is RegionBossActor:
		var b := node as RegionBossActor
		c.display_name = b.display_name
		c.species_id = b.species_id
		c.max_hp = b.max_hp
		c.hp = b.hp
		c.attack = float(b.damage) * 1.15
		c.defense = 14.0
		c.speed = 8.0
		c.tier = &"boss"
	elif node is EcosystemCreature:
		var e := node as EcosystemCreature
		c.display_name = e.display_name
		c.species_id = e.species_id
		c.max_hp = maxf(e.max_hp, 20.0)
		c.hp = e.hp if e.hp > 0.0 else c.max_hp
		c.attack = float(e.damage)
		c.defense = 5.0 + float(e.rarity) * 1.5
		c.speed = 9.0 + float(e.rarity)
		c.tier = &"elite" if e.rarity >= EcosystemCatalog.Rarity.RARE else &"wild"
	elif node is HostileCreatureActor:
		var h := node as HostileCreatureActor
		c.display_name = h.display_name
		c.species_id = h.species_id
		c.max_hp = h.max_hp
		c.hp = h.hp
		c.attack = float(h.damage)
		c.defense = 6.0
		c.speed = 10.0
		c.tier = &"wild"
	else:
		c.display_name = "Wild Signal"
		c.species_id = &"glitchmite"
		c.max_hp = 28.0
		c.hp = 28.0
		c.attack = 6.0
		c.defense = 5.0
		c.speed = 10.0
		c.tier = &"wild"
	c.element = CombatTypes.species_element(c.species_id)
	c.moves = CombatCatalog.moves_for_enemy(c.species_id, c.tier)
	return c
