extends Control

@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var path_line_edit: LineEdit = $SettingsPanel/VBoxContainer/PathRow/PathLineEdit

func _ready() -> void:
	path_line_edit.text = GlobalSettings.get_file_system_path()
	_animate_in()

func _animate_in() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(settings_panel, "position:x", 0.0, 0.25)

func _animate_out() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(settings_panel, "position:x", -settings_panel.size.x - 40, 0.2)
	tween.finished.connect(queue_free)

func _on_browse_pressed() -> void:
	var dialog := FileDialog.new()
	dialog.name = "SettingsFileDialog"
	dialog.title = "Selecciona una carpeta para guardar proyectos"
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	add_child(dialog)
	dialog.popup_centered(Vector2(600, 400))
	
	dialog.dir_selected.connect(_on_directory_selected)
	dialog.canceled.connect(func() -> void:
		dialog.queue_free()
	)
	dialog.close_requested.connect(func() -> void:
		dialog.queue_free()
	)

func _on_directory_selected(path: String) -> void:
	path_line_edit.text = path
	var dialog := get_node_or_null("SettingsFileDialog")
	if is_instance_valid(dialog):
		dialog.queue_free()

func _on_save_pressed() -> void:
	var selected_path := path_line_edit.text.strip_edges()
	if selected_path.is_empty():
		return
	
	if not DirAccess.dir_exists_absolute(selected_path):
		var directory := DirAccess.open(selected_path)
		if directory == null:
			print("La ruta seleccionada no es válida: ", selected_path)
			return
	
	GlobalSettings.set_simulation_save_path(selected_path)
	_on_close_pressed()

func _on_close_pressed() -> void:
	_animate_out()
