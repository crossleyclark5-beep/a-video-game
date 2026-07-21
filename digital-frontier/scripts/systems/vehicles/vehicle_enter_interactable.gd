class_name VehicleEnterInteractable
extends Interactable
## Enter / exit prompt for a VehicleBase.


var _vehicle: VehicleBase = null


func bind_vehicle(vehicle: VehicleBase) -> void:
	_vehicle = vehicle
	prompt_verb = "Enter %s" % vehicle.get_display_name()


func _ready() -> void:
	super._ready()
	once = false
	if _vehicle:
		prompt_verb = "Enter %s" % _vehicle.get_display_name()


func can_interact(actor: Node) -> bool:
	if _vehicle == null or not _vehicle.can_mount(actor):
		return false
	return super.can_interact(actor)


func get_prompt_text() -> String:
	if _vehicle:
		prompt_verb = "Enter %s" % _vehicle.get_display_name()
	return super.get_prompt_text()


func _on_interact(actor: Node) -> void:
	if _vehicle:
		_vehicle.try_mount(actor)
