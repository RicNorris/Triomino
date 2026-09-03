class_name TriominoPiece
extends Control

signal selected(piece: TriominoPiece)

const INK := Color("#34294f")
const OUTLINE := Color("#4b3a61")
const SELECTED_OUTLINE := Color("#fff3a6")
const DISABLED_FILL := Color("#aaa2ad")
const CARD_FILL := Color("#9b4c2d")
const CARD_HOVER := Color("#b95f34")
const PIP_FILL := Color("#fffaf0")
const DEFAULT_FILL := Color("#f4ead8")
const PLAYABLE_COLOR := Color("#2fbd83")
const BLOCKED_COLOR := Color("#ee6572")
const NUMBER_POSITION_RATIO := 0.49
const NUMBER_BUBBLE_RATIO := 0.56
const TILE_COLORS: Array[Color] = [
	Color("#ffd96a"),
	Color("#7cddcb"),
	Color("#ff9d9d"),
	Color("#a6c6ff"),
	Color("#c9a8ef"),
]

var piece_id := -1
var numbers: Array[int] = [0, 0, 0]
var side_length := 108.0
var orientation_degrees := 0.0
var fill_color := Color("#f4ead8")
var is_selected := false
var is_available := true
var preview_alpha := 1.0
var interactive := true
var playability_indicator_visible := false
var can_play_anywhere := false
var _hovered := false
var _motion_tween: Tween


func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(_update_pivot)
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
	playability_indicator_visible = false
	can_play_anywhere = false
	queue_redraw()


func set_selected(value: bool) -> void:
	is_selected = value
	_animate_pose(Vector2(1.075, 1.075) if value else Vector2.ONE, -2.0 if value else 0.0)
	queue_redraw()


func set_available(value: bool) -> void:
	is_available = value
	mouse_filter = Control.MOUSE_FILTER_STOP if value and interactive else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value and interactive else Control.CURSOR_ARROW
	queue_redraw()


func set_display_size(box_size: Vector2, new_side_length: float) -> void:
	custom_minimum_size = box_size
	side_length = new_side_length
	queue_redraw()


func set_playability_indicator(show_indicator: bool, playable: bool) -> void:
	if playability_indicator_visible == show_indicator and can_play_anywhere == playable:
		return
	playability_indicator_visible = show_indicator
	can_play_anywhere = playable
	tooltip_text = (
		"Playable somewhere on the board"
		if show_indicator and playable
		else "No legal placement in any rotation" if show_indicator else ""
	)
	queue_redraw()


func rotate_numbers_clockwise() -> void:
	if numbers.size() != 3:
		return
	numbers = [numbers[1], numbers[2], numbers[0]]
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
	var actual_fill := _playful_fill() if is_available else DISABLED_FILL
	actual_fill.a = preview_alpha if is_available else 0.35
	if interactive:
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = CARD_HOVER if _hovered and is_available else CARD_FILL
		card_style.border_color = SELECTED_OUTLINE if is_selected else Color("#67331f")
		card_style.set_border_width_all(4 if is_selected else 2)
		card_style.set_corner_radius_all(15)
		card_style.shadow_color = Color(0.01, 0.03, 0.035, 0.34)
		card_style.shadow_size = 8 if is_selected else 4
		card_style.shadow_offset = Vector2(0, 5)
		draw_style_box(card_style, Rect2(Vector2(3, 3), size - Vector2(6, 7)))

	var shadow_vertices := PackedVector2Array()
	for vertex in vertices:
		shadow_vertices.append(vertex + Vector2(0, 3))
	var tile_shadow := Color(0.015, 0.04, 0.05, 0.28 * preview_alpha)
	draw_colored_polygon(shadow_vertices, tile_shadow)

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
		var label_position: Vector2 = center.lerp(vertices[index], NUMBER_POSITION_RATIO)
		var text := str(numbers[index])
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var baseline := label_position + Vector2(-text_size.x * 0.5, text_size.y * 0.32)
		var text_color := INK
		text_color.a = preview_alpha if is_available else 0.4
		var pip_fill := PIP_FILL
		pip_fill.a = 0.74 * preview_alpha if is_available else 0.22
		draw_circle(label_position, font_size * NUMBER_BUBBLE_RATIO, pip_fill)
		draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

	var pip_color := OUTLINE
	pip_color.a = 0.35 * preview_alpha
	draw_circle(center, 3.0, pip_color)
	if interactive:
		var points_copy := "%d pts" % (numbers[0] + numbers[1] + numbers[2])
		var points_size := font.get_string_size(points_copy, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		var points_pos := Vector2(size.x - points_size.x - 10, size.y - 9)
		var points_color := Color("#ffe5bd")
		points_color.a = 0.9 if is_available else 0.35
		draw_string(font, points_pos, points_copy, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, points_color)
		_draw_playability_indicator()


func _draw_playability_indicator() -> void:
	if not playability_indicator_visible:
		return
	var indicator_center := Vector2(size.x - 16.0, 16.0)
	var indicator_color := PLAYABLE_COLOR if can_play_anywhere else BLOCKED_COLOR
	draw_circle(indicator_center, 10.0, Color(0.12, 0.09, 0.18, 0.72))
	draw_circle(indicator_center, 8.0, indicator_color)
	if can_play_anywhere:
		draw_line(indicator_center + Vector2(-4.0, 0.0), indicator_center + Vector2(-1.0, 3.0), Color.WHITE, 2.2, true)
		draw_line(indicator_center + Vector2(-1.0, 3.0), indicator_center + Vector2(4.5, -3.5), Color.WHITE, 2.2, true)
	else:
		draw_line(indicator_center + Vector2(-3.5, -3.5), indicator_center + Vector2(3.5, 3.5), Color.WHITE, 2.2, true)
		draw_line(indicator_center + Vector2(3.5, -3.5), indicator_center + Vector2(-3.5, 3.5), Color.WHITE, 2.2, true)


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
	z_index = 20
	var tilt := -2.5 if piece_id % 2 == 0 else 2.5
	_animate_pose(Vector2(1.09, 1.09), tilt)
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	z_index = 10 if is_selected else 0
	_animate_pose(Vector2(1.075, 1.075) if is_selected else Vector2.ONE, -2.0 if is_selected else 0.0)
	queue_redraw()


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _animate_pose(target_scale: Vector2, target_rotation: float) -> void:
	if not is_inside_tree() or not interactive:
		return
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", target_scale, 0.18)
	_motion_tween.tween_property(self, "rotation_degrees", target_rotation, 0.18)


func _playful_fill() -> Color:
	if fill_color.is_equal_approx(DEFAULT_FILL):
		return TILE_COLORS[absi(piece_id) % TILE_COLORS.size()]
	return fill_color
