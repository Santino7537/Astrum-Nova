extends Node

signal connection_changed(is_connected: bool, message: String)

const DEFAULT_PORT := 2456
const REQUEST_TIMEOUT_MS := 10000
const CONNECTION_TIMEOUT_MS := 5000
const MAX_MESSAGE_BYTES := 16 * 1024 * 1024

var connected: bool = false
var _peer: StreamPeerTCP
var _receive_buffer := ""
var _next_request_id := 1
var _responses: Dictionary = {}
var _remote_projects: Dictionary = {}

func _process(_delta: float) -> void:
	if _peer == null:
		return

	_peer.poll()
	var status := _peer.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTED:
		_read_responses()
	elif status != StreamPeerTCP.STATUS_CONNECTING:
		_close_connection("Se perdió la conexión con el servidor.")

func connect_to_server(host: String, port: int, password: String) -> Dictionary:
	disconnect_from_server()
	if host.strip_edges().is_empty() or port < 1 or port > 65535:
		return {"ok": false, "error": "Dirección o puerto inválidos."}
	if password.is_empty():
		return {"ok": false, "error": "La contraseña es obligatoria."}

	_peer = StreamPeerTCP.new()
	var error := _peer.connect_to_host(host.strip_edges(), port)
	if error != OK:
		_close_connection("No se pudo iniciar la conexión (%s)." % error_string(error))
		return {"ok": false, "error": "No se pudo iniciar la conexión (%s)." % error_string(error)}

	var deadline := Time.get_ticks_msec() + CONNECTION_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		_peer.poll()
		if _peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTING:
			_close_connection("No se pudo conectar con el servidor.")
			return {"ok": false, "error": "No se pudo conectar con el servidor."}
		await get_tree().process_frame

	if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		_close_connection("Se agotó el tiempo de conexión.")
		return {"ok": false, "error": "Se agotó el tiempo de conexión."}

	var authentication := await _request("auth", {"password": password})
	if not authentication.get("ok", false):
		var message := str(authentication.get("error", "Autenticación rechazada."))
		_close_connection(message)
		return {"ok": false, "error": message}

	connected = true
	connection_changed.emit(true, "Conectado.")
	return {"ok": true}

func disconnect_from_server() -> void:
	if _peer != null:
		_peer.disconnect_from_host()
		_peer = null
	_receive_buffer = ""
	_responses.clear()
	if connected:
		connected = false
		connection_changed.emit(false, "Desconectado.")

func list_projects() -> Dictionary:
	return await _request("list_projects")

func load_project(project_name: String) -> Dictionary:
	return await _request("load_project", {"project_name": project_name})

func save_project(project_name: String, project: Dictionary) -> Dictionary:
	return await _request("save_project", {
		"project_name": project_name,
		"project": project
	})

func mark_project_remote(project_name: String) -> void:
	_remote_projects[project_name] = true

func is_project_remote(project_name: String) -> bool:
	return _remote_projects.has(project_name)

func _request(action: String, data: Dictionary = {}) -> Dictionary:
	if _peer == null or _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return {"ok": false, "error": "No hay conexión con el servidor."}

	var request_id := _next_request_id
	_next_request_id += 1
	var message := data.duplicate()
	message["id"] = request_id
	message["action"] = action
	var encoded_message := (JSON.stringify(message) + "\n").to_utf8_buffer()
	if encoded_message.size() > MAX_MESSAGE_BYTES:
		return {"ok": false, "error": "La solicitud supera el tamaño máximo permitido de 16 MiB."}
	var error := _peer.put_data(encoded_message)
	if error != OK:
		return {"ok": false, "error": "No se pudo enviar la solicitud (%s)." % error_string(error)}

	var deadline := Time.get_ticks_msec() + REQUEST_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if _responses.has(request_id):
			var response: Dictionary = _responses[request_id]
			_responses.erase(request_id)
			return response
		if _peer == null or _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			return {"ok": false, "error": "Se perdió la conexión con el servidor."}
		await get_tree().process_frame

	_responses.erase(request_id)
	return {"ok": false, "error": "El servidor no respondió a tiempo."}

func _read_responses() -> void:
	var available := _peer.get_available_bytes()
	if available <= 0:
		return
	if available > MAX_MESSAGE_BYTES:
		_close_connection("El servidor envió un mensaje demasiado grande.")
		return

	var result := _peer.get_data(available)
	if result[0] != OK:
		_close_connection("No se pudieron leer datos del servidor.")
		return
	var bytes: PackedByteArray = result[1]
	_receive_buffer += bytes.get_string_from_utf8()
	if _receive_buffer.to_utf8_buffer().size() > MAX_MESSAGE_BYTES:
		_close_connection("El servidor envió un mensaje demasiado grande.")
		return

	while true:
		var separator := _receive_buffer.find("\n")
		if separator < 0:
			break
		var line := _receive_buffer.substr(0, separator)
		_receive_buffer = _receive_buffer.substr(separator + 1)
		var parsed: Variant = JSON.parse_string(line)
		if not parsed is Dictionary:
			_close_connection("El servidor envió una respuesta inválida.")
			return
		var request_id := int(parsed.get("id", 0))
		if request_id > 0:
			_responses[request_id] = parsed

func _close_connection(message: String) -> void:
	if _peer != null:
		_peer.disconnect_from_host()
		_peer = null
	_receive_buffer = ""
	_responses.clear()
	if connected:
		connected = false
		connection_changed.emit(false, message)
