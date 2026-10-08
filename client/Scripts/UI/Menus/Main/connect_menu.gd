extends Control

@onready var connect_panel: PanelContainer = $ConnectPanel
@onready var server_line_edit: LineEdit = $ConnectPanel/VBoxContainer/ServerRow/ServerLineEdit
@onready var password_line_edit: LineEdit = $ConnectPanel/VBoxContainer/PasswordRow/PasswordLineEdit
@onready var spacer: Control = $ConnectPanel/VBoxContainer/Spacer
@onready var connect_button: Button = $ConnectPanel/VBoxContainer/Actions/ConnectButton

func _ready() -> void:
	_update_connection_button()
	_animate_in()

func _animate_in() -> void:
	connect_panel.pivot_offset = connect_panel.size / 2.0
	connect_panel.scale = Vector2(0.8, 0.8)
	connect_panel.modulate.a = 0.0
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(connect_panel, "scale", Vector2.ONE, 0.25)
	tween.tween_property(connect_panel, "modulate:a", 1.0, 0.2)

func _animate_out() -> void:
	connect_panel.pivot_offset = connect_panel.size / 2.0
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(connect_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(connect_panel, "modulate:a", 0.0, 0.2)
	
	# Destruye el CanvasLayer entero (nodo raíz) al finalizar la animación
	tween.chain().tween_callback(func() -> void:
		if get_parent() is CanvasLayer:
			get_parent().queue_free()
		else:
			queue_free()
	)

func _on_close_button_pressed() -> void:
	_animate_out()

func _on_connect_button_pressed() -> void:
	if NetworkClient.connected:
		NetworkClient.disconnect_from_server()
		_update_connection_button()
		show_error("Desconectado del servidor.")
		return

	var address := server_line_edit.text.strip_edges()
	var host := address
	var port := NetworkClient.DEFAULT_PORT
	if address.contains(":"):
		var address_parts := address.split(":")
		if address_parts.size() != 2 or address_parts[1].is_empty() or not address_parts[1].is_valid_int():
			show_error("Usa una dirección IP o nombre de host, con puerto opcional (host:puerto).")
			return
		host = address_parts[0]
		port = int(address_parts[1])
		if port < 1 or port > 65535:
			show_error("El puerto debe estar entre 1 y 65535.")
			return

	hide_errors()
	connect_button.disabled = true
	var response: Dictionary = await NetworkClient.connect_to_server(
		host,
		port,
		password_line_edit.text
	)
	connect_button.disabled = false
	if not response.get("ok", false):
		show_error(str(response.get("error", "No se pudo conectar.")))
		return
	_update_connection_button()
	show_error("Conectado. La conexión permanecerá activa hasta desconectarte.")

func _update_connection_button() -> void:
	connect_button.text = "Disconnect" if NetworkClient.connected else "Connect"

func show_error(message : String) -> void:
	hide_errors()
	var error_label : Label = Label.new()
	error_label.text = message
	spacer.add_child(error_label)

func hide_errors() -> void:
	for child in spacer.get_children():
		child.queue_free()
