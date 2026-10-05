class_name OrbitalCamera
extends Node3D

const MIN_DISTANCE: float = 0.01
const MAX_DISTANCE: float = 2000.0

@export var current_min_distance: float = MIN_DISTANCE
@export var current_max_distance: float = MAX_DISTANCE
@export var zoom_factor: float = 0.85

## Que tan sensible es la cámara para moverse arrastrando el mouse
@export var orbit_sensitivity: float = 0.01
## Que tan cerca tiene que ser el click de un cuerpo para ser seleccionado
@export var selection_tolerance: float = 0.08

var camera: Camera3D
var target_mesh: Node3D
var target_id: String = ""

## A que distancia está la cámara del cuerpo seleccionado
var distance: float = current_min_distance
## Ángulo (en radianes) horizontal de la cámara respecto al cuerpo
var azimuth: float = 0.0
## Ángulo (en radianes) vertical de la cámara respecto al cuerpo
var elevation: float = 0.0
## Indica si el usuario está haciendo click mientras mueve la cámara
var dragging: bool = false

func _ready() -> void:
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)

## Ajusta la distancia mínima actuál de la cámara respecto al cuerpo observado.
func _set_current_min_distance(body_radius: float) -> void:
	if body_radius > MIN_DISTANCE:
		current_min_distance = body_radius * 3
		distance = current_min_distance

## Pone a la cámara mirando al objeto seleccionado
func select_body(body_id: String) -> void:
	if !GlobalSimulationUtils.has_existing_body(body_id):
		return
	target_id = body_id
	target_mesh = GlobalSimulationUtils.get_body_mesh(body_id)
	
	var body_radius := GlobalSimulationUtils.get_body_by_id(body_id).physical_radius
	_set_current_min_distance(body_radius * GlobalSimulationUtils.RADIUS_SCALE)
	_update_transform()

## Mueve la cámara a donde la mueve el usuario
func _update_transform() -> void:
	var target_position := target_mesh.global_position
	var horizontal_distance := distance * cos(elevation)
	
	camera.global_position = target_position + Vector3(
		horizontal_distance * sin(azimuth),
		distance * sin(elevation),
		horizontal_distance * cos(azimuth)
	)
	camera.look_at(target_position, Vector3.UP)

## Acerca o aleja la cámara
func _zoom(multiplier: float) -> void:
	distance = clamp(distance * multiplier, current_min_distance, current_max_distance)
	_update_transform()

## Revisa los inputs que otros nodos no manejaron
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if dragging:
				_select_from_screen(event.position)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(zoom_factor)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / zoom_factor)
	
	elif event is InputEventMouseMotion and dragging:
		azimuth -= event.relative.x * orbit_sensitivity
		elevation = clamp(elevation + event.relative.y * orbit_sensitivity, -1.45, 1.45)
		_update_transform()

## Revisa si algún cuerpo fue seleccionado por el usuario
func _select_from_screen(screen_position: Vector2) -> void:
	if GlobalSimulationUtils.get_bodies().is_empty():
		return
	
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	var closest_id: String = ""
	var closest_distance := INF
	
	for body_id in GlobalSimulationUtils.get_bodies_meshes():
		var visual: MeshInstance3D = GlobalSimulationUtils.get_body_mesh(body_id)
		if not is_instance_valid(visual):
			continue
		
		var to_body := visual.global_position - ray_origin
		var along_ray := to_body.dot(ray_direction)
		if along_ray <= 0.0:
			continue
		
		var ray_distance := (to_body - ray_direction * along_ray).length()
		var tolerance: float = maxf(selection_tolerance, along_ray * 0.025)
		if ray_distance <= tolerance and along_ray < closest_distance:
			closest_distance = along_ray
			closest_id = body_id
	if !closest_id.is_empty():
		select_body(closest_id)

func _process(_delta: float) -> void:
	if is_instance_valid(target_mesh):
		_update_transform()
