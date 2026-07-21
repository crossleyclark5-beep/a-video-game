class_name VehicleSpawner
extends RefCounted
## Factory for world vehicles — keeps builders free of controller boilerplate.


static func spawn_car(
	parent: Node3D,
	vehicle_id: StringName,
	pos: Vector3,
	yaw_deg: float = 0.0,
	instance_name: String = "",
	body_color_override: Color = Color(0, 0, 0, 0),
) -> CarVehicle:
	var data: VehicleData = ResourceRegistry.get_vehicle(vehicle_id)
	var car := CarVehicle.new()
	car.name = instance_name if instance_name != "" else String(vehicle_id)
	car.vehicle_id = vehicle_id
	if data:
		var d := data.duplicate(true) as VehicleData
		if body_color_override.a > 0.01:
			d.body_color = body_color_override
		car.data = d
	car.position = pos
	car.rotation_degrees.y = yaw_deg
	parent.add_child(car)
	if data and data.starter_unlock:
		VehicleManager.unlock(vehicle_id, false)
	return car


static func spawn_park_fleet(parent: Node3D, specs: Array) -> Array[CarVehicle]:
	## specs: { pos, yaw, vehicle_id?, color? }
	var out: Array[CarVehicle] = []
	var ids: Array[StringName] = [&"park_cruiser", &"adventure_suv", &"utility_truck"]
	for i in specs.size():
		var spec: Dictionary = specs[i]
		var vid: StringName = spec.get("vehicle_id", ids[i % ids.size()])
		var color := Color(0, 0, 0, 0)
		if spec.has("color"):
			color = spec["color"]
		out.append(
			spawn_car(parent, vid, spec["pos"], float(spec.get("yaw", 0.0)), "Car_%d" % i, color)
		)
	return out
