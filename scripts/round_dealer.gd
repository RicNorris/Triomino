class_name TriominoRoundDealer
extends RefCounted

var piece_well: Array[int] = []
var pieces_per_player := 7
var rng_seed := -1


func configure_for_player_count(player_count: int) -> void:
	pieces_per_player = 9 if player_count == 2 else 7


func deal(piece_count: int, player_order: Array[int]) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	var shuffled_piece_ids: Array[int] = []
	for piece_id in piece_count:
		shuffled_piece_ids.append(piece_id)
	_shuffle_ids(shuffled_piece_ids, rng)

	var generated_trays: Dictionary = {}
	var next_piece_index := 0
	for peer_id in player_order:
		var remaining_count := shuffled_piece_ids.size() - next_piece_index
		var deal_count := mini(pieces_per_player, maxi(remaining_count, 0))
		var tray_ids: Array[int] = []
		for offset in deal_count:
			tray_ids.append(shuffled_piece_ids[next_piece_index + offset])
		next_piece_index += deal_count
		generated_trays[peer_id] = tray_ids

	piece_well = shuffled_piece_ids.slice(next_piece_index)
	return generated_trays


func clear() -> void:
	piece_well.clear()

func has_pieces_in_well() -> bool:
	return !piece_well.is_empty()
	
func draw_piece_from_well() -> int:
	if piece_well.is_empty():
		return -1
	var piece_to_return: int = piece_well[0]
	piece_well.remove_at(0)
	return piece_to_return
	

func _shuffle_ids(piece_ids: Array[int], rng: RandomNumberGenerator) -> void:
	for index in piece_ids.size():
		var swap_index := rng.randi_range(index, piece_ids.size() - 1)
		var temporary_id := piece_ids[index]
		piece_ids[index] = piece_ids[swap_index]
		piece_ids[swap_index] = temporary_id
