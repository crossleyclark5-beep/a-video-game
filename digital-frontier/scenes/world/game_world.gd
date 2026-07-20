extends Node3D
## Top-level world scene shell for overworld gameplay.
##
## Layer hierarchy (see docs/SCENE_ARCHITECTURE.md):
## - HexGridLayer: tile mesh instances, chunk streaming
## - EntityLayer: player, NPCs, creatures
## - BuildingLayer: exterior building instances
## - EffectsLayer: particles, weather VFX
## - CameraRig: top-down 2.5D camera

@onready var hex_grid_layer: Node3D = $HexGridLayer
@onready var entity_layer: Node3D = $EntityLayer
@onready var building_layer: Node3D = $BuildingLayer


func _ready() -> void:
	# Load default region when world gameplay is implemented.
	var default_region := &"starter_plains"
	EventBus.region_load_requested.emit(default_region)
