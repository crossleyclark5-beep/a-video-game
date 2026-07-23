class_name WorldPerfMonitor
extends Node
## Developer performance readout — nodes, stream bands, FPS, living counts, warnings.


const GROUP := &"world_perf"
## Throttle full-tree walks — counting 10k+ nodes every frame freezes handheld.
const NODE_COUNT_INTERVAL_FRAMES := 45

var _warn: PackedStringArray = []
var _cached_world_nodes: int = 0
var _cache_frame: int = -99999


func _ready() -> void:
	add_to_group(GROUP)
	name = "WorldPerfMonitor"


func snapshot(world_root: Node = null) -> Dictionary:
	_warn.clear()
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var mem_static := Performance.get_monitor(Performance.MEMORY_STATIC)
	var obj_count := Performance.get_monitor(Performance.OBJECT_COUNT)
	var node_count := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var res_count := Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)

	var world_nodes := 0
	var root := world_root if world_root and is_instance_valid(world_root) else null
	if root == null and get_tree() and get_tree().current_scene:
		root = get_tree().current_scene
	if root:
		var frame := Engine.get_process_frames()
		if frame - _cache_frame >= NODE_COUNT_INTERVAL_FRAMES or _cached_world_nodes <= 0:
			_cached_world_nodes = _count_nodes(root)
			_cache_frame = frame
		world_nodes = _cached_world_nodes

	var stream_stats := {}
	var streams := get_tree().get_nodes_in_group(WorldStreamController.GROUP)
	var airborne := false
	if not streams.is_empty() and streams[0] is WorldStreamController:
		var sc := streams[0] as WorldStreamController
		stream_stats = sc.get_stats()
		airborne = sc.is_airborne()

	var living := _living_counts()

	if world_nodes > AdventureNodeBudget.ACTIVE_NODE_CRITICAL:
		_warn.append("Active/world nodes CRITICAL (%d > %d)" % [world_nodes, AdventureNodeBudget.ACTIVE_NODE_CRITICAL])
	elif world_nodes > AdventureNodeBudget.ACTIVE_NODE_WARN:
		_warn.append("Active/world nodes high (%d > %d)" % [world_nodes, AdventureNodeBudget.ACTIVE_NODE_WARN])
	if fps > 0.0 and fps < 25.0:
		_warn.append("FPS low (%.0f)" % fps)
	if frame_ms > AdventureNodeBudget.STREAM_TICK_SEC * 1000.0 and frame_ms > 22.0:
		_warn.append("Frame time high (%.1f ms)" % frame_ms)
	if int(stream_stats.get(&"near", 0)) > 80:
		_warn.append("Many NEAR stream units (%s)" % stream_stats.get(&"near", 0))

	return {
		&"fps": fps,
		&"frame_ms": frame_ms,
		&"draw_calls": draw_calls,
		&"primitives": prims,
		&"mem_static": mem_static,
		&"object_count": obj_count,
		&"node_count": node_count,
		&"resource_count": res_count,
		&"world_nodes": world_nodes,
		&"authored_gate": AdventureNodeBudget.AUTHORED_NODE_GATE,
		&"stream": stream_stats,
		&"airborne": airborne,
		&"living": living,
		&"warnings": _warn.duplicate(),
	}


func format_hud_block(world_root: Node = null) -> String:
	var s := snapshot(world_root)
	var st: Dictionary = s.get(&"stream", {})
	var liv: Dictionary = s.get(&"living", {})
	var lines: PackedStringArray = [
		"PERF  FPS %.0f  frame %.1fms  draws %.0f" % [s[&"fps"], s[&"frame_ms"], s[&"draw_calls"]],
		"Nodes world %d / gate %d  eng %d  mem %.1fMB" % [
			s[&"world_nodes"],
			s[&"authored_gate"],
			s[&"node_count"],
			float(s[&"mem_static"]) / (1024.0 * 1024.0),
		],
		"Stream N:%s M:%s F:%s VF:%s  air=%s" % [
			st.get(&"near", 0), st.get(&"medium", 0), st.get(&"far", 0), st.get(&"very_far", 0),
			str(s[&"airborne"]),
		],
		"Living W:%s H:%s N:%s A:%s" % [
			liv.get(&"wildlife", 0), liv.get(&"hostiles", 0), liv.get(&"npcs", 0), liv.get(&"aquatic", 0),
		],
	]
	var warnings: PackedStringArray = s.get(&"warnings", PackedStringArray())
	for w in warnings:
		lines.append("! %s" % w)
	return "\n".join(lines)


func _living_counts() -> Dictionary:
	var out := {&"wildlife": 0, &"hostiles": 0, &"npcs": 0, &"aquatic": 0}
	if get_tree() == null:
		return out
	var living := get_tree().get_nodes_in_group(&"living_world")
	if living.is_empty():
		## Fallback: count by child roots
		for n in get_tree().get_nodes_in_group(GameConstants.GROUP_PLAYER):
			pass
	for n in get_tree().get_nodes_in_group(&"living_world"):
		if n.has_method("population_snapshot"):
			return n.call("population_snapshot")
	## Soft count via known groups
	out[&"hostiles"] = get_tree().get_nodes_in_group(HostileCreatureActor.GROUP).size()
	return out


func _count_nodes(n: Node) -> int:
	var total := 1
	for c in n.get_children():
		total += _count_nodes(c)
	return total
