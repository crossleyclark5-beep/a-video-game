class_name OcclusionUtil
extends RefCounted
## Marks meshes that may fade when they block the camera→player line of sight.


const GROUP := &"occludable"


static func mark(node: Node) -> void:
	if node == null:
		return
	if node is MeshInstance3D:
		(node as MeshInstance3D).add_to_group(GROUP)
	for child in node.get_children():
		if child is MeshInstance3D:
			var n := String(child.name)
			if _name_looks_occludable(n):
				(child as MeshInstance3D).add_to_group(GROUP)


static func mark_mesh(mi: MeshInstance3D) -> void:
	if mi:
		mi.add_to_group(GROUP)


static func mark_named_in(root: Node, names: PackedStringArray) -> void:
	if root == null:
		return
	for n in names:
		var node := root.get_node_or_null(String(n))
		if node is MeshInstance3D:
			mark_mesh(node as MeshInstance3D)
		elif node != null:
			for child in node.get_children():
				if child is MeshInstance3D:
					mark_mesh(child as MeshInstance3D)


static func _name_looks_occludable(n: String) -> bool:
	var l := n.to_lower()
	return (
		l.contains("roof")
		or l.contains("canopy")
		or l.contains("awning")
		or l.contains("overhang")
		or l.contains("pavilion")
		or l.contains("bridge")
		or l.begins_with("leaf")
		or l.contains("foliage")
	)
