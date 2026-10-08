extends HBoxContainer

signal project_selected(project_path: String, is_remote: bool)
signal project_upload_requested(project_path: String, project_name: String)

@onready var open_button: Button = $OpenButton
@onready var upload_button: Button = $UploadButton

var project_name: String
var project_path: String
var display_name: String
var is_remote: bool = false

func configure(row_project_name: String, row_project_path: String, remote: bool = false) -> void:
	display_name = row_project_name
	project_path = row_project_path
	is_remote = remote

func _ready() -> void:
	project_name = display_name.trim_prefix("☁️ ").trim_prefix("🖥️ ")
	open_button.text = display_name
	upload_button.visible = not is_remote and NetworkClient.connected
	open_button.pressed.connect(_on_open_pressed)
	upload_button.pressed.connect(_on_upload_pressed)
	NetworkClient.connection_changed.connect(_on_connection_changed)

func _exit_tree() -> void:
	if NetworkClient.connection_changed.is_connected(_on_connection_changed):
		NetworkClient.connection_changed.disconnect(_on_connection_changed)

func _on_open_pressed() -> void:
	project_selected.emit(project_path, is_remote)

func _on_upload_pressed() -> void:
	upload_button.disabled = true
	project_upload_requested.emit(project_path, project_name)

func set_upload_status(message: String) -> void:
	upload_button.text = message
	upload_button.disabled = false

func _on_connection_changed(is_connected: bool, _message: String) -> void:
	upload_button.visible = not is_remote and is_connected
