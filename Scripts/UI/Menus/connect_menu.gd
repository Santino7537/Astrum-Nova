extends Control

@onready var connect_panel: PanelContainer = $ConnectPanel
@onready var server_line_edit: LineEdit = $ConnectPanel/VBoxContainer/ServerRow/ServerLineEdit
@onready var password_line_edit: LineEdit = $ConnectPanel/VBoxContainer/PasswordRow/PasswordLineEdit
@onready var spacer: Control = $ConnectPanel/VBoxContainer/Spacer

func _ready() -> void:
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
	var ip : String = server_line_edit.text
	
	# verificar la IP
	var octets : PackedStringArray = ip.split(".")
	if octets.size() != 4:
		show_error("Formato de IP inadecuado")
		return
	
	for octet : String in octets:
		if !octet.is_valid_int() or int(octet) != min(max(int(octet), 0), 255):
			show_error("Formato de IP inadecuado")
			return
	
	hide_errors()

func show_error(message : String) -> void:
	var error_label : Label = Label.new()
	error_label.text = message
	spacer.add_child(error_label)

func hide_errors() -> void:
	for child in spacer.get_children():
		child.queue_free()
