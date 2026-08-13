extends Control

const PieceScene := preload("res://scripts/triomino_piece.gd")
const TRAY_TILE_SIZE := Vector2(136.0, 112.0)
const TRAY_TILE_SIDE := 90.0
const MAX_PIECE_NUMBER := 5

@onready var board: TriominoBoard = $Layout/Board
@onready var piece_tray: GridContainer = $Layout/Sidebar/Margin/Content/Scroll/PieceTray
@onready var status_label: Label = $Layout/Sidebar/Margin/Content/Status
@onready var instructions_label: Label = $Layout/Sidebar/Margin/Content/Instructions
@onready var rotate_button: Button = $Layout/Sidebar/Margin/Content/PieceControls/RotateButton
@onready var piece_count_label: Label = $Layout/Sidebar/Margin/Content/Footer/PieceCount
@onready var reset_button: Button = $Layout/Sidebar/Margin/Content/Footer/ResetButton

var tray_pieces: Dictionary = {}
var selected_tray_piece: TriominoPiece
var piece_definitions: Array[Array] = []


func _ready() -> void:
	piece_definitions = generate_complete_set(MAX_PIECE_NUMBER)
	_build_piece_tray()
	board.piece_committed.connect(_on_piece_committed)
	board.placed_count_changed.connect(_on_placed_count_changed)
	board.placement_rejected.connect(_on_placement_rejected)
	rotate_button.pressed.connect(_rotate_selected_piece)
	reset_button.pressed.connect(_on_reset_pressed)


func _build_piece_tray() -> void:
	for piece_id in piece_definitions.size():
		var piece := PieceScene.new() as TriominoPiece
		piece.custom_minimum_size = TRAY_TILE_SIZE
		piece.configure(piece_id, _typed_numbers(piece_definitions[piece_id]), TRAY_TILE_SIDE)
		piece.selected.connect(_on_tray_piece_selected)
		piece_tray.add_child(piece)
		tray_pieces[piece_id] = piece


static func generate_complete_set(max_number: int = MAX_PIECE_NUMBER) -> Array[Array]:
	var complete_set: Array[Array] = []
	for first_number in range(max_number + 1):
		for second_number in range(first_number, max_number + 1):
			for third_number in range(second_number, max_number + 1):
				# Piece arrays follow the drawing vertices: top, bottom-left, bottom-right.
				# The official tile sequence is read clockwise: top, bottom-right, bottom-left.
				complete_set.append([first_number, third_number, second_number])
	return complete_set


func _typed_numbers(source: Array) -> Array[int]:
	var result: Array[int] = []
	for value in source:
		result.append(int(value))
	return result


func _on_tray_piece_selected(piece: TriominoPiece) -> void:
	if selected_tray_piece != null:
		selected_tray_piece.set_selected(false)
	selected_tray_piece = piece
	piece.set_selected(true)
	board.select_piece(piece.piece_id, piece.numbers)
	rotate_button.disabled = false

	if board.placed_pieces.is_empty():
		status_label.text = "First piece selected"
		instructions_label.text = "Rotate with R if needed, then click the board.\nIt will be placed exactly in the center."
	else:
		status_label.text = "Piece selected"
		instructions_label.text = "Rotate with R. Green edges match;\nred edges are blocked."


func _on_piece_committed(piece_id: int) -> void:
	var piece: TriominoPiece = tray_pieces[piece_id]
	piece.set_selected(false)
	piece.set_available(false)
	selected_tray_piece = null
	rotate_button.disabled = true
	status_label.text = "Piece placed"
	instructions_label.text = "Choose another numbered piece. Matching\ncorner numbers are required on every contact."


func _rotate_selected_piece() -> void:
	if selected_tray_piece == null:
		return
	selected_tray_piece.rotate_numbers_clockwise()
	board.select_piece(selected_tray_piece.piece_id, selected_tray_piece.numbers)
	status_label.text = "Piece rotated clockwise"
	if board.placed_pieces.is_empty():
		instructions_label.text = "Press R again or click the board to place it\nexactly in the center."
	else:
		instructions_label.text = "Green edges match this rotation;\nred edges are blocked."


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_rotate_selected_piece()
		get_viewport().set_input_as_handled()


func _on_placement_rejected(reason: String) -> void:
	status_label.text = "Placement blocked"
	instructions_label.text = reason + "\nRotate the piece or choose a green edge."


func _on_placed_count_changed(count: int) -> void:
	piece_count_label.text = "%d piece%s placed" % [count, "" if count == 1 else "s"]


func _on_reset_pressed() -> void:
	board.reset_board()
	selected_tray_piece = null
	rotate_button.disabled = true
	for piece_id in tray_pieces:
		var piece: TriominoPiece = tray_pieces[piece_id]
		piece.configure(piece_id, _typed_numbers(piece_definitions[piece_id]), TRAY_TILE_SIDE)
		piece.set_selected(false)
		piece.set_available(true)
	status_label.text = "Choose your first piece"
	instructions_label.text = "Select a piece below, then click the board.\nThe first piece always lands in the center."
