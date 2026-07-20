class_name ChestInteractable
extends Interactable
## Loot chest — opens in place. Never changes scenes or kicks the player out.

enum Rarity {
	NORMAL,
	RARE,
	LEGENDARY,
}

enum ChestState {
	CLOSED,
	OPENING,
	OPENED,
}

@export var chest_id: StringName = &""
@export var rarity: Rarity = Rarity.NORMAL
@export var loot_table_id: StringName = &""
@export var loot_item_id: StringName = &"hex_shard"
@export var loot_quantity: int = 1
## Hours until this chest can refill. 0 = never respawns.
@export var respawn_hours: float = 0.0
@export var creature_xp_on_open: int = 6

var _lid: MeshInstance3D = null
var _chest_state: ChestState = ChestState.CLOSED
var _rest_y: float = 0.0


func _ready() -> void:
	super._ready()
	once = false
	if chest_id == &"":
		chest_id = StringName("chest_%s" % String(interaction_id))
	_rest_y = position.y
	_cache_lid()
	_apply_rarity_prompt()
	WorldManager.refresh_chest_respawn(chest_id, respawn_hours)
	if WorldManager.is_chest_opened(chest_id):
		_apply_opened_visual(false)
		_chest_state = ChestState.OPENED
		enabled = respawn_hours > 0.0
		if not enabled:
			prompt_verb = "Empty"


func get_chest_state() -> ChestState:
	return _chest_state


func _cache_lid() -> void:
	_lid = get_node_or_null("Lid") as MeshInstance3D
	if _lid:
		return
	var meshes: Array[MeshInstance3D] = []
	for child in get_children():
		if child is MeshInstance3D:
			meshes.append(child as MeshInstance3D)
	if meshes.size() >= 2:
		_lid = meshes[1]


func _apply_rarity_prompt() -> void:
	match rarity:
		Rarity.RARE:
			prompt_verb = "Open rare chest"
		Rarity.LEGENDARY:
			prompt_verb = "Open legendary chest"
		_:
			prompt_verb = "Open chest"


func can_interact(actor: Node) -> bool:
	if _chest_state == ChestState.OPENING:
		return false
	var available := WorldManager.refresh_chest_respawn(chest_id, respawn_hours)
	if available and _chest_state == ChestState.OPENED:
		_reset_for_respawn()
	if not available or _chest_state == ChestState.OPENED:
		return false
	return super.can_interact(actor)


func _reset_for_respawn() -> void:
	_chest_state = ChestState.CLOSED
	_used = false
	enabled = true
	_apply_rarity_prompt()
	position.y = _rest_y
	if _lid:
		_lid.rotation_degrees.x = 0.0
	for child in get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			if mesh.material_override is StandardMaterial3D:
				var mat := (mesh.material_override as StandardMaterial3D).duplicate()
				mat.albedo_color = Color.WHITE
				mesh.material_override = mat


func _on_interact(_actor: Node) -> void:
	if _chest_state != ChestState.CLOSED:
		return
	if WorldManager.is_chest_opened(chest_id) and respawn_hours <= 0.0:
		return
	_chest_state = ChestState.OPENING
	_play_open_feedback()
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
	EventBus.sfx_play_requested.emit(&"chest_open", global_position)
	DeviceService.notify_event(&"chest_open")
	DeviceService.play_haptic(&"loot", 0.45)
	if creature_xp_on_open > 0:
		CreatureManager.grant_adventure_experience(creature_xp_on_open)
	_apply_opened_visual(true)
	_chest_state = ChestState.OPENED
	enabled = respawn_hours > 0.0
	if not enabled:
		prompt_verb = "Empty"
	if summary.is_empty():
		EventBus.ui_notification_requested.emit("%s opened" % _rarity_label(), 2.0)


func _play_open_feedback() -> void:
	var body: MeshInstance3D = null
	for child in get_children():
		if child is MeshInstance3D and child != _lid:
			body = child as MeshInstance3D
			break
	if _lid:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_lid, "rotation_degrees:x", -70.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_lid, "position:y", _lid.position.y + 0.15, 0.28)
	elif body:
		var base_y := body.position.y
		var hop := create_tween()
		hop.tween_property(body, "position:y", base_y + 0.18, 0.12)
		hop.tween_property(body, "position:y", base_y, 0.18)


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


func _apply_opened_visual(just_opened: bool) -> void:
	_used = true
	for child in get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			var shade := Color(0.45, 0.45, 0.45)
			match rarity:
				Rarity.RARE:
					shade = Color(0.4, 0.45, 0.55) if just_opened else Color(0.35, 0.35, 0.4)
				Rarity.LEGENDARY:
					shade = Color(0.55, 0.45, 0.25) if just_opened else Color(0.4, 0.35, 0.25)
			if mesh.material_override is StandardMaterial3D:
				var mat := (mesh.material_override as StandardMaterial3D).duplicate()
				mat.albedo_color = shade
				mesh.material_override = mat
			else:
				mesh.material_override = StylizedMesh.make_material(shade, 0.75)
	if _lid and just_opened == false:
		_lid.rotation_degrees.x = -70.0
