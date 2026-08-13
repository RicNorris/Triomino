extends Control

const PieceScene := preload("res://scripts/triomino_piece.gd")
const TRAY_TILE_SIZE := Vector2(136.0, 112.0)
const TRAY_TILE_SIDE := 90.0

const STARTING_PIECES: Array[Array] = [
	[0, 0, 0], [0, 0, 1], [0, 1, 1], [1, 1, 1],
	[0, 1, 2], [1, 2, 2], [2, 2, 2], [0, 2, 3],
	[1, 3, 4], [2, 4, 5], [3, 5, 5], [4, 5, 5]
]

@onready var board: TriominoBoard = $Layout/Board
@onready var piece_tray: GridContainer = $Layout/Sidebar/Margin/Content/Scroll/PieceTray
@onready var status_label: Label = $Layout/Sidebar/Margin/Content/Status
@onready var instructions_label: Label = $Layout/Sidebar/Margin/Content/Instructions
@onready var piece_count_label: Label = $Layout/Sidebar/Margin/Content/Footer/PieceCount
@onready var reset_button: Button = $Layout/Sidebar/Margin/Content/Footer/ResetButton

var tray_pieces: Dictionary = {}
var selected_tray_piece: TriominoPiece


func _ready() -> void:
	_build_piece_tray()
	board.piece_committed.connect(_on_piece_committed)
	board.placed_count_changed.connect(_on_placed_count_changed)
	reset_button.pressed.connect(_on_reset_pressed)


func _build_piece_tray() -> void:
	for piece_id in STARTING_PIECES.size():
		var piece := PieceScene.new() as TriominoPiece
		piece.custom_minimum_size = TRAY_TILE_SIZE
		piece.configure(piece_id, _typed_numbers(STARTING_PIECES[piece_id]), TRAY_TILE_SIDE)
		piece.selected.connect(_on_tray_piece_selected)
		piece_tray.add_child(piece)
		tray_pieces[piece_id] = piece


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

	if board.placed_pieces.is_empty():
		status_label.text = "First piece selected"
		instructions_label.text = "Click anywhere on the board.\nIt will be placed exactly in the center."
	else:
		status_label.text = "Piece selected"
		instructions_label.text = "Hover near a glowing open edge,\nthen click to attach the piece."


func _on_piece_committed(piece_id: int) -> void:
	var piece: TriominoPiece = tray_pieces[piece_id]
	piece.set_selected(false)
	piece.set_available(false)
	selected_tray_piece = null
	status_label.text = "Piece placed"
	instructions_label.text = "Choose another numbered piece, then\nattach it to any glowing open edge."


func _on_placed_count_changed(count: int) -> void:
	piece_count_label.text = "%d piece%s placed" % [count, "" if count == 1 else "s"]


func _on_reset_pressed() -> void:
	board.reset_board()
	selected_tray_piece = null
	for piece: TriominoPiece in tray_pieces.values():
		piece.set_selected(false)
		piece.set_available(true)
	status_label.text = "Choose your first piece"
	instructions_label.text = "Select a piece below, then click the board.\nThe first piece always lands in the center."
