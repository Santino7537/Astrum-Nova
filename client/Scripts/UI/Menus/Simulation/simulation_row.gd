extends Button

var simulation_name: String
var simulation_index: int

func configure(row_simulation_name: String, row_simulation_index: int) -> void:
	simulation_name = row_simulation_name
	simulation_index = row_simulation_index

func _ready() -> void:
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	text = simulation_name

func _on_pressed() -> void:
	GlobalProjectUtilities.set_simulation_index(simulation_index)
