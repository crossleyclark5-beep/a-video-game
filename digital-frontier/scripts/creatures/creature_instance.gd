class_name CreatureInstance
extends RefCounted
## Runtime state for one owned creature companion.
##
## Species templates live in CreatureData (.tres). This holds the living
## instance: needs, growth, skin, personality, evolution stage.
## Designed for collection, trading, and multi-creature parties.

const NEED_MIN := 0.0
const NEED_MAX := 100.0
const XP_PER_LEVEL_BASE := 40

## Soft decay rates per real-time second (can be scaled by personality).
const DECAY_HUNGER := 0.35
const DECAY_ENERGY := 0.18
const DECAY_HAPPINESS := 0.08
const DECAY_HEALTH_NEGLECT := 0.05

var instance_id: StringName = &""
var species_id: StringName = &""
var nickname: String = ""

var level: int = 1
var experience: int = 0

var hunger: float = 72.0       ## fullness: high = fed
var happiness: float = 70.0
var energy: float = 80.0
var friendship: float = 40.0
var health: float = 95.0

## Combat / adventure stats (derived + trained).
var stats: Dictionary = {
	"hp": 45,
	"attack": 8,
	"defense": 6,
	"speed": 12,
}

var skin_id: StringName = &"default"
var evolution_stage: int = 0

## Personality axes 0–100 — drive AI weights, not hardcoded behaviors.
var personality: Dictionary = {
	"playful": 55.0,
	"curious": 60.0,
	"affectionate": 50.0,
	"lazy": 35.0,
	"brave": 45.0,
}

var unlocked_skin_ids: PackedStringArray = PackedStringArray(["default"])


static func create_from_species(species: CreatureData, custom_nickname: String = "") -> CreatureInstance:
	var inst := CreatureInstance.new()
	inst.instance_id = StringName("inst_%s_%d" % [String(species.id), Time.get_ticks_msec()])
	inst.species_id = species.id
	inst.nickname = custom_nickname if not custom_nickname.is_empty() else species.display_name
	inst.skin_id = species.default_skin_id if species.default_skin_id != &"" else &"default"
	inst.evolution_stage = 0
	inst.level = 1
	inst.experience = 0
	inst.stats = species.base_stats.duplicate(true)
	if inst.stats.is_empty():
		inst.stats = {"hp": 40, "attack": 7, "defense": 5, "speed": 10}
	inst.personality = species.default_personality.duplicate(true)
	if inst.personality.is_empty():
		inst.personality = {
			"playful": 55.0,
			"curious": 60.0,
			"affectionate": 50.0,
			"lazy": 35.0,
			"brave": 45.0,
		}
	inst.hunger = 75.0
	inst.happiness = 72.0
	inst.energy = 85.0
	inst.friendship = 25.0
	inst.health = 100.0
	inst.unlocked_skin_ids = PackedStringArray([String(inst.skin_id)])
	return inst


func get_species() -> CreatureData:
	return ResourceRegistry.get_creature(species_id)


func get_xp_to_next_level() -> int:
	return XP_PER_LEVEL_BASE + (level - 1) * 15


func get_xp_progress() -> float:
	var need := get_xp_to_next_level()
	if need <= 0:
		return 1.0
	return clampf(float(experience) / float(need), 0.0, 1.0)


func add_experience(amount: int) -> Dictionary:
	## Returns {leveled_up: bool, levels_gained: int, new_level: int}
	var result := {"leveled_up": false, "levels_gained": 0, "new_level": level}
	if amount <= 0:
		return result
	experience += amount
	var gained := 0
	while experience >= get_xp_to_next_level() and level < 99:
		experience -= get_xp_to_next_level()
		level += 1
		gained += 1
		_apply_level_growth()
	if gained > 0:
		result["leveled_up"] = true
		result["levels_gained"] = gained
		result["new_level"] = level
	return result


func get_personality(trait_id: String, default: float = 50.0) -> float:
	return float(personality.get(trait_id, default))


func get_stat(stat_id: String, default: float = 0.0) -> float:
	return float(stats.get(stat_id, default))


func get_walk_speed_multiplier() -> float:
	## Mood + personality modulate home locomotion.
	var mult := 1.0
	if energy < 30.0:
		mult *= 0.65
	elif happiness > 75.0:
		mult *= 1.15
	if happiness < 35.0:
		mult *= 0.75
	mult *= lerpf(0.85, 1.2, get_personality("curious") / 100.0)
	mult *= lerpf(1.1, 0.75, get_personality("lazy") / 100.0)
	return clampf(mult, 0.45, 1.4)


func get_behavior_bias() -> StringName:
	if energy < 28.0 or (get_personality("lazy") > 70.0 and energy < 45.0):
		return &"sleep"
	if hunger < 35.0:
		return &"eat"
	if happiness < 40.0:
		return &"play"
	if happiness > 70.0 and get_personality("playful") > 50.0 and energy > 55.0:
		return &"playful"
	if get_personality("curious") > 65.0 and energy > 50.0:
		return &"explore"
	return &"idle"


func apply_care(action: StringName, deltas: Dictionary) -> void:
	for key: String in deltas.keys():
		_add_need(key, float(deltas[key]))
	## Affectionate creatures gain a little extra friendship from pet/play.
	if action == &"pet" or action == &"play":
		var bonus := (get_personality("affectionate") - 50.0) * 0.04
		_add_need("friendship", bonus)


func apply_passive_decay(delta: float) -> void:
	var hunger_rate := DECAY_HUNGER * lerpf(1.15, 0.85, get_personality("lazy") / 100.0)
	var energy_rate := DECAY_ENERGY * lerpf(0.85, 1.2, get_personality("playful") / 100.0)
	var happy_rate := DECAY_HAPPINESS

	hunger = maxf(NEED_MIN, hunger - hunger_rate * delta)
	energy = maxf(NEED_MIN, energy - energy_rate * delta)
	if hunger < 25.0:
		happy_rate *= 2.0
	happiness = maxf(NEED_MIN, happiness - happy_rate * delta)

	var neglect := 0
	if hunger < 25.0:
		neglect += 1
	if energy < 20.0:
		neglect += 1
	if happiness < 25.0:
		neglect += 1
	if neglect >= 2:
		health = maxf(NEED_MIN, health - DECAY_HEALTH_NEGLECT * delta * float(neglect))

	if hunger > 70.0 and energy > 60.0 and happiness > 60.0:
		health = minf(NEED_MAX, health + 0.02 * delta)
		friendship = minf(NEED_MAX, friendship + 0.01 * delta)


func to_dict() -> Dictionary:
	return {
		&"instance_id": String(instance_id),
		&"species_id": String(species_id),
		&"nickname": nickname,
		&"level": level,
		&"experience": experience,
		&"hunger": hunger,
		&"happiness": happiness,
		&"energy": energy,
		&"friendship": friendship,
		&"health": health,
		&"stats": stats.duplicate(true),
		&"skin_id": String(skin_id),
		&"evolution_stage": evolution_stage,
		&"personality": personality.duplicate(true),
		&"unlocked_skin_ids": Array(unlocked_skin_ids),
	}


static func from_dict(data: Dictionary) -> CreatureInstance:
	var inst := CreatureInstance.new()
	if data.is_empty():
		return inst
	inst.instance_id = StringName(str(data.get(&"instance_id", data.get("instance_id", ""))))
	inst.species_id = StringName(str(data.get(&"species_id", data.get("species_id", ""))))
	inst.nickname = str(data.get(&"nickname", data.get("nickname", "")))
	inst.level = int(data.get(&"level", data.get("level", 1)))
	inst.experience = int(data.get(&"experience", data.get("experience", 0)))
	inst.hunger = float(data.get(&"hunger", data.get("hunger", 72.0)))
	inst.happiness = float(data.get(&"happiness", data.get("happiness", 70.0)))
	inst.energy = float(data.get(&"energy", data.get("energy", 80.0)))
	inst.friendship = float(data.get(&"friendship", data.get("friendship", 40.0)))
	inst.health = float(data.get(&"health", data.get("health", 95.0)))
	var st = data.get(&"stats", data.get("stats", {}))
	if st is Dictionary:
		inst.stats = (st as Dictionary).duplicate(true)
	inst.skin_id = StringName(str(data.get(&"skin_id", data.get("skin_id", "default"))))
	inst.evolution_stage = int(data.get(&"evolution_stage", data.get("evolution_stage", 0)))
	var per = data.get(&"personality", data.get("personality", {}))
	if per is Dictionary:
		inst.personality = (per as Dictionary).duplicate(true)
	var skins = data.get(&"unlocked_skin_ids", data.get("unlocked_skin_ids", ["default"]))
	if skins is Array:
		inst.unlocked_skin_ids = PackedStringArray(skins)
	inst.clamp_needs()
	return inst


func clamp_needs() -> void:
	hunger = clampf(hunger, NEED_MIN, NEED_MAX)
	happiness = clampf(happiness, NEED_MIN, NEED_MAX)
	energy = clampf(energy, NEED_MIN, NEED_MAX)
	friendship = clampf(friendship, NEED_MIN, NEED_MAX)
	health = clampf(health, NEED_MIN, NEED_MAX)


func _add_need(key: String, amount: float) -> void:
	match key:
		"hunger":
			hunger = clampf(hunger + amount, NEED_MIN, NEED_MAX)
		"happiness":
			happiness = clampf(happiness + amount, NEED_MIN, NEED_MAX)
		"energy":
			energy = clampf(energy + amount, NEED_MIN, NEED_MAX)
		"friendship":
			friendship = clampf(friendship + amount, NEED_MIN, NEED_MAX)
		"health":
			health = clampf(health + amount, NEED_MIN, NEED_MAX)


func _apply_level_growth() -> void:
	var species := get_species()
	var rates: Dictionary = {}
	if species:
		rates = species.growth_rates
	for key in stats.keys():
		var growth := float(rates.get(key, 1.5))
		stats[key] = float(stats[key]) + growth
	## Leveling feels good at home too.
	happiness = minf(NEED_MAX, happiness + 4.0)
	friendship = minf(NEED_MAX, friendship + 2.0)
