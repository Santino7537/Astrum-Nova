extends Control

@onready var pause_button: Button = $SimulationControlPanel/VBoxContainer/TimeRow/PauseButton
@onready var date_time_line: LineEdit = $SimulationControlPanel/VBoxContainer/TimeRow/DateTimeLine
@onready var simulation_speed_line: LineEdit = $SimulationControlPanel/VBoxContainer/TimeRow/SimulationSpeedLine
@onready var create_body_button: Button = $SimulationControlPanel/VBoxContainer/BodyRow/CreateButton

var icon_play = preload("res://Scripts/UI/Assets/play.svg")
var icon_pause = preload("res://Scripts/UI/Assets/pause.svg")

var simulation_date_time_unix: int

func _ready() -> void:
	GlobalSimulationUtils.setted_running.connect(_change_pause_icon)
	GlobalSimulationUtils.setted_playback_speed.connect(_change_simulation_speed)
	GlobalSimulationUtils.setted_running.connect(_disable_inputs)
	GlobalSimulationUtils.setted_simulation_time.connect(_disable_inputs)
	GlobalSimulationUtils.setted_simulation_time.connect(_update_simulation_date_time)
	
	var simulation = GlobalProjectUtilities.get_simulation(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index())
	var simulation_date_time_string = simulation["start_date"]
	var simulacion_date_time_dict: Dictionary = Time.get_datetime_dict_from_datetime_string(simulation_date_time_string, true)
	simulation_date_time_unix = Time.get_unix_time_from_datetime_dict(simulacion_date_time_dict)

func _change_pause_icon(running: bool) -> void:
	pause_button.icon = icon_pause if running else icon_play

func _change_simulation_speed(playback_speed: int) -> void:
	simulation_speed_line.text = str(playback_speed) + "s/s"

func _disable_inputs(_value: Variant) -> void:
	var disable_state := GlobalSimulationUtils.get_simulation_time() != 0.0 or GlobalSimulationUtils.get_running()
	create_body_button.disabled = disable_state
	date_time_line.editable = !disable_state

func _update_simulation_date_time(simulation_time: float) -> void:
	var unix_time = simulation_date_time_unix + simulation_time
	var date_time: String = Time.get_datetime_string_from_unix_time(int(unix_time), true)
	date_time_line.text = date_time

func _on_pause_pressed() -> void:
	GlobalSimulationUtils.set_running(!GlobalSimulationUtils.get_running())

func _on_restart_pressed() -> void:
	GlobalProjectUtilities.set_simulation_index(GlobalProjectUtilities.get_simulation_index())

func _on_date_time_line_submitted(new_text: String) -> void:
	GlobalProjectUtilities.modify_simulation(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), new_text, "start_date")

func _on_slow_down_pressed() -> void:
	GlobalSimulationUtils.set_playback_speed(GlobalSimulationUtils.get_playback_speed() / 2)

func _on_speed_up_pressed() -> void:
	GlobalSimulationUtils.set_playback_speed(GlobalSimulationUtils.get_playback_speed() * 2)

func _on_create_pressed() -> void:
	var body: CelestialBody = CelestialBody.new(randi(), randi_range(1e6, 1e7), GlobalSimulationUtils.generate_id(), Vector3(randi_range(-1e10, 1e10), randi_range(-1e10, 1e10), randi_range(-1e10, 1e10)))
	GlobalProjectUtilities.create_body(GlobalSettings.get_current_project_path(), GlobalProjectUtilities.get_simulation_index(), body)
	GlobalSimulationUtils.set_auxiliar_selected_body(body.id)
	GlobalSimulationUtils.add_body(body)
	_on_restart_pressed()
