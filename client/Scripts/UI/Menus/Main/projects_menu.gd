extends Control

const PROJECT_ROW_SCENE := preload("res://Scenes/UI/Menus/Main/project_row.tscn")
const ProjectRow := preload("res://Scripts/UI/Menus/Main/project_row.gd")

@onready var projects_panel: PanelContainer = $ProjectsPanel
@onready var projects_list: ScrollContainer = $ProjectsPanel/VBoxContainer/ProjectsList
@onready var project_rows: VBoxContainer = $ProjectsPanel/VBoxContainer/ProjectsList/ProjectRows
@onready var empty_state: Label = $ProjectsPanel/VBoxContainer/EmptyState
@onready var overlay: ColorRect = $"../Overlay"

var _remote_project_names: Dictionary = {}

func _ready() -> void:
	_add_rows()
	_animate_in()
	if NetworkClient.connected:
		await _refresh_remote_projects()

## Agrega filas en el menú, las cuales te permiten abrir proyectos.
func _add_rows() -> void:
	var root_path := GlobalSettings.get_file_system_path()
	var projects: Array = _find_projects(root_path) if not root_path.is_empty() else []
	projects_list.visible = not projects.is_empty()
	empty_state.visible = projects.is_empty()
	
	for project in projects:
		_add_project_row(project.name, project.path)

func _refresh_remote_projects() -> void:
	var response: Dictionary = await NetworkClient.list_projects()
	if not response.get("ok", false):
		push_error("No se pudieron obtener los proyectos del servidor: %s" % response.get("error", "Error desconocido."))
		return
	for project_name in response.get("projects", []):
		var name := str(project_name)
		_remote_project_names[name] = true
		NetworkClient.mark_project_remote(name)
		_add_project_row("☁️ " + name, name, true)

	projects_list.visible = project_rows.get_child_count() > 0
	empty_state.visible = project_rows.get_child_count() == 0

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
				projects.append({
					"name": "🖥️ " + project_name,
					"project_name": project_name,
					"path": file_path
				})
	
	return projects

## Crea una fila con una plantilla base y la añade al menú.
func _add_project_row(project_name: String, project_path: String, is_remote: bool = false) -> void:
	var row: ProjectRow = PROJECT_ROW_SCENE.instantiate()
	row.configure(project_name, project_path, is_remote)
	row.project_selected.connect(_on_project_selected)
	row.project_upload_requested.connect(_on_project_upload_requested)
	project_rows.add_child(row)

func _on_project_upload_requested(project_path: String, project_name: String) -> void:
	var replacing_remote := _remote_project_names.has(project_name)
	var project_file := FileAccess.open(project_path, FileAccess.READ)
	if project_file == null:
		_set_upload_status(project_name, "Retry")
		push_error("No se pudo leer el proyecto %s: %s" % [project_name, error_string(FileAccess.get_open_error())])
		return

	var project: Variant = JSON.parse_string(project_file.get_as_text())
	project_file.close()
	if not project is Dictionary or project.get("project_name", "") != project_name:
		_set_upload_status(project_name, "Retry")
		push_error("No se pudo subir %s: los datos del proyecto no son válidos." % project_name)
		return

	var response: Dictionary = await NetworkClient.save_project(project_name, project)
	if not response.get("ok", false):
		_set_upload_status(project_name, "Retry")
		push_error("No se pudo subir %s al servidor: %s" % [project_name, response.get("error", "Error desconocido.")])
		return

	_remote_project_names[project_name] = true
	NetworkClient.mark_project_remote(project_name)
	_set_upload_status(project_name, "Replaced" if replacing_remote else "Uploaded")

func _set_upload_status(project_name: String, status: String) -> void:
	for child in project_rows.get_children():
		var row := child as ProjectRow
		if row != null and not row.is_remote and row.project_name == project_name:
			row.set_upload_status(status)

## Descarga proyectos remotos y abre el archivo JSON local con la escena existente.
func _on_project_selected(project_path: String, is_remote: bool) -> void:
	if is_remote:
		var response: Dictionary = await NetworkClient.load_project(project_path)
		if not response.get("ok", false):
			push_error("No se pudo descargar el proyecto: %s" % response.get("error", "Error desconocido."))
			return
		var project: Dictionary = response.get("project", {})
		var project_name := str(project.get("project_name", ""))
		NetworkClient.mark_project_remote(project_name)
		var base_path := GlobalSettings.get_file_system_path()
		if project_name.is_empty() or base_path.is_empty():
			push_error("No se pudo guardar localmente el proyecto descargado.")
			return
		var project_directory := base_path.path_join(project_name)
		var directory_error := DirAccess.make_dir_recursive_absolute(project_directory)
		if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
			push_error("No se pudo crear el directorio local del proyecto: %s" % error_string(directory_error))
			return
		project_path = project_directory.path_join(project_name + ".json")
		var project_file := FileAccess.open(project_path, FileAccess.WRITE)
		if project_file == null:
			push_error("No se pudo guardar localmente el proyecto: %s" % error_string(FileAccess.get_open_error()))
			return
		project_file.store_string(JSON.stringify(project, "\t"))
		var write_error := project_file.get_error()
		project_file.close()
		if write_error != OK:
			push_error("No se pudo completar la descarga del proyecto: %s" % error_string(write_error))
			return

	_open_project(project_path)

## Abre una escena para visualizar un proyecto en un plano tridimensional.
func _open_project(project_path: String) -> void:
	var transition := create_tween()
	transition.tween_property(overlay, "color:a", 0.8, 1.0)
	transition.tween_callback(func() -> void:
		GlobalSettings.set_current_project_path(project_path)
		var error := get_tree().change_scene_to_file("res://Scenes/tridimentional_view.tscn")
		if error != OK:
			push_error("No se pudo abrir la escena tridimensional: %s" % error)
			var fade_back := create_tween()
			fade_back.tween_property(overlay, "color:a", 0.8, 1.0)
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
