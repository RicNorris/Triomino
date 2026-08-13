extends SceneTree

var _failures := 0


func _init() -> void:
	var board := TriominoBoard.new()
	var placed := {
		"center": Vector2(300.0, 300.0),
		"rotation": 0.0,
		"numbers": [1, 2, 3]
	}
	board.placed_pieces.append(placed)

	var matching_numbers: Array[Array] = [
		[1, 4, 2],
		[4, 3, 2],
		[1, 3, 4]
	]
	var mismatched_corner_indices: Array[int] = [0, 1, 0]
	for edge_index in 3:
		var candidate := board._candidate_across_edge(placed, edge_index)
		var legal := _typed_numbers(matching_numbers[edge_index])
		_expect(board._candidate_is_legal(candidate, legal), "Edge %d should accept matching numbers" % edge_index)
		var mismatch_index := mismatched_corner_indices[edge_index]
		legal[mismatch_index] = 9 if legal[mismatch_index] != 9 else 8
		_expect(not board._candidate_is_legal(candidate, legal), "Edge %d should reject a mismatch" % edge_index)

	_test_single_tip_contact(board)
	board.free()
	if _failures == 0:
		print("Placement rule smoke tests passed.")
		quit()
	else:
		printerr("%d placement rule smoke test(s) failed." % _failures)
		quit(1)


func _test_single_tip_contact(board: TriominoBoard) -> void:
	board.placed_pieces.clear()
	var candidate := {"center": Vector2(500.0, 500.0), "rotation": 0.0}
	var candidate_vertices := TriominoPiece.get_triangle_vertices(candidate.center, board.TILE_SIDE, candidate.rotation)
	var placed_local_vertices := TriominoPiece.get_triangle_vertices(Vector2.ZERO, board.TILE_SIDE, 0.0)
	var tip_piece := {
		"center": candidate_vertices[0] - placed_local_vertices[1],
		"rotation": 0.0,
		"numbers": [7, 5, 8]
	}
	board.placed_pieces.append(tip_piece)
	_expect(board._candidate_is_legal(candidate, [5, 1, 2]), "Equal touching tips should be legal")
	_expect(not board._candidate_is_legal(candidate, [6, 1, 2]), "Unequal touching tips should be rejected")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)


func _typed_numbers(source: Array) -> Array[int]:
	var result: Array[int] = []
	for value in source:
		result.append(int(value))
	return result
