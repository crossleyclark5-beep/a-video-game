class_name ExternalPropCatalog
extends RefCounted
## Curated external GLB props — stylized handheld-safe subset.


const ROOT := "res://assets/models/external/"

## id -> { path, scale, y_offset, collision, category }
const PROPS: Dictionary = {
	## Nature
	&"tree_pine": {"path": "nature/tree_pine.glb", "scale": 1.35, "y": 0.0, "collision": true, "category": &"nature"},
	&"tree_oak": {"path": "nature/tree_oak.glb", "scale": 1.2, "y": 0.0, "collision": true, "category": &"nature"},
	&"tree_default": {"path": "nature/tree_default.glb", "scale": 1.15, "y": 0.0, "collision": true, "category": &"nature"},
	&"bush": {"path": "nature/bush.glb", "scale": 1.4, "y": 0.0, "collision": false, "category": &"nature"},
	&"flower_red": {"path": "nature/flower_red.glb", "scale": 1.2, "y": 0.0, "collision": false, "category": &"nature"},
	&"flower_yellow": {"path": "nature/flower_yellow.glb", "scale": 1.2, "y": 0.0, "collision": false, "category": &"nature"},
	&"rock_large": {"path": "nature/rock_large.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"nature"},
	&"rock_tall": {"path": "nature/rock_tall.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"nature"},
	&"rock_small": {"path": "nature/rock_small.glb", "scale": 1.2, "y": 0.0, "collision": false, "category": &"nature"},
	&"log": {"path": "nature/log.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"nature"},
	&"mushroom": {"path": "nature/mushroom.glb", "scale": 1.3, "y": 0.0, "collision": false, "category": &"nature"},
	&"campfire": {"path": "nature/campfire.glb", "scale": 1.1, "y": 0.0, "collision": false, "category": &"nature"},
	&"tent": {"path": "nature/tent.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"nature"},
	## Town
	&"lantern": {"path": "town/lantern.glb", "scale": 1.2, "y": 0.0, "collision": false, "category": &"town"},
	&"fence": {"path": "town/fence.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"town"},
	&"fence_gate": {"path": "town/fence_gate.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"town"},
	&"bench": {"path": "town/bench.glb", "scale": 1.15, "y": 0.0, "collision": true, "category": &"town"},
	&"market_stall": {"path": "town/market_stall.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"town"},
	&"cart": {"path": "town/cart.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"town"},
	&"fountain": {"path": "town/fountain.glb", "scale": 0.85, "y": 0.0, "collision": true, "category": &"town"},
	&"banner": {"path": "town/banner.glb", "scale": 1.0, "y": 0.0, "collision": false, "category": &"town"},
	## Interior
	&"bed": {"path": "interior/bed.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"interior"},
	&"sofa": {"path": "interior/sofa.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"interior"},
	&"coffee_table": {"path": "interior/coffee_table.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"interior"},
	&"chair": {"path": "interior/chair.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"interior"},
	&"desk": {"path": "interior/desk.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"interior"},
	&"bookcase": {"path": "interior/bookcase.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"interior"},
	&"fridge": {"path": "interior/fridge.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"interior"},
	&"stove": {"path": "interior/stove.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"interior"},
	&"sink": {"path": "interior/sink.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"interior"},
	&"toilet": {"path": "interior/toilet.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"interior"},
	&"television": {"path": "interior/television.glb", "scale": 1.0, "y": 0.0, "collision": false, "category": &"interior"},
	&"potted_plant": {"path": "interior/potted_plant.glb", "scale": 1.0, "y": 0.0, "collision": false, "category": &"interior"},
	&"floor_lamp": {"path": "interior/floor_lamp.glb", "scale": 1.0, "y": 0.0, "collision": false, "category": &"interior"},
	## Adventure / gameplay props
	&"pillar": {"path": "adventure/pillar.glb", "scale": 1.2, "y": 0.0, "collision": true, "category": &"adventure"},
	&"ruin_rocks": {"path": "adventure/ruin_rocks.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"adventure"},
	&"flag": {"path": "adventure/flag.glb", "scale": 1.1, "y": 0.0, "collision": false, "category": &"adventure"},
	&"treasure_chest": {"path": "adventure/treasure_chest.glb", "scale": 1.15, "y": 0.0, "collision": true, "category": &"adventure"},
	&"supply_crate": {"path": "adventure/supply_crate.glb", "scale": 1.1, "y": 0.0, "collision": true, "category": &"adventure"},
	&"supply_crate_item": {"path": "adventure/supply_crate_item.glb", "scale": 1.1, "y": 0.0, "collision": true, "category": &"adventure"},
	&"barrel": {"path": "adventure/barrel.glb", "scale": 1.2, "y": 0.0, "collision": true, "category": &"adventure"},
	&"quest_key": {"path": "adventure/quest_key.glb", "scale": 1.4, "y": 0.0, "collision": false, "category": &"adventure"},
	&"collectible_coin": {"path": "adventure/collectible_coin.glb", "scale": 1.5, "y": 0.0, "collision": false, "category": &"adventure"},
	## Transport — Field Skiff aircraft + town vehicles (Kenney CC0)
	&"craft_speeder": {"path": "transport/craft_speeder.glb", "scale": 1.35, "y": 0.35, "collision": true, "category": &"transport"},
	&"craft_speeder_alt": {"path": "transport/craft_speeder_alt.glb", "scale": 1.35, "y": 0.35, "collision": true, "category": &"transport"},
	&"craft_racer": {"path": "transport/craft_racer.glb", "scale": 1.3, "y": 0.35, "collision": true, "category": &"transport"},
	&"craft_cargo": {"path": "transport/craft_cargo.glb", "scale": 1.25, "y": 0.4, "collision": true, "category": &"transport"},
	&"hangar_small": {"path": "transport/hangar_small.glb", "scale": 1.4, "y": 0.0, "collision": true, "category": &"transport"},
	&"park_car": {"path": "transport/park_car.glb", "scale": 1.0, "y": 0.0, "collision": true, "category": &"transport"},
	&"adventure_suv": {"path": "transport/adventure_suv.glb", "scale": 1.05, "y": 0.0, "collision": true, "category": &"transport"},
}


static func has_prop(prop_id: StringName) -> bool:
	return PROPS.has(prop_id)


static func prop_path(prop_id: StringName) -> String:
	if not PROPS.has(prop_id):
		return ""
	return ROOT + String(PROPS[prop_id]["path"])


static func prop_def(prop_id: StringName) -> Dictionary:
	return PROPS.get(prop_id, {})
