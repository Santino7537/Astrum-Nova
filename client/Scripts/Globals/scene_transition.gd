extends Node

var _snapshot: TextureRect
var _is_frozen: bool = false
var _release_ticket: int = 0

func _ready() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)

	_snapshot = TextureRect.new()
	_snapshot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_snapshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_snapshot.stretch_mode = TextureRect.STRETCH_SCALE
	_snapshot.mouse_filter = Control.MOUSE_FILTER_STOP
	_snapshot.visible = false
	canvas_layer.add_child(_snapshot)

func freeze_screen() -> void:
	if not _is_frozen:
		var image := get_viewport().get_texture().get_image()
		if image.is_empty():
			push_warning("No se pudo capturar la pantalla antes de la transición.")
			return
		_snapshot.texture = ImageTexture.create_from_image(image)
		_snapshot.visible = true
		_is_frozen = true

	_release_ticket += 1
	_release_after_render(_release_ticket)

func change_scene_to_file(scene_path: String) -> Error:
	freeze_screen()
	return get_tree().change_scene_to_file(scene_path)

func _release_after_render(ticket: int) -> void:
	await RenderingServer.frame_post_draw
	if ticket != _release_ticket:
		return

	_snapshot.visible = false
	_snapshot.texture = null
	_is_frozen = false
