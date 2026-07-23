class_name WorldDressKit
extends RefCounted
## Shared prop dressing for micro-stories and landmarks — every kind answers “why here?”


static func dress(node: Node3D, kind: StringName, seed_i: int) -> void:
	match kind:
		&"camp":
			StylizedMesh.add_box(node, Vector3(2.8, 0.04, 2.8), WorldPalette.DIRT, Vector3(0, 0.02, 0), "Pad", false, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.85, 0.22, 0.85), WorldPalette.ROCK, Vector3(0, 0.12, 0), "FireRing", false, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.35, 0.15, 0.35), Color(0.15, 0.12, 0.1), Vector3(0, 0.22, 0), "Ash", false, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(1.3, 0.25, 0.35), WorldPalette.WOOD, Vector3(1.1, 0.15, 0.7), "LogSeat", false, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.5, 0.35, 0.4), Color(0.4, 0.32, 0.22), Vector3(-1.0, 0.2, -0.6), "Pack", false, 1.0, &"wood")
		&"wreck":
			StylizedMesh.add_box(node, Vector3(2.6, 0.65, 1.3), WorldPalette.WOOD.darkened(0.18), Vector3(0, 0.35, 0), "Hull", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.8, 0.12, 2.0), WorldPalette.METAL.darkened(0.3), Vector3(0.3, 0.85, 0), "Beam", false, 1.0, &"brick")
			StylizedMesh.add_box(node, Vector3(0.35, 0.35, 0.35), WorldPalette.METAL, Vector3(-1.1, 0.25, 0.5), "Wheel", false, 1.0, &"brick")
		&"bones":
			StylizedMesh.add_box(node, Vector3(1.4, 0.12, 0.35), Color(0.85, 0.82, 0.75), Vector3(0, 0.08, 0), "Rib", false, 1.0, &"flat")
			StylizedMesh.add_box(node, Vector3(0.35, 0.28, 0.3), Color(0.9, 0.88, 0.8), Vector3(0.7, 0.15, 0.1), "Skull", false, 1.0, &"flat")
			StylizedMesh.add_box(node, Vector3(0.5, 0.08, 0.5), WorldPalette.DIRT.darkened(0.1), Vector3(0, 0.03, 0), "Stain", false, 1.0, &"dirt")
		&"pack":
			StylizedMesh.add_box(node, Vector3(0.55, 0.45, 0.4), Color(0.35, 0.4, 0.3), Vector3(0, 0.25, 0), "Bag", false, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.4, 0.08, 0.3), WorldPalette.UI_PAPER, Vector3(0.3, 0.15, 0.35), "Logbook", false, 1.0, &"flat")
		&"monument", &"statue":
			StylizedMesh.add_box(node, Vector3(1.4, 0.35, 1.4), WorldPalette.ROCK, Vector3(0, 0.15, 0), "Base", true, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.7, 1.8, 0.55), WorldPalette.ROCK.lightened(0.05), Vector3(0, 1.1, 0), "Figure", true, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.25, 0.25, 0.25), Color(0.45, 0.85, 0.95), Vector3(0, 2.1, 0.1), "Hex", false, 1.0, &"flat")
		&"crystal":
			for j in 5:
				var ang := float(j) * TAU / 5.0 + float(seed_i) * 0.05
				var h := 0.8 + float(j % 3) * 0.35
				StylizedMesh.add_box(node, Vector3(0.25, h, 0.25), Color(0.35, 0.7, 0.95), Vector3(cos(ang) * 0.9, h * 0.5, sin(ang) * 0.9), "C_%d" % j, false, 1.0, &"flat")
		&"stones":
			for j in 7:
				var ang := float(j) * TAU / 7.0
				StylizedMesh.add_box(node, Vector3(0.5, 0.85 + float(j % 3) * 0.12, 0.35), WorldPalette.ROCK, Vector3(cos(ang) * 2.4, 0.45, sin(ang) * 2.4), "S_%d" % j, true, 1.0, &"dirt")
		&"bridge":
			StylizedMesh.add_box(node, Vector3(4.5, 0.18, 1.4), WorldPalette.WOOD.darkened(0.1), Vector3(0, 0.5, 0), "Deck", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.25, 1.0, 0.25), WorldPalette.WOOD, Vector3(-2.0, 0.4, 0.6), "PostA", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.25, 0.55, 0.25), WorldPalette.WOOD.darkened(0.2), Vector3(2.0, 0.2, -0.5), "PostBroke", false, 1.0, &"wood")
		&"cabin":
			StylizedMesh.add_box(node, Vector3(4.0, 2.0, 0.25), WorldPalette.WOOD.darkened(0.15), Vector3(0, 1.0, -1.8), "Wall", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.25, 2.0, 3.5), WorldPalette.WOOD.darkened(0.1), Vector3(-1.9, 1.0, 0), "WallB", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.7, 0.55, 0.7), WorldPalette.METAL.darkened(0.25), Vector3(0.8, 0.3, 0.5), "Stove", false, 1.0, &"brick")
			StylizedMesh.add_box(node, Vector3(0.35, 0.25, 0.35), WorldPalette.METAL, Vector3(0.8, 0.65, 0.5), "Kettle", false, 1.0, &"brick")
		&"meglog":
			StylizedMesh.add_box(node, Vector3(5.5, 0.7, 0.9), WorldPalette.TRUNK.darkened(0.12), Vector3(0, 0.35, 0), "Trunk", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(1.2, 0.35, 0.9), Color(0.1, 0.1, 0.12), Vector3(1.2, 0.45, 0), "Hollow", false, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.9, 0.2, 0.9), WorldPalette.LEAF_DARK, Vector3(-1.5, 0.7, 0.1), "Moss", false, 1.0, &"leaf")
		&"pond":
			StylizedMesh.add_box(node, Vector3(7, 0.1, 5.5), WorldPalette.DIRT.darkened(0.12), Vector3(0, -0.06, 0), "Bed", false, 1.0, &"dirt")
			var water := MeshInstance3D.new()
			water.name = "Water"
			var wm := BoxMesh.new()
			wm.size = Vector3(6.2, 0.07, 4.8)
			water.mesh = wm
			water.material_override = StylizedMesh.make_water_material(WorldPalette.WATER)
			water.position = Vector3(0, 0.03, 0)
			node.add_child(water)
			RegionPropKit.attach_living_water(water, Vector3(5.8, 0.05, 4.4))
		&"waterfall":
			StylizedMesh.add_box(node, Vector3(3.5, 2.8, 1.2), WorldPalette.ROCK, Vector3(0, 1.2, -0.4), "Cliff", true, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.6, 2.2, 0.25), WorldPalette.WATER.lightened(0.15), Vector3(0, 1.0, 0.2), "Fall", false, 1.0, &"flat")
			StylizedMesh.add_box(node, Vector3(2.8, 0.12, 2.2), WorldPalette.WATER, Vector3(0, 0.05, 1.2), "Pool", false, 1.0, &"flat")
		&"tower":
			StylizedMesh.add_box(node, Vector3(1.4, 1.2, 1.4), WorldPalette.WOOD.darkened(0.15), Vector3(0, 0.6, 0), "Base", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.35, 2.5, 0.35), WorldPalette.WOOD, Vector3(0.3, 2.0, 0.2), "Splinter", false, 1.0, &"wood")
		&"shrine":
			StylizedMesh.add_box(node, Vector3(1.6, 0.3, 1.2), WorldPalette.ROCK, Vector3(0, 0.15, 0), "Altar", true, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.4, 0.7, 0.25), WorldPalette.ROCK.lightened(0.08), Vector3(0, 0.6, 0), "Stone", false, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.5, 0.08, 0.5), WorldPalette.FLOWER, Vector3(0.4, 0.35, 0.3), "Petals", false, 1.0, &"leaf")
		&"meteor":
			StylizedMesh.add_box(node, Vector3(5.5, 0.06, 5.5), Color(0.12, 0.1, 0.1), Vector3(0, 0.03, 0), "Scar", false, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.7, 0.5, 0.6), Color(0.55, 0.35, 0.85), Vector3(0, 0.3, 0), "Shard", true, 1.0, &"flat")
		&"nest":
			StylizedMesh.add_box(node, Vector3(1.2, 0.35, 1.2), WorldPalette.WOOD.darkened(0.2), Vector3(0, 1.4, 0), "Nest", false, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.35, 2.2, 0.35), WorldPalette.TRUNK, Vector3(0, 0.9, 0), "DeadPine", false, 1.0, &"wood")
		&"marker":
			StylizedMesh.add_box(node, Vector3(0.15, 1.4, 0.15), WorldPalette.WOOD, Vector3(0, 0.7, 0), "Stake", false, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.55, 0.3, 0.08), Color(0.7, 0.25, 0.2), Vector3(0.25, 1.15, 0), "Sign", false, 1.0, &"wood")
		&"garden":
			StylizedMesh.add_box(node, Vector3(3.2, 0.05, 3.2), WorldPalette.DIRT, Vector3(0, 0.03, 0), "Soil", false, 1.0, &"dirt")
			for j in 6:
				var ang := float(j) * TAU / 6.0
				StylizedMesh.add_box(node, Vector3(0.2, 0.45, 0.2), Color(0.4, 0.85, 0.55), Vector3(cos(ang) * 1.1, 0.25, sin(ang) * 1.1), "Herb_%d" % j, false, 1.0, &"leaf")
		&"picnic":
			StylizedMesh.add_box(node, Vector3(2.0, 0.05, 1.4), Color(0.75, 0.55, 0.35), Vector3(0, 0.03, 0), "Blanket", false, 1.0, &"flat")
			StylizedMesh.add_box(node, Vector3(0.2, 0.18, 0.2), WorldPalette.UI_PAPER, Vector3(0.4, 0.12, 0.2), "CupA", false, 1.0, &"flat")
			StylizedMesh.add_box(node, Vector3(0.2, 0.18, 0.2), WorldPalette.UI_PAPER, Vector3(-0.35, 0.12, -0.15), "CupB", false, 1.0, &"flat")
		&"scarecrow":
			StylizedMesh.add_box(node, Vector3(0.2, 2.2, 0.2), WorldPalette.WOOD, Vector3(0, 1.1, 0), "Pole", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(1.2, 0.15, 0.15), WorldPalette.WOOD, Vector3(0, 1.7, 0), "Arms", false, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.45, 0.45, 0.45), Color(0.55, 0.85, 0.4), Vector3(0, 2.15, 0), "HexHead", false, 1.0, &"flat")
		&"arch":
			StylizedMesh.add_box(node, Vector3(0.8, 2.4, 0.8), WorldPalette.ROCK, Vector3(-1.3, 1.2, 0), "L", true, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.8, 2.4, 0.8), WorldPalette.ROCK, Vector3(1.3, 1.2, 0), "R", true, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(3.2, 0.55, 0.9), WorldPalette.ROCK.lightened(0.05), Vector3(0, 2.5, 0), "Cap", true, 1.0, &"dirt")
		&"cave":
			StylizedMesh.add_box(node, Vector3(6, 3.5, 5), WorldPalette.ROCK, Vector3(0, 1.5, 0), "Hill", true, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(2.0, 1.8, 1.8), Color(0.07, 0.07, 0.09), Vector3(0, 0.9, 2.2), "Mouth")
		&"viewpoint":
			StylizedMesh.add_box(node, Vector3(2.6, 0.22, 1.3), WorldPalette.ROCK.lightened(0.06), Vector3(0, 0.12, 0), "Shelf", true, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(1.7, 0.14, 0.4), WorldPalette.WOOD, Vector3(0, 0.38, 0), "Bench", false, 1.0, &"wood")
		_:
			StylizedMesh.add_box(node, Vector3(1.0, 0.4, 1.0), WorldPalette.ROCK, Vector3(0, 0.2, 0), "Mark", false, 1.0, &"dirt")
