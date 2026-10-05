extends Node

const RADIUS_SCALE: float = 1/5e8
var bodies: Array[CelestialBody] = []
var bodies_meshes: Dictionary[String, MeshInstance3D] = {}

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
			bodies_meshes.erase(body_id)
			return

func remove_all_bodies() -> void:
	bodies = []
	for mesh in bodies_meshes.values():
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
