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
	},
	"display": {
		"window_mode": Window.MODE_WINDOWED
	}
}

## Ruta del sistema de archivos del usuario
var file_system_path: String = ""
## Ruta del proyecto actuál
var current_project_path: String = ""
## Modo de la ventana
var window_mode: int = Window.MODE_WINDOWED

func _init() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	
	for section in DEFAULT_CONFIG:
		for key in DEFAULT_CONFIG[section]:
			if not config.has_section_key(section, key):
				store_in_disk(section, key, DEFAULT_CONFIG[section][key], config)
	
	file_system_path = load_from_disk("paths", "file_system_path", config)

func _ready() -> void:
	var saved_window_mode: Variant = load_from_disk("display", "window_mode")
	if saved_window_mode is int and (saved_window_mode == Window.MODE_WINDOWED or saved_window_mode == Window.MODE_FULLSCREEN):
		window_mode = saved_window_mode
	get_window().mode = window_mode

func load_from_disk(section: String, key: String, config_file: ConfigFile = ConfigFile.new()) -> Variant:
	var error := config_file.load(SETTINGS_PATH)
	if error != OK:
		if error != ERR_FILE_NOT_FOUND:
			push_error("No se pudo cargar la configuración: %s" % error_string(error))
		return null
	return config_file.get_value(section, key, null)

func store_in_disk(section: String, key: String, value: Variant, config_file: ConfigFile = ConfigFile.new()) -> void:
	var error := config_file.load(SETTINGS_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_error("No se pudo cargar la configuración: %s" % error_string(error))
		return

	config_file.set_value(section, key, value)
	error = config_file.save(SETTINGS_PATH)
	if error != OK:
		push_error("No se pudo guardar la configuración: %s" % error_string(error))

func set_window_mode(mode: int) -> void:
	if mode != Window.MODE_WINDOWED and mode != Window.MODE_FULLSCREEN:
		push_error("Modo de ventana no válido: %s" % mode)
		return

	window_mode = mode
	get_window().mode = window_mode
	store_in_disk("display", "window_mode", window_mode)

func get_window_mode() -> int:
	return window_mode

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
