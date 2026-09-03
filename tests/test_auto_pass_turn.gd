extends SceneTree

const MainScene := preload("res://scenes/main.tscn")

var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Variant = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	main.state.players = {1: "Player 1", 2: "Player 2"}
	var player_order: Array[int] = [1, 2]
	main.state.begin_round(player_order, {1: 0, 2: 0}, {1: [], 2: []}, 3)
	var blocked_draws: Array[int] = [0, 1, 2]
	main.dealer.piece_well = blocked_draws
	main.board.placed_pieces.append({
		"center": Vector2(300.0, 300.0),
		"rotation": 0.0,
		"numbers": [6, 6, 6],
	})

	main._process_draw_from_well_requested(1)
	main._process_draw_from_well_requested(1)
	_expect(main.state.current_player_id() == 1, "The turn should remain active through the second draw.")
	main._process_draw_from_well_requested(1)
	_expect(
		main.state.current_player_id() == 2,
		"A player with no playable tile should pass automatically after the third draw."
	)
	_expect(
		main.state.player_current_turn_draws == 0,
		"The automatic pass should reset the next player's draw count."
	)
	_expect(
		main.state.player_tray_piece_ids[1].size() == 3,
		"All three drawn pieces should reach the tray before the automatic pass."
	)
	_expect(
		main.state.player_scores[1] == -25,
		"An automatic pass after three draws should subtract the full 25-point draw penalty."
	)

	main.board.placed_pieces.clear()
	main.state.begin_round(player_order, {1: 0, 2: 0}, {1: [], 2: []}, 3)
	var playable_draws: Array[int] = [3, 4, 5]
	main.dealer.piece_well = playable_draws
	main._process_draw_from_well_requested(1)
	main._process_draw_from_well_requested(1)
	main._process_draw_from_well_requested(1)
	_expect(
		main.state.current_player_id() == 1,
		"A player who can place a tile after three draws should keep the turn."
	)
	_expect(main.state.player_current_turn_draws == 3, "The retained turn should keep its three-draw count.")
	_expect(main.state.player_scores[1] == 0, "No points should be subtracted while the player retains the turn.")
	_expect(not _has_pass_turn_button(main), "The manual pass-turn button should be removed.")

	if failures.is_empty():
		print("Automatic pass turn tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _has_pass_turn_button(node: Node) -> bool:
	if node is Button and "pass turn" in node.text.to_lower():
		return true
	for child in node.get_children():
		if _has_pass_turn_button(child):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
