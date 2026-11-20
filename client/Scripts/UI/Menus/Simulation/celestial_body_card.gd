class_name CelestialBodyCard
extends Button

signal body_selected(body_id: String)

@onready var body_name_label: Label = $CardContent/BodyName
@onready var preview_viewport: SubViewport = $CardContent/PlanetPreview/PreviewViewport
@onready var preview_sphere: MeshInstance3D = $CardContent/PlanetPreview/PreviewViewport/PreviewScene/PreviewSphere

var celestial_body: CelestialBody
var body_id: String = ""

func _ready() -> void:
	pressed.connect(_on_pressed)
	if celestial_body != null:
		_update_preview()

func configure(body: CelestialBody) -> void:
	celestial_body = body
	body_id = body.id
	if is_node_ready():
		_update_preview()

func refresh_preview() -> void:
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _update_preview() -> void:
	body_name_label.text = celestial_body.name
	var source_mesh := GlobalSimulationUtils.get_body_mesh(body_id)
	if is_instance_valid(source_mesh) and source_mesh.material_override != null:
		preview_sphere.material_override = source_mesh.material_override.duplicate()
	else:
		var material := StandardMaterial3D.new()
		material.albedo_color = celestial_body.color
		material.emission_enabled = celestial_body.mass >= 1.6e29
		material.emission = celestial_body.color
		material.emission_energy_multiplier = 1.5 if material.emission_enabled else 0.0
		preview_sphere.material_override = material
	refresh_preview()

func _on_pressed() -> void:
	if not body_id.is_empty():
		body_selected.emit(body_id)
