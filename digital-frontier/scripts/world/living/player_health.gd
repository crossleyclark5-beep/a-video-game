class_name PlayerHealth
extends Node
## Adventure health, damage, healing, and Field Unit reboot respawn.

signal health_changed(current: float, maximum: float)
signal died
signal respawned

const MAX_HP := 100.0
const RESPAWN_DELAY := 1.35

var max_hp: float = MAX_HP
var hp: float = MAX_HP
var invuln: float = 0.0
var _dead: bool = false
var _respawn_timer: float = -1.0
var _player: Node3D = null


func _ready() -> void:
	_player = get_parent() as Node3D
	add_to_group(&"player_health")
	health_changed.emit(hp, max_hp)


func _process(delta: float) -> void:
	invuln = maxf(0.0, invuln - delta)
	if _respawn_timer >= 0.0:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_do_respawn()


func get_hp_ratio() -> float:
	return hp / maxf(max_hp, 1.0)


func is_alive() -> bool:
	return not _dead and hp > 0.0


func apply_damage(amount: float, source: Node = null) -> void:
	if _dead or invuln > 0.0 or amount <= 0.0:
		return
	## Modal sheets pause threats.
	if UIManager.has_open_modal():
		return
	hp = maxf(0.0, hp - amount)
	invuln = 0.85
	health_changed.emit(hp, max_hp)
	EventBus.player_damaged.emit(amount, source)
	EventBus.sfx_play_requested.emit(&"battle_hit", _player.global_position if _player else Vector3.ZERO)
	DeviceService.notify_event(&"ui")
	if hp <= 0.0:
		_begin_death()


func heal(amount: float) -> void:
	if _dead:
		return
	hp = minf(max_hp, hp + amount)
	health_changed.emit(hp, max_hp)


func full_heal() -> void:
	hp = max_hp
	_dead = false
	health_changed.emit(hp, max_hp)


func _begin_death() -> void:
	_dead = true
	died.emit()
	EventBus.player_died.emit()
	EventBus.ui_notification_requested.emit("Field Unit critical… rebooting!", 2.5)
	EventBus.sfx_play_requested.emit(&"battle_start", Vector3.ZERO)
	_respawn_timer = RESPAWN_DELAY
	if _player:
		_player.set_physics_process(false)


func _do_respawn() -> void:
	_respawn_timer = -1.0
	var spawn := Vector3(0.0, 0.15, 18.0)
	if WorldManager.has_player_checkpoint():
		spawn = WorldManager.get_player_checkpoint()
	## Prefer Pleasant Park if somehow underground.
	if spawn.y < -2.0:
		spawn = GrasslandLayout.PLEASANT_PARK + Vector3(0, 0.15, 18)
	if _player and is_instance_valid(_player):
		_player.global_position = spawn
		if _player is CharacterBody3D:
			(_player as CharacterBody3D).velocity = Vector3.ZERO
		_player.set_physics_process(true)
	full_heal()
	invuln = 2.0
	respawned.emit()
	EventBus.player_respawned.emit(spawn)
	EventBus.ui_notification_requested.emit("You wake near a safe checkpoint.", 2.8)
	EventBus.sfx_play_requested.emit(&"creature_heal", spawn)
