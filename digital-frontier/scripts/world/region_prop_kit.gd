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
	## Prefer curated treasure chest GLB; lid anim falls back to hop if no Lid child.
	var used_external := false
	if ExternalPropKit.is_available():
		var visual := ExternalPropKit.spawn(area, &"treasure_chest", Vector3(0, -0.4, 0), 0.0, 1.05, "ChestMesh")
		used_external = visual != null
	if not used_external:
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


static func add_supply_stash(parent: Node3D, pos: Vector3, yaw: float = 0.0, node_name: String = "SupplyStash") -> Node3D:
	## Decorative Fortnite-style loot/supply cluster — not a second loot table.
	var stash := Node3D.new()
	stash.name = node_name
	stash.position = pos
	stash.rotation_degrees.y = yaw
	parent.add_child(stash)
	if ExternalPropKit.is_available():
		ExternalPropKit.spawn(stash, &"supply_crate", Vector3(0, 0, 0), 0.0, 1.1, "Crate")
		ExternalPropKit.spawn(stash, &"barrel", Vector3(1.1, 0, 0.4), 25.0, 1.0, "Barrel")
		if randf() < 0.5:
			ExternalPropKit.spawn(stash, &"supply_crate_item", Vector3(-1.0, 0, -0.5), -20.0, 1.0, "CrateB")
	else:
		StylizedMesh.add_box(stash, Vector3(1.0, 0.9, 1.0), Color(0.55, 0.4, 0.25), Vector3(0, 0.45, 0), "Crate", true, 1.0, &"wood")
	return stash


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
	return make_enterable_building(
		parent, house_name, pos, wall, roof, yaw, result, InteriorKinds.HOUSE
	)


static func make_enterable_building(
	parent: Node3D,
	building_name: String,
	pos: Vector3,
	wall: Color,
	roof: Color,
	yaw: float,
	result: Dictionary,
	kind: StringName = InteriorKinds.HOUSE,
	footprint: Vector3 = Vector3(5.4, 2.8, 4.6),
) -> Node3D:
	## Universal enterable shell — open top, door contract, modular interior by kind.
	var house := Node3D.new()
	house.name = building_name
	house.position = pos
	house.rotation_degrees.y = yaw
	parent.add_child(house)
	var fw := footprint.x
	var fh := footprint.y
	var fd := footprint.z
	StylizedMesh.add_box(house, Vector3(fw + 2.6, 0.05, fd + 2.4), WorldPalette.DIRT.lightened(0.08), Vector3(0, 0.03, 0), "Yard", false, 1.0, &"dirt")
	StylizedMesh.add_box(house, Vector3(fw + 0.2, 0.2, fd + 0.2), WorldPalette.SIDEWALK, Vector3(0, 0.12, 0), "Foundation", false, 1.0, &"asphalt")
	StylizedMesh.add_box(house, Vector3(fw, fh, 0.2), wall, Vector3(0, fh * 0.5, -fd * 0.5), "WallBack", true, 1.0, &"brick")
	StylizedMesh.add_box(house, Vector3(0.2, fh, fd), wall, Vector3(-fw * 0.5, fh * 0.5, 0), "WallL", true, 1.0, &"brick")
	StylizedMesh.add_box(house, Vector3(0.2, fh, fd), wall, Vector3(fw * 0.5, fh * 0.5, 0), "WallR", true, 1.0, &"brick")
	var gap := mini(1.8, fw * 0.35)
	var wing := (fw - gap) * 0.5
	StylizedMesh.add_box(house, Vector3(wing, fh, 0.2), wall, Vector3(-(gap * 0.5 + wing * 0.5), fh * 0.5, fd * 0.5), "WallF1", true, 1.0, &"brick")
	StylizedMesh.add_box(house, Vector3(wing, fh, 0.2), wall, Vector3(gap * 0.5 + wing * 0.5, fh * 0.5, fd * 0.5), "WallF2", true, 1.0, &"brick")
	var body_mark := Node3D.new()
	body_mark.name = "Body"
	house.add_child(body_mark)
	StylizedMesh.add_box(house, Vector3(fw - 0.4, 0.08, fd - 0.4), WorldPalette.WOOD, Vector3(0, 0.16, 0), "ShellFloor", false, 1.0, &"wood")
	var roof_mi := MeshInstance3D.new()
	roof_mi.name = "Roof"
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(fw + 0.8, 0.45, fd + 0.8)
	roof_mi.mesh = roof_mesh
	roof_mi.material_override = StylizedMesh.make_transparent_material(roof)
	roof_mi.position = Vector3(0, fh + 0.35, 0)
	house.add_child(roof_mi)
	OcclusionUtil.mark_mesh(roof_mi)
	var peak := StylizedMesh.add_box(house, Vector3(fw * 0.65, 0.55, fd * 0.6), roof.darkened(0.08), Vector3(0, fh + 0.75, 0), "RoofPeak", false, 1.0, &"roof")
	OcclusionUtil.mark(peak)
	var ridge := StylizedMesh.add_box(house, Vector3(fw * 0.7, 0.1, 0.25), roof.lightened(0.05), Vector3(0, fh + 1.05, 0), "Ridge", false, 1.0, &"roof")
	OcclusionUtil.mark(ridge)
	StylizedMesh.add_box(house, Vector3(1.0, 1.9, 0.1), WorldPalette.WOOD.darkened(0.2), Vector3(0, 1.05, fd * 0.5 + 0.1), "Door", false, 1.0, &"wood")
	StylizedMesh.add_box(house, Vector3(0.1, 0.1, 0.1), WorldPalette.FLOWER_Y, Vector3(0.35, 1.05, fd * 0.5 + 0.18), "Knob")
	StylizedMesh.add_window_pane(house, Vector3(0.9, 0.8, 0.08), Vector3(-fw * 0.28, fh * 0.6, fd * 0.5 + 0.12), "WinL")
	StylizedMesh.add_window_pane(house, Vector3(0.9, 0.8, 0.08), Vector3(fw * 0.28, fh * 0.6, fd * 0.5 + 0.12), "WinR")
	StylizedMesh.add_box(house, Vector3(0.55, 0.4, 0.55), WorldPalette.BUSH, Vector3(-fw * 0.5 - 0.2, 0.25, fd * 0.5 + 0.5), "Bush", false, 1.0, &"leaf")

	var door := Interactable.new()
	door.name = "DoorInteractable"
	door.position = Vector3(0, 1.0, fd * 0.5 + 0.4)
	door.once = false
	door.prompt_verb = "Enter %s" % building_name
	var dshape := CollisionShape3D.new()
	var dbox := BoxShape3D.new()
	dbox.size = Vector3(1.4, 2.2, 1.0)
	dshape.shape = dbox
	door.add_child(dshape)
	house.add_child(door)
	var exit_m := Marker3D.new()
	exit_m.name = "ExteriorExit"
	exit_m.position = Vector3(0, 0.15, fd * 0.5 + 1.8)
	house.add_child(exit_m)
	var entry_m := Marker3D.new()
	entry_m.name = "InteriorEntry"
	entry_m.position = Vector3(0, 0.15, 0.8)
	house.add_child(entry_m)
	house.set_script(load("res://scripts/systems/buildings/building_volume.gd"))
	house.set("building_id", StringName(building_name.to_snake_case()))
	house.set("display_name", building_name)
	house.set("interior_kind", kind)
	house.set("interior_personality", InteriorPersonality.from_building_id(StringName(building_name.to_snake_case()), kind))
	house.set("interior_scene", null)
	house.set("exterior_zoom", 14.5)
	house.set("interior_zoom", 9.2 if kind != InteriorKinds.TOWER else 8.5)
	house.set("roof_paths", [NodePath("Roof"), NodePath("RoofPeak"), NodePath("Ridge")])
	house.set("cutaway_paths", [])
	if house.has_method("bind_door_now"):
		house.call("bind_door_now")
	if result.has(&"enterable_houses"):
		result[&"enterable_houses"].append(house)
	return house


static func attach_living_water(mesh: MeshInstance3D, size: Vector3) -> WaterBody:
	## Bobbing surface + aquatic spawn volume registration.
	return WaterBody.attach_to_mesh(mesh, size)
