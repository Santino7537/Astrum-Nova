extends Control

const SETTINGS_MENU_SCENE := preload("res://Scripts/UI/settings_menu.tscn")

func _on_create_sim_pressed() -> void:
	pass # Replace with function body.

func _on_open_sim_pressed() -> void:
	pass # Replace with function body.

func _on_settings_pressed() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	
	if root.has_node("SettingsMenu"):
		return
	
	var settings_menu := SETTINGS_MENU_SCENE.instantiate()
	root.add_child(settings_menu)
	settings_menu.name = "SettingsMenu"

func _on_exit_pressed() -> void:
	get_tree().quit()
