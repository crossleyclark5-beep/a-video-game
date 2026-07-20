class_name InteriorKinds
extends RefCounted
## Canonical interior recipe ids for ModularInteriorBuilder.


const HOUSE := &"house"
const SHOP := &"shop"
const RESTAURANT := &"restaurant"
const OFFICE := &"office"
const APARTMENT := &"apartment"
const WAREHOUSE := &"warehouse"
const TOWER := &"tower"
const LANDMARK := &"landmark"
const BARN := &"barn"
const BOOTH := &"booth"
const CABIN := &"cabin"
const FARMHOUSE := &"farmhouse"


static func stories_for(kind: StringName) -> int:
	match kind:
		TOWER:
			return 4
		APARTMENT:
			return 3
		WAREHOUSE, BARN:
			return 1
		BOOTH:
			return 1
		OFFICE, LANDMARK:
			return 2
		_:
			return 2


static func floor_name(kind: StringName, index: int) -> String:
	if index <= 0:
		match kind:
			SHOP, RESTAURANT, BOOTH:
				return "Shop Floor"
			WAREHOUSE, BARN:
				return "Ground Floor"
			_:
				return "Ground Floor"
	if kind == TOWER or kind == APARTMENT:
		return "Floor %d" % (index + 1)
	if index == 1:
		return "Upstairs"
	return "Floor %d" % (index + 1)


static func display_verb(kind: StringName) -> String:
	match kind:
		SHOP:
			return "shop"
		RESTAURANT:
			return "restaurant"
		OFFICE:
			return "office"
		WAREHOUSE:
			return "warehouse"
		BARN:
			return "barn"
		BOOTH:
			return "booth"
		TOWER:
			return "tower"
		APARTMENT:
			return "apartment"
		_:
			return "building"
