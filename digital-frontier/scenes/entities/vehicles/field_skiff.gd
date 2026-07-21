extends Node3D
## Field Skiff visual root — prefers curated Kenney craft GLB, toon rematerialized.


func _ready() -> void:
	if ExternalPropKit.is_available():
		ExternalPropKit.spawn(self, &"craft_speeder", Vector3.ZERO, 0.0, 1.2, "Hull")
	else:
		StylizedMesh.add_box(self, Vector3(2.4, 0.55, 3.2), Color(0.35, 0.55, 0.85), Vector3(0, 0.4, 0), "Hull")
		StylizedMesh.add_box(self, Vector3(1.2, 0.45, 1.4), Color(0.55, 0.75, 0.95), Vector3(0, 0.85, -0.2), "Canopy")
		StylizedMesh.add_box(self, Vector3(0.35, 0.2, 0.8), WorldPalette.LAMP_GLOW, Vector3(0, 0.25, -1.7), "Thruster")
