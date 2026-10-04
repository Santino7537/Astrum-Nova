extends Control

const SETTINGS_MENU_SCENE := preload("res://Scripts/UI/Menus/Settings/settings_menu.tscn")
const PROJECTS_MENU_SCENE := preload("res://Scripts/UI/Menus/Projects/projects_menu.tscn")

func _on_create_sim_pressed() -> void:
	pass 

func _on_open_sim_pressed() -> void:
	var root := get_tree().current_scene
	if root == null or root.has_node("ProjectsCanvas"):
		return
	
	var projects_menu := PROJECTS_MENU_SCENE.instantiate()
	root.add_child(projects_menu)
	projects_menu.name = "ProjectsMenu"

func _on_settings_pressed() -> void:
	var root := get_tree().current_scene
	if root == null or root.has_node("SettingsMenu"):
		return
	
	var settings_menu := SETTINGS_MENU_SCENE.instantiate()
	root.add_child(settings_menu)
	settings_menu.name = "SettingsMenu"

func _on_exit_pressed() -> void:
	get_tree().quit()
