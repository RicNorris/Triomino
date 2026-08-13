extends SceneTree

const MainScript := preload("res://scripts/main.gd")

var _failures := 0


func _init() -> void:
	var pieces: Array[Array] = MainScript.generate_complete_set(5)
	_expect(pieces.size() == 56, "A double-six set must contain 56 pieces")

	var unique_pieces: Dictionary = {}
	for piece in pieces:
		_expect(piece.size() == 3, "Every piece must contain three numbers")
		if piece.size() != 3:
			continue
		_expect(piece[0] >= 0 and piece[2] <= 5, "Every number must be between 0 and 5")
		_expect(piece[0] <= piece[1] and piece[1] <= piece[2], "Piece definitions must be ordered")
		unique_pieces["%d-%d-%d" % piece] = true

	_expect(unique_pieces.size() == 56, "The complete set must not contain duplicates")
	for first_number in range(6):
		for second_number in range(first_number, 6):
			for third_number in range(second_number, 6):
				var key := "%d-%d-%d" % [first_number, second_number, third_number]
				_expect(unique_pieces.has(key), "Missing piece " + key)

	if _failures == 0:
		print("Complete 56-piece set tests passed.")
		quit()
	else:
		printerr("%d complete-set test(s) failed." % _failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)
