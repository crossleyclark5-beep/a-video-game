class_name CharacterLookalikeKit
extends RefCounted
## High-quality Digital Frontier look-alikes for the Item Shop roster.
## Original retro pixel-toon builds — inspired silhouettes, not IP meshes.
## Characters read clearer than the diorama world (intentional contrast).


static func build(parent: Node3D, outfit_id: StringName, scale_mul: float = 1.0) -> Node3D:
	if parent == null or not CharacterOutfitCatalog.has_outfit(outfit_id):
		return null
	var root := Node3D.new()
	root.name = "Lookalike_%s" % String(outfit_id)
	root.scale = Vector3(scale_mul, scale_mul, scale_mul)
	parent.add_child(root)
	match outfit_id:
		&"char_jonesy":
			_jonesy(root)
		&"char_ice_king":
			_ice_king(root)
		&"char_indiana":
			_indiana(root)
		&"char_8ball":
			_eight_ball(root)
		&"char_prisoner":
			_prisoner(root)
		&"char_black_knight":
			_black_knight(root)
		&"char_peely":
			_peely(root)
		&"char_marshmallow":
			_marshmallow(root)
		&"char_master_chief":
			_master_chief(root)
		&"char_dj_yonder":
			_dj_yonder(root)
		&"char_dark_voyager":
			_dark_voyager(root)
		&"char_omega":
			_omega(root)
		&"char_raptor":
			_raptor(root)
		&"char_storm_trooper":
			_storm_trooper(root)
		_:
			_jonesy(root)
	return root


## --- Shared humanoid scaffold -------------------------------------------------


static func _base_human(
	root: Node3D,
	skin: Color,
	shirt: Color,
	pants: Color,
	shoes: Color,
	hair: Color,
) -> Dictionary:
	var hip := Node3D.new()
	hip.name = "Hip"
	hip.position = Vector3(0, 0.52, 0)
	root.add_child(hip)

	var torso := Node3D.new()
	torso.name = "Torso"
	hip.add_child(torso)
	StylizedMesh.add_box(torso, Vector3(0.46, 0.52, 0.3), shirt, Vector3(0, 0.2, 0), "Shirt")
	StylizedMesh.add_box(torso, Vector3(0.48, 0.07, 0.32), shirt.lightened(0.12), Vector3(0, 0.44, 0), "Collar")

	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.56, 0)
	torso.add_child(head)
	StylizedMesh.add_sphere(head, 0.21, skin, Vector3.ZERO, "HeadMesh", 10, 6)
	if hair.a > 0.01:
		StylizedMesh.add_sphere(head, 0.19, hair, Vector3(0, 0.1, -0.03), "Hair", 10, 6)
	StylizedCreatureKit.eye_pair(head, Vector3(0, 0.02, 0.17), 0.075, 0.036)

	var arm_l := _limb(torso, "ArmL", Vector3(-0.3, 0.3, 0), skin, true)
	var arm_r := _limb(torso, "ArmR", Vector3(0.3, 0.3, 0), skin, true)
	var leg_l := _limb(hip, "LegL", Vector3(-0.13, -0.06, 0), pants, false)
	var leg_r := _limb(hip, "LegR", Vector3(0.13, -0.06, 0), pants, false)
	StylizedMesh.add_box(leg_l, Vector3(0.14, 0.09, 0.2), shoes, Vector3(0, -0.44, 0.04), "ShoeL")
	StylizedMesh.add_box(leg_r, Vector3(0.14, 0.09, 0.2), shoes, Vector3(0, -0.44, 0.04), "ShoeR")
	return {"hip": hip, "torso": torso, "head": head, "arm_l": arm_l, "arm_r": arm_r, "leg_l": leg_l, "leg_r": leg_r}


static func _limb(parent: Node3D, lname: String, pos: Vector3, color: Color, is_arm: bool) -> Node3D:
	var n := Node3D.new()
	n.name = lname
	n.position = pos
	parent.add_child(n)
	var h := 0.4 if is_arm else 0.46
	StylizedMesh.add_box(n, Vector3(0.11, h, 0.11), color, Vector3(0, -h * 0.35, 0), lname + "Mesh")
	return n


static func _glow_box(parent: Node3D, size: Vector3, color: Color, pos: Vector3, name_: String, energy: float = 0.35) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = StylizedMesh.make_material(color, 1.0, 0.0, energy, &"flat")
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _glow_sphere(parent: Node3D, radius: float, color: Color, pos: Vector3, name_: String, energy: float = 0.35) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 5
	mi.mesh = mesh
	mi.material_override = StylizedMesh.make_material(color, 1.0, 0.0, energy, &"flat")
	mi.position = pos
	parent.add_child(mi)
	return mi


## --- Roster builds -----------------------------------------------------------


static func _jonesy(root: Node3D) -> void:
	## Retro field agent — blue polo, denim, DF cap. Readable starter hero.
	var skin := Color(0.96, 0.78, 0.62)
	var parts := _base_human(root, skin, Color(0.28, 0.48, 0.88), Color(0.22, 0.32, 0.55), Color(0.35, 0.22, 0.12), Color(0.42, 0.28, 0.16))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	## DF field cap
	StylizedMesh.add_box(head, Vector3(0.38, 0.1, 0.38), Color(0.22, 0.4, 0.78), Vector3(0, 0.18, 0), "Cap")
	StylizedMesh.add_box(head, Vector3(0.2, 0.045, 0.16), Color(0.95, 0.82, 0.25), Vector3(0, 0.14, 0.2), "Bill")
	StylizedMesh.add_box(head, Vector3(0.12, 0.04, 0.04), Color(0.2, 0.9, 0.95), Vector3(0, 0.2, 0.12), "CapPip")
	## Backpack + belt
	StylizedMesh.add_box(torso, Vector3(0.32, 0.28, 0.14), Color(0.35, 0.25, 0.15), Vector3(0, 0.18, -0.2), "Pack")
	StylizedMesh.add_box(torso, Vector3(0.48, 0.06, 0.32), Color(0.55, 0.4, 0.2), Vector3(0, -0.02, 0), "Belt")
	StylizedMesh.add_box(torso, Vector3(0.08, 0.08, 0.06), Color(0.95, 0.8, 0.25), Vector3(0.14, -0.02, 0.14), "Buckle")


static func _ice_king(root: Node3D) -> void:
	## Frost monarch — crystalline crown, ice cape, cool glow.
	var ice := Color(0.55, 0.85, 1.0)
	var deep := Color(0.25, 0.45, 0.75)
	var parts := _base_human(root, Color(0.75, 0.9, 1.0), ice, deep, Color(0.7, 0.88, 1.0), Color(0.85, 0.95, 1.0))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	## Jagged ice crown
	_glow_box(head, Vector3(0.46, 0.1, 0.46), ice.lightened(0.1), Vector3(0, 0.22, 0), "CrownBase", 0.25)
	for i in 5:
		var x := (i - 2) * 0.09
		var h := 0.16 + (0.08 if i == 2 else 0.0)
		_glow_box(head, Vector3(0.07, h, 0.07), Color(0.8, 0.95, 1.0), Vector3(x, 0.3 + h * 0.35, 0), "Spike%d" % i, 0.4)
	## Cape + shoulder frost
	StylizedMesh.add_box(torso, Vector3(0.62, 0.55, 0.08), deep.lightened(0.1), Vector3(0, 0.05, -0.2), "Cape")
	_glow_box(torso, Vector3(0.18, 0.14, 0.18), ice, Vector3(-0.28, 0.38, 0), "PadL", 0.3)
	_glow_box(torso, Vector3(0.18, 0.14, 0.18), ice, Vector3(0.28, 0.38, 0), "PadR", 0.3)
	_glow_sphere(torso, 0.06, Color(0.9, 0.98, 1.0), Vector3(0, 0.25, 0.16), "Core", 0.45)


static func _indiana(root: Node3D) -> void:
	## Relic runner — fedora, leather jacket, satchel, whip coil.
	var leather := Color(0.42, 0.26, 0.14)
	var khaki := Color(0.72, 0.58, 0.35)
	var parts := _base_human(root, Color(0.9, 0.72, 0.55), leather, khaki, Color(0.28, 0.18, 0.1), Color(0.25, 0.15, 0.08))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	var arm_r: Node3D = parts["arm_r"]
	## Fedora
	StylizedMesh.add_cylinder(head, 0.2, 0.14, leather.darkened(0.1), Vector3(0, 0.2, 0), "Fedora", false, 8)
	StylizedMesh.add_box(head, Vector3(0.58, 0.05, 0.58), leather, Vector3(0, 0.14, 0), "Brim")
	StylizedMesh.add_box(head, Vector3(0.42, 0.04, 0.06), Color(0.55, 0.2, 0.12), Vector3(0, 0.18, 0.02), "Band")
	## Jacket lapels + satchel
	StylizedMesh.add_box(torso, Vector3(0.14, 0.35, 0.06), leather.lightened(0.08), Vector3(-0.16, 0.22, 0.14), "LapelL")
	StylizedMesh.add_box(torso, Vector3(0.14, 0.35, 0.06), leather.lightened(0.08), Vector3(0.16, 0.22, 0.14), "LapelR")
	StylizedMesh.add_box(torso, Vector3(0.22, 0.26, 0.1), Color(0.55, 0.38, 0.2), Vector3(0.28, 0.05, 0.05), "Satchel")
	StylizedMesh.add_box(torso, Vector3(0.04, 0.35, 0.04), Color(0.35, 0.22, 0.12), Vector3(0.18, 0.25, 0.02), "Strap")
	## Whip coil on hip
	StylizedMesh.add_cylinder(arm_r, 0.07, 0.08, leather.darkened(0.15), Vector3(0.12, -0.35, 0.05), "Whip", false, 8)


static func _eight_ball(root: Node3D) -> void:
	## Cue-ball swagger — glossy black, white 8 medallion.
	var black := Color(0.1, 0.1, 0.12)
	var white := Color(0.95, 0.95, 0.98)
	var parts := _base_human(root, Color(0.35, 0.28, 0.25), black, black, black, Color(0.08, 0.08, 0.1))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	## Cue-ball dome over head
	StylizedMesh.add_sphere(head, 0.24, black, Vector3(0, 0.06, 0), "BallDome", 10, 6)
	StylizedMesh.add_sphere(head, 0.1, white, Vector3(0, 0.14, 0.14), "EightCircle", 8, 5)
	StylizedMesh.add_box(head, Vector3(0.04, 0.1, 0.02), black, Vector3(0, 0.14, 0.22), "EightNum")
	## Chest medallion
	StylizedMesh.add_sphere(torso, 0.12, white, Vector3(0, 0.22, 0.16), "Medal", 8, 5)
	StylizedMesh.add_box(torso, Vector3(0.035, 0.09, 0.02), black, Vector3(0, 0.22, 0.26), "Medal8")
	StylizedMesh.add_box(torso, Vector3(0.5, 0.08, 0.32), white.darkened(0.05), Vector3(0, -0.02, 0), "Stripe")


static func _prisoner(root: Node3D) -> void:
	## Breakout orange jumpsuit with stripe blocks.
	var orange := Color(0.95, 0.48, 0.12)
	var stripe := Color(0.12, 0.12, 0.14)
	var parts := _base_human(root, Color(0.92, 0.75, 0.6), orange, orange, Color(0.25, 0.2, 0.15), Color(0.2, 0.15, 0.12))
	var torso: Node3D = parts["torso"]
	var leg_l: Node3D = parts["leg_l"]
	var leg_r: Node3D = parts["leg_r"]
	## Prison stripes
	for y in [0.05, 0.2, 0.35]:
		StylizedMesh.add_box(torso, Vector3(0.48, 0.06, 0.32), stripe, Vector3(0, y, 0.01), "Stripe%d" % int(y * 100))
	StylizedMesh.add_box(leg_l, Vector3(0.13, 0.08, 0.13), stripe, Vector3(0, -0.15, 0), "LegStripeL")
	StylizedMesh.add_box(leg_r, Vector3(0.13, 0.08, 0.13), stripe, Vector3(0, -0.15, 0), "LegStripeR")
	## Broken cuff accents
	StylizedMesh.add_cylinder(parts["arm_l"], 0.08, 0.06, Color(0.45, 0.45, 0.48), Vector3(0, -0.32, 0), "CuffL", false, 8)
	StylizedMesh.add_cylinder(parts["arm_r"], 0.08, 0.06, Color(0.45, 0.45, 0.48), Vector3(0, -0.32, 0), "CuffR", false, 8)
	StylizedMesh.add_box(torso, Vector3(0.16, 0.12, 0.04), stripe, Vector3(0, 0.3, 0.16), "IDTag")


static func _black_knight(root: Node3D) -> void:
	## Onyx plate — red plume, visor slit, cape.
	var onyx := Color(0.12, 0.12, 0.16)
	var steel := Color(0.28, 0.28, 0.34)
	var crimson := Color(0.72, 0.12, 0.16)
	var parts := _base_human(root, Color(0.55, 0.45, 0.4), onyx, onyx, onyx, Color(0, 0, 0, 0))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	## Great helm
	StylizedMesh.add_box(head, Vector3(0.4, 0.36, 0.42), steel, Vector3(0, 0.08, 0), "Helm")
	StylizedMesh.add_box(head, Vector3(0.28, 0.05, 0.08), Color(0.05, 0.05, 0.06), Vector3(0, 0.06, 0.2), "VisorSlit")
	StylizedMesh.add_box(head, Vector3(0.06, 0.28, 0.06), crimson, Vector3(0, 0.32, -0.05), "Plume")
	## Plate + cape
	StylizedMesh.add_box(torso, Vector3(0.52, 0.4, 0.34), steel.darkened(0.1), Vector3(0, 0.2, 0), "Breastplate")
	StylizedMesh.add_box(torso, Vector3(0.18, 0.18, 0.08), crimson, Vector3(0, 0.28, 0.18), "Crest")
	StylizedMesh.add_box(torso, Vector3(0.7, 0.65, 0.08), crimson.darkened(0.25), Vector3(0, 0.0, -0.22), "Cape")
	StylizedMesh.add_box(torso, Vector3(0.2, 0.12, 0.2), steel, Vector3(-0.3, 0.4, 0), "PadL")
	StylizedMesh.add_box(torso, Vector3(0.2, 0.12, 0.2), steel, Vector3(0.3, 0.4, 0), "PadR")


static func _peely(root: Node3D) -> void:
	## Sunny peel companion-hero — banana silhouette, retro cute.
	var yellow := Color(0.98, 0.86, 0.18)
	var peel := Color(0.95, 0.75, 0.12)
	var green := Color(0.35, 0.7, 0.22)
	var hip := Node3D.new()
	hip.name = "Hip"
	hip.position = Vector3(0, 0.45, 0)
	root.add_child(hip)
	## Elongated banana body
	StylizedMesh.add_cylinder(hip, 0.28, 1.15, yellow, Vector3(0, 0.35, 0), "Body", false, 8)
	StylizedMesh.add_sphere(hip, 0.3, yellow.lightened(0.05), Vector3(0, 0.95, 0.02), "Head", 10, 6)
	## Stem + peel flaps
	StylizedMesh.add_cylinder(hip, 0.06, 0.18, green, Vector3(0, 1.22, 0), "Stem", false, 6)
	StylizedMesh.add_box(hip, Vector3(0.12, 0.55, 0.08), peel, Vector3(-0.32, 0.4, 0), "PeelL")
	StylizedMesh.add_box(hip, Vector3(0.12, 0.55, 0.08), peel, Vector3(0.32, 0.4, 0), "PeelR")
	StylizedMesh.add_box(hip, Vector3(0.22, 0.5, 0.08), peel.darkened(0.05), Vector3(0, 0.35, -0.28), "PeelBack")
	## Face + limbs
	StylizedCreatureKit.eye_pair(hip, Vector3(0, 0.95, 0.26), 0.09, 0.045, Color(0.15, 0.12, 0.1))
	StylizedMesh.add_box(hip, Vector3(0.14, 0.04, 0.04), Color(0.55, 0.25, 0.2), Vector3(0, 0.86, 0.28), "Smile")
	StylizedMesh.add_box(hip, Vector3(0.1, 0.42, 0.1), yellow.darkened(0.08), Vector3(-0.28, 0.15, 0.05), "ArmL")
	StylizedMesh.add_box(hip, Vector3(0.1, 0.42, 0.1), yellow.darkened(0.08), Vector3(0.28, 0.15, 0.05), "ArmR")
	StylizedMesh.add_box(hip, Vector3(0.12, 0.28, 0.14), peel.darkened(0.1), Vector3(-0.12, -0.2, 0.04), "FootL")
	StylizedMesh.add_box(hip, Vector3(0.12, 0.28, 0.14), peel.darkened(0.1), Vector3(0.12, -0.2, 0.04), "FootR")
	_glow_sphere(hip, 0.05, Color(1.0, 0.95, 0.4), Vector3(0, 1.15, 0.2), "Spark", 0.3)


static func _marshmallow(root: Node3D) -> void:
	## Soft-guard snow puff — stacked marshmallow body, scarf, coal dots.
	var white := Color(0.96, 0.97, 1.0)
	var blue := Color(0.55, 0.75, 0.95)
	var coal := Color(0.15, 0.15, 0.18)
	var hip := Node3D.new()
	hip.name = "Hip"
	hip.position = Vector3(0, 0.35, 0)
	root.add_child(hip)
	StylizedMesh.add_sphere(hip, 0.42, white, Vector3(0, 0.15, 0), "Belly", 10, 6)
	StylizedMesh.add_sphere(hip, 0.34, white, Vector3(0, 0.7, 0), "Mid", 10, 6)
	StylizedMesh.add_sphere(hip, 0.28, white, Vector3(0, 1.15, 0), "Head", 10, 6)
	## Scarf + coal face/buttons
	StylizedMesh.add_box(hip, Vector3(0.55, 0.1, 0.55), blue, Vector3(0, 0.95, 0), "Scarf")
	StylizedMesh.add_box(hip, Vector3(0.12, 0.28, 0.08), blue.darkened(0.05), Vector3(0.22, 0.75, 0.1), "ScarfTail")
	StylizedCreatureKit.eye_pair(hip, Vector3(0, 1.18, 0.22), 0.08, 0.04, coal)
	StylizedMesh.add_sphere(hip, 0.04, Color(0.95, 0.45, 0.2), Vector3(0, 1.1, 0.24), "Nose", 6, 4)
	for y in [0.55, 0.7, 0.85]:
		StylizedMesh.add_sphere(hip, 0.035, coal, Vector3(0, y, 0.3), "Btn", 6, 4)
	## Twig arms
	StylizedMesh.add_box(hip, Vector3(0.08, 0.08, 0.45), Color(0.4, 0.28, 0.15), Vector3(-0.4, 0.7, 0), "ArmL")
	StylizedMesh.add_box(hip, Vector3(0.08, 0.08, 0.45), Color(0.4, 0.28, 0.15), Vector3(0.4, 0.7, 0), "ArmR")
	_glow_sphere(hip, 0.06, blue.lightened(0.2), Vector3(0, 1.4, 0), "Halo", 0.25)


static func _master_chief(root: Node3D) -> void:
	## Chrome-green sentinel — chunky retro armor + gold visor.
	var olive := Color(0.32, 0.48, 0.28)
	var dark := Color(0.18, 0.22, 0.16)
	var gold := Color(0.9, 0.75, 0.2)
	var parts := _base_human(root, dark, olive, olive, dark, Color(0, 0, 0, 0))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	## Angular helm + visor
	StylizedMesh.add_box(head, Vector3(0.42, 0.34, 0.46), olive.darkened(0.08), Vector3(0, 0.08, 0), "Helm")
	_glow_box(head, Vector3(0.34, 0.1, 0.12), gold, Vector3(0, 0.06, 0.2), "Visor", 0.4)
	StylizedMesh.add_box(head, Vector3(0.14, 0.12, 0.2), dark, Vector3(0, 0.22, -0.05), "Antenna")
	## Armor plates
	StylizedMesh.add_box(torso, Vector3(0.54, 0.42, 0.36), olive.lightened(0.05), Vector3(0, 0.22, 0), "Chest")
	StylizedMesh.add_box(torso, Vector3(0.2, 0.16, 0.1), dark, Vector3(0, 0.28, 0.18), "CorePlate")
	StylizedMesh.add_box(torso, Vector3(0.22, 0.14, 0.22), olive, Vector3(-0.32, 0.4, 0), "PadL")
	StylizedMesh.add_box(torso, Vector3(0.22, 0.14, 0.22), olive, Vector3(0.32, 0.4, 0), "PadR")
	StylizedMesh.add_box(torso, Vector3(0.36, 0.28, 0.16), dark, Vector3(0, 0.15, -0.22), "Pack")
	_glow_box(torso, Vector3(0.08, 0.08, 0.04), gold, Vector3(0, 0.28, 0.22), "Status", 0.35)


static func _dj_yonder(root: Node3D) -> void:
	## Neon mixer — purple suit, cyan glow headset + speaker pack.
	var purple := Color(0.52, 0.22, 0.78)
	var cyan := Color(0.2, 0.95, 0.9)
	var parts := _base_human(root, Color(0.45, 0.32, 0.28), purple, Color(0.2, 0.12, 0.28), Color(0.15, 0.1, 0.2), Color(0.85, 0.35, 0.95))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	## Headset
	_glow_box(head, Vector3(0.52, 0.08, 0.08), cyan, Vector3(0, 0.08, 0), "Band", 0.45)
	_glow_box(head, Vector3(0.12, 0.16, 0.12), cyan.lightened(0.1), Vector3(0.24, 0.05, 0), "CupR", 0.5)
	_glow_box(head, Vector3(0.12, 0.16, 0.12), cyan.lightened(0.1), Vector3(-0.24, 0.05, 0), "CupL", 0.5)
	## Speaker backpack
	StylizedMesh.add_box(torso, Vector3(0.4, 0.4, 0.2), Color(0.25, 0.12, 0.35), Vector3(0, 0.2, -0.24), "Speakers")
	_glow_sphere(torso, 0.1, cyan, Vector3(-0.1, 0.25, -0.32), "ConeL", 0.4)
	_glow_sphere(torso, 0.1, cyan, Vector3(0.1, 0.25, -0.32), "ConeR", 0.4)
	_glow_box(torso, Vector3(0.46, 0.06, 0.32), cyan, Vector3(0, 0.05, 0.02), "NeonBelt", 0.35)
	StylizedMesh.add_box(torso, Vector3(0.1, 0.2, 0.06), Color(0.95, 0.4, 0.85), Vector3(0.18, 0.3, 0.16), "Badge")


static func _dark_voyager(root: Node3D) -> void:
	## Void voyager — dark space suit, purple visor, constellation pack.
	var void_c := Color(0.12, 0.08, 0.2)
	var purple := Color(0.55, 0.3, 0.95)
	var parts := _base_human(root, Color(0.25, 0.2, 0.3), void_c, void_c, Color(0.08, 0.06, 0.12), Color(0, 0, 0, 0))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	StylizedMesh.add_sphere(head, 0.26, void_c.lightened(0.05), Vector3(0, 0.06, 0), "Helm", 10, 6)
	_glow_box(head, Vector3(0.32, 0.12, 0.14), purple, Vector3(0, 0.06, 0.18), "Visor", 0.55)
	StylizedMesh.add_box(torso, Vector3(0.5, 0.45, 0.34), void_c.lightened(0.08), Vector3(0, 0.2, 0), "Suit")
	StylizedMesh.add_box(torso, Vector3(0.38, 0.35, 0.18), Color(0.18, 0.12, 0.3), Vector3(0, 0.2, -0.24), "Pack")
	_glow_sphere(torso, 0.07, purple, Vector3(0, 0.35, -0.32), "Tank", 0.4)
	for i in 4:
		_glow_sphere(torso, 0.025, Color(0.85, 0.7, 1.0), Vector3((-1.5 + i) * 0.08, 0.15 + (i % 2) * 0.08, 0.18), "Star%d" % i, 0.5)


static func _omega(root: Node3D) -> void:
	## Apex protocol — dark armor with orange energy veins.
	var armor := Color(0.18, 0.2, 0.24)
	var orange := Color(0.98, 0.5, 0.12)
	var parts := _base_human(root, Color(0.3, 0.28, 0.32), armor, armor, Color(0.12, 0.12, 0.14), Color(0, 0, 0, 0))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	StylizedMesh.add_box(head, Vector3(0.4, 0.36, 0.44), armor.lightened(0.08), Vector3(0, 0.08, 0), "Helm")
	_glow_box(head, Vector3(0.3, 0.08, 0.1), orange, Vector3(0, 0.08, 0.2), "Visor", 0.5)
	StylizedMesh.add_box(head, Vector3(0.08, 0.2, 0.08), orange.darkened(0.1), Vector3(0, 0.28, -0.05), "Crest")
	## Energy veins
	_glow_box(torso, Vector3(0.06, 0.4, 0.04), orange, Vector3(-0.12, 0.2, 0.16), "VeinL", 0.45)
	_glow_box(torso, Vector3(0.06, 0.4, 0.04), orange, Vector3(0.12, 0.2, 0.16), "VeinR", 0.45)
	StylizedMesh.add_box(torso, Vector3(0.56, 0.4, 0.36), armor.lightened(0.05), Vector3(0, 0.2, 0), "Plate")
	StylizedMesh.add_box(torso, Vector3(0.24, 0.16, 0.24), armor, Vector3(-0.32, 0.42, 0), "PadL")
	StylizedMesh.add_box(torso, Vector3(0.24, 0.16, 0.24), armor, Vector3(0.32, 0.42, 0), "PadR")
	_glow_sphere(torso, 0.07, orange, Vector3(0, 0.28, 0.2), "Core", 0.55)


static func _raptor(root: Node3D) -> void:
	## Ridge scout — camo greens, raptor-mask hood, utility vest.
	var camo := Color(0.3, 0.48, 0.24)
	var brown := Color(0.42, 0.3, 0.16)
	var parts := _base_human(root, Color(0.85, 0.68, 0.5), camo, Color(0.25, 0.32, 0.2), brown, Color(0.2, 0.15, 0.1))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	## Raptor mask / hood
	StylizedMesh.add_box(head, Vector3(0.4, 0.28, 0.42), camo.darkened(0.1), Vector3(0, 0.12, 0), "Hood")
	StylizedMesh.add_box(head, Vector3(0.28, 0.14, 0.28), camo.lightened(0.05), Vector3(0, 0.05, 0.18), "Snout")
	StylizedMesh.add_box(head, Vector3(0.08, 0.06, 0.06), Color(0.9, 0.85, 0.3), Vector3(-0.1, 0.12, 0.28), "EyeL")
	StylizedMesh.add_box(head, Vector3(0.08, 0.06, 0.06), Color(0.9, 0.85, 0.3), Vector3(0.1, 0.12, 0.28), "EyeR")
	## Utility vest + pouches
	StylizedMesh.add_box(torso, Vector3(0.5, 0.35, 0.34), brown, Vector3(0, 0.18, 0), "Vest")
	StylizedMesh.add_box(torso, Vector3(0.12, 0.12, 0.08), camo.darkened(0.15), Vector3(-0.16, 0.1, 0.16), "PouchL")
	StylizedMesh.add_box(torso, Vector3(0.12, 0.12, 0.08), camo.darkened(0.15), Vector3(0.16, 0.1, 0.16), "PouchR")
	StylizedMesh.add_box(torso, Vector3(0.3, 0.22, 0.12), brown.darkened(0.1), Vector3(0, 0.15, -0.2), "Pack")


static func _storm_trooper(root: Node3D) -> void:
	## Star patrol — glossy white plates, black joints, toy-plastic retro helm.
	var white := Color(0.94, 0.94, 0.97)
	var black := Color(0.12, 0.12, 0.14)
	var parts := _base_human(root, black, white, white, white, Color(0, 0, 0, 0))
	var head: Node3D = parts["head"]
	var torso: Node3D = parts["torso"]
	## Classic bucket helm
	StylizedMesh.add_box(head, Vector3(0.4, 0.36, 0.44), white, Vector3(0, 0.08, 0), "Helm")
	StylizedMesh.add_box(head, Vector3(0.32, 0.08, 0.1), black, Vector3(0, 0.1, 0.2), "Visor")
	StylizedMesh.add_box(head, Vector3(0.1, 0.06, 0.08), black, Vector3(-0.12, 0.02, 0.2), "LensL")
	StylizedMesh.add_box(head, Vector3(0.1, 0.06, 0.08), black, Vector3(0.12, 0.02, 0.2), "LensR")
	StylizedMesh.add_box(head, Vector3(0.16, 0.08, 0.12), black, Vector3(0, -0.02, 0.18), "Mouth")
	## Armor segments
	StylizedMesh.add_box(torso, Vector3(0.52, 0.38, 0.34), white.darkened(0.03), Vector3(0, 0.22, 0), "Chest")
	StylizedMesh.add_box(torso, Vector3(0.48, 0.06, 0.32), black, Vector3(0, 0.02, 0), "Abs")
	StylizedMesh.add_box(torso, Vector3(0.2, 0.12, 0.2), white, Vector3(-0.3, 0.4, 0), "PadL")
	StylizedMesh.add_box(torso, Vector3(0.2, 0.12, 0.2), white, Vector3(0.3, 0.4, 0), "PadR")
	StylizedMesh.add_box(torso, Vector3(0.28, 0.22, 0.12), black, Vector3(0, 0.18, -0.2), "Pack")
	StylizedMesh.add_box(torso, Vector3(0.1, 0.1, 0.04), Color(0.85, 0.15, 0.15), Vector3(0, 0.32, 0.18), "Rank")
