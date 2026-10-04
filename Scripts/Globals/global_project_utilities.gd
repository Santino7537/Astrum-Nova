extends Node

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

## Crea una simulación dentro de un proyecto
func create_simulation(project_path: String, simulation_name: String) -> void:
	var project_file := FileAccess.open(project_path, FileAccess.READ)
	if project_file == null:
		print("No se pudo abrir el archivo.")
		return
	
	var content := project_file.get_as_text()
	project_file.close()
	
	var data = JSON.parse_string(content)
	if data == null:
		print("El JSON no es válido.")
		return
	
	# Agrega la simulación
	data["simulations"].append(
	{
		"simulation_name": simulation_name,
		"start_date": Time.get_datetime_string_from_system(false, true),
		"celestial_bodies": []
	}
	)
	var new_content := JSON.stringify(data, "\t")
	
	project_file = FileAccess.open(project_path, FileAccess.WRITE)
	if project_file == null:
		print("No se pudo abrir el archivo para escribir.")
		return
	
	project_file.store_string(new_content)
	project_file.close()
