extends Node

## Ruta del archivo de configuración
const SETTINGS_PATH := "user://settings.cfg"
## Variables por defecto que deben tener todos los usuarios en su configuración
const DEFAULT_CONFIG := {
	"paths": {
		"file_system_path": "C:/"
	},
	"magnitude_units": {
		"mass": Constants.MASS_UNITS.kg,
		"length": Constants.LENGTH_UNITS.km,
		"velocity": Constants.VELOCITY_UNITS.km_s
	}
}

## Ruta del sistema de archivos del usuario
var file_system_path: String = ""
## Ruta del proyecto actuál
var current_project_path: String = ""

func _init() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	
	for section in DEFAULT_CONFIG:
		for key in DEFAULT_CONFIG[section]:
			if not config.has_section_key(section, key):
				store_in_disk(section, key, DEFAULT_CONFIG[section][key], config)
	
	file_system_path = load_from_disk("paths", "file_system_path", config)

func load_from_disk(section: String, key: String, config_file: ConfigFile = ConfigFile.new()) -> Variant:
	if config_file.load(SETTINGS_PATH) == OK:
		return config_file.get_value(section, key)
	return null

func store_in_disk(section: String, key: String, value: Variant, config_file: ConfigFile = ConfigFile.new()) -> void:
	if config_file.load(SETTINGS_PATH) == OK:
		config_file.set_value(section, key, value)
		config_file.save(SETTINGS_PATH)

func set_file_system_path(path: String) -> void:
	var cleaned_path := path.strip_edges()
	if cleaned_path.is_empty():
		return
	
	file_system_path = cleaned_path
	store_in_disk("paths", "file_system_path", file_system_path)

func get_file_system_path() -> String:
	return file_system_path

func set_current_project_path(path: String) -> void:
	current_project_path = path

func get_current_project_path() -> String:
	return current_project_path
