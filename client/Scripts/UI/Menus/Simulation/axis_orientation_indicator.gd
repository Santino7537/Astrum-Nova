extends Control

const AXIS_LENGTH := 34.0
const ARROW_LENGTH := 8.0
const X_COLOR := Color(0.94, 0.32, 0.34)
const Y_COLOR := Color(0.38, 0.82, 0.48)
const Z_COLOR := Color(0.34, 0.61, 0.98)

var _camera_basis: Basis = Basis.IDENTITY

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	var active_camera := get_viewport().get_camera_3d()
	if active_camera != null:
		_camera_basis = active_camera.global_transform.basis.orthonormalized()
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.47
	draw_circle(center, radius, Color(0.04, 0.07, 0.12, 0.78))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.4, 0.6, 0.85, 0.5), 1.0, true)

	_draw_axis(center, Vector3.RIGHT, "X", X_COLOR)
	_draw_axis(center, Vector3.UP, "Y", Y_COLOR)
	_draw_axis(center, Vector3.BACK, "Z", Z_COLOR)

func _draw_axis(center: Vector2, axis: Vector3, label: String, color: Color) -> void:
	var projected_axis := Vector2(
		axis.dot(_camera_basis.x),
		-axis.dot(_camera_basis.y)
	)
	var endpoint := center + projected_axis * AXIS_LENGTH
	draw_line(center, endpoint, color, 3.0, true)

	if projected_axis.length_squared() < 0.01:
		draw_circle(center, 3.5, color)
		draw_string(ThemeDB.fallback_font, center + Vector2(6.0, -5.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		return

	var direction := projected_axis.normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var arrow_base := endpoint - direction * ARROW_LENGTH
	var arrow_points := PackedVector2Array([
		endpoint,
		arrow_base + perpendicular * 4.0,
		arrow_base - perpendicular * 4.0,
	])
	draw_colored_polygon(arrow_points, color)
	draw_string(ThemeDB.fallback_font, endpoint + direction * 9.0 + Vector2(-4.0, 5.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
