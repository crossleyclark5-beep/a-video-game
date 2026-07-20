class_name IdentifiableResource
extends Resource
## Base class for all data-driven game content resources.
##
## Every content resource must have a stable StringName ID used for lookup,
## save serialization, and cross-references between data files.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""


func get_id() -> StringName:
	return id


func _validate_property(property: Dictionary) -> void:
	if property.name == &"id" and id.is_empty():
		push_warning("%s: id is empty" % resource_path)
