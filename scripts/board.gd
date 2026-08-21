class_name TriominoBoard
extends Control

signal piece_committed(piece_id: int)
signal placed_count_changed(count: int)
signal placement_rejected(reason: String)
signal placement_requested(piece_id: int, numbers: Array[int], center_offset: Vector2, rotation: float)

const PieceScene := preload("res://scripts/triomino_piece.gd")
const TILE_SIDE := 116.0
const TILE_BOX := Vector2(138.0, 126.0)
const SNAP_RADIUS := 72.0
const TIP_MATCH_TOLERANCE := 3.0
const EDGE_ROTATIONS: Array[float] = [60.0, 180.0, -60.0]
const BOARD_COLOR := Color("#e8f1f2")
const GRID_COLOR := Color("#d2e1e3")
const CENTER_COLOR := Color("#6e9299")
const OPEN_EDGE_COLOR := Color("#639ba5")
const LEGAL_EDGE_COLOR := Color("#36a875")
const INVALID_EDGE_COLOR := Color("#c95668")
const LEGAL_GHOST_COLOR := Color("#dff3e5")
const INVALID_GHOST_COLOR := Color("#f5c9cf")

var selected_piece_id := -1
var selected_numbers: Array[int] = []
var placed_pieces: Array[Dictionary] = []
var _mouse_position := Vector2.ZERO
var _hover_candidate: Dictionary = {}
var _ghost: TriominoPiece


func _ready() -> void:
	clip_contents = true
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
	placed_count_changed.emit(0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_position = event.position
		_update_candidate(_mouse_position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_mouse_position = event.position
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BOARD_COLOR)
	_draw_grid()

	if placed_pieces.is_empty():
		var board_center := size * 0.5
		draw_circle(board_center, 10.0, CENTER_COLOR, false, 2.0, true)
		draw_line(board_center - Vector2(18, 0), board_center + Vector2(18, 0), CENTER_COLOR, 2.0, true)
		draw_line(board_center - Vector2(0, 18), board_center + Vector2(0, 18), CENTER_COLOR, 2.0, true)
	else:
		_draw_open_edges()


func _draw_grid() -> void:
	var spacing := 44.0
	var x := fmod(size.x * 0.5, spacing)
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), GRID_COLOR, 1.0)
		x += spacing
	var y := fmod(size.y * 0.5, spacing)
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID_COLOR, 1.0)
		y += spacing


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
				draw_line(start.lerp(finish, 0.16), start.lerp(finish, 0.84), edge_color, 3.0, true)


func _update_candidate(mouse_position: Vector2) -> void:
	_hover_candidate.clear()
	if selected_piece_id < 0:
		_update_ghost()
		return

	if placed_pieces.is_empty():
		_hover_candidate = {"center": size * 0.5, "rotation": 0.0, "is_legal": true}
	else:
		var best_distance := SNAP_RADIUS
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
	piece.position = candidate.center - TILE_BOX * 0.5
	piece.configure(piece_id, numbers, TILE_SIDE, candidate.rotation)
	add_child(piece)

	placed_pieces.append({
		"node": piece,
		"piece_id": piece_id,
		"numbers": numbers.duplicate(),
		"center": candidate.center,
		"rotation": candidate.rotation
	})
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
	_ghost.position = _hover_candidate.center - TILE_BOX * 0.5
	var ghost_color := LEGAL_GHOST_COLOR if _hover_candidate.is_legal else INVALID_GHOST_COLOR
	_ghost.configure(selected_piece_id, selected_numbers, TILE_SIDE, _hover_candidate.rotation, ghost_color)
	move_child(_ghost, get_child_count() - 1)


func _on_resized() -> void:
	if placed_pieces.is_empty():
		_update_candidate(_mouse_position)
	queue_redraw()
