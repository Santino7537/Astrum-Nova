class_name OrbitalElements
extends RefCounted

## Constante gravitatoria
const G: float = Constants.Gravity
## Evita divisiones por cero en los cálculos gravitatorios
const EPSILON: float = 1.0e-12

## A partir de los datos de una órbita elíptica, calcula la anomalía excéntrica
static func solve_kepler(mean_anomaly: float, eccentricity: float, tolerance: float = 1.0e-12, max_iterations: int = 32) -> float:
	# Solo se aceptan órbitas elípticas
	if eccentricity < 0.0 or eccentricity >= 1.0:
		push_error("This v1 conversion supports elliptic orbits with 0 <= e < 1")
		return mean_anomaly
	
	# Tomamos un valor aproximado de la anomalía excéntrica
	var eccentric_anomaly := mean_anomaly if eccentricity < 0.8 else PI
	for _iteration in max_iterations:
		# Nos acercamos al valor real de la anomalía excéntrica con el método de Newton-Raphson
		var correction := (eccentric_anomaly - eccentricity * sin(eccentric_anomaly) - mean_anomaly) / (1.0 - eccentricity * cos(eccentric_anomaly))
		eccentric_anomaly -= correction
		
		# Si la corrección es muy chica, paramos de hacer el cálculo
		if abs(correction) <= tolerance:
			break
	return eccentric_anomaly

## A partir de los elementos orbitales se calcula la posición y velocidad
static func elements_to_state(elements: Dictionary, central_mass: float, body_mass: float = 0.0) -> Dictionary:
	var semi_major_axis: float = elements.get("semi_major_axis", 0.0)
	var eccentricity: float = elements.get("eccentricity", 0.0)
	var inclination: float = elements.get("inclination", 0.0)
	var argument_of_periapsis: float = elements.get("argument_of_periapsis", 0.0)
	var longitude_of_ascending_node: float = elements.get("longitude_of_ascending_node", 0.0)
	var mean_anomaly: float = elements.get("mean_anomaly", 0.0)
	if semi_major_axis <= 0.0 or eccentricity < 0.0 or eccentricity >= 1.0:
		push_error("Invalid elliptic orbital elements")
		return {}
	
	var mu := G * (central_mass + body_mass)
	var eccentric_anomaly := solve_kepler(mean_anomaly, eccentricity)
	var eccentricity_root := sqrt(1.0 - eccentricity * eccentricity)
	var perifocal_position := Vector3(semi_major_axis * (cos(eccentric_anomaly) - eccentricity), 0.0, semi_major_axis * eccentricity_root * sin(eccentric_anomaly))
	var eccentric_denominator := 1.0 - eccentricity * cos(eccentric_anomaly)
	var perifocal_velocity := Vector3(-sin(eccentric_anomaly), 0.0, eccentricity_root * cos(eccentric_anomaly)) * sqrt(mu * semi_major_axis) / (semi_major_axis * eccentric_denominator)
	var orientation := Basis(Vector3.UP, longitude_of_ascending_node) * Basis(Vector3.RIGHT, inclination) * Basis(Vector3.UP, argument_of_periapsis)
	
	return {"position": orientation * perifocal_position, "velocity": orientation * perifocal_velocity}

## A partir de la posición y velocidad calcula los elementos orbitales
static func state_to_elements(relative_position: Vector3, relative_velocity: Vector3, central_mass: float, body_mass: float = 0.0) -> Dictionary:
	var mu := G * (central_mass + body_mass)
	var radius := relative_position.length()
	var speed_squared := relative_velocity.length_squared()
	if radius <= EPSILON or mu <= 0.0:
		push_error("Position and central mass must be valid")
		return {}
	
	var angular_momentum := relative_position.cross(relative_velocity)
	var h := angular_momentum.length()
	var eccentricity_vector := relative_velocity.cross(angular_momentum) / mu - relative_position / radius
	var eccentricity := eccentricity_vector.length()
	var specific_energy := speed_squared * 0.5 - mu / radius
	var semi_major_axis := -mu / (2.0 * specific_energy) if abs(specific_energy) > EPSILON else INF
	var inclination := acos(clamp(angular_momentum.y / h, -1.0, 1.0)) if h > EPSILON else 0.0
	var node := Vector3(-angular_momentum.z, 0.0, angular_momentum.x)
	var node_length := node.length()
	var longitude := atan2(node.z, node.x) if node_length > EPSILON else 0.0
	var argument := acos(clamp(node.dot(eccentricity_vector) / (node_length * eccentricity), -1.0, 1.0)) if node_length > EPSILON and eccentricity > EPSILON else 0.0
	
	if eccentricity > EPSILON and eccentricity_vector.y < 0.0:
		argument = TAU - argument
	
	var true_anomaly := acos(clamp(eccentricity_vector.dot(relative_position) / (eccentricity * radius), -1.0, 1.0)) if eccentricity > EPSILON else 0.0
	if eccentricity > EPSILON and relative_position.dot(relative_velocity) < 0.0:
		true_anomaly = TAU - true_anomaly
	
	var eccentric_anomaly := 2.0 * atan2(sqrt(1.0 - eccentricity) * sin(true_anomaly * 0.5), sqrt(1.0 + eccentricity) * cos(true_anomaly * 0.5)) if eccentricity < 1.0 else 0.0
	return {"semi_major_axis": semi_major_axis, "eccentricity": eccentricity, "inclination": inclination, "argument_of_periapsis": argument, "longitude_of_ascending_node": longitude, "mean_anomaly": eccentric_anomaly - eccentricity * sin(eccentric_anomaly)}
