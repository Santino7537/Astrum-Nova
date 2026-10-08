class_name PhysicsWorld
extends RefCounted

const PARALLEL_MINIMUM_BODY_COUNT := 64

## Constante gravitatoria
var G: float = Constants.Gravity
## Utilizado para no hacer división por 0 en ciertos casos
var softening_length: float
## Máximo de workers para aceleraciones; 0 desactiva el paralelismo
var max_worker_threads: int
## Guarda las coliciones
var collision_events: Array[Dictionary] = []
## Bandera para saber si se aplicaron las aceleraciones de los cuerpos
var _accelerations_ready := false

func _init(softening: float = 1.0e6, max_worker_threads: int = 4) -> void:
	if softening < 0.0:
		push_error("Softening must be valid; using default values")
		softening = 1.0e6
	softening_length = softening
	self.max_worker_threads = maxi(max_worker_threads, 0)

## Calcula la aceleración de todos los cuerpos
func calculate_accelerations() -> Array[Vector3]:
	var bodies := GlobalSimulationUtils.get_bodies()
	var bodies_size := bodies.size()
	var positions: Array[Vector3] = []
	var masses: Array[float] = []
	positions.resize(bodies_size)
	masses.resize(bodies_size)
	for body_index in bodies_size:
		positions[body_index] = bodies[body_index].position
		masses[body_index] = bodies[body_index].mass

	var worker_count := mini(max_worker_threads, mini(maxi(OS.get_processor_count(), 1), bodies_size))
	if bodies_size < PARALLEL_MINIMUM_BODY_COUNT or worker_count < 2:
		return _calculate_acceleration_range(0, bodies_size, positions, masses)

	var acceleration_chunks: Array = []
	acceleration_chunks.resize(worker_count)
	var results_mutex := Mutex.new()
	var task_id := WorkerThreadPool.add_group_task(
		_calculate_acceleration_chunk.bind(positions, masses, acceleration_chunks, results_mutex),
		worker_count,
		worker_count,
		false,
		"Calculating celestial body accelerations"
	)
	if task_id < 0:
		push_error("Failed to schedule parallel acceleration calculation; using the main thread")
		return _calculate_acceleration_range(0, bodies_size, positions, masses)
	WorkerThreadPool.wait_for_group_task_completion(task_id)

	var accelerations: Array[Vector3] = []
	accelerations.resize(bodies_size)
	var acceleration_index := 0
	for chunk_variant in acceleration_chunks:
		var chunk: Array = chunk_variant
		for acceleration in chunk:
			accelerations[acceleration_index] = acceleration
			acceleration_index += 1
	return accelerations

func _calculate_acceleration_chunk(worker_index: int, positions: Array[Vector3], masses: Array[float], acceleration_chunks: Array, results_mutex: Mutex) -> void:
	var start_index := int(positions.size() * worker_index / acceleration_chunks.size())
	var end_index := int(positions.size() * (worker_index + 1) / acceleration_chunks.size())
	var chunk := _calculate_acceleration_range(start_index, end_index, positions, masses)
	results_mutex.lock()
	acceleration_chunks[worker_index] = chunk
	results_mutex.unlock()

func _calculate_acceleration_range(start_index: int, end_index: int, positions: Array[Vector3], masses: Array[float]) -> Array[Vector3]:
	var accelerations: Array[Vector3] = []
	accelerations.resize(end_index - start_index)
	for body_index in range(start_index, end_index):
		var acceleration := Vector3.ZERO
		for source_index in positions.size():
			if source_index == body_index:
				continue
			var offset := positions[source_index] - positions[body_index]
			var distance_squared := offset.length_squared() + softening_length * softening_length
			var scale := G / pow(distance_squared, 1.5)
			acceleration += offset * (masses[source_index] * scale)
		accelerations[body_index - start_index] = acceleration
	return accelerations

## Hace los cálculos de aceleración, velocidad y paso para mover los cuerpos
func step(delta_seconds: float) -> Array[Dictionary]:
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
	GlobalSimulationUtils.set_simulation_time(GlobalSimulationUtils.get_simulation_time() + delta_seconds)
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
		
		events.append({"removed_ids": [first_id, second_id], "new_id": merged.id, "time": GlobalSimulationUtils.get_simulation_time()})
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
