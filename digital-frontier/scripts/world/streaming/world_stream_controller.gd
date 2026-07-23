class_name WorldStreamController
extends Node
## Distance-based world streaming — authored density stays; activation follows the focus.
##
## Build the full Grassland, then register stream units. Near the player (or aircraft /
## inspect camera): full detail. Far away: visual-only or inactive.
## Player should not notice loads — hysteresis rings prevent thrashing.


signal band_changed(unit_id: StringName, band: int)
signal focus_changed(focus: Vector3, airborne: bool)

const GROUP := &"world_stream"

var _units: Array[WorldStreamUnit] = []
var _focus_provider: Callable = Callable()
var _player: Node3D = null
var _tick: float = 0.0
var _airborne: bool = false
var _region_root: Node3D = null
var _stats := {
	&"near": 0,
	&"medium": 0,
	&"far": 0,
	&"very_far": 0,
	&"units": 0,
}


func _ready() -> void:
	add_to_group(GROUP)
	name = "WorldStreamController"
	set_process(true)


func setup(region_root: Node3D, player: Node3D) -> void:
	_region_root = region_root
	_player = player
	_units.clear()
	if _region_root:
		_register_from_region(_region_root)
		## Initial classification from player spawn.
		var focus := _player.global_position if _player else Vector3.ZERO
		_classify_all(focus, false)
		WorldLodPolicy.apply_to_vegetation_root(_region_root.get_node_or_null("RegionVegetation"), false)
	_stats[&"units"] = _units.size()
	print("WORLD_STREAM_UNITS=%d" % _units.size())


func set_player(player: Node3D) -> void:
	_player = player


func set_focus_provider(provider: Callable) -> void:
	_focus_provider = provider


func set_airborne(airborne: bool) -> void:
	if _airborne == airborne:
		return
	_airborne = airborne
	if _region_root:
		WorldLodPolicy.apply_to_vegetation_root(_region_root.get_node_or_null("RegionVegetation"), _airborne)


func is_airborne() -> bool:
	return _airborne


func get_units() -> Array[WorldStreamUnit]:
	return _units


func get_stats() -> Dictionary:
	return _stats.duplicate()


func get_focus_position() -> Vector3:
	if _focus_provider.is_valid():
		var v = _focus_provider.call()
		if v is Vector3:
			return v
	if _player and is_instance_valid(_player):
		return _player.global_position
	return Vector3.ZERO


func pin_unit_near(unit_id: StringName, pinned: bool = true) -> void:
	for u in _units:
		if u.id == unit_id:
			u.always_near = pinned
			if pinned:
				u.apply_band(AdventureNodeBudget.Band.NEAR)
			return


func pin_hub_at(world_pos: Vector3, pinned: bool = true) -> void:
	## Pin nearest hub so interiors / towns stay hot while occupied.
	var best: WorldStreamUnit = null
	var best_d := 1e9
	for u in _units:
		if u.kind != WorldStreamUnit.Kind.HUB:
			continue
		var d := Vector3(u.origin.x, 0, u.origin.z).distance_to(Vector3(world_pos.x, 0, world_pos.z))
		if d < best_d:
			best_d = d
			best = u
	if best and best_d < 200.0:
		best.always_near = pinned
		if pinned:
			best.apply_band(AdventureNodeBudget.Band.NEAR)


func force_refresh() -> void:
	_classify_all(get_focus_position(), _airborne)


func _process(delta: float) -> void:
	_tick += delta
	if _tick < AdventureNodeBudget.STREAM_TICK_SEC:
		return
	_tick = 0.0
	## Auto-detect inspect / high altitude as airborne for LOD rings.
	var focus := get_focus_position()
	var inspect_air := false
	var inspects := get_tree().get_nodes_in_group(WorldInspectController.GROUP)
	if not inspects.is_empty() and inspects[0].has_method("is_active") and inspects[0].call("is_active"):
		inspect_air = true
		var cam := inspects[0].get_node_or_null("InspectCamera") as Camera3D
		if cam:
			focus = cam.global_position
	var high := focus.y > 35.0
	var want_air := inspect_air or high
	if want_air != _airborne:
		set_airborne(want_air)
	_classify_all(focus, _airborne)
	focus_changed.emit(focus, _airborne)


func _register_from_region(root: Node3D) -> void:
	## Terrain chunks
	var terrain := root.get_node_or_null("GrasslandTerrain")
	if terrain:
		for c in terrain.get_children():
			if c is Node3D and String(c.name).begins_with("TerrainChunk_"):
				_add_unit(StringName(c.name), WorldStreamUnit.Kind.TERRAIN, c as Node3D, 200.0, true)
		for scenic in ["RiverRibbon", "ScenicPonds"]:
			var n := terrain.get_node_or_null(scenic)
			if n is Node3D:
				_add_unit(StringName(scenic), WorldStreamUnit.Kind.LANDMARK, n as Node3D, 120.0, true)

	## Hubs
	for hub_name in [
		"PleasantPark", "GreaseGrove", "MirrorMere", "MarketMile",
		"SaltySprings", "RiskyReels", "FatalFields",
	]:
		var hub := root.find_child(hub_name, true, false)
		if hub is Node3D:
			_add_unit(StringName(hub_name), WorldStreamUnit.Kind.HUB, hub as Node3D, 110.0, true)

	## Vegetation subgroups — MultiMesh density stays; we only sleep far groups.
	## keep_visible_when_far=true so forests remain aerial silhouettes until VERY_FAR.
	var veg := root.get_node_or_null("RegionVegetation")
	if veg:
		for c in veg.get_children():
			if c is Node3D:
				_add_unit(StringName("Veg_%s" % c.name), WorldStreamUnit.Kind.VEGETATION, c as Node3D, 180.0, true)

	## Region terrain overlays (mountains, cliffs, caves)
	var rt := root.get_node_or_null("RegionTerrain")
	if rt:
		for c in rt.get_children():
			if c is Node3D:
				_add_unit(StringName("TerrainOverlay_%s" % c.name), WorldStreamUnit.Kind.LANDMARK, c as Node3D, 140.0, true)

	## Discoveries
	var disc := root.get_node_or_null("RegionDiscoveries")
	if disc:
		for c in disc.get_children():
			if c is Node3D:
				_add_unit(StringName("Disc_%s" % c.name), WorldStreamUnit.Kind.DISCOVERY, c as Node3D, 40.0, false)

	## Corridors / expansion
	for nm in ["RegionCorridors", "ExpansionPoints", "SatelliteHangars"]:
		var n2 := root.get_node_or_null(nm)
		if n2 == null:
			n2 = root.find_child(nm, true, false)
		if n2 is Node3D:
			_add_unit(StringName(nm), WorldStreamUnit.Kind.CORRIDOR, n2 as Node3D, 200.0, true)


func _add_unit(id: StringName, kind: WorldStreamUnit.Kind, node: Node3D, radius: float, keep_far_visible: bool) -> void:
	if node == null:
		return
	## Avoid double-register
	for u in _units:
		if u.root == node:
			return
	var unit := WorldStreamUnit.new()
	unit.id = id
	unit.kind = kind
	unit.root = node
	unit.origin = node.global_position if node.is_inside_tree() else node.position
	unit.radius = radius
	unit.keep_visible_when_far = keep_far_visible
	unit.capture_defaults()
	_units.append(unit)


func _classify_all(focus: Vector3, airborne: bool) -> void:
	var near_n := 0
	var med_n := 0
	var far_n := 0
	var vfar_n := 0
	for u in _units:
		if u.root == null or not is_instance_valid(u.root):
			continue
		## Refresh origin for moved hubs (should be rare).
		if u.root.is_inside_tree():
			u.origin = u.root.global_position
		var band := _band_for(u, focus, airborne)
		if u.band != band:
			u.apply_band(band)
			band_changed.emit(u.id, band)
		match band:
			AdventureNodeBudget.Band.NEAR: near_n += 1
			AdventureNodeBudget.Band.MEDIUM: med_n += 1
			AdventureNodeBudget.Band.FAR: far_n += 1
			_: vfar_n += 1
	_stats[&"near"] = near_n
	_stats[&"medium"] = med_n
	_stats[&"far"] = far_n
	_stats[&"very_far"] = vfar_n
	_stats[&"units"] = _units.size()


func _band_for(unit: WorldStreamUnit, focus: Vector3, airborne: bool) -> AdventureNodeBudget.Band:
	if unit.always_near:
		return AdventureNodeBudget.Band.NEAR
	var d := Vector3(unit.origin.x, 0, unit.origin.z).distance_to(Vector3(focus.x, 0, focus.z))
	d = maxf(0.0, d - unit.radius * 0.35)
	var near_e: float
	var near_x: float
	var med_e: float
	var med_x: float
	var far_e: float
	var far_x: float
	if airborne:
		near_e = AdventureNodeBudget.AIR_NEAR_ENTER
		near_x = AdventureNodeBudget.AIR_NEAR_EXIT
		med_e = AdventureNodeBudget.AIR_MEDIUM_ENTER
		med_x = AdventureNodeBudget.AIR_MEDIUM_EXIT
		far_e = AdventureNodeBudget.AIR_FAR_ENTER
		far_x = AdventureNodeBudget.AIR_FAR_EXIT
	else:
		near_e = AdventureNodeBudget.GROUND_NEAR_ENTER
		near_x = AdventureNodeBudget.GROUND_NEAR_EXIT
		med_e = AdventureNodeBudget.GROUND_MEDIUM_ENTER
		med_x = AdventureNodeBudget.GROUND_MEDIUM_EXIT
		far_e = AdventureNodeBudget.GROUND_FAR_ENTER
		far_x = AdventureNodeBudget.GROUND_FAR_EXIT
	## Hysteresis based on previous band.
	match unit.band:
		AdventureNodeBudget.Band.NEAR:
			if d <= near_x:
				return AdventureNodeBudget.Band.NEAR
			if d <= med_x:
				return AdventureNodeBudget.Band.MEDIUM
			if d <= far_x:
				return AdventureNodeBudget.Band.FAR
			return AdventureNodeBudget.Band.VERY_FAR
		AdventureNodeBudget.Band.MEDIUM:
			if d <= near_e:
				return AdventureNodeBudget.Band.NEAR
			if d <= med_x:
				return AdventureNodeBudget.Band.MEDIUM
			if d <= far_x:
				return AdventureNodeBudget.Band.FAR
			return AdventureNodeBudget.Band.VERY_FAR
		AdventureNodeBudget.Band.FAR:
			if d <= near_e:
				return AdventureNodeBudget.Band.NEAR
			if d <= med_e:
				return AdventureNodeBudget.Band.MEDIUM
			if d <= far_x:
				return AdventureNodeBudget.Band.FAR
			return AdventureNodeBudget.Band.VERY_FAR
		_:
			if d <= near_e:
				return AdventureNodeBudget.Band.NEAR
			if d <= med_e:
				return AdventureNodeBudget.Band.MEDIUM
			if d <= far_e:
				return AdventureNodeBudget.Band.FAR
			return AdventureNodeBudget.Band.VERY_FAR
