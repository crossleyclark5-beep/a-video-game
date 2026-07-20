extends Node3D
## Test house interior — ground floor + upstairs foundation with stairs.

@onready var _ground: BuildingFloor = $GroundFloor
@onready var _upstairs: BuildingFloor = $Upstairs
@onready var _stairs_up: FloorTransition = $GroundFloor/StairsUp
@onready var _stairs_down: FloorTransition = $Upstairs/StairsDown


func _ready() -> void:
	_ground.spawn_marker = $GroundFloor/Spawn
	_upstairs.spawn_marker = $Upstairs/Spawn
	_stairs_up.target_spawn = $GroundFloor/StairsUp/UpstairsSpawn
	_stairs_down.target_spawn = $Upstairs/StairsDown/GroundSpawn
	_build_visuals()


func _build_visuals() -> void:
	# Ground floor slab + walls (open top so camera sees in)
	StylizedMesh.add_box(_ground, Vector3(7.0, 0.12, 6.0), Color(0.62, 0.48, 0.34), Vector3(0, 0.06, 0), "Floor", true)
	StylizedMesh.add_box(_ground, Vector3(7.0, 2.8, 0.2), Color(0.85, 0.82, 0.75), Vector3(0, 1.5, -3.0), "WallBack", true)
	StylizedMesh.add_box(_ground, Vector3(0.2, 2.8, 6.0), Color(0.85, 0.82, 0.75), Vector3(-3.5, 1.5, 0), "WallL", true)
	StylizedMesh.add_box(_ground, Vector3(0.2, 2.8, 6.0), Color(0.85, 0.82, 0.75), Vector3(3.5, 1.5, 0), "WallR", true)
	# Front wall with doorway gap (two segments)
	StylizedMesh.add_box(_ground, Vector3(2.4, 2.8, 0.2), Color(0.85, 0.82, 0.75), Vector3(-2.2, 1.5, 3.0), "WallF1", true)
	StylizedMesh.add_box(_ground, Vector3(2.4, 2.8, 0.2), Color(0.85, 0.82, 0.75), Vector3(2.2, 1.5, 3.0), "WallF2", true)
	# Furniture
	StylizedMesh.add_box(_ground, Vector3(2.0, 0.5, 0.9), Color(0.55, 0.22, 0.2), Vector3(-1.5, 0.4, -1.5), "Couch")
	StylizedMesh.add_box(_ground, Vector3(1.2, 0.6, 0.8), Color(0.4, 0.25, 0.15), Vector3(1.2, 0.45, -1.2), "Table")
	StylizedMesh.add_box(_ground, Vector3(0.9, 1.6, 0.4), Color(0.45, 0.35, 0.6), Vector3(2.4, 0.95, -2.0), "Shelf")
	StylizedMesh.add_box(_ground, Vector3(1.0, 0.15, 0.7), Color(0.7, 0.7, 0.75), Vector3(-2.2, 1.1, 1.5), "Counter")
	# Stair visual
	StylizedMesh.add_box(_ground, Vector3(1.4, 0.25, 0.5), Color(0.55, 0.4, 0.25), Vector3(2.2, 0.3, -2.0), "Step1")
	StylizedMesh.add_box(_ground, Vector3(1.4, 0.25, 0.5), Color(0.55, 0.4, 0.25), Vector3(2.2, 0.7, -2.3), "Step2")
	StylizedMesh.add_box(_ground, Vector3(1.4, 0.25, 0.5), Color(0.55, 0.4, 0.25), Vector3(2.2, 1.1, -2.6), "Step3")
	StylizedMesh.add_box(_ground, Vector3(1.4, 0.25, 0.5), Color(0.55, 0.4, 0.25), Vector3(2.2, 1.5, -2.9), "Step4")
	# Rug collectible hint
	StylizedMesh.add_box(_ground, Vector3(2.2, 0.04, 1.4), Color(0.55, 0.2, 0.25), Vector3(0, 0.14, 0.5), "Rug")

	# Upstairs
	StylizedMesh.add_box(_upstairs, Vector3(7.0, 0.12, 6.0), Color(0.58, 0.45, 0.32), Vector3(0, 0.06, 0), "FloorUp", true)
	StylizedMesh.add_box(_upstairs, Vector3(7.0, 1.6, 0.2), Color(0.8, 0.78, 0.72), Vector3(0, 0.9, -3.0), "WallBackUp", true)
	StylizedMesh.add_box(_upstairs, Vector3(0.2, 1.6, 6.0), Color(0.8, 0.78, 0.72), Vector3(-3.5, 0.9, 0), "WallLUp", true)
	StylizedMesh.add_box(_upstairs, Vector3(0.2, 1.6, 6.0), Color(0.8, 0.78, 0.72), Vector3(3.5, 0.9, 0), "WallRUp", true)
	StylizedMesh.add_box(_upstairs, Vector3(1.8, 0.4, 1.2), Color(0.35, 0.45, 0.7), Vector3(-1.5, 0.35, 0.5), "Bed")
	StylizedMesh.add_box(_upstairs, Vector3(0.8, 1.0, 0.4), Color(0.5, 0.35, 0.25), Vector3(1.5, 0.6, -1.5), "Dresser")
	# Hidden attic chest upstairs
	var chest := ChestInteractable.new()
	chest.name = "AtticChest"
	chest.chest_id = &"brick_house_attic_chest"
	chest.rarity = ChestInteractable.Rarity.RARE
	chest.loot_table_id = &"loot_chest_rare"
	chest.position = Vector3(-2.4, 0.45, -2.2)
	chest.loot_item_id = &"hex_shard"
	chest.loot_quantity = 2
	chest.prompt_verb = "Open hidden chest"
	_upstairs.add_child(chest)
	_add_chest_mesh(chest)


func _add_chest_mesh(chest: Area3D) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.55, 0.7)
	mi.mesh = box
	mi.material_override = StylizedMesh.make_material(Color(0.88, 0.68, 0.18))
	chest.add_child(mi)
	var shape := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(1.4, 1.2, 1.4)
	shape.shape = s
	chest.add_child(shape)
