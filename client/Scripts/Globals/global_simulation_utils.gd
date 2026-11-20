extends Node

const STAR_AURA_SHADER := preload("res://Shaders/star_aura.gdshader")
const PLANET_SURFACE_SHADER := preload("res://Shaders/planet_surface.gdshader")
const STAR_SURFACE_SHADER := preload("res://Shaders/star_surface.gdshader")
const WORLD_UNITS_PER_AU := 400.0
const STAR_LIGHT_RANGE_AU := 5.0
const STAR_LIGHT_RANGE := STAR_LIGHT_RANGE_AU * WORLD_UNITS_PER_AU
const STAR_LIGHT_ENERGY := 1500.0
const SOLAR_LUMINOSITY := 3.828e26
const PLANET_SURFACE_STYLE_COUNT := 4

signal bodies_changed
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

func add_body(body: CelestialBody, notify_change: bool = true) -> MeshInstance3D:
	if has_existing_body(body.id):
		push_error("Body IDs must be unique")
		return
	var body_mesh := _create_body_mesh(body)
	bodies.append(body)
	bodies_meshes[body.id] = body_mesh
	if notify_change:
		bodies_changed.emit()
	return body_mesh

## Crea una instancia visible del cuerpo
func _create_body_mesh(body: CelestialBody) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var display_radius := body.physical_radius * RADIUS_SCALE
	sphere.radius = display_radius
	sphere.height = display_radius * 2.0
	mesh_instance.mesh = sphere
	var body_hash := body.id.hash()
	var surface_seed := float(posmod(body_hash, 65536)) / 65536.0
	if body.is_star():
		var material := ShaderMaterial.new()
		material.shader = STAR_SURFACE_SHADER
		material.set_shader_parameter("body_tint", body.color)
		material.set_shader_parameter("surface_seed", surface_seed)
		mesh_instance.material_override = material
		_add_star_effects(mesh_instance, body, display_radius)
	else:
		var material := ShaderMaterial.new()
		material.shader = PLANET_SURFACE_SHADER
		material.set_shader_parameter("body_tint", body.color)
		material.set_shader_parameter("surface_seed", surface_seed)
		material.set_shader_parameter("surface_style", posmod(body_hash, PLANET_SURFACE_STYLE_COUNT))
		mesh_instance.material_override = material
	return mesh_instance

func _add_star_effects(mesh_instance: MeshInstance3D, body: CelestialBody, display_radius: float) -> void:
	var luminosity_ratio := body.luminosity() / SOLAR_LUMINOSITY
	var star_light := OmniLight3D.new()
	star_light.light_color = Color.WHITE
	star_light.light_energy = clampf(STAR_LIGHT_ENERGY * sqrt(luminosity_ratio), 100.0, 15000.0)
	star_light.omni_range = STAR_LIGHT_RANGE
	star_light.omni_attenuation = 2.0
	star_light.shadow_enabled = true
	mesh_instance.add_child(star_light)

	var aura_mesh := QuadMesh.new()
	aura_mesh.size = Vector2.ONE * display_radius * 5.0
	var aura := MeshInstance3D.new()
	aura.mesh = aura_mesh
	aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var aura_material := ShaderMaterial.new()
	aura_material.shader = STAR_AURA_SHADER
	aura_material.set_shader_parameter("aura_color", body.color)
	aura.material_override = aura_material
	mesh_instance.add_child(aura)

func remove_body(body_id: String) -> void:
	for body in bodies:
		if body.id == body_id:
			bodies.erase(body)
			bodies_meshes[body_id].queue_free()
			bodies_meshes.erase(body_id)
			bodies_changed.emit()
			return

func remove_all_bodies() -> void:
	bodies = []
	for mesh in bodies_meshes.values():
		if is_instance_valid(mesh):
			mesh.queue_free()
	
	bodies_meshes = {}
	bodies_changed.emit()

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
