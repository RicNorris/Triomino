extends SceneTree

const MainScene := preload("res://scenes/main.tscn")

var _failures := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Variant = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	var order: Array[int] = [1, 2, 3]
	main.dealer.rng_seed = 12345
	main.dealer.pieces_per_player = 7
	var trays: Dictionary = main.dealer.deal(main.piece_definitions.size(), order)

	_expect(trays.size() == 3, "Every player should receive a tray")
	var all_dealt_ids: Dictionary = {}
	for peer_id in order:
		var tray: Array = trays[peer_id]
		_expect(tray.size() == main.dealer.pieces_per_player, "Every tray should contain the configured number of pieces")
		var unique_ids: Dictionary = {}
		for piece_id in tray:
			_expect(piece_id >= 0 and piece_id < 56, "Tray piece IDs should come from the complete set")
			unique_ids[piece_id] = true
			all_dealt_ids[piece_id] = true
		_expect(unique_ids.size() == main.dealer.pieces_per_player, "A player's tray should not contain duplicates")
	_expect(
		all_dealt_ids.size() == order.size() * main.dealer.pieces_per_player,
		"The same physical tile should not be dealt to multiple players"
	)
	_expect(
		main.dealer.piece_well.size() == 56 - all_dealt_ids.size(),
		"The well should contain exactly the undealt pieces"
	)

	main.state.players = {1: "One", 2: "Two", 3: "Three"}
	main.state.session_active = true
	var scores := {1: 0, 2: 0, 3: 0}
	main._apply_round_started(order, scores, trays, main.dealer.piece_well.size())
	var visible_count := 0
	for piece_id in main.tray_pieces:
		if main.tray_pieces[piece_id].visible:
			visible_count += 1
	_expect(visible_count == main.dealer.pieces_per_player, "Only the local player's assigned pieces should be visible")
	var visible_tray_order: Array[int] = []
	for child in main.piece_tray.get_children():
		if child.visible:
			visible_tray_order.append(child.piece_id)
	_expect(visible_tray_order == trays[1], "The rack should preserve the order in which tiles were dealt")
	for piece_id in trays[1]:
		_expect(
			main.tray_pieces[piece_id].playability_indicator_visible,
			"Each local tray piece should show a playability indicator during a round"
		)
		_expect(
			main.tray_pieces[piece_id].can_play_anywhere,
			"Every local tray piece should be marked playable while the board is empty"
		)

	var well_size_before_draw: int = main.dealer.piece_well.size()
	var expected_drawn_piece: int = main.dealer.piece_well[0]
	main._process_draw_from_well_requested(1)
	_expect(main.dealer.piece_well.size() == well_size_before_draw - 1, "Drawing should remove one piece from the well")
	_expect(main.state.has_tray_piece(1, expected_drawn_piece), "The drawn piece should enter the requesting player's tray")
	_expect(main.tray_pieces[expected_drawn_piece].visible, "The local player should see the drawn piece")
	_expect(
		main.tray_pieces[expected_drawn_piece].playability_indicator_visible,
		"A newly drawn local piece should immediately receive a playability indicator"
	)
	visible_tray_order.clear()
	for child in main.piece_tray.get_children():
		if child.visible:
			visible_tray_order.append(child.piece_id)
	_expect(visible_tray_order[-1] == expected_drawn_piece, "A newly drawn tile should appear at the right end of the rack")
	_expect(not main.draw_from_well_button.disabled, "The draw button should remain enabled while the well has pieces")

	var final_well_piece: int = main.dealer.piece_well[0]
	var final_well: Array[int] = [final_well_piece]
	main.dealer.piece_well = final_well
	main.state.well_piece_count = 1
	main._update_draw_button()
	main._process_draw_from_well_requested(1)
	_expect(main.state.well_piece_count == 0, "Every peer should receive an empty synchronized well count")
	_expect(main.draw_from_well_button.disabled, "The draw button should be disabled when the well is empty")

	var consumed_piece_id: int = trays[1][0]
	main.state.mark_piece_used(1, consumed_piece_id)
	main._set_game_controls_enabled(true)
	_expect(not main.tray_pieces[consumed_piece_id].visible, "A used piece should leave only that player's tray")
	_expect(main.state.has_tray_piece(2, trays[2][0]), "Other players should retain their own assigned trays")
	_expect(not _has_scroll_ancestor(main.piece_tray, main), "The tray should not hide pieces inside a scroll container")
	for candidate_piece_id in main.piece_definitions.size():
		if main._remaining_piece_count(1) >= 12:
			break
		if not main.state.has_tray_piece(1, candidate_piece_id):
			main.state.add_piece_to_tray(1, candidate_piece_id)
	main._set_game_controls_enabled(true)
	main._update_hand_count()
	for frame in 4:
		await process_frame
	var occupied_width := 0.0
	var visible_piece_count := 0
	for piece_id in main.state.player_tray_piece_ids[1]:
		if main.state.has_used_piece(1, piece_id):
			continue
		occupied_width += main.tray_pieces[piece_id].custom_minimum_size.x
		visible_piece_count += 1
	occupied_width += float(maxi(0, visible_piece_count - 1) * 6)
	_expect(visible_piece_count == 12, "The maximum post-draw hand fixture should contain twelve visible pieces")
	_expect(
		occupied_width <= main.tray_well.size.x,
		"All twelve tray pieces should resize to remain visible without scrolling"
	)

	main.queue_free()
	if _failures == 0:
		print("Per-player sequential tray tests passed.")
		quit()
	else:
		printerr("%d player tray test(s) failed." % _failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)


func _has_scroll_ancestor(node: Node, stop_at: Node) -> bool:
	var ancestor := node.get_parent()
	while ancestor != null and ancestor != stop_at:
		if ancestor is ScrollContainer:
			return true
		ancestor = ancestor.get_parent()
	return false
