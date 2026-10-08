class_name CelestialBody
extends RefCounted

const STEFAN_BOLTZMANN := 5.670374419e-8   # constante usada para la luminocidad W·m⁻²·K⁻⁴
const SOLAR_MASS := 1.989e30               # kg
const STAR_MIN_MASS := 0.08 * SOLAR_MASS   # umbral de fusión de hidrógeno
const STAR_TEMPERATURE := 5772.0           # K (fija para todas las estrellas)

var id: String
var mass: float
var physical_radius: float
var position: Vector3
var velocity: Vector3
var acceleration: Vector3 = Vector3.ZERO
var name: String
var color: Color

## Se considera estrella si su masa alcanza el umbral de fusión.
func is_star() -> bool:
	return mass >= STAR_MIN_MASS

## Temperatura de emisión: fija según el tipo de cuerpo.
func temperature() -> float:
	return STAR_TEMPERATURE if is_star() else 0.0

## Luminosidad en watts (Stefan-Boltzmann). mass en kg y physical_radius en metros.
func luminosity() -> float:
	return 4.0 * PI * physical_radius * physical_radius * STEFAN_BOLTZMANN * pow(temperature(), 4.0)

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
