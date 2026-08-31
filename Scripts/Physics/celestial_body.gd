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

func _init(mass: float, radius: float, name: String, initial_position: Vector3 = Vector3.ZERO, initial_velocity: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> void:
	if mass <= 0.0 or radius <= 0.0:
		push_error("Body mass and radius must be positive")
		return
	id = Constants.generate_id()
	self.mass = mass
	physical_radius = radius
	position = initial_position
	velocity = initial_velocity
	self.name = name if name else id
	self.color = color

func momentum() -> Vector3:
	return velocity * mass

func duplicate_body() -> CelestialBody:
	var copy := CelestialBody.new(mass, physical_radius, name, position, velocity, color)
	copy.acceleration = acceleration
	return copy
