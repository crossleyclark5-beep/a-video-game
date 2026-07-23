class_name WorldObjectPool
extends RefCounted
## Lightweight node pool — spawn/despawn without allocate thrash.


var _scene: PackedScene = null
var _script: Script = null
var _factory: Callable = Callable()
var _free: Array[Node] = []
var _live: Array[Node] = []
var _parent: Node = null
var max_free: int = 32


func setup_scene(parent: Node, scene: PackedScene, free_cap: int = 32) -> void:
	_parent = parent
	_scene = scene
	max_free = free_cap


func setup_factory(parent: Node, factory: Callable, free_cap: int = 32) -> void:
	_parent = parent
	_factory = factory
	max_free = free_cap


func acquire() -> Node:
	var node: Node = null
	if not _free.is_empty():
		node = _free.pop_back()
	elif _scene:
		node = _scene.instantiate()
	elif _factory.is_valid():
		node = _factory.call()
	if node == null:
		return null
	_live.append(node)
	if _parent and node.get_parent() != _parent:
		if node.get_parent():
			node.get_parent().remove_child(node)
		_parent.add_child(node)
	if node is Node3D:
		(node as Node3D).visible = true
	node.process_mode = Node.PROCESS_MODE_INHERIT
	return node


func release(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	_live.erase(node)
	if node is Node3D:
		(node as Node3D).visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if _free.size() >= max_free:
		node.queue_free()
		return
	_free.append(node)


func release_all() -> void:
	for n in _live.duplicate():
		release(n)


func live_count() -> int:
	return _live.size()


func free_count() -> int:
	return _free.size()
