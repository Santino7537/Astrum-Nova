extends Node3D

const MENU_BUTTON_SCENE := preload("res://Scenes/UI/Menus/Simulation/menu_button.tscn")
const SIMULATION_CONTROL_SCENE := preload("res://Scenes/UI/Menus/Simulation/simulation_control_menu.tscn")
const BODY_INSPECTOR_SCENE := preload("res://Scenes/UI/Menus/Simulation/body_inspector_menu.tscn")
const MAX_PHYSICS_WORKER_THREADS := 4

var world: PhysicsWorld
var orbital_camera: OrbitalCamera
var trails: Dictionary = {}
var trial_intances: Array[MeshInstance3D] = []
var body_inspector_menu: Control

func _ready() -> void:
	GlobalProjectUtilities.selected_simulation.connect(_on_simulation_selected)
	GlobalProjectUtilities.changed_body.connect(_on_simulation_selected)
	_setup_menus()
	_setup_scene()
	_on_simulation_selected(GlobalProjectUtilities.get_simulation_index())

## Cambia de simulación
func _on_simulation_selected(simulation_index: int) -> void:
	_set_default_values()
	_setup_bodies(simulation_index)
	
	var bodies := GlobalSimulationUtils.get_bodies()
	var first_body: String = "" if bodies.is_empty() else bodies[0].id
	var auxiliar_body_id: String = GlobalSimulationUtils.get_auxiliar_selected_body()
	
	orbital_camera.select_body(first_body if auxiliar_body_id.is_empty() else auxiliar_body_id)
	GlobalSimulationUtils.set_auxiliar_selected_body("")

func _setup_menus() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	
	if !root.has_node("MenuButton"):
		var menu_button := MENU_BUTTON_SCENE.instantiate()
		root.add_child(menu_button)
		menu_button.name = "MenuButton"
	
	if !root.has_node("SimulationControlMenu"):
		var simulation_control_menu := SIMULATION_CONTROL_SCENE.instantiate()
		root.add_child(simulation_control_menu)
		simulation_control_menu.name = "SimulationControlMenu"

func _setup_scene() -> void:
	orbital_camera = OrbitalCamera.new()
	add_child(orbital_camera)
	orbital_camera.selected_body.connect(_update_body_inspector)
	
	world = PhysicsWorld.new(1.0e3, MAX_PHYSICS_WORKER_THREADS)

func _update_body_inspector(body_id: String) -> void:
	var root := get_tree().current_scene
	if root == null or body_id.is_empty():
		return
	
	if !root.has_node("BodyInspectorMenu"):
		var body_inspector := BODY_INSPECTOR_SCENE.instantiate()
		root.add_child(body_inspector)
		body_inspector.name = "BodyInspectorMenu"
		body_inspector_menu = body_inspector.get_node("BodyInspectorMenu")
	
	body_inspector_menu.set_body_id(body_id)

func _set_default_values() -> void:
	GlobalSimulationUtils.set_running(false)
	GlobalSimulationUtils.set_playback_speed(600)
	GlobalSimulationUtils.set_simulation_time(0.0)
	GlobalSimulationUtils.remove_all_bodies()
	
	for trial_instance in trial_intances:
		trial_instance.queue_free()
	trial_intances = []
	trails = {}
	world.collision_events = []
	world._accelerations_ready = false

func _setup_bodies(simulation_index: int) -> void:
	var simulation = GlobalProjectUtilities.get_simulation(GlobalSettings.get_current_project_path(), simulation_index)
	var bodies = simulation["celestial_bodies"]
	var celestial_bodies = bodies.map(func (b:Dictionary) -> CelestialBody:
		return CelestialBody.dictionary_to_celestial_body(b))
	
	for body in celestial_bodies:
		_create_body_visual(body)
	
	if celestial_bodies.size() == 0 and is_instance_valid(body_inspector_menu):
		body_inspector_menu.set_body_id("")

func _create_body_visual(body: CelestialBody) -> void:
	var mesh_instance := GlobalSimulationUtils.add_body(body)
	add_child(mesh_instance)
	var trail := ImmediateMesh.new()
	var trail_instance := MeshInstance3D.new()
	trail_instance.mesh = trail
	var trail_material := StandardMaterial3D.new()
	trail_material.albedo_color = body.color
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_instance.material_override = trail_material
	add_child(trail_instance)
	trial_intances.append(trail_instance)
	trails[body.id] = {"mesh": trail, "points": PackedVector3Array()}

func _process(_frame_delta: float) -> void:
	if GlobalSimulationUtils.get_running():
		world.step(_frame_delta * GlobalSimulationUtils.get_playback_speed())
		if is_instance_valid(body_inspector_menu):
			body_inspector_menu.update_values()
	_update_visuals()

func _update_visuals() -> void:
	for body in GlobalSimulationUtils.get_bodies():
		var body_id := body.id
		var scene_position := body.position / (Constants.AU / 400)
		if GlobalSimulationUtils.has_existing_body(body_id):
			GlobalSimulationUtils.get_body_mesh(body_id).position = scene_position
		if trails.has(body_id):
			var trail_data: Dictionary = trails[body_id]
			var points: PackedVector3Array = trail_data.points
			
			points.append(scene_position)
			if points.size() > 160:
				points.remove_at(0)
			
			trail_data.points = points
			var mesh: ImmediateMesh = trail_data.mesh
			mesh.clear_surfaces()
			if points.size() > 1:
				mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
				for point in points:
					mesh.surface_add_vertex(point)
				mesh.surface_end()
