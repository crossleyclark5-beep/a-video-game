class_name ExternalPropCatalog
extends RefCounted
## Curated external GLB props — scales normalized via AssetStandardizer height targets.
##
## Raw Kenney heights vary wildly. Catalog `scale` fits each prop to DF world units
## (human adult ≈ 1.7m). Optional `mesh_yaw` rotates +Z mesh nose to world forward.


const ROOT := "res://assets/models/external/"

## id -> { path, scale, y, collision, category, mesh_yaw?, tint? }
const PROPS: Dictionary = {
	## Nature — landmark trees taller than player
	&"tree_pine": {"path": "nature/tree_pine.glb", "scale": 3.2, "y": 0.0, "collision": true, "category": &"nature", "target_height": 6.0},
	&"tree_oak": {"path": "nature/tree_oak.glb", "scale": 4.2, "y": 0.0, "collision": true, "category": &"nature", "target_height": 7.5},
	&"tree_default": {"path": "nature/tree_default.glb", "scale": 3.6, "y": 0.0, "collision": true, "category": &"nature", "target_height": 5.5},
	&"bush": {"path": "nature/bush.glb", "scale": 2.2, "y": 0.0, "collision": false, "category": &"nature", "target_height": 0.85},
	&"flower_red": {"path": "nature/flower_red.glb", "scale": 1.8, "y": 0.0, "collision": false, "category": &"nature"},
	&"flower_yellow": {"path": "nature/flower_yellow.glb", "scale": 1.8, "y": 0.0, "collision": false, "category": &"nature"},
	&"rock_large": {"path": "nature/rock_large.glb", "scale": 1.8, "y": 0.0, "collision": true, "category": &"nature"},
	&"rock_tall": {"path": "nature/rock_tall.glb", "scale": 2.0, "y": 0.0, "collision": true, "category": &"nature"},
	&"rock_small": {"path": "nature/rock_small.glb", "scale": 1.6, "y": 0.0, "collision": false, "category": &"nature"},
	&"log": {"path": "nature/log.glb", "scale": 1.6, "y": 0.0, "collision": true, "category": &"nature"},
	&"mushroom": {"path": "nature/mushroom.glb", "scale": 1.5, "y": 0.0, "collision": false, "category": &"nature", "tint": Color(0.85, 0.35, 0.3)},
	&"campfire": {"path": "nature/campfire.glb", "scale": 1.35, "y": 0.0, "collision": false, "category": &"nature"},
	&"tent": {"path": "nature/tent.glb", "scale": 1.55, "y": 0.0, "collision": true, "category": &"nature"},
	## Town
	&"lantern": {"path": "town/lantern.glb", "scale": 1.6, "y": 0.0, "collision": false, "category": &"town"},
	&"fence": {"path": "town/fence.glb", "scale": 1.45, "y": 0.0, "collision": true, "category": &"town"},
	&"fence_gate": {"path": "town/fence_gate.glb", "scale": 1.45, "y": 0.0, "collision": true, "category": &"town"},
	&"bench": {"path": "town/bench.glb", "scale": 2.1, "y": 0.0, "collision": true, "category": &"town", "target_height": 0.55},
	&"market_stall": {"path": "town/market_stall.glb", "scale": 1.55, "y": 0.0, "collision": true, "category": &"town", "target_height": 2.4},
	&"cart": {"path": "town/cart.glb", "scale": 1.7, "y": 0.0, "collision": true, "category": &"town", "target_height": 1.4},
	&"fountain": {"path": "town/fountain.glb", "scale": 1.8, "y": 0.0, "collision": true, "category": &"town", "target_height": 1.25},
	&"banner": {"path": "town/banner.glb", "scale": 1.8, "y": 0.0, "collision": false, "category": &"town"},
	## Interior — furniture sized for 1.7m humans
	&"bed": {"path": "interior/bed.glb", "scale": 1.55, "y": 0.0, "collision": true, "category": &"interior", "target_height": 0.75},
	&"sofa": {"path": "interior/sofa.glb", "scale": 1.5, "y": 0.0, "collision": true, "category": &"interior", "target_height": 0.85},
	&"coffee_table": {"path": "interior/coffee_table.glb", "scale": 1.45, "y": 0.0, "collision": true, "category": &"interior", "target_height": 0.45},
	&"chair": {"path": "interior/chair.glb", "scale": 1.45, "y": 0.0, "collision": true, "category": &"interior", "target_height": 0.9},
	&"desk": {"path": "interior/desk.glb", "scale": 1.45, "y": 0.0, "collision": true, "category": &"interior", "target_height": 0.85},
	&"bookcase": {"path": "interior/bookcase.glb", "scale": 1.5, "y": 0.0, "collision": true, "category": &"interior", "target_height": 1.9},
	&"fridge": {"path": "interior/fridge.glb", "scale": 1.55, "y": 0.0, "collision": true, "category": &"interior", "tint": Color(0.75, 0.78, 0.82), "target_height": 1.75},
	&"stove": {"path": "interior/stove.glb", "scale": 1.5, "y": 0.0, "collision": true, "category": &"interior", "tint": Color(0.35, 0.36, 0.4), "target_height": 0.95},
	&"sink": {"path": "interior/sink.glb", "scale": 1.45, "y": 0.0, "collision": true, "category": &"interior", "tint": Color(0.82, 0.85, 0.88), "target_height": 0.9},
	&"toilet": {"path": "interior/toilet.glb", "scale": 1.4, "y": 0.0, "collision": true, "category": &"interior", "tint": Color(0.9, 0.92, 0.94), "target_height": 0.75},
	&"television": {"path": "interior/television.glb", "scale": 1.4, "y": 0.0, "collision": false, "category": &"interior", "target_height": 0.7},
	&"potted_plant": {"path": "interior/potted_plant.glb", "scale": 1.4, "y": 0.0, "collision": false, "category": &"interior", "target_height": 0.85},
	&"floor_lamp": {"path": "interior/floor_lamp.glb", "scale": 1.45, "y": 0.0, "collision": false, "category": &"interior", "target_height": 1.55},
	## Adventure
	&"pillar": {"path": "adventure/pillar.glb", "scale": 1.8, "y": 0.0, "collision": true, "category": &"adventure"},
	&"ruin_rocks": {"path": "adventure/ruin_rocks.glb", "scale": 1.6, "y": 0.0, "collision": true, "category": &"adventure"},
	&"flag": {"path": "adventure/flag.glb", "scale": 1.7, "y": 0.0, "collision": false, "category": &"adventure"},
	&"treasure_chest": {"path": "adventure/treasure_chest.glb", "scale": 1.5, "y": 0.0, "collision": true, "category": &"adventure"},
	&"supply_crate": {"path": "adventure/supply_crate.glb", "scale": 1.45, "y": 0.0, "collision": true, "category": &"adventure"},
	&"supply_crate_item": {"path": "adventure/supply_crate_item.glb", "scale": 1.45, "y": 0.0, "collision": true, "category": &"adventure"},
	&"barrel": {"path": "adventure/barrel.glb", "scale": 1.5, "y": 0.0, "collision": true, "category": &"adventure"},
	&"quest_key": {"path": "adventure/quest_key.glb", "scale": 1.6, "y": 0.0, "collision": false, "category": &"adventure"},
	&"collectible_coin": {"path": "adventure/collectible_coin.glb", "scale": 1.7, "y": 0.0, "collision": false, "category": &"adventure"},
	## Transport — cars sized for one driver; mesh_yaw aligns Kenney +Z nose with drive −Z
	&"craft_speeder": {"path": "transport/craft_speeder.glb", "scale": 2.4, "y": 0.2, "collision": true, "category": &"transport", "mesh_yaw": 180.0, "tint": Color(0.35, 0.7, 0.85), "target_height": 1.6},
	&"craft_speeder_alt": {"path": "transport/craft_speeder_alt.glb", "scale": 2.4, "y": 0.2, "collision": true, "category": &"transport", "mesh_yaw": 180.0, "tint": Color(0.85, 0.55, 0.25), "target_height": 1.6},
	&"craft_racer": {"path": "transport/craft_racer.glb", "scale": 2.3, "y": 0.2, "collision": true, "category": &"transport", "mesh_yaw": 180.0, "tint": Color(0.9, 0.3, 0.35), "target_height": 1.35},
	&"craft_cargo": {"path": "transport/craft_cargo.glb", "scale": 2.5, "y": 0.25, "collision": true, "category": &"transport", "mesh_yaw": 180.0, "tint": Color(0.55, 0.6, 0.45), "target_height": 2.0},
	&"hangar_small": {"path": "transport/hangar_small.glb", "scale": 2.0, "y": 0.0, "collision": true, "category": &"transport", "target_height": 4.5},
	&"park_car": {"path": "transport/park_car.glb", "scale": 3.8, "y": 0.0, "collision": true, "category": &"transport", "mesh_yaw": 180.0, "tint": Color(0.78, 0.22, 0.18), "target_height": 1.45},
	&"adventure_suv": {"path": "transport/adventure_suv.glb", "scale": 1.55, "y": 0.0, "collision": true, "category": &"transport", "mesh_yaw": 180.0, "tint": Color(0.25, 0.45, 0.35), "target_height": 1.70},
}


static func has_prop(prop_id: StringName) -> bool:
	return PROPS.has(prop_id)


static func prop_path(prop_id: StringName) -> String:
	if not PROPS.has(prop_id):
		return ""
	return ROOT + String(PROPS[prop_id]["path"])


static func prop_def(prop_id: StringName) -> Dictionary:
	return PROPS.get(prop_id, {})


static func all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k in PROPS.keys():
		out.append(k)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out
