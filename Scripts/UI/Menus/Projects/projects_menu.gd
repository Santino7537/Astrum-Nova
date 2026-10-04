extends Control

const PROJECT_ROW_SCENE := preload("res://Scripts/UI/Menus/Projects/project_row.tscn")
const ProjectRow := preload("res://Scripts/UI/Menus/Projects/project_row.gd")

@onready var projects_panel: PanelContainer = $ProjectsPanel
@onready var projects_list: ScrollContainer = $ProjectsPanel/VBoxContainer/ProjectsList
@onready var project_rows: VBoxContainer = $ProjectsPanel/VBoxContainer/ProjectsList/ProjectRows
@onready var empty_state: Label = $ProjectsPanel/VBoxContainer/EmptyState
@onready var overlay: ColorRect = $"../Overlay"


func _ready() -> void:
	_add_rows()
	_animate_in()

## Agrega filas en el menú, las cuales te permiten abrir proyectos.
func _add_rows() -> void:
	var root_path := GlobalSettings.get_file_system_path()
	var projects := _find_projects(root_path) if not root_path.is_empty() else []
	projects_list.visible = not projects.is_empty()
	empty_state.visible = projects.is_empty()
	
	for project in projects:
		_add_project_row(project.name, project.path)

## Busca en un directorio proyectos dentro de sus directorios.
func _find_projects(directory_path: String) -> Array[Dictionary]:
	var projects: Array[Dictionary] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return projects
	
	var dir_names := directory.get_directories()
	
	for dir_name in dir_names:
		var dir_access := DirAccess.open(directory_path.path_join(dir_name))
		var file_names := dir_access.get_files()
		
		for file_name in file_names:
			if file_name.get_extension().to_lower() != "json":
				continue
			
			var file_path := directory_path.path_join(dir_name + "/" + file_name)
			var file := FileAccess.open(file_path, FileAccess.READ)
			if file == null:
				continue
			
			var parsed_data: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if not parsed_data is Dictionary:
				continue
			
			var project_name := str(parsed_data.get("project_name", ""))
			if not project_name.is_empty():
				projects.append({"name": "🖥️ project_name", "path": file_path})
	
	return projects

## Crea una fila con una plantilla base y la añade al menú.
func _add_project_row(project_name: String, project_path: String) -> void:
	var row: ProjectRow = PROJECT_ROW_SCENE.instantiate()
	row.configure(project_name, project_path)
	row.project_selected.connect(_on_project_selected)
	project_rows.add_child(row)

## Abre una escena para visualizar un proyecto en un plano tridimensional.
func _on_project_selected(_project_path: String) -> void:
	var transition := create_tween()
	transition.tween_property(overlay, "color:a", 1.0, 0.35)
	transition.tween_callback(func() -> void:
		GlobalSettings.current_project_path = _project_path
		var error := get_tree().change_scene_to_file("res://Scenes/tridimentional_view.tscn")
		if error != OK:
			push_error("No se pudo abrir la escena tridimensional: %s" % error)
			var fade_back := create_tween()
			fade_back.tween_property(overlay, "color:a", 0.6, 0.2)
	)

## Anima la abertura del menú
func _animate_in() -> void:
	projects_panel.pivot_offset = projects_panel.size / 2.0
	projects_panel.scale = Vector2(0.8, 0.8)
	projects_panel.modulate.a = 0.0
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(projects_panel, "scale", Vector2.ONE, 0.25)
	tween.tween_property(projects_panel, "modulate:a", 1.0, 0.2)

## Anima el cierre del menú
func _animate_out() -> void:
	projects_panel.pivot_offset = projects_panel.size / 2.0
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(projects_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(projects_panel, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(func() -> void:
		if get_parent() is CanvasLayer:
			get_parent().queue_free()
		else:
			queue_free()
	)

func _on_close_pressed() -> void:
	_animate_out()
