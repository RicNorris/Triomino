class_name TriominoPiece
extends Control

signal selected(piece: TriominoPiece)

const INK := Color("#13212c")
const OUTLINE := Color("#192b37")
const SELECTED_OUTLINE := Color("#f6b73c")
const DISABLED_FILL := Color("#7c8991")

var piece_id := -1
var numbers: Array[int] = [0, 0, 0]
var side_length := 108.0
var orientation_degrees := 0.0
var fill_color := Color("#f4ead8")
var is_selected := false
var is_available := true
var preview_alpha := 1.0
var interactive := true
var _hovered := false


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	queue_redraw()


func configure(
	new_id: int,
	new_numbers: Array[int],
	new_side_length: float = 108.0,
	new_orientation: float = 0.0,
	new_fill: Color = Color("#f4ead8")
) -> void:
	piece_id = new_id
	numbers = new_numbers.duplicate()
	side_length = new_side_length
	orientation_degrees = new_orientation
	fill_color = new_fill
	queue_redraw()


func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()


func set_available(value: bool) -> void:
	is_available = value
	mouse_filter = Control.MOUSE_FILTER_STOP if value and interactive else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value and interactive else Control.CURSOR_ARROW
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not interactive or not is_available:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(self)
		accept_event()


func _draw() -> void:
	var center := size * 0.5
	var vertices := get_triangle_vertices(center, side_length, orientation_degrees)
	var actual_fill := fill_color if is_available else DISABLED_FILL
	actual_fill.a = preview_alpha if is_available else 0.35

	draw_colored_polygon(PackedVector2Array(vertices), actual_fill)
	var outline_color := SELECTED_OUTLINE if is_selected else OUTLINE
	if _hovered and is_available and not is_selected:
		outline_color = outline_color.lightened(0.22)
	outline_color.a = preview_alpha
	var closed := PackedVector2Array([vertices[0], vertices[1], vertices[2], vertices[0]])
	draw_polyline(closed, outline_color, 5.0 if is_selected else 3.0, true)

	var font := ThemeDB.fallback_font
	var font_size := int(clamp(side_length * 0.20, 16.0, 25.0))
	for index in 3:
		var label_position: Vector2 = center.lerp(vertices[index], 0.57)
		var text := str(numbers[index])
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var baseline := label_position + Vector2(-text_size.x * 0.5, text_size.y * 0.32)
		var text_color := INK
		text_color.a = preview_alpha if is_available else 0.4
		draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

	var pip_color := OUTLINE
	pip_color.a = 0.35 * preview_alpha
	draw_circle(center, 3.0, pip_color)


static func get_triangle_vertices(center: Vector2, side: float, degrees: float) -> Array[Vector2]:
	var radius := side / sqrt(3.0)
	var rotation := deg_to_rad(degrees)
	var vertices: Array[Vector2] = []
	for base_degrees in [-90.0, 150.0, 30.0]:
		var angle := deg_to_rad(base_degrees) + rotation
		vertices.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return vertices


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()
