extends Control

const SETTINGS_MENU_SCENE := preload("res://Scenes/UI/Menus/Main/settings_menu.tscn")
const PROJECTS_MENU_SCENE := preload("res://Scenes/UI/Menus/Main/projects_menu.tscn")
const PROJECT_CREATION_MENU_SCENE := preload("res://Scenes/UI/Menus/Main/project_creation_menu.tscn")
const CONNECT_MENU_SCENE := preload("res://Scenes/UI/Menus/Main/connect_menu.tscn")

func _on_create_sim_pressed() -> void:
	var root := get_tree().current_scene
	if root == null or root.has_node("ProjectCreationCanvas"):
		return
	
	var project_creation_menu := PROJECT_CREATION_MENU_SCENE.instantiate()
	root.add_child(project_creation_menu)
	project_creation_menu.name = "ProjectCreationMenu"

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


func _on_connect_pressed() -> void:
	var root := get_tree().current_scene
	if root == null or root.has_node("ConnectMenu"):
		return
	
	var connect_menu := CONNECT_MENU_SCENE.instantiate()
	root.add_child(connect_menu)
	connect_menu.name = "ConnectMenu"
