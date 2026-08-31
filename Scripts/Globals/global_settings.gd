extends RefCounted

## Ruta del archivo de configuración
const SETTINGS_PATH := "user://settings.cfg"

## Ruta del sistema de archivos del usuario
var file_system_path: String = ""

func _ready() -> void:
	_load_from_disk()

func _load_from_disk() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		file_system_path = config.get_value("paths", "file_system_path", "")

func set_file_system_path(path: String) -> void:
	var cleaned_path := path.strip_edges()
	if cleaned_path.is_empty():
		return
	
	file_system_path = cleaned_path
	var config := ConfigFile.new()
	config.set_value("paths", "file_system_path", file_system_path)
	config.save(SETTINGS_PATH)

func get_file_system_path() -> String:
	return file_system_path
