class_name PhysicsWorld
extends RefCounted

## Constante gravitatoria
var G: float = Constants.Gravity
## Utilizado para no hacer división por 0 en ciertos casos
var softening_length: float
## Paso temporal de la simulación (en segundos)
var fixed_delta: float
## Tiempo de la simulación (en segundos)
var simulation_time: float = 0.0
## Guarda las coliciones
var collision_events: Array[Dictionary] = []
## Bandera para saber si se aplicaron las aceleraciones de los cuerpos
var _accelerations_ready := false

func _init(delta_seconds: float = 3600.0, softening: float = 1.0e6) -> void:
	if delta_seconds <= 0.0 or softening < 0.0:
		push_error("Delta and softening must be valid; using default values")
		delta_seconds = 3600.0
		softening = 1.0e6
	fixed_delta = delta_seconds
	softening_length = softening

## Calcula la aceleración de todos los cuerpos
func calculate_accelerations() -> Array[Vector3]:
	## Aceleración de cada cuerpo
	var accelerations: Array[Vector3] = []
	var bodies_size := GlobalSimulationUtils.get_bodies().size()
	accelerations.resize(bodies_size)
	
	for body_index in bodies_size:
		accelerations[body_index] = Vector3.ZERO
	
	for first_index in range(bodies_size):
		for second_index in range(first_index + 1, bodies_size):
			var first: CelestialBody = GlobalSimulationUtils.get_body_by_index(first_index)
			var second: CelestialBody = GlobalSimulationUtils.get_body_by_index(second_index)
			var offset := second.position - first.position
			var distance_squared := offset.length_squared() + softening_length * softening_length
			var scale := G / pow(distance_squared, 1.5)
			
			accelerations[first_index] += offset * (second.mass * scale)
			accelerations[second_index] -= offset * (first.mass * scale)
	return accelerations

## Hace los cálculos de aceleración, velocidad y paso para mover los cuerpos
func step(delta_seconds: float = fixed_delta) -> Array[Dictionary]:
	if delta_seconds <= 0.0:
		push_error("Physics delta must be positive")
		return []
	
	if not _accelerations_ready:
		var initial_accelerations := calculate_accelerations()
		_apply_accelerations(initial_accelerations)
		_accelerations_ready = true
	
	var bodies := GlobalSimulationUtils.get_bodies()
	for body in bodies:
		body.velocity += body.acceleration * (delta_seconds * 0.5)
		body.position += body.velocity * delta_seconds
	
	var new_accelerations := calculate_accelerations()
	for body_index in bodies.size():
		var body := GlobalSimulationUtils.get_body_by_index(body_index)
		body.velocity += new_accelerations[body_index] * (delta_seconds * 0.5)
		body.acceleration = new_accelerations[body_index]
	simulation_time += delta_seconds
	collision_events = _resolve_collisions()
	return collision_events

## Aplica la aceleración en todos los cuerpos
func _apply_accelerations(accelerations: Array[Vector3]) -> void:
	for body_index in GlobalSimulationUtils.get_bodies().size():
		GlobalSimulationUtils.get_body_by_index(body_index).acceleration = accelerations[body_index]

## Revisa si los cuerpos colicionan, y actúa si fue así
func _resolve_collisions() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var pairs: Array[Array] = []
	var bodies_size := GlobalSimulationUtils.get_bodies().size()
	
	for first_index in range(bodies_size):
		for second_index in range(first_index + 1, bodies_size):
			var first: CelestialBody = GlobalSimulationUtils.get_body_by_index(first_index)
			var second: CelestialBody = GlobalSimulationUtils.get_body_by_index(second_index)
			if first.position.distance_to(second.position) <= first.physical_radius + second.physical_radius:
				pairs.append([first, second])
	
	for pair in pairs:
		var first: CelestialBody = pair[0]
		var first_id := first.id
		var second: CelestialBody = pair[1]
		var second_id := second.id
		if not GlobalSimulationUtils.has_existing_body(first_id) or not GlobalSimulationUtils.has_existing_body(second_id):
			continue
		
		var merged := _merge_bodies(first, second)
		GlobalSimulationUtils.remove_body(first_id)
		GlobalSimulationUtils.remove_body(second_id)
		GlobalSimulationUtils.add_body(merged)
		
		events.append({"removed_ids": [first_id, second_id], "new_id": merged.id, "time": simulation_time})
	_accelerations_ready = false
	return events

## Crea un nuevo cuerpo a partir de la fusión de dos cuerpos
func _merge_bodies(first: CelestialBody, second: CelestialBody) -> CelestialBody:
	var total_mass := first.mass + second.mass
	var merged_position := (first.position * first.mass + second.position * second.mass) / total_mass
	var merged_velocity := (first.velocity * first.mass + second.velocity * second.mass) / total_mass
	var merged_radius := pow(pow(first.physical_radius, 3.0) + pow(second.physical_radius, 3.0), 1.0 / 3.0)
	
	var dominant_body: CelestialBody = first if first.mass / total_mass > second.mass / total_mass else second
	return CelestialBody.new(total_mass, merged_radius, dominant_body.name, merged_position, merged_velocity, dominant_body.color)
