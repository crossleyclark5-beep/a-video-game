class_name ShopInteractable
extends Interactable
## Opens the Field Unit shop at Market Mile (and other world counters).

@export var shop_id: StringName = &"market_mile_shop"
@export var shopkeeper_name: String = "Mile Clerk"


func _ready() -> void:
	super._ready()
	prompt_verb = "Browse shop"


func _on_interact(_actor: Node) -> void:
	EventBus.ui_notification_requested.emit("%s: Welcome in — spend those Bits wisely." % shopkeeper_name, 2.2)
	var tree := get_tree()
	if tree == null:
		return
	var host := tree.current_scene
	if host == null:
		host = tree.root
	FieldUnitShop.present(host, shop_id)
