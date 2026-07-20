extends BaseManager
## Creature collection, party, and companion state.
##
## WHY: Captured creatures have runtime instances (level, nickname) separate from
## CreatureData templates. Supports overworld party and home-screen companion.

var _captured: Dictionary = {}  ## instance_id -> Dictionary runtime snapshot
var _party: PackedStringArray = PackedStringArray()
var _companion_id: StringName = &""


func _initialize_manager() -> void:
	_log("CreatureManager initialized")


func get_party() -> PackedStringArray:
	return _party


func get_companion_id() -> StringName:
	return _companion_id


func export_state() -> Dictionary:
	return {
		&"captured": _captured.duplicate(true),
		&"party": _party.duplicate(),
		&"companion_id": _companion_id,
	}


func import_state(data: Dictionary) -> void:
	if data.has(&"captured"):
		_captured = data[&"captured"].duplicate(true)
	if data.has(&"party"):
		_party = data[&"party"].duplicate()
	if data.has(&"companion_id"):
		_companion_id = data[&"companion_id"]
