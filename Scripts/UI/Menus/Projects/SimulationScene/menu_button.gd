extends Button

const SIMULATIONS_MENU_SCENE := preload("res://Scripts/UI/Menus/Projects/SimulationScene/simulations_menu.tscn")

func _on_pressed() -> void:
	var root := get_tree().current_scene
	if root == null or root.has_node("SimulationsCanvas"):
		return
	
	var simulations_menu := SIMULATIONS_MENU_SCENE.instantiate()
	root.add_child(simulations_menu)
	simulations_menu.name = "SimulationsMenu"
