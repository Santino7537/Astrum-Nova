extends Control

const SIMULATION_ROW_SCENE := preload("res://Scripts/UI/Menus/Projects/SimulationScene/simulation_row.tscn")
const SimulationRow := preload("res://Scripts/UI/Menus/Projects/SimulationScene/simulation_row.gd")

@onready var simulations_panel: PanelContainer = $SimulationsPanel
@onready var simulation_rows: VBoxContainer = $SimulationsPanel/VBoxContainer/SimulationsList/SimulationsRows
@onready var simulation_line_edit: LineEdit = $SimulationsPanel/VBoxContainer/SimulationRow/SimulationLineEdit
@onready var overlay: ColorRect = $"../Overlay"

func _ready() -> void:
	_add_rows()
	_animate_in()

## Agrega filas en el menú, las cuales te permiten abrir simulaciones.
func _add_rows() -> void:
	var project_path := GlobalSettings.get_current_project_path()
	var simulations := GlobalProjectUtilities.get_simulations(project_path)
	
	for index in range(simulations.size()):
		_add_simulation_row(simulations[index].simulation_name, index)

## Crea una fila con una plantilla base y la añade al menú.
func _add_simulation_row(simulation_name: String, simulation_index: int) -> void:
	var row: SimulationRow = SIMULATION_ROW_SCENE.instantiate()
	row.configure(simulation_name, simulation_index)
	GlobalProjectUtilities.selected_simulation.connect(_on_simulation_selected)
	simulation_rows.add_child(row)

func _on_simulation_selected(_index: int) -> void:
	_on_close_pressed()

## Anima la abertura del menú
func _animate_in() -> void:
	simulations_panel.pivot_offset = simulations_panel.size / 2.0
	simulations_panel.scale = Vector2(0.8, 0.8)
	simulations_panel.modulate.a = 0.0
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(simulations_panel, "scale", Vector2.ONE, 0.25)
	tween.tween_property(simulations_panel, "modulate:a", 1.0, 0.2)

## Anima el cierre del menú
func _animate_out() -> void:
	simulations_panel.pivot_offset = simulations_panel.size / 2.0
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(simulations_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(simulations_panel, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(func() -> void:
		if get_parent() is CanvasLayer:
			get_parent().queue_free()
		else:
			queue_free()
	)

func _on_create_pressed() -> void:
	var simulation_name := simulation_line_edit.text.strip_edges()
	if simulation_name.is_empty():
		return
	
	var simulations := GlobalProjectUtilities.get_simulations(GlobalSettings.get_current_project_path())
	var simulation_index := simulations.size()
	var simulations_names = simulations.map(func (s: Dictionary) -> String:
		return s.simulation_name)
	
	if simulations_names.has(simulation_name):
		return
	
	GlobalProjectUtilities.create_simulation(GlobalSettings.get_current_project_path(), simulation_name)
	_add_simulation_row(simulation_name, simulation_index)

func _on_close_pressed() -> void:
	_animate_out()

func _on_exit_pressed() -> void:
	var transition := create_tween()
	transition.tween_property(overlay, "color:a", 0.8, 1.0)
	transition.tween_callback(func() -> void:
		var error := get_tree().change_scene_to_file("res://Scripts/UI/Menus/main_menu.tscn")
		if error != OK:
			push_error("No se pudo abrir el menú principal: %s" % error)
			var fade_back := create_tween()
			fade_back.tween_property(overlay, "color:a", 0.8, 1.0)
	)
