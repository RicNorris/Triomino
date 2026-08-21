class_name TriominoScoring
extends RefCounted

const BRIDGE_BONUS := 40
const HEXAGON_BONUSES := {1: 50, 2: 60, 3: 70}


func tile_value(piece_numbers: Array[int]) -> int:
	var points := 0
	for number in piece_numbers:
		points += number
	return points


func placement_score(piece_numbers: Array[int], board_features: Dictionary) -> Dictionary:
	var tile_points := tile_value(piece_numbers)
	var bonus := 0
	var bonus_label := ""
	var hexagon_count := int(board_features.get("hexagons", 0))
	if hexagon_count > 0:
		bonus = int(HEXAGON_BONUSES.get(hexagon_count, 0))
		bonus_label = ["", "hexagon", "double hexagon", "triple hexagon"][hexagon_count]
	elif board_features.get("bridge", false):
		bonus = BRIDGE_BONUS
		bonus_label = "bridge"
	return {
		"tile_points": tile_points,
		"bonus": bonus,
		"bonus_label": bonus_label,
		"total": tile_points + bonus,
		"bridge": bool(board_features.get("bridge", false)),
		"hexagons": hexagon_count
	}
