extends Control

@onready var name_line_edit: LineEdit = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/NameRow/NameLineEdit
@onready var mass_line_edit: LineEdit = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/MassRow/MassLineEdit
@onready var radius_line_edit: LineEdit = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/RadiusRow/RadiusLineEdit
@onready var color_line_edit: LineEdit = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/ColorRow/ColorLineEdit
@onready var velocity_x_line_edit: LineEdit = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/VelocityXRow/VelocityXLineEdit
@onready var velocity_y_line_edit: LineEdit = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/VelocityYRow/VelocityYLineEdit
@onready var velocity_z_line_edit: LineEdit = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/VelocityZRow/VelocityZLineEdit
@onready var position_x_line_edit: LineEdit = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/PositionXRow/PositionXLineEdit
@onready var position_y_line_edit: LineEdit = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/PositionYRow/PositionYLineEdit
@onready var position_z_line_edit: LineEdit = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/PositionZRow/PositionZLineEdit
@onready var mass_unit_option_button: OptionButton = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/MassUnitRow/MassUnitOptionButton
@onready var length_unit_option_button: OptionButton = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/LengthUnitRow/LengthUnitOptionButton
@onready var velocity_unit_option_button: OptionButton = $BodyInspectorPanel/VBoxContainer/PropertiesList/PropertiesRows/VelocityUnitRow/VelocityUnitOptionButton

@onready var delete_button: Button = $BodyInspectorPanel/VBoxContainer/Actions/DeleteButton

var body_id: String
var mass_unit_selected: int
var length_unit_selected: int
var velocity_unit_selected: int

func _ready() -> void:
	GlobalSimulationUtils.setted_running.connect(disable_inputs)
	GlobalSimulationUtils.setted_simulation_time.connect(disable_inputs)
	
	disable_inputs(null)
	
	mass_unit_option_button.add_item("kg", Constants.MASS_UNITS.kg)
	mass_unit_option_button.add_item("Msun", Constants.MASS_UNITS.Msun)
	mass_unit_option_button.selected = int(GlobalSettings.load_from_disk("magnitude_units", "mass"))
	mass_unit_selected = mass_unit_option_button.selected

	length_unit_option_button.add_item("m", Constants.LENGTH_UNITS.m)
	length_unit_option_button.add_item("km", Constants.LENGTH_UNITS.km)
	length_unit_option_button.selected = int(GlobalSettings.load_from_disk("magnitude_units", "length"))
	length_unit_selected = length_unit_option_button.selected
	
	velocity_unit_option_button.add_item("km/s", Constants.VELOCITY_UNITS.km_s)
	velocity_unit_option_button.add_item("km/h", Constants.VELOCITY_UNITS.km_h)
	velocity_unit_option_button.add_item("m/s", Constants.VELOCITY_UNITS.m_s)
	velocity_unit_option_button.selected = int(GlobalSettings.load_from_disk("magnitude_units", "velocity"))
	velocity_unit_selected = velocity_unit_option_button.selected

func update_values() -> void:
	var body: CelestialBody = GlobalSimulationUtils.get_body_by_id(body_id)
	if body == null:
		_on_close_pressed()
		return
	
	name_line_edit.text = body.name
	mass_line_edit.text = GlobalSimulationUtils.num_to_cientific_notation(Constants.mass_converter(body.mass, Constants.MASS_UNITS.kg, mass_unit_selected))
	radius_line_edit.text = GlobalSimulationUtils.num_to_cientific_notation(Constants.length_converter(body.physical_radius, Constants.LENGTH_UNITS.m, length_unit_selected))
	color_line_edit.text = body.color.to_html()
		
	velocity_x_line_edit.text = GlobalSimulationUtils.num_to_cientific_notation(Constants.velocity_converter(body.velocity.x, Constants.VELOCITY_UNITS.m_s, velocity_unit_selected))
	velocity_y_line_edit.text = GlobalSimulationUtils.num_to_cientific_notation(Constants.velocity_converter(body.velocity.y, Constants.VELOCITY_UNITS.m_s, velocity_unit_selected))
	velocity_z_line_edit.text = GlobalSimulationUtils.num_to_cientific_notation(Constants.velocity_converter(body.velocity.z, Constants.VELOCITY_UNITS.m_s, velocity_unit_selected))
	position_x_line_edit.text = GlobalSimulationUtils.num_to_cientific_notation(Constants.length_converter(body.position.x, Constants.LENGTH_UNITS.m, length_unit_selected))
	position_y_line_edit.text = GlobalSimulationUtils.num_to_cientific_notation(Constants.length_converter(body.position.y, Constants.LENGTH_UNITS.m, length_unit_selected))
	position_z_line_edit.text = GlobalSimulationUtils.num_to_cientific_notation(Constants.length_converter(body.position.z, Constants.LENGTH_UNITS.m, length_unit_selected))

func disable_inputs(value: Variant) -> void:
	var editable := GlobalSimulationUtils.get_simulation_time() == 0.0 and !GlobalSimulationUtils.get_running()
	delete_button.disabled = !editable
	name_line_edit.editable = editable
	mass_line_edit.editable = editable
	radius_line_edit.editable = editable
	color_line_edit.editable = editable
	velocity_x_line_edit.editable = editable
	velocity_y_line_edit.editable = editable
	velocity_z_line_edit.editable = editable
	position_x_line_edit.editable = editable
	position_y_line_edit.editable = editable
	position_z_line_edit.editable = editable

func set_body_id(body_id: String) -> void:
	self.body_id = body_id
	update_values()

func _on_name_line_edit_text_submitted(new_text: String) -> void:
	GlobalProjectUtilities.modify_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id, new_text, "name")

func _on_mass_line_edit_text_submitted(new_text: String) -> void:
	var mass_in_kg := Constants.mass_converter(float(new_text), mass_unit_selected, Constants.MASS_UNITS.kg)
	GlobalProjectUtilities.modify_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id, mass_in_kg, "mass")

func _on_radius_line_edit_text_submitted(new_text: String) -> void:
	var radius_in_m := Constants.length_converter(float(new_text), length_unit_selected, Constants.LENGTH_UNITS.m)
	GlobalProjectUtilities.modify_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id, radius_in_m, "physical_radius")

func _on_color_line_edit_text_submitted(new_text: String) -> void:
	GlobalProjectUtilities.modify_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id, new_text, "color")

func _on_velocity_x_line_edit_submitted(new_text: String) -> void:
	var velocity: Array = [new_text, velocity_y_line_edit.text, velocity_z_line_edit.text]
	var velocity_in_m_s := velocity.map(func (n): return Constants.velocity_converter(float(n), velocity_unit_selected, Constants.VELOCITY_UNITS.m_s))
	GlobalProjectUtilities.modify_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id, velocity_in_m_s, "velocity")

func _on_velocity_y_line_edit_submitted(new_text: String) -> void:
	var velocity: Array = [velocity_x_line_edit.text, new_text, velocity_z_line_edit.text]
	var velocity_in_m_s := velocity.map(func (n): return Constants.velocity_converter(float(n), velocity_unit_selected, Constants.VELOCITY_UNITS.m_s))
	GlobalProjectUtilities.modify_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id, velocity_in_m_s, "velocity")

func _on_velocity_z_line_edit_submitted(new_text: String) -> void:
	var velocity: Array = [velocity_x_line_edit.text, velocity_y_line_edit.text, new_text]
	var velocity_in_m_s := velocity.map(func (n): return Constants.velocity_converter(float(n), velocity_unit_selected, Constants.VELOCITY_UNITS.m_s))
	GlobalProjectUtilities.modify_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id, velocity_in_m_s, "velocity")

func _on_position_x_line_edit_submitted(new_text: String) -> void:
	var position: Array = [new_text, position_y_line_edit.text, position_z_line_edit.text]
	var position_in_m := position.map(func (n): return Constants.length_converter(float(n), length_unit_selected, Constants.LENGTH_UNITS.m))
	GlobalProjectUtilities.modify_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id, position_in_m, "position")

func _on_position_y_line_edit_submitted(new_text: String) -> void:
	var position: Array = [position_x_line_edit.text, new_text, position_z_line_edit.text]
	var position_in_m := position.map(func (n): return Constants.length_converter(float(n), length_unit_selected, Constants.LENGTH_UNITS.m))
	GlobalProjectUtilities.modify_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id, position_in_m, "position")

func _on_position_z_line_edit_submitted(new_text: String) -> void:
	var position: Array = [position_x_line_edit.text, position_y_line_edit.text, new_text]
	var position_in_m := position.map(func (n): return Constants.length_converter(float(n), length_unit_selected, Constants.LENGTH_UNITS.m))
	GlobalProjectUtilities.modify_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id, position_in_m, "position")

func _on_mass_unit_selected(index: int) -> void:
	mass_unit_selected = index
	GlobalSettings.store_in_disk("magnitude_units", "mass", index)
	update_values()

func _on_length_unit_selected(index: int) -> void:
	length_unit_selected = index
	GlobalSettings.store_in_disk("magnitude_units", "length", index)
	update_values()

func _on_velocity_unit_selected(index: int) -> void:
	velocity_unit_selected = index
	GlobalSettings.store_in_disk("magnitude_units", "velocity", index)
	update_values()

func _on_delete_pressed() -> void:
	GlobalProjectUtilities.delete_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body_id)
	GlobalSimulationUtils.remove_body(body_id)
	_on_close_pressed()

func _on_close_pressed() -> void:
	if get_parent() is CanvasLayer:
		get_parent().queue_free()
	else:
		queue_free()
