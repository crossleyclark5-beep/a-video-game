extends Node
func _ready():
	await get_tree().process_frame
	CreatureManager.select_partner(&"companion_agumon", "T")
	var w = load("res://scenes/world/game_world.tscn").instantiate()
	add_child(w)
	await get_tree().process_frame
	await get_tree().process_frame
	var hex = w.get_node("HexGridLayer")
	print("TOTAL=", _count(w))
	print("HEX_TOTAL=", _count(hex))
	var veg = hex.get_node_or_null("RegionVegetation")
	if veg:
		print("VEG_TOTAL=", _count(veg))
		for ch in veg.get_children():
			print("VEG_CHILD ", ch.name, "=", _count(ch))
	get_tree().quit(0)
func _count(n):
	var c=1
	for ch in n.get_children(): c+=_count(ch)
	return c
