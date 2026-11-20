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
	if not is_finite(delta_seconds) or delta_seconds <= 0.0:
		push_error("Physics delta must be finite and positive.")
		return []
	
	if not _accelerations_ready:
		var initial_accelerations := calculate_accelerations()
		if not _vectors_are_finite(initial_accelerations):
			push_error("Physics produced non-finite initial accelerations.")
			return []
		_apply_accelerations(initial_accelerations)
		_accelerations_ready = true
	
	var bodies := GlobalSimulationUtils.get_bodies()
	var half_step_velocities: Array[Vector3] = []
	var next_positions: Array[Vector3] = []
	for body in bodies:
		if not body.position.is_finite() or not body.velocity.is_finite() or not body.acceleration.is_finite():
			_accelerations_ready = false
			push_error("Physics cannot step a body with non-finite state.")
			return []
		var half_step_velocity := body.velocity + body.acceleration * (delta_seconds * 0.5)
		var next_position := body.position + half_step_velocity * delta_seconds
		if not half_step_velocity.is_finite() or not next_position.is_finite():
			_accelerations_ready = false
			push_error("Physics step would produce a non-finite body state.")
			return []
		half_step_velocities.append(half_step_velocity)
		next_positions.append(next_position)

	for body_index in bodies.size():
		bodies[body_index].velocity = half_step_velocities[body_index]
		bodies[body_index].position = next_positions[body_index]
	
	var new_accelerations := calculate_accelerations()
	if not _vectors_are_finite(new_accelerations):
		_accelerations_ready = false
		push_error("Physics produced non-finite accelerations after movement.")
		return []

	var next_velocities: Array[Vector3] = []
	for body_index in bodies.size():
		var next_velocity := bodies[body_index].velocity + new_accelerations[body_index] * (delta_seconds * 0.5)
		if not next_velocity.is_finite():
			_accelerations_ready = false
			push_error("Physics step would produce a non-finite velocity.")
			return []
		next_velocities.append(next_velocity)

	for body_index in bodies.size():
		bodies[body_index].velocity = next_velocities[body_index]
		bodies[body_index].acceleration = new_accelerations[body_index]
	GlobalSimulationUtils.set_simulation_time(GlobalSimulationUtils.get_simulation_time() + delta_seconds)
	collision_events = _resolve_collisions()
	return collision_events

func _vectors_are_finite(vectors: Array[Vector3]) -> bool:
	for vector in vectors:
		if not vector.is_finite():
			return false
	return true

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
		
		var survivor: CelestialBody
		var consumed: CelestialBody
		if first.mass >= second.mass:
			survivor = first
			consumed = second
		else:
			survivor = second
			consumed = first

		if not _merge_bodies(survivor, consumed):
			continue
		GlobalSimulationUtils.update_body_visual(survivor.id)
		GlobalSimulationUtils.remove_body(consumed.id)
		
		events.append({
			"survivor_id": survivor.id,
			"removed_id": consumed.id,
			"time": GlobalSimulationUtils.get_simulation_time()
		})
	_accelerations_ready = false
	return events

## Conserva el cuerpo dominante y transfiere el momento del cuerpo consumido.
func _merge_bodies(survivor: CelestialBody, consumed: CelestialBody) -> bool:
	var survivor_mass := survivor.mass
	var consumed_mass := consumed.mass
	var total_mass := survivor_mass + consumed_mass
	if not is_finite(survivor_mass) or not is_finite(consumed_mass) or survivor_mass <= 0.0 or consumed_mass <= 0.0 or not is_finite(total_mass) or total_mass <= 0.0:
		push_error("Cannot merge bodies with invalid masses.")
		return false
	if not survivor.position.is_finite() or not consumed.position.is_finite() or not survivor.velocity.is_finite() or not consumed.velocity.is_finite():
		push_error("Cannot merge bodies with invalid positions or velocities.")
		return false
	if not is_finite(survivor.physical_radius) or not is_finite(consumed.physical_radius) or survivor.physical_radius <= 0.0 or consumed.physical_radius <= 0.0:
		push_error("Cannot merge bodies with invalid radii.")
		return false

	var survivor_weight := survivor_mass / total_mass
	var consumed_weight := consumed_mass / total_mass
	var merged_position := survivor.position * survivor_weight + consumed.position * consumed_weight
	var merged_velocity := survivor.velocity * survivor_weight + consumed.velocity * consumed_weight
	var largest_radius := maxf(survivor.physical_radius, consumed.physical_radius)
	var survivor_radius_ratio := survivor.physical_radius / largest_radius
	var consumed_radius_ratio := consumed.physical_radius / largest_radius
	var merged_radius := largest_radius * pow(pow(survivor_radius_ratio, 3.0) + pow(consumed_radius_ratio, 3.0), 1.0 / 3.0)
	if not merged_position.is_finite() or not merged_velocity.is_finite() or not is_finite(merged_radius):
		push_error("Collision produced a non-finite merged body.")
		return false

	survivor.position = merged_position
	survivor.velocity = merged_velocity
	survivor.physical_radius = merged_radius
	survivor.mass = total_mass
	survivor.acceleration = Vector3.ZERO
	return true
