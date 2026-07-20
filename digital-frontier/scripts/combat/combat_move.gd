class_name CombatMove
extends RefCounted
## One battle action a companion or enemy can perform.


enum Category {
	ATTACK,
	SPECIAL,
	DEFEND,
	STATUS,
}


var id: StringName = &""
var display_name: String = "Strike"
var category: int = Category.ATTACK
var element: int = CombatTypes.Element.NEUTRAL
var power: float = 12.0
var accuracy: float = 0.95
var energy_cost: float = 0.0
var heal_self: float = 0.0
var status_id: StringName = &""
var status_chance: float = 0.0
var blurb: String = ""


static func make(
	p_id: StringName,
	p_name: String,
	p_category: int,
	p_element: int,
	p_power: float,
	p_accuracy: float = 0.95,
	p_cost: float = 0.0,
	p_heal: float = 0.0,
	p_status: StringName = &"",
	p_status_chance: float = 0.0,
	p_blurb: String = "",
) -> CombatMove:
	var m := CombatMove.new()
	m.id = p_id
	m.display_name = p_name
	m.category = p_category
	m.element = p_element
	m.power = p_power
	m.accuracy = p_accuracy
	m.energy_cost = p_cost
	m.heal_self = p_heal
	m.status_id = p_status
	m.status_chance = p_status_chance
	m.blurb = p_blurb
	return m
