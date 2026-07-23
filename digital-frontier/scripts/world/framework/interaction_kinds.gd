class_name InteractionKinds
extends RefCounted
## Unified interaction vocabulary — every interactable maps to one kind.
## Avoid per-feature interaction systems; extend this catalog instead.


enum Kind {
	TALK,
	OPEN,
	COLLECT,
	ACTIVATE,
	SCAN,
	RIDE,
	PHOTOGRAPH,
	FISH,
	MINE,
	HARVEST,
	READ,
	SHOP,
	ENTER,
	BOARD,  ## aircraft / vehicle
	CUSTOM,
}


static func id_of(kind: int) -> StringName:
	match kind:
		Kind.TALK: return &"talk"
		Kind.OPEN: return &"open"
		Kind.COLLECT: return &"collect"
		Kind.ACTIVATE: return &"activate"
		Kind.SCAN: return &"scan"
		Kind.RIDE: return &"ride"
		Kind.PHOTOGRAPH: return &"photograph"
		Kind.FISH: return &"fish"
		Kind.MINE: return &"mine"
		Kind.HARVEST: return &"harvest"
		Kind.READ: return &"read"
		Kind.SHOP: return &"shop"
		Kind.ENTER: return &"enter"
		Kind.BOARD: return &"board"
		_: return &"custom"


static func verb_of(kind: int) -> String:
	match kind:
		Kind.TALK: return "Talk"
		Kind.OPEN: return "Open"
		Kind.COLLECT: return "Collect"
		Kind.ACTIVATE: return "Activate"
		Kind.SCAN: return "Scan"
		Kind.RIDE: return "Ride"
		Kind.PHOTOGRAPH: return "Photograph"
		Kind.FISH: return "Fish"
		Kind.MINE: return "Mine"
		Kind.HARVEST: return "Harvest"
		Kind.READ: return "Read"
		Kind.SHOP: return "Shop"
		Kind.ENTER: return "Enter"
		Kind.BOARD: return "Board"
		_: return "Interact"


## Map existing Interactable subclasses → kind (plugin table for future types).
static func kind_for_class(class_nm: String) -> int:
	match class_nm:
		"NpcTalkInteractable":
			return Kind.TALK
		"ChestInteractable":
			return Kind.OPEN
		"DiscoverableInteractable":
			return Kind.SCAN
		"ShopInteractable":
			return Kind.SHOP
		"SignInteractable":
			return Kind.READ
		"VehicleEnterInteractable":
			return Kind.RIDE
		"AircraftPadInteractable":
			return Kind.BOARD
		"HollowSealInteractable", "HollowGateInteractable":
			return Kind.ACTIVATE
		_:
			return Kind.CUSTOM


static func all_kinds() -> Array[int]:
	return [
		Kind.TALK, Kind.OPEN, Kind.COLLECT, Kind.ACTIVATE, Kind.SCAN,
		Kind.RIDE, Kind.PHOTOGRAPH, Kind.FISH, Kind.MINE, Kind.HARVEST,
		Kind.READ, Kind.SHOP, Kind.ENTER, Kind.BOARD, Kind.CUSTOM,
	]
