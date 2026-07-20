class_name LootTableData
extends IdentifiableResource
## Weighted loot table for chests, encounters, and exploration rewards.

## Entries: [{ "item_id": StringName, "weight": float, "min_qty": int, "max_qty": int }]
@export var entries: Array[Dictionary] = []
@export var rolls: int = 1
@export var bits_min: int = 0
@export var bits_max: int = 0


func roll() -> Dictionary:
	## Returns { "rewards": Array[{item_id, quantity}], "bits": int }
	var rewards: Array = []
	var count := maxi(1, rolls)
	for _i in count:
		var pick := _pick_entry()
		if pick.is_empty():
			continue
		var iid := StringName(str(pick.get("item_id", pick.get(&"item_id", ""))))
		if iid == &"":
			continue
		var min_q := int(pick.get("min_qty", pick.get(&"min_qty", 1)))
		var max_q := int(pick.get("max_qty", pick.get(&"max_qty", min_q)))
		if max_q < min_q:
			max_q = min_q
		var qty := randi_range(min_q, max_q)
		rewards.append({"item_id": iid, "quantity": qty})
	var bits := 0
	if bits_max > 0:
		bits = randi_range(mini(bits_min, bits_max), maxi(bits_min, bits_max))
	return {"rewards": rewards, "bits": bits}


func _pick_entry() -> Dictionary:
	if entries.is_empty():
		return {}
	var total := 0.0
	for e in entries:
		if e is Dictionary:
			total += float(e.get("weight", e.get(&"weight", 1.0)))
	if total <= 0.0:
		return entries[0] if entries[0] is Dictionary else {}
	var roll_v := randf() * total
	var acc := 0.0
	for e in entries:
		if e is Dictionary:
			acc += float(e.get("weight", e.get(&"weight", 1.0)))
			if roll_v <= acc:
				return e
	var last = entries[entries.size() - 1]
	return last if last is Dictionary else {}
