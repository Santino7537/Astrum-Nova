extends Node

const DEFAULT_PORT := 2456
const MAX_MESSAGE_BYTES := 16 * 1024 * 1024

var _server := TCPServer.new()
var _clients: Array[Dictionary] = []
var _password := ""
var _storage_path := ""

func _ready() -> void:
	_password = OS.get_environment("ASTRUM_SERVER_PASSWORD")
	if _password.is_empty():
		push_error("Debe configurar la variable de entorno ASTRUM_SERVER_PASSWORD.")
		get_tree().quit(1)
		return

	var port_text := OS.get_environment("ASTRUM_SERVER_PORT")
	var port := DEFAULT_PORT if port_text.is_empty() else int(port_text)
	if port < 1 or port > 65535:
		push_error("ASTRUM_SERVER_PORT debe estar entre 1 y 65535.")
		get_tree().quit(1)
		return

	_storage_path = OS.get_environment("ASTRUM_DATA_DIR")
	if _storage_path.is_empty():
		_storage_path = "user://projects"
	_storage_path = ProjectSettings.globalize_path(_storage_path)
	var directory_error := DirAccess.make_dir_recursive_absolute(_storage_path)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("No se pudo crear el directorio de proyectos: %s" % error_string(directory_error))
		get_tree().quit(1)
		return

	var listen_error := _server.listen(port, "0.0.0.0")
	if listen_error != OK:
		push_error("No se pudo abrir el puerto %d: %s" % [port, error_string(listen_error)])
		get_tree().quit(1)
		return
	print("Astrum Nova Server escuchando en el puerto %d. Datos: %s" % [port, _storage_path])

func _process(_delta: float) -> void:
	while _server.is_connection_available():
		var peer := _server.take_connection()
		peer.set_no_delay(true)
		_clients.append({
			"peer": peer,
			"buffer": "",
			"authenticated": false
		})

	for index in range(_clients.size() - 1, -1, -1):
		var session: Dictionary = _clients[index]
		var peer: StreamPeerTCP = session["peer"]
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_clients.remove_at(index)
			continue

		var available := peer.get_available_bytes()
		if available > MAX_MESSAGE_BYTES:
			peer.disconnect_from_host()
			_clients.remove_at(index)
			continue
		if available > 0:
			var result := peer.get_data(available)
			if result[0] != OK:
				peer.disconnect_from_host()
				_clients.remove_at(index)
				continue
			var bytes: PackedByteArray = result[1]
			session["buffer"] += bytes.get_string_from_utf8()
			var buffered_text: String = session["buffer"]
			if buffered_text.to_utf8_buffer().size() > MAX_MESSAGE_BYTES:
				peer.disconnect_from_host()
				_clients.remove_at(index)
				continue

		while true:
			var buffer: String = session["buffer"]
			var separator := buffer.find("\n")
			if separator < 0:
				break
			var line := buffer.substr(0, separator)
			session["buffer"] = buffer.substr(separator + 1)
			_handle_message(session, line)

func _handle_message(session: Dictionary, line: String) -> void:
	var parsed: Variant = JSON.parse_string(line)
	var request_id := 0
	if parsed is Dictionary:
		request_id = int(parsed.get("id", 0))
	if not parsed is Dictionary:
		_send_response(session, request_id, {"ok": false, "error": "JSON inválido."})
		return

	var action := str(parsed.get("action", ""))
	if not session["authenticated"]:
		if action != "auth":
			_send_response(session, request_id, {"ok": false, "error": "Autenticación requerida."})
			return
		if str(parsed.get("password", "")) != _password:
			_send_response(session, request_id, {"ok": false, "error": "Contraseña incorrecta."})
			return
		session["authenticated"] = true
		_send_response(session, request_id, {"ok": true})
		return

	var response: Dictionary
	match action:
		"list_projects":
			response = _list_projects()
		"load_project":
			response = _load_project(str(parsed.get("project_name", "")))
		"save_project":
			response = _save_project(
				str(parsed.get("project_name", "")),
				parsed.get("project")
			)
		_:
			response = {"ok": false, "error": "Acción desconocida."}
	_send_response(session, request_id, response)

func _list_projects() -> Dictionary:
	var directory := DirAccess.open(_storage_path)
	if directory == null:
		return {"ok": false, "error": "No se pudo leer el almacenamiento de proyectos."}

	var projects: Array[String] = []
	for directory_name in directory.get_directories():
		var project_path := _project_file_path(directory_name)
		if not FileAccess.file_exists(project_path):
			continue
		var project := _read_project(project_path)
		if project.get("project_name", "") == directory_name:
			projects.append(directory_name)
	projects.sort()
	return {"ok": true, "projects": projects}

func _load_project(project_name: String) -> Dictionary:
	if not _is_valid_project_name(project_name):
		return {"ok": false, "error": "Nombre de proyecto inválido."}
	var project_path := _project_file_path(project_name)
	if not FileAccess.file_exists(project_path):
		return {"ok": false, "error": "El proyecto no existe."}
	var project := _read_project(project_path)
	if project.is_empty() or project.get("project_name", "") != project_name:
		return {"ok": false, "error": "El archivo del proyecto no es válido."}
	return {"ok": true, "project": project}

func _save_project(project_name: String, value: Variant) -> Dictionary:
	if not _is_valid_project_name(project_name):
		return {"ok": false, "error": "Nombre de proyecto inválido."}
	if not value is Dictionary or value.get("project_name", "") != project_name:
		return {"ok": false, "error": "Los datos del proyecto no son válidos."}
	if not value.get("simulations", []) is Array:
		return {"ok": false, "error": "La lista de simulaciones no es válida."}

	var project_directory := _storage_path.path_join(project_name)
	var directory_error := DirAccess.make_dir_recursive_absolute(project_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return {"ok": false, "error": "No se pudo crear el directorio del proyecto."}

	var file := FileAccess.open(_project_file_path(project_name), FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "No se pudo guardar el proyecto: %s." % error_string(FileAccess.get_open_error())}
	file.store_string(JSON.stringify(value, "\t"))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return {"ok": false, "error": "No se pudo completar la escritura del proyecto."}
	return {"ok": true}

func _read_project(project_path: String) -> Dictionary:
	var file := FileAccess.open(project_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or not parsed.get("simulations", []) is Array:
		return {}
	return parsed

func _project_file_path(project_name: String) -> String:
	return _storage_path.path_join(project_name).path_join(project_name + ".json")

func _is_valid_project_name(project_name: String) -> bool:
	if project_name.is_empty() or project_name != project_name.strip_edges():
		return false
	if project_name.to_utf8_buffer().size() > 120:
		return false
	if project_name == "." or project_name == ".." or project_name.begins_with("."):
		return false
	for invalid_character in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|", "\n", "\r", "\t"]:
		if project_name.contains(invalid_character):
			return false
	return true

func _send_response(session: Dictionary, request_id: int, response: Dictionary) -> void:
	var payload := response.duplicate()
	payload["id"] = request_id
	var peer: StreamPeerTCP = session["peer"]
	var error := peer.put_data((JSON.stringify(payload) + "\n").to_utf8_buffer())
	if error != OK:
		push_warning("No se pudo enviar una respuesta al cliente: %s" % error_string(error))
