extends Control

const CELESTIAL_BODY_CARD_SCENE := preload("res://Scenes/UI/Menus/Simulation/celestial_body_card.tscn")
const PANEL_SLIDE_DURATION := 0.28
const PANEL_DRAG_THRESHOLD := 5.0
const PANEL_TOGGLE_TOP_OFFSET := 0.0

signal body_card_selected(body_id: String)

@onready var body_inspector_panel: PanelContainer = $BodyInspectorPanel
@onready var toggle_button: Button = $InspectorToggleButton
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

@onready var properties_list: ScrollContainer = $BodyInspectorPanel/VBoxContainer/PropertiesList
@onready var all_bodies_scroll: ScrollContainer = $BodyInspectorPanel/VBoxContainer/AllBodiesScroll
@onready var all_bodies_container: VBoxContainer = $BodyInspectorPanel/VBoxContainer/AllBodiesScroll/AllBodiesList
@onready var selected_body_tab: Button = $BodyInspectorPanel/VBoxContainer/Tabs/SelectedBodyTab
@onready var all_bodies_tab: Button = $BodyInspectorPanel/VBoxContainer/Tabs/AllBodiesTab
@onready var delete_button: Button = $BodyInspectorPanel/VBoxContainer/Actions/DeleteButton

var body_id: String
var mass_unit_selected: int
var length_unit_selected: int
var velocity_unit_selected: int
var _panel_open: bool = true
var _panel_open_position: Vector2
var _panel_tween: Tween
var _toggle_dragging: bool = false
var _toggle_was_dragged: bool = false
var _toggle_drag_start: Vector2
var _panel_drag_start: Vector2
var _last_viewport_width: float

func _ready() -> void:
	GlobalSimulationUtils.setted_running.connect(disable_inputs)
	GlobalSimulationUtils.setted_simulation_time.connect(disable_inputs)
	GlobalSimulationUtils.bodies_changed.connect(_refresh_body_cards)
	GlobalProjectUtilities.selected_simulation.connect(_on_simulation_data_changed)
	GlobalProjectUtilities.changed_body.connect(_on_simulation_data_changed)
	toggle_button.button_mask = 0
	toggle_button.pressed.connect(_on_toggle_button_pressed)
	toggle_button.gui_input.connect(_on_toggle_button_gui_input)
	_last_viewport_width = get_viewport_rect().size.x
	_panel_open_position = body_inspector_panel.position
	body_inspector_panel.position.x = get_viewport_rect().size.x
	_sync_toggle_button_position()
	_animate_panel(true)
	
	disable_inputs(null)
	_refresh_body_cards()
	_set_active_tab(false)
	
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

func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED or not is_node_ready():
		return

	var viewport_width := get_viewport_rect().size.x
	var width_delta := viewport_width - _last_viewport_width
	if is_zero_approx(width_delta):
		return
	_last_viewport_width = viewport_width

	var tween_was_running := _panel_tween != null and _panel_tween.is_running()
	if tween_was_running:
		_panel_tween.kill()
	if _panel_open:
		_panel_open_position.x += width_delta
		if tween_was_running and not _toggle_dragging:
			_animate_panel(true)
		else:
			_sync_toggle_button_position()
	else:
		body_inspector_panel.position.x = viewport_width
		_sync_toggle_button_position()

func _on_simulation_data_changed(_simulation_index: int) -> void:
	_refresh_body_cards()

func _on_selected_body_tab_pressed() -> void:
	_set_active_tab(false)

func _on_all_bodies_tab_pressed() -> void:
	_set_active_tab(true)

func _set_active_tab(show_all_bodies: bool) -> void:
	selected_body_tab.set_pressed_no_signal(not show_all_bodies)
	all_bodies_tab.set_pressed_no_signal(show_all_bodies)
	properties_list.visible = not show_all_bodies
	all_bodies_scroll.visible = show_all_bodies
	delete_button.visible = not show_all_bodies

	if show_all_bodies:
		for card in all_bodies_container.get_children():
			if card is CelestialBodyCard:
				card.refresh_preview()

func _refresh_body_cards() -> void:
	for card in all_bodies_container.get_children():
		all_bodies_container.remove_child(card)
		card.queue_free()

	var bodies := GlobalSimulationUtils.get_bodies()
	if bodies.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No bodies available"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		all_bodies_container.add_child(empty_label)
		return

	for body in bodies:
		var card: CelestialBodyCard = CELESTIAL_BODY_CARD_SCENE.instantiate()
		all_bodies_container.add_child(card)
		card.configure(body)
		card.body_selected.connect(_on_body_card_selected)

func _on_body_card_selected(selected_body_id: String) -> void:
	body_card_selected.emit(selected_body_id)

func toggle_menu() -> void:
	if _panel_open:
		_remember_panel_position()
		_animate_panel(false)
	else:
		_animate_panel(true)

func close_menu() -> void:
	if _panel_open:
		_remember_panel_position()
		_animate_panel(false)

func _remember_panel_position() -> void:
	if _panel_tween == null or not _panel_tween.is_running():
		_panel_open_position = body_inspector_panel.position

func _on_toggle_button_pressed() -> void:
	toggle_menu()

func _animate_panel(open: bool) -> void:
	if _panel_tween != null and _panel_tween.is_running():
		_panel_tween.kill()

	_panel_open = open
	toggle_button.text = "Hide" if open else "Show"
	var target_position := _panel_open_position if open else Vector2(get_viewport_rect().size.x, body_inspector_panel.position.y)
	var target_button_position := Vector2(target_position.x - toggle_button.size.x, PANEL_TOGGLE_TOP_OFFSET)
	_panel_tween = create_tween().set_parallel(true)
	_panel_tween.set_trans(Tween.TRANS_CUBIC)
	_panel_tween.set_ease(Tween.EASE_OUT if open else Tween.EASE_IN)
	_panel_tween.tween_property(body_inspector_panel, "position", target_position, PANEL_SLIDE_DURATION)
	_panel_tween.tween_property(toggle_button, "position", target_button_position, PANEL_SLIDE_DURATION)

func _sync_toggle_button_position() -> void:
	toggle_button.position = Vector2(body_inspector_panel.position.x - toggle_button.size.x, PANEL_TOGGLE_TOP_OFFSET)

func _on_toggle_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_dragging = true
		_toggle_was_dragged = false
		_toggle_drag_start = event.global_position
		_panel_drag_start = body_inspector_panel.position
		if _panel_tween != null and _panel_tween.is_running():
			_panel_tween.kill()
		toggle_button.accept_event()

func _input(event: InputEvent) -> void:
	if not _toggle_dragging:
		return

	if event is InputEventMouseMotion:
		var drag_offset = event.global_position - _toggle_drag_start
		if not _toggle_was_dragged and drag_offset.length() < PANEL_DRAG_THRESHOLD:
			return
		_toggle_was_dragged = true
		var viewport_width := get_viewport_rect().size.x
		body_inspector_panel.position.x = clampf(_panel_drag_start.x + drag_offset.x, 0.0, viewport_width)
		_sync_toggle_button_position()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_toggle_dragging = false
		if _toggle_was_dragged:
			_finish_panel_drag()
		else:
			toggle_menu()
		get_viewport().set_input_as_handled()

func _finish_panel_drag() -> void:
	var viewport_width := get_viewport_rect().size.x
	var panel_width := body_inspector_panel.size.x
	var open_threshold := viewport_width - panel_width * 0.5
	var min_open_x := minf(toggle_button.size.x, viewport_width)
	var max_open_x := maxf(min_open_x, viewport_width - panel_width)
	_panel_open_position = Vector2(clampf(body_inspector_panel.position.x, min_open_x, max_open_x), body_inspector_panel.position.y)
	_animate_panel(body_inspector_panel.position.x < open_threshold)

func update_values() -> void:
	var body: CelestialBody = GlobalSimulationUtils.get_body_by_id(body_id)
	if body == null:
		body_id = ""
		var input_fields: Array[LineEdit] = [
			name_line_edit,
			mass_line_edit,
			radius_line_edit,
			color_line_edit,
			velocity_x_line_edit,
			velocity_y_line_edit,
			velocity_z_line_edit,
			position_x_line_edit,
			position_y_line_edit,
			position_z_line_edit,
		]
		for input_field in input_fields:
			input_field.clear()
		disable_inputs(null)
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
	var has_body := not body_id.is_empty() and GlobalSimulationUtils.get_body_by_id(body_id) != null
	var editable := has_body and GlobalSimulationUtils.get_simulation_time() == 0.0 and !GlobalSimulationUtils.get_running()
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
	disable_inputs(null)

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
	close_menu()
