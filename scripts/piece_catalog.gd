class_name TriominoPieceCatalog
extends RefCounted


static func generate_complete_set(max_number: int = 5) -> Array[Array]:
	var complete_set: Array[Array] = []
	for first_number in range(max_number + 1):
		for second_number in range(first_number, max_number + 1):
			for third_number in range(second_number, max_number + 1):
				# Drawing order: top, bottom-left, bottom-right.
				# Official reading order: top, bottom-right, bottom-left.
				complete_set.append([first_number, third_number, second_number])
	return complete_set


static func typed_numbers(source: Array) -> Array[int]:
	var result: Array[int] = []
	for value in source:
		result.append(int(value))
	return result


static func is_valid_rotation(definition: Array, candidate: Array[int]) -> bool:
	if candidate.size() != 3:
		return false
	var rotated := typed_numbers(definition)
	for rotation_index in 3:
		if candidate == rotated:
			return true
		rotated = [rotated[1], rotated[2], rotated[0]]
	return false
