class_name CreatureLookalikeKit
extends RefCounted
## High-quality Digimon-inspired DF retro look-alikes (companions, enemies, bosses).
## Original pixel-toon builds — not Bandai/Toei IP meshes.


static func build(parent: Node3D, creature_id: StringName, scale_mul: float = 1.0) -> Node3D:
	if parent == null or not CreatureLookalikeCatalog.has_creature(creature_id):
		return null
	var def := CreatureLookalikeCatalog.creature_def(creature_id)
	var root := Node3D.new()
	root.name = "Lookalike_%s" % String(creature_id)
	var s := float(def.get("scale", 1.0)) * scale_mul
	root.scale = Vector3(s, s, s)
	parent.add_child(root)
	match creature_id:
		&"companion_tentomon":
			_tentomon(root)
		&"companion_agumon":
			_agumon(root)
		&"companion_gatomon":
			_gatomon(root)
		&"companion_gabumon":
			_gabumon(root)
		&"companion_biyomon":
			_biyomon(root)
		&"companion_gomamon":
			_gomamon(root)
		&"enemy_junkmon":
			_junkmon(root)
		&"enemy_gazimon":
			_gazimon(root)
		&"enemy_impmon":
			_impmon(root)
		&"enemy_koromon":
			_koromon(root)
		&"enemy_chuumon":
			_chuumon(root)
		&"enemy_hagurumon":
			_hagurumon(root)
		&"enemy_numemon":
			_numemon(root)
		&"enemy_datamon":
			_datamon(root)
		&"enemy_bakemon":
			_bakemon(root)
		&"enemy_frigimon":
			_frigimon(root)
		&"enemy_monzaemon":
			_monzaemon(root)
		&"enemy_gotsumon":
			_gotsumon(root)
		&"enemy_icemon":
			_icemon(root)
		&"enemy_pumpkinmon":
			_pumpkinmon(root)
		&"enemy_digitamamon":
			_digitamamon(root)
		&"boss_andromon":
			_andromon(root)
		&"boss_devimon":
			_devimon(root)
		&"boss_orgemon":
			_orgemon(root)
		&"boss_snimon":
			_snimon(root)
		&"boss_meramon":
			_meramon(root)
		&"boss_whamon":
			_whamon(root)
		_:
			_agumon(root)
	return root


static func attach_for_species(parent: Node3D, species_id: StringName, scale_mul: float = 1.0) -> Node3D:
	## Ecosystem / boss spawn ids may equal lookalike ids.
	if CreatureLookalikeCatalog.has_creature(species_id):
		return build(parent, species_id, scale_mul)
	return null


## --- Helpers -----------------------------------------------------------------


static func _glow_box(parent: Node3D, size: Vector3, color: Color, pos: Vector3, name_: String, energy: float = 0.3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = StylizedMesh.make_material(color, 1.0, 0.0, energy, &"flat")
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _glow_sphere(parent: Node3D, radius: float, color: Color, pos: Vector3, name_: String, energy: float = 0.3) -> MeshInstance3D:
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


static func _legs2(parent: Node3D, y: float, color: Color, spread: float = 0.14) -> void:
	StylizedMesh.add_box(parent, Vector3(0.12, 0.28, 0.14), color, Vector3(-spread, y, 0.02), "LegL")
	StylizedMesh.add_box(parent, Vector3(0.12, 0.28, 0.14), color, Vector3(spread, y, 0.02), "LegR")


static func _arms2(parent: Node3D, y: float, color: Color, spread: float = 0.28) -> void:
	StylizedMesh.add_box(parent, Vector3(0.1, 0.28, 0.1), color, Vector3(-spread, y, 0.05), "ArmL")
	StylizedMesh.add_box(parent, Vector3(0.1, 0.28, 0.1), color, Vector3(spread, y, 0.05), "ArmR")


## --- Companions --------------------------------------------------------------


static func _tentomon(root: Node3D) -> void:
	var red := Color(0.85, 0.22, 0.18)
	var shell := Color(0.15, 0.15, 0.18)
	StylizedMesh.add_sphere(root, 0.28, red, Vector3(0, 0.45, 0), "Body", 10, 6)
	StylizedMesh.add_sphere(root, 0.22, red.lightened(0.08), Vector3(0, 0.75, 0.05), "Head", 10, 6)
	## Shell plates
	StylizedMesh.add_box(root, Vector3(0.42, 0.12, 0.35), shell, Vector3(0, 0.55, -0.08), "Shell")
	StylizedMesh.add_box(root, Vector3(0.08, 0.08, 0.08), shell, Vector3(-0.12, 0.62, -0.05), "SpotL")
	StylizedMesh.add_box(root, Vector3(0.08, 0.08, 0.08), shell, Vector3(0.12, 0.62, -0.05), "SpotR")
	## Wings
	StylizedMesh.add_box(root, Vector3(0.35, 0.04, 0.2), Color(0.85, 0.9, 0.95), Vector3(-0.28, 0.55, -0.05), "WingL")
	StylizedMesh.add_box(root, Vector3(0.35, 0.04, 0.2), Color(0.85, 0.9, 0.95), Vector3(0.28, 0.55, -0.05), "WingR")
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.78, 0.2), 0.08, 0.04)
	_legs2(root, 0.12, shell.lightened(0.2), 0.16)
	StylizedMesh.add_box(root, Vector3(0.06, 0.2, 0.06), shell, Vector3(-0.1, 0.95, 0), "AntL")
	StylizedMesh.add_box(root, Vector3(0.06, 0.2, 0.06), shell, Vector3(0.1, 0.95, 0), "AntR")


static func _agumon(root: Node3D) -> void:
	var orange := Color(0.98, 0.55, 0.18)
	var cream := Color(0.98, 0.92, 0.75)
	StylizedMesh.add_sphere(root, 0.26, orange, Vector3(0, 0.38, 0.02), "Body", 10, 6)
	StylizedMesh.add_sphere(root, 0.18, cream, Vector3(0, 0.36, 0.14), "Belly", 8, 5)
	StylizedMesh.add_sphere(root, 0.34, orange, Vector3(0, 0.78, 0.06), "Head", 10, 6)
	StylizedMesh.add_sphere(root, 0.14, orange.lightened(0.05), Vector3(0, 0.68, 0.3), "Snout", 8, 5)
	StylizedMesh.add_sphere(root, 0.1, cream, Vector3(0, 0.62, 0.28), "Jaw", 6, 4)
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.82, 0.28), 0.1, 0.045, Color(0.2, 0.7, 0.25))
	_arms2(root, 0.45, orange, 0.3)
	_legs2(root, 0.1, orange.darkened(0.08), 0.14)
	StylizedMesh.add_box(root, Vector3(0.08, 0.12, 0.08), cream, Vector3(-0.08, 1.05, 0), "SpikeA")
	StylizedMesh.add_box(root, Vector3(0.08, 0.16, 0.08), cream, Vector3(0, 1.08, -0.02), "SpikeB")
	StylizedMesh.add_box(root, Vector3(0.08, 0.12, 0.08), cream, Vector3(0.08, 1.05, 0), "SpikeC")
	StylizedMesh.add_box(root, Vector3(0.1, 0.1, 0.28), orange.darkened(0.1), Vector3(0, 0.35, -0.28), "Tail")


static func _gatomon(root: Node3D) -> void:
	var white := Color(0.96, 0.96, 0.98)
	var gold := Color(0.95, 0.82, 0.25)
	StylizedMesh.add_sphere(root, 0.22, white, Vector3(0, 0.4, 0), "Body", 10, 6)
	StylizedMesh.add_sphere(root, 0.2, white, Vector3(0, 0.72, 0.04), "Head", 10, 6)
	StylizedCreatureKit.ear_pair(root, 0.95, 0.12, Vector3(0.08, 0.18, 0.04), white)
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.74, 0.18), 0.08, 0.035, Color(0.2, 0.55, 0.95))
	StylizedMesh.add_box(root, Vector3(0.12, 0.06, 0.1), Color(0.95, 0.55, 0.65), Vector3(0, 0.66, 0.18), "Nose")
	## Holy ring
	_glow_box(root, Vector3(0.28, 0.05, 0.28), gold, Vector3(0.22, 0.35, 0.05), "HolyRing", 0.45)
	_arms2(root, 0.42, white, 0.24)
	_legs2(root, 0.12, white.darkened(0.05), 0.12)
	StylizedCreatureKit.tail(root, Vector3(0, 0.4, -0.25), 0.35, 0.08, white, true)
	StylizedMesh.add_box(root, Vector3(0.2, 0.08, 0.08), gold, Vector3(0, 0.55, 0.05), "Collar")


static func _gabumon(root: Node3D) -> void:
	var blue := Color(0.45, 0.65, 0.95)
	var fur := Color(0.95, 0.88, 0.7)
	var yellow := Color(0.95, 0.85, 0.25)
	StylizedMesh.add_box(root, Vector3(0.4, 0.4, 0.45), blue, Vector3(0, 0.45, 0), "Body")
	StylizedMesh.add_sphere(root, 0.22, fur, Vector3(0, 0.78, 0.05), "Head", 10, 6)
	## Horn
	StylizedMesh.add_box(root, Vector3(0.08, 0.22, 0.08), yellow, Vector3(0, 1.0, 0), "Horn")
	## Pelt wrap
	StylizedMesh.add_box(root, Vector3(0.48, 0.35, 0.2), fur, Vector3(0, 0.5, -0.18), "Pelt")
	StylizedMesh.add_box(root, Vector3(0.35, 0.25, 0.3), fur, Vector3(0, 0.78, -0.05), "Hood")
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.8, 0.2), 0.08, 0.035)
	_arms2(root, 0.48, blue, 0.28)
	_legs2(root, 0.12, blue.darkened(0.1), 0.14)
	StylizedMesh.add_box(root, Vector3(0.12, 0.12, 0.3), blue, Vector3(0, 0.4, -0.35), "Tail")


static func _biyomon(root: Node3D) -> void:
	var pink := Color(0.95, 0.45, 0.55)
	var crest := Color(0.98, 0.85, 0.35)
	StylizedMesh.add_sphere(root, 0.24, pink, Vector3(0, 0.45, 0), "Body", 10, 6)
	StylizedMesh.add_sphere(root, 0.2, pink.lightened(0.05), Vector3(0, 0.75, 0.05), "Head", 10, 6)
	StylizedMesh.add_box(root, Vector3(0.55, 0.06, 0.22), pink.darkened(0.08), Vector3(0, 0.5, 0), "Wing")
	StylizedMesh.add_box(root, Vector3(0.1, 0.22, 0.08), crest, Vector3(0, 0.98, 0), "Crest")
	StylizedMesh.add_box(root, Vector3(0.08, 0.06, 0.14), Color(0.95, 0.75, 0.2), Vector3(0, 0.7, 0.22), "Beak")
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.78, 0.18), 0.07, 0.035)
	_legs2(root, 0.12, Color(0.95, 0.75, 0.3), 0.1)
	StylizedMesh.add_box(root, Vector3(0.08, 0.08, 0.2), pink.darkened(0.1), Vector3(0, 0.4, -0.25), "Tail")


static func _gomamon(root: Node3D) -> void:
	var white := Color(0.92, 0.92, 0.95)
	var orange := Color(0.98, 0.55, 0.2)
	StylizedMesh.add_sphere(root, 0.3, white, Vector3(0, 0.35, 0), "Body", 10, 6)
	StylizedMesh.add_sphere(root, 0.22, white, Vector3(0, 0.65, 0.08), "Head", 10, 6)
	StylizedMesh.add_box(root, Vector3(0.2, 0.12, 0.08), orange, Vector3(0, 0.82, 0), "Tuft")
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.68, 0.22), 0.08, 0.04, Color(0.2, 0.35, 0.7))
	StylizedMesh.add_box(root, Vector3(0.14, 0.08, 0.1), Color(0.3, 0.3, 0.35), Vector3(0, 0.58, 0.24), "Nose")
	## Flippers
	StylizedMesh.add_box(root, Vector3(0.28, 0.08, 0.16), white.darkened(0.05), Vector3(-0.32, 0.32, 0.05), "FlipL")
	StylizedMesh.add_box(root, Vector3(0.28, 0.08, 0.16), white.darkened(0.05), Vector3(0.32, 0.32, 0.05), "FlipR")
	StylizedMesh.add_box(root, Vector3(0.2, 0.1, 0.28), white.darkened(0.08), Vector3(0, 0.25, -0.3), "TailFlip")
	StylizedMesh.add_box(root, Vector3(0.06, 0.06, 0.06), orange, Vector3(-0.12, 0.45, 0.2), "SpotL")
	StylizedMesh.add_box(root, Vector3(0.06, 0.06, 0.06), orange, Vector3(0.12, 0.45, 0.2), "SpotR")


## --- Enemies -----------------------------------------------------------------


static func _junkmon(root: Node3D) -> void:
	var scrap := Color(0.55, 0.55, 0.5)
	var rust := Color(0.85, 0.55, 0.15)
	StylizedMesh.add_box(root, Vector3(0.45, 0.35, 0.4), scrap, Vector3(0, 0.4, 0), "Body", false, 1.0, &"brick")
	StylizedMesh.add_box(root, Vector3(0.25, 0.2, 0.25), rust, Vector3(0, 0.7, 0.05), "Head")
	StylizedMesh.add_box(root, Vector3(0.15, 0.08, 0.2), scrap.darkened(0.1), Vector3(0.2, 0.55, -0.1), "Can")
	StylizedMesh.add_box(root, Vector3(0.12, 0.12, 0.12), Color(0.4, 0.7, 0.9), Vector3(-0.18, 0.55, 0.1), "Bolt")
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.72, 0.18), 0.06, 0.03, WorldPalette.UI_ACCENT)
	_legs2(root, 0.12, scrap.darkened(0.15), 0.14)
	_arms2(root, 0.45, rust, 0.28)


static func _gazimon(root: Node3D) -> void:
	var purple := Color(0.55, 0.28, 0.65)
	StylizedMesh.add_box(root, Vector3(0.35, 0.3, 0.5), purple, Vector3(0, 0.35, 0), "Body")
	StylizedMesh.add_sphere(root, 0.16, purple.lightened(0.08), Vector3(0, 0.5, -0.28), "Head", 8, 5)
	StylizedCreatureKit.ear_pair(root, 0.65, 0.1, Vector3(0.06, 0.14, 0.04), purple.darkened(0.1), false)
	StylizedCreatureKit.snout(root, Vector3(0, 0.45, -0.4), Vector3(0.1, 0.08, 0.12), purple.darkened(0.05))
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.52, -0.2), 0.06, 0.03, Color(0.95, 0.85, 0.3))
	StylizedCreatureKit.quadruped_legs(root, 0.2, 0.85, purple)
	StylizedCreatureKit.tail(root, Vector3(0, 0.35, 0.28), 0.3, 0.07, purple.darkened(0.1))


static func _impmon(root: Node3D) -> void:
	var dark := Color(0.35, 0.12, 0.4)
	var red := Color(0.95, 0.35, 0.2)
	StylizedMesh.add_sphere(root, 0.2, dark, Vector3(0, 0.4, 0), "Body", 8, 5)
	StylizedMesh.add_sphere(root, 0.18, dark.lightened(0.05), Vector3(0, 0.7, 0.02), "Head", 8, 5)
	StylizedMesh.add_box(root, Vector3(0.06, 0.16, 0.06), red, Vector3(-0.1, 0.9, 0), "HornL")
	StylizedMesh.add_box(root, Vector3(0.06, 0.16, 0.06), red, Vector3(0.1, 0.9, 0), "HornR")
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.72, 0.15), 0.07, 0.035, red)
	_arms2(root, 0.42, dark, 0.22)
	_legs2(root, 0.12, dark.darkened(0.1), 0.1)
	StylizedMesh.add_box(root, Vector3(0.08, 0.08, 0.22), dark, Vector3(0, 0.35, -0.25), "Tail")
	_glow_sphere(root, 0.05, red, Vector3(0, 0.55, 0.12), "Core", 0.4)


static func _koromon(root: Node3D) -> void:
	var pink := Color(0.95, 0.55, 0.7)
	StylizedMesh.add_sphere(root, 0.32, pink, Vector3(0, 0.35, 0), "Body", 10, 6)
	StylizedCreatureKit.ear_pair(root, 0.7, 0.14, Vector3(0.1, 0.22, 0.05), pink.lightened(0.05))
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.42, 0.25), 0.1, 0.05)
	StylizedMesh.add_box(root, Vector3(0.12, 0.04, 0.04), Color(0.85, 0.35, 0.45), Vector3(0, 0.3, 0.28), "Mouth")
	_legs2(root, 0.05, pink.darkened(0.1), 0.12)


static func _chuumon(root: Node3D) -> void:
	var brown := Color(0.75, 0.55, 0.4)
	StylizedMesh.add_sphere(root, 0.18, brown, Vector3(0, 0.28, 0), "Body", 8, 5)
	StylizedMesh.add_sphere(root, 0.14, brown.lightened(0.08), Vector3(0, 0.42, -0.1), "Head", 8, 5)
	StylizedCreatureKit.ear_pair(root, 0.55, 0.08, Vector3(0.06, 0.1, 0.03), brown)
	StylizedCreatureKit.snout(root, Vector3(0, 0.38, -0.22), Vector3(0.08, 0.06, 0.1), Color(0.95, 0.9, 0.85))
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.44, -0.05), 0.05, 0.025)
	StylizedCreatureKit.tail(root, Vector3(0, 0.28, 0.2), 0.35, 0.05, brown.darkened(0.1))
	_legs2(root, 0.08, brown.darkened(0.1), 0.1)


static func _hagurumon(root: Node3D) -> void:
	var brass := Color(0.7, 0.55, 0.25)
	var steel := Color(0.4, 0.4, 0.42)
	StylizedMesh.add_cylinder(root, 0.32, 0.18, brass, Vector3(0, 0.4, 0), "GearCore", false, 10)
	## Teeth
	for i in 8:
		var ang := float(i) * TAU / 8.0
		var p := Vector3(cos(ang) * 0.38, 0.4, sin(ang) * 0.38)
		StylizedMesh.add_box(root, Vector3(0.1, 0.12, 0.1), steel, p, "Tooth%d" % i)
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.42, 0.2), 0.08, 0.04, Color(0.2, 0.2, 0.25))
	_glow_sphere(root, 0.06, Color(0.95, 0.8, 0.3), Vector3(0, 0.4, 0), "Axle", 0.35)


static func _numemon(root: Node3D) -> void:
	var slime := Color(0.45, 0.55, 0.35)
	StylizedMesh.add_sphere(root, 0.35, slime, Vector3(0, 0.3, 0), "Body", 10, 6)
	StylizedMesh.add_sphere(root, 0.2, slime.lightened(0.1), Vector3(0, 0.55, 0.15), "Head", 8, 5)
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.58, 0.28), 0.08, 0.04)
	StylizedMesh.add_box(root, Vector3(0.2, 0.08, 0.12), Color(0.7, 0.75, 0.4), Vector3(0, 0.48, 0.32), "Mouth")
	StylizedMesh.add_box(root, Vector3(0.15, 0.08, 0.25), slime.darkened(0.1), Vector3(0, 0.15, -0.3), "Trail")


static func _datamon(root: Node3D) -> void:
	var cyan := Color(0.55, 0.75, 0.85)
	var red := Color(0.95, 0.35, 0.25)
	StylizedMesh.add_box(root, Vector3(0.4, 0.45, 0.35), cyan, Vector3(0, 0.45, 0), "Body")
	StylizedMesh.add_box(root, Vector3(0.38, 0.32, 0.38), cyan.lightened(0.08), Vector3(0, 0.9, 0), "CubeHead")
	_glow_box(root, Vector3(0.2, 0.08, 0.08), red, Vector3(0, 0.9, 0.2), "Laser", 0.5)
	StylizedMesh.add_box(root, Vector3(0.12, 0.2, 0.12), Color(0.4, 0.45, 0.5), Vector3(-0.28, 0.55, 0), "ArmL")
	StylizedMesh.add_box(root, Vector3(0.12, 0.2, 0.12), Color(0.4, 0.45, 0.5), Vector3(0.28, 0.55, 0), "ArmR")
	_legs2(root, 0.1, cyan.darkened(0.15), 0.14)
	_glow_sphere(root, 0.06, red, Vector3(0, 0.55, 0.18), "Core", 0.4)


static func _bakemon(root: Node3D) -> void:
	var sheet := Color(0.92, 0.92, 0.95)
	var black := Color(0.15, 0.15, 0.18)
	StylizedMesh.add_sphere(root, 0.35, sheet, Vector3(0, 0.55, 0), "Sheet", 10, 6)
	StylizedMesh.add_box(root, Vector3(0.5, 0.45, 0.4), sheet, Vector3(0, 0.25, 0), "Robe")
	StylizedMesh.add_sphere(root, 0.07, black, Vector3(-0.1, 0.6, 0.28), "EyeL", 6, 4)
	StylizedMesh.add_sphere(root, 0.07, black, Vector3(0.1, 0.6, 0.28), "EyeR", 6, 4)
	StylizedMesh.add_box(root, Vector3(0.16, 0.06, 0.04), black, Vector3(0, 0.48, 0.3), "Mouth")
	_arms2(root, 0.4, sheet.darkened(0.05), 0.32)


static func _frigimon(root: Node3D) -> void:
	var snow := Color(0.9, 0.95, 1.0)
	var blue := Color(0.55, 0.75, 0.95)
	StylizedMesh.add_sphere(root, 0.4, snow, Vector3(0, 0.45, 0), "Body", 10, 6)
	StylizedMesh.add_sphere(root, 0.28, snow, Vector3(0, 0.95, 0), "Head", 10, 6)
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.98, 0.22), 0.08, 0.04)
	StylizedMesh.add_box(root, Vector3(0.22, 0.18, 0.18), blue, Vector3(-0.4, 0.5, 0), "MittL")
	StylizedMesh.add_box(root, Vector3(0.22, 0.18, 0.18), blue, Vector3(0.4, 0.5, 0), "MittR")
	_glow_sphere(root, 0.06, blue, Vector3(0, 1.2, 0), "Flake", 0.3)
	_legs2(root, 0.08, snow.darkened(0.05), 0.16)


static func _monzaemon(root: Node3D) -> void:
	var tan := Color(0.85, 0.7, 0.4)
	var pink := Color(0.95, 0.35, 0.45)
	StylizedMesh.add_sphere(root, 0.45, tan, Vector3(0, 0.5, 0), "Body", 10, 6)
	StylizedMesh.add_sphere(root, 0.32, tan.lightened(0.05), Vector3(0, 1.05, 0), "Head", 10, 6)
	StylizedCreatureKit.ear_pair(root, 1.35, 0.18, Vector3(0.1, 0.16, 0.06), tan)
	StylizedCreatureKit.eye_pair(root, Vector3(0, 1.08, 0.25), 0.09, 0.04, Color(0.2, 0.2, 0.25))
	StylizedMesh.add_box(root, Vector3(0.22, 0.08, 0.06), pink, Vector3(0, 0.95, 0.28), "ZipSmile")
	_arms2(root, 0.55, tan, 0.4)
	_legs2(root, 0.1, tan.darkened(0.08), 0.18)
	StylizedMesh.add_box(root, Vector3(0.2, 0.2, 0.08), pink, Vector3(0, 0.55, 0.35), "Heart")


static func _gotsumon(root: Node3D) -> void:
	var rock := Color(0.55, 0.5, 0.45)
	StylizedMesh.add_box(root, Vector3(0.4, 0.4, 0.35), rock, Vector3(0, 0.4, 0), "Body", false, 1.0, &"brick")
	StylizedMesh.add_box(root, Vector3(0.32, 0.28, 0.3), rock.lightened(0.08), Vector3(0, 0.75, 0), "Head")
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.78, 0.16), 0.07, 0.03)
	StylizedMesh.add_box(root, Vector3(0.12, 0.12, 0.1), rock.darkened(0.1), Vector3(-0.15, 0.95, 0), "PebbleL")
	StylizedMesh.add_box(root, Vector3(0.1, 0.14, 0.1), rock.darkened(0.05), Vector3(0.12, 0.95, 0), "PebbleR")
	_arms2(root, 0.45, rock.darkened(0.1), 0.26)
	_legs2(root, 0.1, rock.darkened(0.15), 0.12)


static func _icemon(root: Node3D) -> void:
	var ice := Color(0.65, 0.85, 1.0)
	StylizedMesh.add_box(root, Vector3(0.4, 0.4, 0.35), ice, Vector3(0, 0.4, 0), "Body")
	StylizedMesh.add_box(root, Vector3(0.32, 0.28, 0.3), ice.lightened(0.1), Vector3(0, 0.75, 0), "Head")
	_glow_box(root, Vector3(0.1, 0.18, 0.1), Color(0.9, 0.97, 1.0), Vector3(-0.12, 0.98, 0), "CrystalL", 0.4)
	_glow_box(root, Vector3(0.1, 0.22, 0.1), Color(0.9, 0.97, 1.0), Vector3(0.1, 1.0, 0), "CrystalR", 0.45)
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.78, 0.16), 0.07, 0.03, Color(0.2, 0.4, 0.7))
	_arms2(root, 0.45, ice.darkened(0.08), 0.26)
	_legs2(root, 0.1, ice.darkened(0.12), 0.12)


static func _pumpkinmon(root: Node3D) -> void:
	var orange := Color(0.95, 0.55, 0.12)
	var vine := Color(0.25, 0.55, 0.2)
	var black := Color(0.12, 0.1, 0.08)
	StylizedMesh.add_sphere(root, 0.42, orange, Vector3(0, 0.5, 0), "Pumpkin", 10, 6)
	StylizedMesh.add_box(root, Vector3(0.12, 0.16, 0.12), vine, Vector3(0, 0.95, 0), "Stem")
	StylizedMesh.add_box(root, Vector3(0.1, 0.08, 0.04), black, Vector3(-0.12, 0.55, 0.35), "EyeL")
	StylizedMesh.add_box(root, Vector3(0.1, 0.08, 0.04), black, Vector3(0.12, 0.55, 0.35), "EyeR")
	StylizedMesh.add_box(root, Vector3(0.22, 0.1, 0.04), black, Vector3(0, 0.4, 0.38), "Mouth")
	StylizedMesh.add_box(root, Vector3(0.1, 0.45, 0.1), vine, Vector3(-0.35, 0.4, 0), "ArmL")
	StylizedMesh.add_box(root, Vector3(0.1, 0.45, 0.1), vine, Vector3(0.35, 0.4, 0), "ArmR")
	_legs2(root, 0.08, vine.darkened(0.1), 0.16)


static func _digitamamon(root: Node3D) -> void:
	var shell := Color(0.95, 0.92, 0.85)
	var brown := Color(0.35, 0.25, 0.2)
	StylizedMesh.add_sphere(root, 0.4, shell, Vector3(0, 0.45, 0), "Egg", 10, 6)
	StylizedMesh.add_box(root, Vector3(0.55, 0.08, 0.55), brown, Vector3(0, 0.55, 0), "CrackBand")
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.55, 0.32), 0.09, 0.04, brown)
	StylizedMesh.add_box(root, Vector3(0.16, 0.06, 0.04), brown, Vector3(0, 0.42, 0.35), "Mouth")
	## Chef hat
	StylizedMesh.add_cylinder(root, 0.18, 0.12, shell, Vector3(0, 0.95, 0), "HatBase", false, 8)
	StylizedMesh.add_sphere(root, 0.2, shell, Vector3(0, 1.1, 0), "HatPuff", 8, 5)
	_arms2(root, 0.4, brown, 0.35)
	_legs2(root, 0.08, brown, 0.14)


## --- Bosses ------------------------------------------------------------------


static func _andromon(root: Node3D) -> void:
	var steel := Color(0.55, 0.6, 0.7)
	var red := Color(0.95, 0.35, 0.25)
	StylizedMesh.add_box(root, Vector3(0.7, 0.9, 0.45), steel, Vector3(0, 0.7, 0), "Torso")
	StylizedMesh.add_box(root, Vector3(0.45, 0.4, 0.4), steel.lightened(0.08), Vector3(0, 1.4, 0), "Head")
	_glow_box(root, Vector3(0.28, 0.1, 0.08), red, Vector3(0, 1.4, 0.22), "Visor", 0.5)
	StylizedMesh.add_box(root, Vector3(0.28, 0.7, 0.28), steel.darkened(0.1), Vector3(-0.55, 0.7, 0), "ArmL")
	StylizedMesh.add_box(root, Vector3(0.28, 0.7, 0.28), steel.darkened(0.1), Vector3(0.55, 0.7, 0), "ArmR")
	StylizedMesh.add_box(root, Vector3(0.25, 0.7, 0.28), steel.darkened(0.15), Vector3(-0.2, 0.15, 0), "LegL")
	StylizedMesh.add_box(root, Vector3(0.25, 0.7, 0.28), steel.darkened(0.15), Vector3(0.2, 0.15, 0), "LegR")
	_glow_sphere(root, 0.1, red, Vector3(0, 0.85, 0.25), "Core", 0.55)
	StylizedMesh.add_box(root, Vector3(0.5, 0.35, 0.2), steel, Vector3(0, 0.9, -0.3), "Pack")


static func _devimon(root: Node3D) -> void:
	var dark := Color(0.2, 0.1, 0.28)
	var crimson := Color(0.85, 0.2, 0.35)
	StylizedMesh.add_box(root, Vector3(0.55, 0.85, 0.4), dark, Vector3(0, 0.7, 0), "Torso")
	StylizedMesh.add_sphere(root, 0.28, dark.lightened(0.05), Vector3(0, 1.4, 0), "Head", 10, 6)
	StylizedMesh.add_box(root, Vector3(0.1, 0.25, 0.1), crimson, Vector3(-0.12, 1.7, 0), "HornL")
	StylizedMesh.add_box(root, Vector3(0.1, 0.25, 0.1), crimson, Vector3(0.12, 1.7, 0), "HornR")
	StylizedCreatureKit.eye_pair(root, Vector3(0, 1.42, 0.22), 0.1, 0.045, crimson)
	## Wings
	StylizedMesh.add_box(root, Vector3(0.9, 0.08, 0.5), dark.darkened(0.05), Vector3(-0.7, 1.0, -0.15), "WingL")
	StylizedMesh.add_box(root, Vector3(0.9, 0.08, 0.5), dark.darkened(0.05), Vector3(0.7, 1.0, -0.15), "WingR")
	StylizedMesh.add_box(root, Vector3(0.22, 0.65, 0.22), dark, Vector3(-0.45, 0.55, 0), "ArmL")
	StylizedMesh.add_box(root, Vector3(0.22, 0.65, 0.22), dark, Vector3(0.45, 0.55, 0), "ArmR")
	StylizedMesh.add_box(root, Vector3(0.2, 0.65, 0.22), dark.darkened(0.1), Vector3(-0.18, 0.12, 0), "LegL")
	StylizedMesh.add_box(root, Vector3(0.2, 0.65, 0.22), dark.darkened(0.1), Vector3(0.18, 0.12, 0), "LegR")
	_glow_sphere(root, 0.08, crimson, Vector3(0, 0.9, 0.22), "Heart", 0.5)


static func _orgemon(root: Node3D) -> void:
	var green := Color(0.35, 0.65, 0.35)
	var horn := Color(0.85, 0.55, 0.2)
	StylizedMesh.add_box(root, Vector3(0.8, 0.95, 0.5), green, Vector3(0, 0.75, 0), "Torso")
	StylizedMesh.add_sphere(root, 0.35, green.lightened(0.05), Vector3(0, 1.5, 0), "Head", 10, 6)
	StylizedMesh.add_box(root, Vector3(0.12, 0.35, 0.12), horn, Vector3(-0.15, 1.9, 0), "HornL")
	StylizedMesh.add_box(root, Vector3(0.12, 0.35, 0.12), horn, Vector3(0.15, 1.9, 0), "HornR")
	StylizedCreatureKit.eye_pair(root, Vector3(0, 1.52, 0.28), 0.1, 0.05, Color(0.95, 0.85, 0.2))
	## Big club arm
	StylizedMesh.add_box(root, Vector3(0.35, 0.85, 0.35), green.darkened(0.1), Vector3(-0.65, 0.7, 0), "ArmL")
	StylizedMesh.add_box(root, Vector3(0.45, 0.45, 0.45), Color(0.45, 0.35, 0.25), Vector3(0.7, 0.55, 0.1), "Club")
	StylizedMesh.add_box(root, Vector3(0.28, 0.7, 0.28), green.darkened(0.1), Vector3(0.55, 0.9, 0), "ArmR")
	StylizedMesh.add_box(root, Vector3(0.28, 0.7, 0.3), green.darkened(0.15), Vector3(-0.22, 0.15, 0), "LegL")
	StylizedMesh.add_box(root, Vector3(0.28, 0.7, 0.3), green.darkened(0.15), Vector3(0.22, 0.15, 0), "LegR")


static func _snimon(root: Node3D) -> void:
	var green := Color(0.45, 0.75, 0.35)
	var blade := Color(0.9, 0.9, 0.85)
	StylizedMesh.add_box(root, Vector3(0.45, 0.7, 0.4), green, Vector3(0, 0.7, 0), "Thorax")
	StylizedMesh.add_sphere(root, 0.28, green.lightened(0.08), Vector3(0, 1.35, 0.1), "Head", 10, 6)
	StylizedCreatureKit.eye_pair(root, Vector3(0, 1.4, 0.3), 0.12, 0.05, Color(0.95, 0.3, 0.2))
	## Scythe arms
	StylizedMesh.add_box(root, Vector3(0.15, 0.15, 0.9), blade, Vector3(-0.55, 0.9, 0.2), "BladeL")
	StylizedMesh.add_box(root, Vector3(0.15, 0.15, 0.9), blade, Vector3(0.55, 0.9, 0.2), "BladeR")
	StylizedMesh.add_box(root, Vector3(0.7, 0.08, 0.35), green.darkened(0.1), Vector3(0, 1.1, -0.2), "Wing")
	StylizedMesh.add_box(root, Vector3(0.18, 0.55, 0.18), green.darkened(0.15), Vector3(-0.15, 0.2, 0), "LegL")
	StylizedMesh.add_box(root, Vector3(0.18, 0.55, 0.18), green.darkened(0.15), Vector3(0.15, 0.2, 0), "LegR")
	StylizedMesh.add_box(root, Vector3(0.12, 0.12, 0.5), green, Vector3(0, 0.55, -0.4), "Abdomen")


static func _meramon(root: Node3D) -> void:
	var flame := Color(0.95, 0.4, 0.12)
	var gold := Color(1.0, 0.85, 0.25)
	StylizedMesh.add_box(root, Vector3(0.65, 0.9, 0.45), flame, Vector3(0, 0.7, 0), "Torso")
	StylizedMesh.add_sphere(root, 0.32, flame.lightened(0.1), Vector3(0, 1.4, 0), "Head", 10, 6)
	_glow_box(root, Vector3(0.15, 0.35, 0.15), gold, Vector3(-0.2, 1.75, 0), "FlameL", 0.55)
	_glow_box(root, Vector3(0.18, 0.4, 0.18), gold, Vector3(0, 1.8, 0), "FlameC", 0.6)
	_glow_box(root, Vector3(0.15, 0.35, 0.15), gold, Vector3(0.2, 1.75, 0), "FlameR", 0.55)
	StylizedCreatureKit.eye_pair(root, Vector3(0, 1.42, 0.25), 0.1, 0.045, Color(0.2, 0.15, 0.1))
	StylizedMesh.add_box(root, Vector3(0.3, 0.7, 0.3), flame.darkened(0.1), Vector3(-0.55, 0.65, 0), "ArmL")
	StylizedMesh.add_box(root, Vector3(0.3, 0.7, 0.3), flame.darkened(0.1), Vector3(0.55, 0.65, 0), "ArmR")
	StylizedMesh.add_box(root, Vector3(0.25, 0.65, 0.28), flame.darkened(0.15), Vector3(-0.2, 0.12, 0), "LegL")
	StylizedMesh.add_box(root, Vector3(0.25, 0.65, 0.28), flame.darkened(0.15), Vector3(0.2, 0.12, 0), "LegR")
	_glow_sphere(root, 0.12, gold, Vector3(0, 0.9, 0.25), "Core", 0.6)


static func _whamon(root: Node3D) -> void:
	var blue := Color(0.35, 0.55, 0.85)
	var belly := Color(0.85, 0.9, 1.0)
	StylizedMesh.add_sphere(root, 0.7, blue, Vector3(0, 0.7, 0), "Body", 10, 6)
	StylizedMesh.add_sphere(root, 0.45, belly, Vector3(0, 0.55, 0.35), "Belly", 8, 5)
	StylizedMesh.add_sphere(root, 0.35, blue.lightened(0.05), Vector3(0, 0.85, -0.65), "Head", 10, 6)
	StylizedCreatureKit.eye_pair(root, Vector3(0, 0.95, -0.5), 0.14, 0.06)
	StylizedMesh.add_box(root, Vector3(0.2, 0.15, 0.35), blue.darkened(0.1), Vector3(0, 0.7, -0.95), "Snout")
	## Fins + tail fluke
	StylizedMesh.add_box(root, Vector3(0.8, 0.1, 0.35), blue.darkened(0.08), Vector3(-0.7, 0.7, 0), "FinL")
	StylizedMesh.add_box(root, Vector3(0.8, 0.1, 0.35), blue.darkened(0.08), Vector3(0.7, 0.7, 0), "FinR")
	StylizedMesh.add_box(root, Vector3(0.9, 0.12, 0.35), blue, Vector3(0, 0.75, 0.85), "Fluke")
	_glow_sphere(root, 0.1, belly, Vector3(0, 1.1, -0.4), "Spout", 0.35)
