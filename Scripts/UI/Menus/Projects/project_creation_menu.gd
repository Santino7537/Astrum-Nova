extends Control

@onready var project_creation_panel: PanelContainer = $ProjectCreationPanel
@onready var project_line_edit: LineEdit = $ProjectCreationPanel/VBoxContainer/ProjectRow/ProjectLineEdit
@onready var simulation_line_edit: LineEdit = $ProjectCreationPanel/VBoxContainer/SimulationRow/SimulationLineEdit

func _ready() -> void:
	_animate_in()

func _animate_in() -> void:
	project_creation_panel.pivot_offset = project_creation_panel.size / 2.0
	project_creation_panel.scale = Vector2(0.8, 0.8)
	project_creation_panel.modulate.a = 0.0
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(project_creation_panel, "scale", Vector2.ONE, 0.25)
	tween.tween_property(project_creation_panel, "modulate:a", 1.0, 0.2)

func _animate_out() -> void:
	project_creation_panel.pivot_offset = project_creation_panel.size / 2.0
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(project_creation_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(project_creation_panel, "modulate:a", 0.0, 0.2)
	
	# Destruye el CanvasLayer entero (nodo raíz) al finalizar la animación
	tween.chain().tween_callback(func() -> void:
		if get_parent() is CanvasLayer:
			get_parent().queue_free()
		else:
			queue_free()
	)

func _on_save_button_pressed() -> void:
	var project_name := project_line_edit.text.strip_edges()
	if project_name.is_empty():
		return
	
	var simulation_name := simulation_line_edit.text.strip_edges()
	if simulation_name.is_empty():
		return
	
	GlobalProjectUtilities.create_project(project_name, simulation_name)
	_on_close_button_pressed()

func _on_close_button_pressed() -> void:
	_animate_out()
