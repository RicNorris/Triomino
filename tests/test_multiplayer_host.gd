extends SceneTree

const MainScene := preload("res://scenes/main.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Variant = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	main.network_port = 29745
	main.dealer.rng_seed = 12345
	main.name_edit.text = "Host"
	main.address_edit.text = "127.0.0.1"
	main._host_lobby()
	if not main.state.session_active:
		_fail("Host could not create a lobby")
		return

	if not await _wait_until(func() -> bool: return main.state.players.size() == 2):
		_fail("Guest did not register with the host")
		return
	main._start_game()
	await process_frame
	if not main.state.game_started or main.state.player_order.size() != 2:
		_fail("Host did not start a two-player round")
		return
	if main.state.player_tray_piece_ids[1].size() != main.dealer.pieces_per_player:
		_fail("Host did not receive the configured number of pieces")
		return

	var host_piece_id: int = main.state.player_tray_piece_ids[1][0]
	var lowest_value := 99
	for candidate_piece_id in main.state.player_tray_piece_ids[1]:
		var candidate_numbers: Array[int] = main.PieceCatalogScript.typed_numbers(main.piece_definitions[candidate_piece_id])
		var candidate_value: int = main.scoring.tile_value(candidate_numbers)
		if candidate_value < lowest_value:
			lowest_value = candidate_value
			host_piece_id = candidate_piece_id
	if lowest_value > 10:
		_fail("The deterministic host tray needs a tile worth 10 or fewer points")
		return
	var host_numbers: Array[int] = main.PieceCatalogScript.typed_numbers(main.piece_definitions[host_piece_id])
	main._on_board_placement_requested(host_piece_id, host_numbers, Vector2.ZERO, 0.0)
	if not await _wait_until(func() -> bool: return main.board.placed_pieces.size() == 1):
		_fail("Host placement was not committed")
		return
	if not main.state.game_started or not main.state.has_used_piece(1, host_piece_id):
		_fail("Host tray did not consume the placed piece")
		return
	if main.tray_pieces[host_piece_id].visible:
		_fail("The placed piece should be unavailable in the host's tray")
		return
	if not _tray_indicators_match_board(main, 1):
		_fail("Host tray indicators were not refreshed after the host placement")
		return
	var guest_id: int = main.state.current_player_id()
	if not await _wait_until(func() -> bool: return main.board.placed_pieces.size() == 2):
		_fail("Host did not receive the guest placement")
		return
	var guest_piece_id: int = main.board.placed_pieces[1].piece_id
	if main.state.player_tray_piece_ids[guest_id].size() != main.dealer.pieces_per_player + 1:
		_fail("Host did not apply the guest's synchronized well draw")
		return
	if not main.state.has_tray_piece(guest_id, guest_piece_id):
		_fail("Guest placed a piece that was not in its assigned tray")
		return
	if not main.state.has_used_piece(guest_id, guest_piece_id):
		_fail("Guest tray did not consume its placed piece")
		return
	if not _tray_indicators_match_board(main, 1):
		_fail("Host tray indicators were not refreshed after the guest placement")
		return
	print("Multiplayer host smoke test passed.")
	quit()


func _wait_until(predicate: Callable, frame_limit: int = 600) -> bool:
	for frame in frame_limit:
		if predicate.call():
			return true
		await process_frame
	return false


func _tray_indicators_match_board(main: Variant, peer_id: int) -> bool:
	for piece_id in main.state.player_tray_piece_ids[peer_id]:
		var piece: TriominoPiece = main.tray_pieces[piece_id]
		if main.state.has_used_piece(peer_id, piece_id):
			if piece.playability_indicator_visible:
				return false
			continue
		var numbers: Array[int] = main.PieceCatalogScript.typed_numbers(main.piece_definitions[piece_id])
		if not piece.playability_indicator_visible:
			return false
		if piece.can_play_anywhere != main.board.can_place_numbers_anywhere(numbers):
			return false
	return true


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)
