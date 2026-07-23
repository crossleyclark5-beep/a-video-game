class_name WorldLodPolicy
extends RefCounted
## Distance LOD policy for vegetation MultiMesh + visual instances.
## Does not remove density — only visibility ranges and air-mode multipliers.


static func apply_to_vegetation_root(veg_root: Node, airborne: bool = false) -> void:
	if veg_root == null:
		return
	var mult := AdventureNodeBudget.LOD_AIR_MULT if airborne else 1.0
	for node in veg_root.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := node as MultiMeshInstance3D
		var end_v := _end_for_name(String(mmi.name)) * mult
		mmi.visibility_range_begin = 0.0
		mmi.visibility_range_end = end_v
		mmi.visibility_range_end_margin = maxf(40.0, end_v * 0.12)
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


static func apply_to_mesh_instance(mi: MeshInstance3D, kind: StringName, airborne: bool = false) -> void:
	if mi == null:
		return
	var mult := AdventureNodeBudget.LOD_AIR_MULT if airborne else 1.0
	var end_v := AdventureNodeBudget.LOD_TREE_END
	match kind:
		&"bush":
			end_v = AdventureNodeBudget.LOD_BUSH_END
		&"rock":
			end_v = AdventureNodeBudget.LOD_ROCK_END
		&"grass":
			end_v = AdventureNodeBudget.LOD_GRASS_END
		&"building":
			end_v = 900.0
		&"vehicle":
			end_v = 500.0
		&"npc", &"creature":
			end_v = 220.0
		_:
			end_v = AdventureNodeBudget.LOD_TREE_END
	end_v *= mult
	mi.visibility_range_end = end_v
	mi.visibility_range_end_margin = maxf(30.0, end_v * 0.1)
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


static func _end_for_name(nm: String) -> float:
	var lower := nm.to_lower()
	if "grass" in lower:
		return AdventureNodeBudget.LOD_GRASS_END
	if "bush" in lower:
		return AdventureNodeBudget.LOD_BUSH_END
	if "rock" in lower:
		return AdventureNodeBudget.LOD_ROCK_END
	if "mush" in lower:
		return AdventureNodeBudget.LOD_MUSHROOM_END
	if "pine" in lower or "tree" in lower or "forest" in lower or "clump" in lower or "corridor" in lower or "field" in lower or "hollow" in lower or "meadow" in lower:
		return AdventureNodeBudget.LOD_TREE_END
	return AdventureNodeBudget.LOD_TREE_END
