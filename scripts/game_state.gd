class_name TriominoGameState
extends RefCounted

var players: Dictionary = {}
var player_order: Array[int] = []
var player_scores: Dictionary = {}
var player_wins: Dictionary = {}
var player_tray_piece_ids: Dictionary = {}
var used_piece_ids_by_player: Dictionary = {}
var current_turn_index := 0
var well_piece_count := 0
var player_current_turn_draws := 0
var session_active := false
var game_started := false

func create_host(display_name: String) -> void:
	session_active = true
	players = {1: display_name}
	player_order = [1]
	player_wins = {1: 0}


func register_player(peer_id: int, display_name: String) -> void:
	players[peer_id] = display_name
	if not player_wins.has(peer_id):
		player_wins[peer_id] = 0
	if not player_order.has(peer_id):
		player_order.append(peer_id)


func apply_lobby(new_players: Dictionary, new_order: Array[int], new_wins: Dictionary) -> void:
	players = new_players.duplicate()
	player_order = new_order.duplicate()
	player_wins = new_wins.duplicate()


func begin_round(
	new_order: Array[int],
	new_scores: Dictionary,
	new_trays: Dictionary,
	initial_well_piece_count: int
) -> void:
	player_order = new_order.duplicate()
	player_scores = new_scores.duplicate()
	player_tray_piece_ids = new_trays.duplicate(true)
	used_piece_ids_by_player.clear()
	for peer_id in player_order:
		used_piece_ids_by_player[peer_id] = {}
	current_turn_index = 0
	well_piece_count = initial_well_piece_count
	player_current_turn_draws = 0
	game_started = true


func apply_placement(peer_id: int, piece_id: int, scores: Dictionary, next_turn: int) -> bool:
	if has_used_piece(peer_id, piece_id):
		return false
	mark_piece_used(peer_id, piece_id)
	player_scores = scores.duplicate()
	current_turn_index = next_turn
	return true
	
func add_piece_to_tray(peer_id: int, piece_id: int) -> void:
	var tray_ids: Array = player_tray_piece_ids.get(peer_id, [])
	if not tray_ids.has(piece_id):
		tray_ids.append(piece_id)
	player_tray_piece_ids[peer_id] = tray_ids


func apply_winner(winner_peer_id: int, updated_wins: Dictionary) -> void:
	player_wins = updated_wins.duplicate()
	game_started = false


func remove_player(peer_id: int) -> void:
	players.erase(peer_id)
	player_scores.erase(peer_id)
	player_wins.erase(peer_id)
	player_tray_piece_ids.erase(peer_id)
	used_piece_ids_by_player.erase(peer_id)
	var removed_index := player_order.find(peer_id)
	if removed_index >= 0:
		player_order.remove_at(removed_index)
	if player_order.is_empty():
		current_turn_index = 0
	else:
		current_turn_index = mini(current_turn_index, player_order.size() - 1)


func apply_player_snapshot(
	new_players: Dictionary,
	new_order: Array[int],
	new_scores: Dictionary,
	new_wins: Dictionary,
	new_turn_index: int,
	round_in_progress: bool
) -> void:
	players = new_players.duplicate()
	player_order = new_order.duplicate()
	player_scores = new_scores.duplicate()
	player_wins = new_wins.duplicate()
	for tray_peer_id in player_tray_piece_ids.keys():
		if not players.has(tray_peer_id):
			player_tray_piece_ids.erase(tray_peer_id)
	current_turn_index = new_turn_index
	game_started = round_in_progress


func clear() -> void:
	players.clear()
	player_order.clear()
	player_scores.clear()
	player_wins.clear()
	player_tray_piece_ids.clear()
	used_piece_ids_by_player.clear()
	current_turn_index = 0
	well_piece_count = 0
	session_active = false
	game_started = false


func has_tray_piece(peer_id: int, piece_id: int) -> bool:
	var tray_ids: Array = player_tray_piece_ids.get(peer_id, [])
	return tray_ids.has(piece_id)


func has_used_piece(peer_id: int, piece_id: int) -> bool:
	var used_pieces: Dictionary = used_piece_ids_by_player.get(peer_id, {})
	return used_pieces.has(piece_id)


func mark_piece_used(peer_id: int, piece_id: int) -> void:
	var used_pieces: Dictionary = used_piece_ids_by_player.get(peer_id, {})
	used_pieces[piece_id] = true
	used_piece_ids_by_player[peer_id] = used_pieces


func current_player_id() -> int:
	if player_order.is_empty() or current_turn_index < 0 or current_turn_index >= player_order.size():
		return -1
	return player_order[current_turn_index]


func current_player_name() -> String:
	return str(players.get(current_player_id(), "Another player"))


func is_peer_turn(peer_id: int) -> bool:
	return game_started and current_player_id() == peer_id


func has_lobby_wins() -> bool:
	for peer_id in player_wins:
		if int(player_wins[peer_id]) > 0:
			return true
	return false
