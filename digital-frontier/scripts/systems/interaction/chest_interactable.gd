class_name ChestInteractable
extends Interactable
## Loot chest with rarity tiers and data-driven randomized rewards.
## Opened state persists via WorldManager flags (save-friendly).

enum Rarity {
	NORMAL,
	RARE,
	LEGENDARY,
}

@export var chest_id: StringName = &""
@export var rarity: Rarity = Rarity.NORMAL
@export var loot_table_id: StringName = &""
## Fallback if no loot table is found.
@export var loot_item_id: StringName = &"hex_shard"
@export var loot_quantity: int = 1


func _ready() -> void:
	super._ready()
	once = true
	if chest_id == &"":
		chest_id = StringName("chest_%s" % String(interaction_id))
	_apply_rarity_prompt()
	if WorldManager.is_chest_opened(chest_id):
		_mark_opened(false)


func _apply_rarity_prompt() -> void:
	match rarity:
		Rarity.RARE:
			prompt_text = "Press E to open rare chest"
		Rarity.LEGENDARY:
			prompt_text = "Press E to open legendary chest"
		_:
			prompt_text = "Press E to open chest"


func can_interact(actor: Node) -> bool:
	if WorldManager.is_chest_opened(chest_id):
		return false
	return super.can_interact(actor)


func _on_interact(_actor: Node) -> void:
	if WorldManager.is_chest_opened(chest_id):
		return
	var table_id := loot_table_id
	if table_id == &"":
		table_id = _default_table_for_rarity()
	var table: LootTableData = ResourceRegistry.get_loot_table(table_id)
	var summary := ""
	if table:
		var rolled: Dictionary = table.roll()
		summary = InventoryManager.grant_rewards(
			rolled.get("rewards", []),
			int(rolled.get("bits", 0)),
			_rarity_label(),
		)
	else:
		summary = InventoryManager.grant_rewards(
			[{"item_id": loot_item_id, "quantity": loot_quantity}],
			_fallback_bits(),
			_rarity_label(),
		)
	WorldManager.set_chest_opened(chest_id, true)
	EventBus.chest_opened.emit(chest_id, StringName(_rarity_key()))
	_mark_opened(true)
	## Quest listeners also hear inventory events from grant_rewards.


func _default_table_for_rarity() -> StringName:
	match rarity:
		Rarity.RARE:
			return &"loot_chest_rare"
		Rarity.LEGENDARY:
			return &"loot_chest_legendary"
		_:
			return &"loot_chest_normal"


func _fallback_bits() -> int:
	match rarity:
		Rarity.RARE:
			return 25
		Rarity.LEGENDARY:
			return 60
		_:
			return 8


func _rarity_label() -> String:
	match rarity:
		Rarity.RARE:
			return "Rare chest"
		Rarity.LEGENDARY:
			return "Legendary chest"
		_:
			return "Chest"


func _rarity_key() -> String:
	match rarity:
		Rarity.RARE:
			return "rare"
		Rarity.LEGENDARY:
			return "legendary"
		_:
			return "normal"


func _mark_opened(just_opened: bool) -> void:
	_used = true
	enabled = false
	prompt_text = "Empty"
	for child in get_children():
		if child is MeshInstance3D:
			var shade := Color(0.45, 0.45, 0.45)
			match rarity:
				Rarity.RARE:
					shade = Color(0.4, 0.45, 0.55) if just_opened else Color(0.35, 0.35, 0.4)
				Rarity.LEGENDARY:
					shade = Color(0.55, 0.45, 0.25) if just_opened else Color(0.4, 0.35, 0.25)
			(child as MeshInstance3D).modulate = shade
