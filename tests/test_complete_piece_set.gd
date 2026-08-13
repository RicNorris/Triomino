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
		var clockwise_numbers := [piece[0], piece[2], piece[1]]
		_expect(clockwise_numbers[0] >= 0 and clockwise_numbers[2] <= 5, "Every number must be between 0 and 5")
		_expect(
			clockwise_numbers[0] <= clockwise_numbers[1] and clockwise_numbers[1] <= clockwise_numbers[2],
			"Numbers must increase clockwise from the lowest corner"
		)
		unique_pieces["%d-%d-%d" % clockwise_numbers] = true

	_expect(unique_pieces.size() == 56, "The complete set must not contain duplicates")
	_expect(pieces.has([1, 5, 3]), "The 1-3-5 tile must use the official clockwise handedness")
	_expect(not pieces.has([1, 3, 5]), "The mirrored 1-5-3 tile must not be included")
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
