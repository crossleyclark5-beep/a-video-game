class_name IdValidator
extends RefCounted
## Validates StringName IDs used across data files.

static func is_valid_id(id: StringName) -> bool:
	var s := String(id)
	if s.is_empty():
		return false
	# snake_case alphanumeric + underscores
	var regex := RegEx.new()
	regex.compile("^[a-z][a-z0-9_]*$")
	return regex.search(s) != null
