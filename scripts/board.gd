class_name TriominoBoard
extends Control

signal piece_committed(piece_id: int)
signal placed_count_changed(count: int)
signal placement_rejected(reason: String)
signal placement_requested(piece_id: int, numbers: Array[int], center_offset: Vector2, rotation: float)
signal view_changed(zoom_percent: int)

const PieceScene := preload("res://scripts/triomino_piece.gd")
const TILE_SIDE := 116.0
const TILE_BOX := Vector2(138.0, 126.0)
const SNAP_RADIUS := 72.0
const TIP_MATCH_TOLERANCE := 3.0
const EDGE_ROTATIONS: Array[float] = [60.0, 180.0, -60.0]
const BOARD_COLOR := Color("#fff8df")
const GRID_COLOR := Color("#ded2e9")
const CENTER_COLOR := Color("#6256b3")
const OPEN_EDGE_COLOR := Color("#7c8ed6")
const LEGAL_EDGE_COLOR := Color("#2fbd83")
const INVALID_EDGE_COLOR := Color("#ee6572")
const LEGAL_GHOST_COLOR := Color("#a7ebc5")
const INVALID_GHOST_COLOR := Color("#ffc1c7")
const PLAYMAT_CORNER_RADIUS := 23.0
const MIN_ZOOM := 0.45
const MAX_ZOOM := 1.8
const ZOOM_STEP := 1.14

var selected_piece_id := -1
var selected_numbers: Array[int] = []
var placed_pieces: Array[Dictionary] = []
var _mouse_position := Vector2.ZERO
var _last_screen_mouse := Vector2.ZERO
var _hover_candidate: Dictionary = {}
var _ghost: TriominoPiece
var _last_size := Vector2.ZERO
var _view_zoom := 1.0
var _view_offset := Vector2.ZERO
var _is_panning := false


func _ready() -> void:
	clip_contents = true
	_last_size = size
	resized.connect(_on_resized)
	_create_ghost()
	queue_redraw()


func select_piece(piece_id: int, numbers: Array[int]) -> void:
	selected_piece_id = piece_id
	selected_numbers = numbers.duplicate()
	_update_candidate(_mouse_position)
	queue_redraw()


func clear_selection() -> void:
	selected_piece_id = -1
	selected_numbers.clear()
	_hover_candidate.clear()
	_update_ghost()
	queue_redraw()


func reset_board() -> void:
	for placed in placed_pieces:
		var node: TriominoPiece = placed.node
		node.queue_free()
	placed_pieces.clear()
	clear_selection()
	reset_view()
	placed_count_changed.emit(0)
	queue_redraw()


func zoom_in() -> void:
	_zoom_at(size * 0.5, _view_zoom * ZOOM_STEP)


func zoom_out() -> void:
	_zoom_at(size * 0.5, _view_zoom / ZOOM_STEP)


func reset_view() -> void:
	#_view_zoom = 1.0
	_view_offset = Vector2.ZERO
	_apply_view_transform()
	view_changed.emit(get_zoom_percent())
	queue_redraw()


func get_zoom_percent() -> int:
	return int(round(_view_zoom * 100.0))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_last_screen_mouse = event.position
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, _view_zoom * ZOOM_STEP)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, _view_zoom / ZOOM_STEP)
			accept_event()
			return
		if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			_is_panning = event.pressed
			mouse_default_cursor_shape = Control.CURSOR_DRAG if _is_panning else Control.CURSOR_CROSS
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_mouse_position = _screen_to_world(event.position)
			_update_candidate(_mouse_position)
			if selected_piece_id >= 0 and not _hover_candidate.is_empty():
				if _hover_candidate.is_legal:
					placement_requested.emit(
						selected_piece_id,
						selected_numbers.duplicate(),
						_hover_candidate.center - size * 0.5,
						_hover_candidate.rotation
					)
				else:
					placement_rejected.emit("The touching corner numbers must match.")
				accept_event()
	elif event is InputEventMouseMotion:
		_last_screen_mouse = event.position
		if _is_panning:
			_view_offset += event.relative
			_apply_view_transform()
			queue_redraw()
			accept_event()
			return
		_mouse_position = _screen_to_world(event.position)
		_update_candidate(_mouse_position)


func _draw() -> void:
	var playmat_style := StyleBoxFlat.new()
	playmat_style.bg_color = BOARD_COLOR
	playmat_style.set_corner_radius_all(int(PLAYMAT_CORNER_RADIUS))
	playmat_style.anti_aliasing = true
	draw_style_box(playmat_style, Rect2(Vector2.ZERO, size))
	_draw_grid()
	_draw_doodles()
	draw_set_transform(_view_offset + size * 0.5 * (Vector2.ONE - Vector2(_view_zoom, _view_zoom)), 0.0, Vector2(_view_zoom, _view_zoom))

	if placed_pieces.is_empty():
		var board_center := size * 0.5
		draw_circle(board_center, 34.0, Color("#fff0a8"))
		draw_circle(board_center, 25.0, Color("#ff9d9d"), false, 5.0, true)
		draw_circle(board_center, 12.0, CENTER_COLOR, false, 3.0, true)
		draw_line(board_center - Vector2(21, 0), board_center + Vector2(21, 0), CENTER_COLOR, 3.0, true)
		draw_line(board_center - Vector2(0, 21), board_center + Vector2(0, 21), CENTER_COLOR, 3.0, true)
		var hint := "DROP YOUR FIRST TILE HERE!"
		var font := ThemeDB.fallback_font
		var hint_size := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		draw_string(font, board_center + Vector2(-hint_size.x * 0.5, 58), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CENTER_COLOR)
	else:
		_draw_open_edges()


func _draw_grid() -> void:
	var spacing := 36.0
	var x := fmod(size.x * 0.5, spacing)
	while x < size.x:
		var y := fmod(size.y * 0.5, spacing)
		while y < size.y:
			if not _point_inside_rounded_playmat(Vector2(x, y)):
				y += spacing
				continue
			var grid_index := int(x / spacing) + int(y / spacing)
			var dot_color := Color("#e8bfc9") if grid_index % 5 == 0 else GRID_COLOR
			draw_circle(Vector2(x, y), 1.65 if grid_index % 5 == 0 else 1.15, dot_color)
			y += spacing
		x += spacing


func _point_inside_rounded_playmat(point: Vector2) -> bool:
	var nearest := Vector2(
		clampf(point.x, PLAYMAT_CORNER_RADIUS, size.x - PLAYMAT_CORNER_RADIUS),
		clampf(point.y, PLAYMAT_CORNER_RADIUS, size.y - PLAYMAT_CORNER_RADIUS)
	)
	return point.distance_squared_to(nearest) <= PLAYMAT_CORNER_RADIUS * PLAYMAT_CORNER_RADIUS


func _draw_doodles() -> void:
	var yellow := Color(1.0, 0.76, 0.2, 0.6)
	var pink := Color(1.0, 0.43, 0.51, 0.48)
	var purple := Color(0.39, 0.34, 0.7, 0.4)
	var mint := Color(0.2, 0.72, 0.58, 0.45)
	var sun_center := Vector2(42, 42)
	draw_circle(sun_center, 10, yellow, false, 3, true)
	for spoke in 8:
		var direction := Vector2.from_angle(float(spoke) * TAU / 8.0)
		draw_line(sun_center + direction * 15, sun_center + direction * 22, yellow, 3, true)
	draw_circle(Vector2(size.x - 46, 39), 14, pink, false, 4, true)
	draw_circle(Vector2(size.x - 46, 39), 4, pink)
	var triangle := PackedVector2Array([
		Vector2(38, size.y - 30),
		Vector2(53, size.y - 55),
		Vector2(68, size.y - 30),
		Vector2(38, size.y - 30),
	])
	draw_polyline(triangle, mint, 4, true)
	var wave := PackedVector2Array()
	for wave_step in 7:
		wave.append(Vector2(size.x - 105 + wave_step * 12, size.y - 40 + sin(float(wave_step) * 1.7) * 7))
	draw_polyline(wave, purple, 4, true)


func _draw_open_edges() -> void:
	for placed in placed_pieces:
		var vertices := TriominoPiece.get_triangle_vertices(placed.center, TILE_SIDE, placed.rotation)
		for edge_index in 3:
			var candidate := _candidate_across_edge(placed, edge_index)
			if _position_is_free(candidate.center):
				var start: Vector2 = vertices[edge_index]
				var finish: Vector2 = vertices[(edge_index + 1) % 3]
				var edge_color := OPEN_EDGE_COLOR
				if selected_piece_id >= 0:
					edge_color = LEGAL_EDGE_COLOR if _candidate_is_legal(candidate, selected_numbers) else INVALID_EDGE_COLOR
				var edge_start := start.lerp(finish, 0.16)
				var edge_finish := start.lerp(finish, 0.84)
				draw_line(edge_start, edge_finish, edge_color, 5.0, true)
				draw_circle(edge_start, 2.5, edge_color)
				draw_circle(edge_finish, 2.5, edge_color)


func _update_candidate(mouse_position: Vector2) -> void:
	_hover_candidate.clear()
	if selected_piece_id < 0:
		_update_ghost()
		return

	if placed_pieces.is_empty():
		_hover_candidate = {"center": size * 0.5, "rotation": 0.0, "is_legal": true}
	else:
		var best_distance := SNAP_RADIUS / _view_zoom
		for placed in placed_pieces:
			for edge_index in 3:
				var candidate := _candidate_across_edge(placed, edge_index)
				if not _position_is_free(candidate.center):
					continue
				var distance := mouse_position.distance_to(candidate.center)
				if distance < best_distance:
					best_distance = distance
					candidate["is_legal"] = _candidate_is_legal(candidate, selected_numbers)
					_hover_candidate = candidate
	_update_ghost()
	queue_redraw()


func _candidate_across_edge(placed: Dictionary, edge_index: int) -> Dictionary:
	var vertices := TriominoPiece.get_triangle_vertices(placed.center, TILE_SIDE, placed.rotation)
	var edge_midpoint: Vector2 = (vertices[edge_index] + vertices[(edge_index + 1) % 3]) * 0.5
	return {
		"center": edge_midpoint * 2.0 - placed.center,
		"rotation": fmod(placed.rotation + EDGE_ROTATIONS[edge_index] + 360.0, 360.0)
	}


func _position_is_free(candidate_center: Vector2) -> bool:
	for placed in placed_pieces:
		if candidate_center.distance_to(placed.center) < 5.0:
			return false
	return true


func _candidate_is_legal(candidate: Dictionary, candidate_numbers: Array[int]) -> bool:
	var candidate_vertices := TriominoPiece.get_triangle_vertices(
		candidate.center,
		TILE_SIDE,
		candidate.rotation
	)
	for placed in placed_pieces:
		var placed_vertices := TriominoPiece.get_triangle_vertices(
			placed.center,
			TILE_SIDE,
			placed.rotation
		)
		for candidate_index in 3:
			for placed_index in 3:
				if candidate_vertices[candidate_index].distance_to(placed_vertices[placed_index]) <= TIP_MATCH_TOLERANCE:
					if candidate_numbers[candidate_index] != placed.numbers[placed_index]:
						return false
	return true


func can_place_numbers_anywhere(piece_numbers: Array[int]) -> bool:
	if piece_numbers.size() != 3:
		return false
	if placed_pieces.is_empty():
		return true
	var rotated_numbers: Array[int] = piece_numbers.duplicate()
	for number_rotation in 3:
		for placed in placed_pieces:
			for edge_index in 3:
				var candidate := _candidate_across_edge(placed, edge_index)
				if not _position_is_free(candidate.center):
					continue
				if _candidate_is_legal(candidate, rotated_numbers):
					return true
		rotated_numbers = [rotated_numbers[1], rotated_numbers[2], rotated_numbers[0]]
	return false


func is_network_placement_legal(center_offset: Vector2, rotation: float, numbers: Array[int]) -> bool:
	var requested_center := size * 0.5 + center_offset
	if placed_pieces.is_empty():
		return requested_center.distance_to(size * 0.5) <= TIP_MATCH_TOLERANCE \
			and absf(angle_difference(deg_to_rad(rotation), 0.0)) <= 0.001

	for placed in placed_pieces:
		for edge_index in 3:
			var candidate := _candidate_across_edge(placed, edge_index)
			if candidate.center.distance_to(requested_center) > TIP_MATCH_TOLERANCE:
				continue
			if absf(angle_difference(deg_to_rad(candidate.rotation), deg_to_rad(rotation))) > 0.001:
				continue
			return _position_is_free(candidate.center) and _candidate_is_legal(candidate, numbers)
	return false


func get_placement_features(center_offset: Vector2, rotation: float) -> Dictionary:
	var candidate_vertices := TriominoPiece.get_triangle_vertices(
		size * 0.5 + center_offset,
		TILE_SIDE,
		rotation
	)
	var touching_corner_count := 0
	var completed_hexagons := 0

	for candidate_vertex in candidate_vertices:
		var triangles_already_at_corner := 0
		for placed in placed_pieces:
			var placed_vertices := TriominoPiece.get_triangle_vertices(
				placed.center,
				TILE_SIDE,
				placed.rotation
			)
			for placed_vertex in placed_vertices:
				if candidate_vertex.distance_to(placed_vertex) <= TIP_MATCH_TOLERANCE:
					triangles_already_at_corner += 1
					break
		if triangles_already_at_corner > 0:
			touching_corner_count += 1
		if triangles_already_at_corner == 5:
			completed_hexagons += 1

	return {
		"touching_corners": touching_corner_count,
		"hexagons": completed_hexagons,
		"bridge": touching_corner_count == 3 and completed_hexagons == 0
	}


func commit_network_piece(
	piece_id: int,
	numbers: Array[int],
	center_offset: Vector2,
	rotation: float
) -> void:
	var candidate := {
		"center": size * 0.5 + center_offset,
		"rotation": rotation,
		"is_legal": true
	}
	_place_piece(piece_id, numbers, candidate)


func _place_piece(piece_id: int, numbers: Array[int], candidate: Dictionary) -> void:
	var piece := PieceScene.new() as TriominoPiece
	piece.interactive = false
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece.custom_minimum_size = TILE_BOX
	piece.size = TILE_BOX
	piece.configure(piece_id, numbers, TILE_SIDE, candidate.rotation)
	add_child(piece)
	if piece.is_inside_tree():
		piece.pivot_offset = piece.size * 0.5
		piece.scale = Vector2(0.28, 0.28)
		piece.rotation_degrees = -12.0 if piece_id % 2 == 0 else 12.0
		piece.modulate.a = 0.0
		var drop_tween := piece.create_tween().set_parallel(true)
		drop_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		drop_tween.tween_property(piece, "scale", Vector2.ONE, 0.42)
		drop_tween.tween_property(piece, "rotation_degrees", 0.0, 0.42)
		drop_tween.tween_property(piece, "modulate:a", 1.0, 0.24)

	placed_pieces.append({
		"node": piece,
		"piece_id": piece_id,
		"numbers": numbers.duplicate(),
		"center": candidate.center,
		"rotation": candidate.rotation
	})
	_update_piece_transform(piece, candidate.center)
	clear_selection()
	piece_committed.emit(piece_id)
	placed_count_changed.emit(placed_pieces.size())
	queue_redraw()


func _create_ghost() -> void:
	_ghost = PieceScene.new() as TriominoPiece
	_ghost.interactive = false
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.preview_alpha = 0.48
	_ghost.custom_minimum_size = TILE_BOX
	_ghost.size = TILE_BOX
	_ghost.visible = false
	add_child(_ghost)


func _update_ghost() -> void:
	if selected_piece_id < 0 or _hover_candidate.is_empty():
		_ghost.visible = false
		return
	_ghost.visible = true
	var ghost_color := LEGAL_GHOST_COLOR if _hover_candidate.is_legal else INVALID_GHOST_COLOR
	_ghost.configure(selected_piece_id, selected_numbers, TILE_SIDE, _hover_candidate.rotation, ghost_color)
	_update_piece_transform(_ghost, _hover_candidate.center)
	move_child(_ghost, get_child_count() - 1)


func _on_resized() -> void:
	var center_shift := (size - _last_size) * 0.5
	if not placed_pieces.is_empty() and not center_shift.is_zero_approx():
		for placed in placed_pieces:
			var old_center: Vector2 = placed.center
			placed.center = old_center + center_shift
	_last_size = size
	_apply_view_transform()
	_mouse_position = _screen_to_world(_last_screen_mouse)
	_update_candidate(_mouse_position)
	queue_redraw()


func _zoom_at(screen_point: Vector2, requested_zoom: float) -> void:
	var world_point := _screen_to_world(screen_point)
	_view_zoom = clampf(requested_zoom, MIN_ZOOM, MAX_ZOOM)
	_view_offset = screen_point - size * 0.5 - (world_point - size * 0.5) * _view_zoom
	_apply_view_transform()
	_mouse_position = _screen_to_world(screen_point)
	_update_candidate(_mouse_position)
	view_changed.emit(get_zoom_percent())
	queue_redraw()


func _world_to_screen(world_point: Vector2) -> Vector2:
	return size * 0.5 + _view_offset + (world_point - size * 0.5) * _view_zoom


func _screen_to_world(screen_point: Vector2) -> Vector2:
	return size * 0.5 + (screen_point - size * 0.5 - _view_offset) / _view_zoom


func _apply_view_transform() -> void:
	for placed in placed_pieces:
		var placed_node: TriominoPiece = placed.node
		_update_piece_transform(placed_node, placed.center)
	if _ghost != null and not _hover_candidate.is_empty():
		_update_piece_transform(_ghost, _hover_candidate.center)


func _update_piece_transform(piece: TriominoPiece, world_center: Vector2) -> void:
	piece.pivot_offset = TILE_BOX * 0.5
	piece.position = _world_to_screen(world_center) - TILE_BOX * 0.5
	piece.scale = Vector2(_view_zoom, _view_zoom)
