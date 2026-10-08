extends Node

signal setted_running(running: bool)
signal setted_simulation_time(simulation_time: float)
signal setted_playback_speed(playback_speed: int)

const RADIUS_SCALE: float = 1/5e8
var bodies: Array[CelestialBody] = []
var bodies_meshes: Dictionary[String, MeshInstance3D] = {}

## Indica si la simulación está ejecutandose
var running: bool
## Tiempo que avanza la simulación en un segundo (en segundos)
var playback_speed: int = 600
## Tiempo de la simulación (en segundos)
var simulation_time: float = 0.0
## Id del cuerpo que se debería de ver al iniciar la simulación
var auxiliar_selected_body: String = ""

func set_running(running: bool) -> void:
	self.running = running
	setted_running.emit(self.running)

func get_running() -> bool:
	return running

func set_playback_speed(value: int) -> void:
	playback_speed = min(max(value, 1), 10000000)
	setted_playback_speed.emit(playback_speed)

func get_playback_speed() -> int:
	return playback_speed

func set_simulation_time(value: float) -> void:
	simulation_time = value
	setted_simulation_time.emit(value)

func get_simulation_time() -> float:
	return simulation_time

func get_auxiliar_selected_body() -> String:
	return auxiliar_selected_body

func set_auxiliar_selected_body(body_id: String) -> void:
	auxiliar_selected_body = body_id

func add_body(body: CelestialBody) -> MeshInstance3D:
	if has_existing_body(body.id):
		push_error("Body IDs must be unique")
		return
	var body_mesh := _create_body_mesh(body)
	bodies.append(body)
	bodies_meshes[body.id] = body_mesh
	return body_mesh

## Crea una instancia visible del cuerpo
func _create_body_mesh(body: CelestialBody) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var display_radius := body.physical_radius * RADIUS_SCALE
	sphere.radius = display_radius
	sphere.height = display_radius * 2.0
	mesh_instance.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = body.color
	material.emission_enabled = body.mass >= 1.6e29
	material.emission = body.color
	material.emission_energy_multiplier = 1.5 if material.emission_enabled else 0.0
	mesh_instance.material_override = material
	return mesh_instance

func remove_body(body_id: String) -> void:
	for body in bodies:
		if body.id == body_id:
			bodies.erase(body)
			bodies_meshes[body_id].queue_free()
			bodies_meshes.erase(body_id)
			return

func remove_all_bodies() -> void:
	bodies = []
	for mesh in bodies_meshes.values():
		if is_instance_valid(mesh):
			mesh.queue_free()
	
	bodies_meshes = {}

func has_existing_body(body_id: String) -> bool:
	return bodies_meshes.has(body_id)

func get_bodies() -> Array[CelestialBody]:
	return bodies

func get_bodies_meshes() -> Dictionary[String, MeshInstance3D]:
	return bodies_meshes

func get_body_by_id(body_id: String) -> CelestialBody:
	for body in bodies:
		if body.id == body_id:
			return body
	return null

func get_body_by_index(index: int) -> CelestialBody:
	return bodies.get(index)

func get_body_mesh(body_id: String) -> MeshInstance3D:
	return bodies_meshes.get(body_id)

## Genera una id aleatoria de tipo String
func generate_id(length: int = 16) -> String:
	var chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var id := ""
	
	for i in range(length):
		id += chars[randi() % chars.length()]
	
	return id

## Convierte un número en uno equivalente expresado en notación científica
func num_to_cientific_notation(num: Variant) -> String:
	if ![TYPE_STRING, TYPE_INT, TYPE_FLOAT].has(typeof(num)):
		return ""
	
	num = float(num) if typeof(num) != TYPE_FLOAT else num
	if num == 0.0:
		return "0"
	
	var exponent := int(floor(log(abs(num)) / log(10.0)))
	var decimal_part: float = num / pow(10.0, exponent)
	
	# Redondear a 10 decimales
	decimal_part = snapped(decimal_part, 0.0000000001)
	
	# Si el redondeo produce 10.0, corregimos la parte decimal y exponente
	if abs(decimal_part) >= 10.0:
		decimal_part /= 10.0
		exponent += 1
	
	var str_decimal_part: String = str(decimal_part)
	
	# Eliminar ceros sobrantes
	if str_decimal_part.contains("."):
		str_decimal_part = str_decimal_part.rstrip("0").rstrip(".")
	
	return str_decimal_part + "e" + str(exponent)
