extends Button

signal project_selected(project_path: String)

var project_name: String
var project_path: String

func configure(row_project_name: String, row_project_path: String) -> void:
	project_name = row_project_name
	project_path = row_project_path

func _ready() -> void:
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	text = project_name
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	project_selected.emit(project_path)
