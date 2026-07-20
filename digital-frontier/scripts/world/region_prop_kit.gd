class_name RegionPropKit
extends RefCounted
## Shared gameplay props for region / POI builders (chests, discoveries, signs).


static func build_chest(
	parent: Node3D,
	chest_name: String,
	pos: Vector3,
	rarity: ChestInteractable.Rarity = ChestInteractable.Rarity.NORMAL,
	respawn_hours: float = 0.0,
	prompt: String = "",
) -> Area3D:
	var area := ChestInteractable.new()
	area.name = chest_name
	area.chest_id = StringName(chest_name.to_snake_case())
	area.rarity = rarity
	area.respawn_hours = respawn_hours
	area.position = pos + Vector3(0, 0.4, 0)
	area.loot_item_id = &"hex_shard"
	area.loot_quantity = 1
	if not prompt.is_empty():
		area.prompt_verb = prompt
	match rarity:
		ChestInteractable.Rarity.RARE:
			area.loot_table_id = &"loot_chest_rare"
			area.creature_xp_on_open = 10
		ChestInteractable.Rarity.LEGENDARY:
			area.loot_table_id = &"loot_chest_legendary"
			area.creature_xp_on_open = 18
		_:
			area.loot_table_id = &"loot_chest_normal"
			area.creature_xp_on_open = 6
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.95, 0.55, 0.7)
	body.mesh = box
	var body_color := Color(0.88, 0.68, 0.18)
	match rarity:
		ChestInteractable.Rarity.RARE:
			body_color = Color(0.45, 0.65, 0.95)
		ChestInteractable.Rarity.LEGENDARY:
			body_color = Color(0.95, 0.55, 0.2)
	body.material_override = StylizedMesh.make_material(body_color, 1.0, 0.0, 0.0, &"wood")
	area.add_child(body)
	## Metal band + latch for recognizable high-res prop silhouette.
	StylizedMesh.add_box(area, Vector3(0.98, 0.08, 0.72), body_color.darkened(0.25), Vector3(0, 0.05, 0), "Band", false, 1.0, &"brick")
	StylizedMesh.add_box(area, Vector3(0.14, 0.12, 0.08), WorldPalette.METAL, Vector3(0, 0.22, 0.38), "Latch")
	var lid := MeshInstance3D.new()
	lid.name = "Lid"
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.98, 0.18, 0.72)
	lid.mesh = lid_mesh
	lid.material_override = StylizedMesh.make_material(body_color.darkened(0.15), 1.0, 0.0, 0.0, &"wood")
	lid.position = Vector3(0, 0.35, 0)
	area.add_child(lid)
	var shape := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(1.5, 1.3, 1.5)
	shape.shape = s
	area.add_child(shape)
	parent.add_child(area)
	return area


static func add_discoverable(
	parent: Node3D,
	location_id: StringName,
	location_name: String,
	pos: Vector3,
	bits: int = 10,
	message: String = "",
) -> DiscoverableInteractable:
	var d := DiscoverableInteractable.new()
	d.name = String(location_id).capitalize().replace(" ", "")
	d.position = pos
	d.location_id = location_id
	d.location_name = location_name
	d.discover_message = message
	d.bits_reward = bits
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 2.0, 2.2)
	shape.shape = box
	d.add_child(shape)
	StylizedMesh.add_box(d, Vector3(0.55, 1.1, 0.12), WorldPalette.WOOD, Vector3(0, 0.0, 0), "Marker", false, 1.0, &"wood")
	StylizedMesh.add_box(d, Vector3(0.7, 0.35, 0.08), WorldPalette.UI_ACCENT, Vector3(0, 0.55, 0.02), "Flag")
	parent.add_child(d)
	return d


static func add_welcome_sign(parent: Node3D, pos: Vector3, text: String, location_id: StringName = &"") -> void:
	var sign := Node3D.new()
	sign.name = "WelcomeSign"
	sign.position = pos
	parent.add_child(sign)
	StylizedMesh.add_box(sign, Vector3(0.18, 2.4, 0.18), WorldPalette.WOOD, Vector3(0, 1.2, 0), "Post", true, 1.0, &"wood")
	StylizedMesh.add_box(sign, Vector3(3.2, 1.1, 0.14), WorldPalette.UI_PAPER, Vector3(0, 2.2, 0), "Board", false, 1.0, &"wood")
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.position = Vector3(0, 2.2, 0.1)
	label.modulate = WorldPalette.UI_INK
	sign.add_child(label)
	if location_id != &"":
		add_discoverable(sign, location_id, text, Vector3(0, 0.5, 0.8), 12, "Arrived: %s" % text)


static func make_enterable_house(
	parent: Node3D,
	house_name: String,
	pos: Vector3,
	wall: Color,
	roof: Color,
	yaw: float,
	result: Dictionary,
) -> Node3D:
	## Compact interior-ready cottage shell (open top + door contract).
	var house := Node3D.new()
	house.name = house_name
	house.position = pos
	house.rotation_degrees.y = yaw
	parent.add_child(house)
	StylizedMesh.add_box(house, Vector3(8, 0.05, 7), WorldPalette.DIRT.lightened(0.08), Vector3(0, 0.03, 0), "Yard", false, 1.0, &"dirt")
	StylizedMesh.add_box(house, Vector3(5.5, 0.2, 4.8), WorldPalette.SIDEWALK, Vector3(0, 0.12, 0), "Foundation", false, 1.0, &"asphalt")
	StylizedMesh.add_box(house, Vector3(5.4, 2.8, 0.2), wall, Vector3(0, 1.5, -2.3), "WallBack", true, 1.0, &"brick")
	StylizedMesh.add_box(house, Vector3(0.2, 2.8, 4.6), wall, Vector3(-2.6, 1.5, 0), "WallL", true, 1.0, &"brick")
	StylizedMesh.add_box(house, Vector3(0.2, 2.8, 4.6), wall, Vector3(2.6, 1.5, 0), "WallR", true, 1.0, &"brick")
	StylizedMesh.add_box(house, Vector3(1.8, 2.8, 0.2), wall, Vector3(-1.7, 1.5, 2.3), "WallF1", true, 1.0, &"brick")
	StylizedMesh.add_box(house, Vector3(1.8, 2.8, 0.2), wall, Vector3(1.7, 1.5, 2.3), "WallF2", true, 1.0, &"brick")
	var body_mark := Node3D.new()
	body_mark.name = "Body"
	house.add_child(body_mark)
	StylizedMesh.add_box(house, Vector3(5.0, 0.08, 4.2), WorldPalette.WOOD, Vector3(0, 0.16, 0), "ShellFloor", false, 1.0, &"wood")
	var roof_mi := MeshInstance3D.new()
	roof_mi.name = "Roof"
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(6.2, 0.45, 5.4)
	roof_mi.mesh = roof_mesh
	roof_mi.material_override = StylizedMesh.make_transparent_material(roof)
	roof_mi.position = Vector3(0, 3.15, 0)
	house.add_child(roof_mi)
	StylizedMesh.add_box(house, Vector3(3.6, 0.55, 3.2), roof.darkened(0.08), Vector3(0, 3.55, 0), "RoofPeak", false, 1.0, &"roof")
	StylizedMesh.add_box(house, Vector3(3.8, 0.1, 0.25), roof.lightened(0.05), Vector3(0, 3.85, 0), "Ridge", false, 1.0, &"roof")
	StylizedMesh.add_box(house, Vector3(1.0, 1.9, 0.1), WorldPalette.WOOD.darkened(0.2), Vector3(0, 1.05, 2.4), "Door", false, 1.0, &"wood")
	StylizedMesh.add_box(house, Vector3(0.1, 0.1, 0.1), WorldPalette.FLOWER_Y, Vector3(0.35, 1.05, 2.48), "Knob")
	StylizedMesh.add_window_pane(house, Vector3(0.9, 0.8, 0.08), Vector3(-1.5, 1.7, 2.42), "WinL")
	StylizedMesh.add_window_pane(house, Vector3(0.9, 0.8, 0.08), Vector3(1.5, 1.7, 2.42), "WinR")
	## Yard micro props
	StylizedMesh.add_box(house, Vector3(0.55, 0.4, 0.55), WorldPalette.BUSH, Vector3(-2.8, 0.25, 2.8), "Bush", false, 1.0, &"leaf")
	StylizedMesh.add_box(house, Vector3(0.35, 0.18, 0.3), WorldPalette.ROCK, Vector3(2.6, 0.12, 2.5), "Rock", false, 1.0, &"dirt")

	var door := Interactable.new()
	door.name = "DoorInteractable"
	door.position = Vector3(0, 1.0, 2.7)
	door.once = false
	door.prompt_verb = "Enter %s" % house_name
	var dshape := CollisionShape3D.new()
	var dbox := BoxShape3D.new()
	dbox.size = Vector3(1.4, 2.2, 1.0)
	dshape.shape = dbox
	door.add_child(dshape)
	house.add_child(door)
	var exit_m := Marker3D.new()
	exit_m.name = "ExteriorExit"
	exit_m.position = Vector3(0, 0.15, 4.2)
	house.add_child(exit_m)
	var entry_m := Marker3D.new()
	entry_m.name = "InteriorEntry"
	entry_m.position = Vector3(0, 0.15, 0.8)
	house.add_child(entry_m)
	house.set_script(load("res://scripts/systems/buildings/building_volume.gd"))
	house.set("building_id", StringName(house_name.to_snake_case()))
	house.set("display_name", house_name)
	house.set("exterior_zoom", 14.5)
	house.set("interior_zoom", 9.5)
	house.set("roof_paths", [NodePath("Roof"), NodePath("RoofPeak"), NodePath("Ridge")])
	house.set("cutaway_paths", [])
	house.set("interior_scene", load("res://scenes/world/buildings/interiors/test_house_interior.tscn"))
	if house.has_method("bind_door_now"):
		house.call("bind_door_now")
	result[&"enterable_houses"].append(house)
	return house
