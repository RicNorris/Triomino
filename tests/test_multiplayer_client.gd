extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const LobbyCodeScript := preload("res://scripts/lobby_code.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for frame in 20:
		await process_frame
	var main: Variant = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	main.network_port = 29745
	main.name_edit.text = "Guest"
	main.lobby_code_edit.text = LobbyCodeScript.encode("127.0.0.1", main.network_port)
	main._join_lobby()
	if not await _wait_until(func() -> bool: return main.state.players.size() == 2):
		_fail("Client did not receive the two-player lobby")
		return
	if not main.state.players.values().has("Host") or not main.state.players.values().has("Guest"):
		_fail("Display names were not synchronized")
		return
	if not await _wait_until(func() -> bool: return main.state.game_started):
		_fail("Client did not receive the round start")
		return
	var local_peer_id: int = main.multiplayer.get_unique_id()
	if main.state.player_tray_piece_ids[local_peer_id].size() != main.dealer.pieces_per_player:
		_fail("Client did not receive the configured number of pieces")
		return
	var visible_piece_count := 0
	for piece_id in main.tray_pieces:
		if main.tray_pieces[piece_id].visible:
			visible_piece_count += 1
	if visible_piece_count != main.dealer.pieces_per_player:
		_fail("Client should see only its configured tray pieces")
		return
	if not await _wait_until(func() -> bool: return main.board.placed_pieces.size() == 1):
		_fail("Client did not receive the host placement")
		return
	if not main._is_local_turn():
		_fail("The guest did not receive its turn")
		return
	var tray_size_before_draw: int = main.state.player_tray_piece_ids[local_peer_id].size()
	main._draw_from_well()
	if not await _wait_until(
		func() -> bool:
			return main.state.player_tray_piece_ids[local_peer_id].size() == tray_size_before_draw + 1
	):
		_fail("The guest's well draw was not synchronized")
		return
	var legal_move := _find_legal_move(main, local_peer_id)
	if legal_move.is_empty():
		_fail("The deterministic guest tray did not contain a playable piece")
		return
	main._on_board_placement_requested(
		legal_move.piece_id,
		legal_move.numbers,
		legal_move.center_offset,
		legal_move.rotation
	)
	if not await _wait_until(func() -> bool: return main.board.placed_pieces.size() == 2):
		_fail("The guest could not place its own copy of the same piece")
		return
	if not main.state.has_used_piece(local_peer_id, legal_move.piece_id):
		_fail("The guest's placed piece was not consumed from its tray")
		return
	if main.tray_pieces[legal_move.piece_id].visible:
		_fail("The guest's used tray piece should now be unavailable")
		return
	print("Multiplayer client smoke test passed.")
	quit()


func _wait_until(predicate: Callable, frame_limit: int = 600) -> bool:
	for frame in frame_limit:
		if predicate.call():
			return true
		await process_frame
	return false


func _find_legal_move(main: Variant, peer_id: int) -> Dictionary:
	for piece_id in main.state.player_tray_piece_ids[peer_id]:
		var numbers: Array[int] = main.PieceCatalogScript.typed_numbers(main.piece_definitions[piece_id])
		for number_rotation in 3:
			for placed in main.board.placed_pieces:
				for edge_index in 3:
					var candidate: Dictionary = main.board._candidate_across_edge(placed, edge_index)
					if not main.board._position_is_free(candidate.center):
						continue
					if main.board._candidate_is_legal(candidate, numbers):
						return {
							"piece_id": piece_id,
							"numbers": numbers.duplicate(),
							"center_offset": candidate.center - main.board.size * 0.5,
							"rotation": candidate.rotation
						}
			numbers = [numbers[1], numbers[2], numbers[0]]
	return {}


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)
