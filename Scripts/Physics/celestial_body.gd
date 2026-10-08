class_name CelestialBody
extends RefCounted

var id: String
var mass: float
var physical_radius: float
var position: Vector3
var velocity: Vector3
var acceleration: Vector3 = Vector3.ZERO
var name: String
var color: Color

func _init(mass: float, radius: float, name: String, initial_position: Vector3 = Vector3.ZERO, initial_velocity: Vector3 = Vector3.ZERO, color: Color = Color.WHITE, id: String = GlobalSimulationUtils.generate_id()) -> void:
	if mass <= 0.0 or radius <= 0.0:
		push_error("Body mass and radius must be positive")
		return
	self.id = id
	self.mass = mass
	physical_radius = radius
	position = initial_position
	velocity = initial_velocity
	self.name = name if name else id
	self.color = color

static func dictionary_to_celestial_body(data: Dictionary) -> CelestialBody:
	var position := Vector3(
		data["position"][0],
		data["position"][1],
		data["position"][2]
	)

	var velocity := Vector3(
		data["velocity"][0],
		data["velocity"][1],
		data["velocity"][2]
	)

	var color := Color(data["color"])

	return CelestialBody.new(
		data["mass"],
		data["physical_radius"],
		data["name"],
		position,
		velocity,
		color,
		data["id"]
	)
