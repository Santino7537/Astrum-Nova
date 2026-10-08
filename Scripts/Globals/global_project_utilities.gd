extends Node

signal selected_simulation(simulation_index: int)
signal changed_body(simulation_index: int)

var simulation_index: int = 0

func set_simulation_index(index: int) -> void:
	simulation_index = index
	selected_simulation.emit(index)

func get_simulation_index() -> int:
	return simulation_index

## Crea una carpeta, y dentro un json que contiene un nuevo proyecto con una simulación.
func create_project(project_name: String, simulation_name: String) -> void:
	var file_system_path := GlobalSettings.get_file_system_path()
	
	var dir := DirAccess.open(file_system_path)
	if dir == null:
		print("No se pudo acceder al directorio.")
		return
	
	# Crear la carpeta del proyecto
	var project_dir_path := file_system_path.path_join(project_name)
	if not DirAccess.dir_exists_absolute(project_dir_path):
		var error := DirAccess.make_dir_recursive_absolute(project_dir_path)
		
		if error != OK:
			print("No se pudo crear la carpeta. Error: ", error)
			return
	
	var project_path := project_dir_path.path_join(project_name + ".json")
	
	# Estructura inicial del proyecto
	var data := {
		"project_name": project_name,
		"simulations": []
	}
	var json_data := JSON.stringify(data, "\t")
	
	# Crea el archivo del proyecto
	var project_file := FileAccess.open(project_path, FileAccess.WRITE)
	if project_file == null:
		print("No se pudo crear el archivo JSON.")
		return
	
	project_file.store_string(json_data)
	project_file.close()
	
	# Crea una simulación dentro del proyecto
	create_simulation(project_path, simulation_name)

## Obtiene el contenido de un archivo JSON
func _obtain_json_file_content(project_path: String) -> Dictionary:
	var project_file := FileAccess.open(project_path, FileAccess.READ)
	if project_file == null:
		print("No se pudo abrir el archivo.")
		return {}
	
	var content := project_file.get_as_text()
	project_file.close()
	
	var data = JSON.parse_string(content)
	if data == null:
		print("El JSON no es válido.")
		return {}
	
	return data

## Reemplaza todo el contenido de un archivo JSON por uno nuevo
func _write_json_file(project_path: String, new_content: String) -> void:
	var project_file := FileAccess.open(project_path, FileAccess.WRITE)
	if project_file == null:
		print("No se pudo abrir el archivo para escribir.")
		return
	
	project_file.store_string(new_content)
	project_file.close()

## Modifica valores dentro de datos compuestos
func _set_nested_value(data: Variant, path: Array, value: Variant, append_value: bool) -> void:
	if path.is_empty():
		return
	
	var current = data
	for i in range(path.size() - 1):
		current = current[path[i]]
	var final_key = path[-1]
	
	if !append_value:
		current[final_key] = value
	else:
		if current is Dictionary:
			current[final_key] = value
		elif current is Array:
			current.append(value)

## Modifica un campo de un proyecto
func _modify_proyect(project_path: String, simulation_index: int, path: Array, value: Variant, append_value: bool = false) -> void:
	var data := _obtain_json_file_content(project_path)
	if data == {}:
		return
	
	# Modifica el campo
	_set_nested_value(data, path, value, append_value)
	var new_content := JSON.stringify(data, "\t")
	
	_write_json_file(project_path, new_content)

## Crea una simulación dentro de un proyecto
func create_simulation(project_path: String, simulation_name: String) -> void:
	var path: Array = ["simulations"]
	var simulation := {
		"simulation_name": simulation_name,
		"start_date": Time.get_datetime_string_from_system(false, true),
		"celestial_bodies": []
	}
	
	_modify_proyect(project_path, simulation_index, path, simulation, true)

## Obtiene una lista de simulaciones de un proyecto
func get_simulations(project_path: String) -> Array:
	var data := _obtain_json_file_content(project_path)
	if data == {}:
		return []
	
	var simulations: Array = data["simulations"]
	return simulations

func get_simulation(project_path: String, simulation_index: int) -> Dictionary:
	return get_simulations(project_path)[simulation_index]

func modify_body(project_path: String, simulation_index: int, body_id: String, new_value: Variant, field_name: String) -> void:
	var data := _obtain_json_file_content(project_path)
	var bodies = data["simulations"][simulation_index]["celestial_bodies"]
	var wanted_body: Dictionary = {}
	
	for body in bodies:
		if body.id == body_id:
			wanted_body = body
			break
	
	if wanted_body == {}:
		print("No existe el cuerpo con ID " + body_id)
		return
	
	wanted_body[field_name] = new_value
	var new_content := JSON.stringify(data, "\t")
	
	_write_json_file(project_path, new_content)
	
	GlobalSimulationUtils.set_auxiliar_selected_body(body_id)
	changed_body.emit(simulation_index)
