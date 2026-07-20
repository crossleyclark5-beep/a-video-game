extends SceneTree
## Run: godot --headless --path . -s res://tools/world_polish_smoke.gd


func _initialize() -> void:
	await process_frame
	var ok := true
	var coast: PackedVector2Array = GrasslandLayout.island_coastline()
	if coast.size() < 8:
		push_error("coastline too small")
		ok = false
	for p in [
		GrasslandLayout.PLEASANT_PARK,
		GrasslandLayout.RISKY_REELS,
		GrasslandLayout.MIRROR_MERE,
		GrasslandLayout.MARKET_MILE,
		GrasslandLayout.GREASE_GROVE,
		GrasslandLayout.SALTY_SPRINGS,
		GrasslandLayout.FATAL_FIELDS,
	]:
		if not GrasslandLayout.is_on_island(p):
			push_error("POI off island: %s" % str(p))
			ok = false
	## Ocean point should be outside.
	if GrasslandLayout.is_on_island(Vector3(6000, 0, 6000)):
		push_error("ocean counted as island")
		ok = false
	if GrasslandLayout.road_clearance() < 5.0:
		push_error("road clearance too small")
		ok = false
	var ctrl_script := load("res://scripts/systems/buildings/building_interior_controller.gd")
	if ctrl_script == null:
		push_error("missing interior controller")
		ok = false
	var cam_script := load("res://scenes/world/camera_rig.gd")
	if cam_script == null:
		push_error("missing camera rig")
		ok = false
	print("WORLD_POLISH_SMOKE_OK" if ok else "WORLD_POLISH_SMOKE_FAIL")
	quit(0 if ok else 1)
