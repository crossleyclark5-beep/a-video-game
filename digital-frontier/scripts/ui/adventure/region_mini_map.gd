class_name RegionMiniMap
extends Control
## Handheld-friendly grassland mini / full map.
## Undiscovered majors = desaturated mystery icons; discovered = full color + name.
## Buttons only — no mouse required. Parent HUD handles open/close.

@export var show_labels: bool = false
@export var show_player: bool = true
@export var frame_map: bool = true

var _player: Node3D = null
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.location_discovered.connect(_on_discovered)
	queue_redraw()


func bind_player(player: Node3D) -> void:
	_player = player
	queue_redraw()


func _process(delta: float) -> void:
	_pulse = fposmod(_pulse + delta * 2.2, TAU)
	if show_player and _player != null and is_instance_valid(_player):
		queue_redraw()


func _on_discovered(_id: StringName = &"") -> void:
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x < 8.0 or rect.size.y < 8.0:
		return
	var bounds := RegionMapCatalog.region_bounds()
	## Paper / ink handheld chrome.
	if frame_map:
		draw_rect(rect, WorldPalette.UI_BORDER)
		rect = rect.grow(-3.0)
	draw_rect(rect, WorldPalette.UI_PAPER.darkened(0.08))
	## Terrain wash.
	draw_rect(rect.grow(-2.0), Color(0.42, 0.62, 0.36))
	_draw_explored_wash(rect, bounds)
	_draw_terrain(rect, bounds)
	_draw_roads(rect, bounds)
	_draw_markers(rect, bounds)
	_draw_player(rect, bounds)
	## Inner border.
	draw_rect(rect, WorldPalette.UI_BORDER, false, 2.0)


func _world_to_map(world: Vector3, map_rect: Rect2, bounds: Rect2) -> Vector2:
	var nx := (world.x - bounds.position.x) / maxf(bounds.size.x, 1.0)
	var nz := (world.z - bounds.position.y) / maxf(bounds.size.y, 1.0)
	## Keep north (-Z) toward the top of the control.
	return Vector2(
		map_rect.position.x + nx * map_rect.size.x,
		map_rect.position.y + (1.0 - nz) * map_rect.size.y,
	)


func _draw_explored_wash(map_rect: Rect2, bounds: Rect2) -> void:
	## Soft brighter patches where the player has explored cells.
	var cells: Array = WorldManager.get_explored_cells()
	if cells.is_empty():
		return
	var cell := WorldManager.EXPLORE_CELL_SIZE
	for key in cells:
		var parts := String(key).split(",")
		if parts.size() != 2:
			continue
		var cx := int(parts[0])
		var cz := int(parts[1])
		var world := Vector3(float(cx) * cell + cell * 0.5, 0.0, float(cz) * cell + cell * 0.5)
		var p := _world_to_map(world, map_rect, bounds)
		var sx := map_rect.size.x * (cell / bounds.size.x)
		var sy := map_rect.size.y * (cell / bounds.size.y)
		draw_rect(Rect2(p - Vector2(sx, sy) * 0.5, Vector2(sx, sy)), Color(0.48, 0.70, 0.40, 0.35))


func _draw_terrain(map_rect: Rect2, bounds: Rect2) -> void:
	for feat in RegionMapCatalog.terrain_features():
		var p: Vector3 = feat["pos"]
		var r: float = float(feat.get("radius", 20.0))
		var c := _world_to_map(p, map_rect, bounds)
		var pr := maxf(3.0, map_rect.size.x * (r / bounds.size.x))
		match int(feat["kind"]):
			RegionMapCatalog.IconKind.WATER:
				draw_circle(c, pr, Color(0.28, 0.52, 0.78, 0.85))
			RegionMapCatalog.IconKind.MOUNTAIN:
				_draw_mountain_icon(c, pr, Color(0.45, 0.42, 0.40), true)


func _draw_roads(map_rect: Rect2, bounds: Rect2) -> void:
	for poly in RegionMapCatalog.road_polylines():
		var pts: PackedVector2Array = PackedVector2Array()
		for w in poly:
			pts.append(_world_to_map(w, map_rect, bounds))
		if pts.size() >= 2:
			draw_polyline(pts, Color(0.22, 0.22, 0.26, 0.9), 2.0, true)
			draw_polyline(pts, Color(0.85, 0.78, 0.45, 0.55), 1.0, true)


func _draw_markers(map_rect: Rect2, bounds: Rect2) -> void:
	var all: Array[Dictionary] = []
	all.append_array(RegionMapCatalog.major_markers())
	all.append_array(RegionMapCatalog.landmark_markers())
	for m in all:
		if not RegionMapCatalog.should_draw_marker(m):
			continue
		var discovered := RegionMapCatalog.is_discovered(m)
		var p := _world_to_map(m["pos"], map_rect, bounds)
		var kind: int = int(m["kind"])
		var col := _icon_color(kind, discovered)
		_draw_icon(p, kind, col, discovered)
		if show_labels:
			var label := RegionMapCatalog.display_label(m)
			var font := ThemeDB.fallback_font
			var fs := 11 if discovered else 10
			var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var lc := WorldPalette.UI_INK if discovered else Color(0.35, 0.35, 0.38)
			draw_string(font, p + Vector2(-tw * 0.5, 14.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, lc)


func _icon_color(kind: int, discovered: bool) -> Color:
	var c := Color(0.75, 0.75, 0.72)
	match kind:
		RegionMapCatalog.IconKind.TOWN:
			c = Color(0.92, 0.55, 0.28)
		RegionMapCatalog.IconKind.FARM:
			c = Color(0.78, 0.68, 0.22)
		RegionMapCatalog.IconKind.CINEMA:
			c = Color(0.85, 0.35, 0.45)
		RegionMapCatalog.IconKind.SPRING:
			c = Color(0.35, 0.65, 0.88)
		RegionMapCatalog.IconKind.WATER:
			c = Color(0.30, 0.55, 0.80)
		RegionMapCatalog.IconKind.MOUNTAIN:
			c = Color(0.55, 0.50, 0.46)
		RegionMapCatalog.IconKind.VIEWPOINT:
			c = Color(0.55, 0.78, 0.40)
		RegionMapCatalog.IconKind.CAVE:
			c = Color(0.40, 0.35, 0.32)
		RegionMapCatalog.IconKind.SECRET:
			c = Color(0.95, 0.75, 0.25)
		_:
			c = Color(0.70, 0.55, 0.40)
	if not discovered:
		var g := (c.r + c.g + c.b) / 3.0
		c = Color(g * 0.7, g * 0.7, g * 0.72)
	return c


func _draw_icon(center: Vector2, kind: int, color: Color, discovered: bool) -> void:
	var s := 7.0 if discovered else 6.0
	match kind:
		RegionMapCatalog.IconKind.TOWN, RegionMapCatalog.IconKind.SPRING:
			draw_rect(Rect2(center - Vector2(s, s), Vector2(s * 2.0, s * 2.0)), color)
			if discovered:
				draw_rect(Rect2(center - Vector2(s * 0.4, s * 1.4), Vector2(s * 0.8, s * 0.7)), color.lightened(0.15))
		RegionMapCatalog.IconKind.FARM:
			draw_rect(Rect2(center - Vector2(s * 1.1, s * 0.7), Vector2(s * 2.2, s * 1.4)), color)
		RegionMapCatalog.IconKind.CINEMA:
			draw_circle(center, s, color)
			draw_rect(Rect2(center + Vector2(-s * 0.3, -s * 1.5), Vector2(s * 0.6, s)), color.darkened(0.2))
		RegionMapCatalog.IconKind.MOUNTAIN:
			_draw_mountain_icon(center, s * 1.4, color, discovered)
		RegionMapCatalog.IconKind.WATER:
			draw_circle(center, s * 0.9, color)
		RegionMapCatalog.IconKind.VIEWPOINT:
			draw_circle(center, s * 0.7, color)
			draw_arc(center, s * 1.2, 0.0, TAU, 12, color, 1.5)
		RegionMapCatalog.IconKind.CAVE:
			draw_circle(center, s, color.darkened(0.2))
			draw_circle(center + Vector2(0, 1), s * 0.45, Color(0.08, 0.08, 0.1))
		RegionMapCatalog.IconKind.SECRET:
			draw_circle(center, s, color)
		_:
			draw_rect(Rect2(center - Vector2(s * 0.7, s * 0.7), Vector2(s * 1.4, s * 1.4)), color)
	## Mystery outline.
	if not discovered:
		draw_arc(center, s + 2.0, 0.0, TAU, 14, Color(0.2, 0.2, 0.22, 0.8), 1.5)


func _draw_mountain_icon(center: Vector2, s: float, color: Color, _filled: bool) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, -s),
		center + Vector2(s, s * 0.7),
		center + Vector2(-s, s * 0.7),
	])
	draw_colored_polygon(pts, color)


func _draw_player(map_rect: Rect2, bounds: Rect2) -> void:
	if not show_player or _player == null or not is_instance_valid(_player):
		return
	var p := _world_to_map(_player.global_position, map_rect, bounds)
	p.x = clampf(p.x, map_rect.position.x + 4.0, map_rect.end.x - 4.0)
	p.y = clampf(p.y, map_rect.position.y + 4.0, map_rect.end.y - 4.0)
	var pulse_r := 6.0 + sin(_pulse) * 1.5
	draw_circle(p, pulse_r + 2.0, Color(1.0, 1.0, 1.0, 0.35))
	draw_circle(p, 5.0, WorldPalette.UI_ACCENT)
	draw_circle(p, 2.2, WorldPalette.UI_PAPER)
	## Facing chevron from player basis if available.
	var forward := Vector3(0, 0, -1)
	if _player.has_node("VisualRoot"):
		forward = -_player.get_node("VisualRoot").global_transform.basis.z
	var f2 := Vector2(forward.x, -forward.z).normalized()
	if f2.length_squared() > 0.01:
		var tip := p + f2 * 9.0
		draw_line(p, tip, WorldPalette.UI_INK, 2.0)
