class_name TriominoMultiplayerSession
extends Node

signal connection_succeeded
signal connection_failed_event
signal server_disconnected_event
signal peer_disconnected_event(peer_id: int)
signal register_player_requested(peer_id: int, display_name: String)
signal lobby_state_received(players: Dictionary, player_order: Array[int], wins: Dictionary)
signal join_rejected(reason: String)
signal round_started_received(
	player_order: Array[int],
	scores: Dictionary,
	trays: Dictionary,
	well_piece_count: int
)
signal play_requested(peer_id: int, piece_id: int, numbers: Array[int], center_offset: Vector2, rotation: float)
signal move_rejected(reason: String)
signal draw_from_well_requested(peer_id: int)
signal pass_turn_requested(peer_id: int)
signal piece_drawn_received(peer_id: int, piece_id: int, well_piece_count: int)
signal placement_received(
	peer_id: int,
	piece_id: int,
	numbers: Array[int],
	center_offset: Vector2,
	rotation: float,
	score_breakdown: Dictionary,
	scores: Dictionary,
	next_turn: int
)
signal winner_received(winner_peer_id: int, wins: Dictionary)
signal player_state_received(
	players: Dictionary,
	player_order: Array[int],
	scores: Dictionary,
	wins: Dictionary,
	turn_index: int,
	round_in_progress: bool
)


func _ready() -> void:
	multiplayer.connected_to_server.connect(connection_succeeded.emit)
	multiplayer.connection_failed.connect(connection_failed_event.emit)
	multiplayer.server_disconnected.connect(server_disconnected_event.emit)
	multiplayer.peer_disconnected.connect(peer_disconnected_event.emit)


func host(port: int, max_players: int) -> int:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, max_players)
	if error == OK:
		multiplayer.multiplayer_peer = peer
	return error


func join(address: String, port: int) -> int:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error == OK:
		multiplayer.multiplayer_peer = peer
	return error


func close() -> void:
	var current_peer := multiplayer.multiplayer_peer
	if current_peer is ENetMultiplayerPeer:
		current_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func send_register_player(display_name: String) -> void:
	_request_register_player.rpc_id(1, display_name)


func broadcast_lobby_state(players: Dictionary, player_order: Array[int], wins: Dictionary) -> void:
	_sync_lobby_state.rpc(players, player_order, wins)


func reject_join_for(peer_id: int, reason: String) -> void:
	_reject_join.rpc_id(peer_id, reason)


func broadcast_round_started(
	player_order: Array[int],
	scores: Dictionary,
	trays: Dictionary,
	well_piece_count: int
) -> void:
	_sync_round_started.rpc(player_order, scores, trays, well_piece_count)


func send_play_request(piece_id: int, numbers: Array[int], center_offset: Vector2, rotation: float) -> void:
	if multiplayer.is_server():
		play_requested.emit(1, piece_id, numbers, center_offset, rotation)
	else:
		_request_play.rpc_id(1, piece_id, numbers, center_offset, rotation)

func send_draw_from_well_request() -> void:
	if multiplayer.is_server():
		draw_from_well_requested.emit(1)
	else:
		_request_draw_from_well.rpc_id(1)


func send_pass_turn_request() -> void:
	if multiplayer.is_server():
		pass_turn_requested.emit(1)
	else:
		_request_pass_turn.rpc_id(1)


func broadcast_piece_drawn(peer_id: int, piece_id: int, well_piece_count: int) -> void:
	_sync_piece_drawn.rpc(peer_id, piece_id, well_piece_count)

func reject_move_for(peer_id: int, reason: String) -> void:
	if peer_id == 1:
		move_rejected.emit(reason)
	else:
		_reject_move.rpc_id(peer_id, reason)


func broadcast_placement(
	peer_id: int,
	piece_id: int,
	numbers: Array[int],
	center_offset: Vector2,
	rotation: float,
	score_breakdown: Dictionary,
	scores: Dictionary,
	next_turn: int
) -> void:
	_sync_placement.rpc(
		peer_id,
		piece_id,
		numbers,
		center_offset,
		rotation,
		score_breakdown,
		scores,
		next_turn
	)


func broadcast_winner(winner_peer_id: int, wins: Dictionary) -> void:
	_sync_winner.rpc(winner_peer_id, wins)


func broadcast_player_state(
	players: Dictionary,
	player_order: Array[int],
	scores: Dictionary,
	wins: Dictionary,
	turn_index: int,
	round_in_progress: bool
) -> void:
	_sync_player_state.rpc(players, player_order, scores, wins, turn_index, round_in_progress)


@rpc("any_peer", "call_remote", "reliable")
func _request_register_player(display_name: String) -> void:
	if multiplayer.is_server():
		register_player_requested.emit(multiplayer.get_remote_sender_id(), display_name)


@rpc("authority", "call_local", "reliable")
func _sync_lobby_state(players: Dictionary, player_order: Array[int], wins: Dictionary) -> void:
	lobby_state_received.emit(players, player_order, wins)


@rpc("authority", "call_remote", "reliable")
func _reject_join(reason: String) -> void:
	join_rejected.emit(reason)


@rpc("authority", "call_local", "reliable")
func _sync_round_started(
	player_order: Array[int],
	scores: Dictionary,
	trays: Dictionary,
	well_piece_count: int
) -> void:
	round_started_received.emit(player_order, scores, trays, well_piece_count)


@rpc("any_peer", "call_remote", "reliable")
func _request_play(piece_id: int, numbers: Array[int], center_offset: Vector2, rotation: float) -> void:
	if multiplayer.is_server():
		play_requested.emit(multiplayer.get_remote_sender_id(), piece_id, numbers, center_offset, rotation)

@rpc("any_peer", "call_remote", "reliable")
func _request_draw_from_well() -> void:
	if multiplayer.is_server():
		draw_from_well_requested.emit(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _request_pass_turn() -> void:
	if multiplayer.is_server():
		pass_turn_requested.emit(multiplayer.get_remote_sender_id())


@rpc("authority", "call_local", "reliable")
func _sync_piece_drawn(peer_id: int, piece_id: int, well_piece_count: int) -> void:
	piece_drawn_received.emit(peer_id, piece_id, well_piece_count)

@rpc("authority", "call_remote", "reliable")
func _reject_move(reason: String) -> void:
	move_rejected.emit(reason)


@rpc("authority", "call_local", "reliable")
func _sync_placement(
	peer_id: int,
	piece_id: int,
	numbers: Array[int],
	center_offset: Vector2,
	rotation: float,
	score_breakdown: Dictionary,
	scores: Dictionary,
	next_turn: int
) -> void:
	placement_received.emit(
		peer_id,
		piece_id,
		numbers,
		center_offset,
		rotation,
		score_breakdown,
		scores,
		next_turn
	)


@rpc("authority", "call_local", "reliable")
func _sync_winner(winner_peer_id: int, wins: Dictionary) -> void:
	winner_received.emit(winner_peer_id, wins)


@rpc("authority", "call_local", "reliable")
func _sync_player_state(
	players: Dictionary,
	player_order: Array[int],
	scores: Dictionary,
	wins: Dictionary,
	turn_index: int,
	round_in_progress: bool
) -> void:
	player_state_received.emit(players, player_order, scores, wins, turn_index, round_in_progress)
