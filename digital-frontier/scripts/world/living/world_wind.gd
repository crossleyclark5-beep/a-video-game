class_name WorldWind
extends RefCounted
## Global wind strength from weather — drives ambience + vegetation sway.


static func strength() -> float:
	match WorldAtmosphere.current_weather_id():
		&"storm":
			return 1.0
		&"rain":
			return 0.65
		&"fog":
			return 0.2
		_:
			return 0.35


static func gust_phase(t: float) -> float:
	## Soft oscillating gust for leaf/particle drift.
	return sin(t * 0.7) * 0.55 + sin(t * 1.3) * 0.35


static func apply_sway(node: Node3D, t: float, base_yaw: float = 0.0) -> void:
	if node == null:
		return
	var w := strength()
	var g := gust_phase(t)
	node.rotation.z = sin(t * 1.1 + base_yaw) * 0.04 * w
	node.rotation.x = cos(t * 0.9 + base_yaw) * 0.025 * w * (0.6 + g * 0.4)
