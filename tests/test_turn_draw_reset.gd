extends SceneTree

const GameStateScript := preload("res://scripts/game_state.gd")

var failures: Array[String] = []


func _init() -> void:
	var state = GameStateScript.new()
	state.players = {1: "Player 1", 2: "Player 2"}
	state.begin_round([1, 2], {1: 0, 2: 0}, {1: [10], 2: [20]}, 40)
	state.player_current_turn_draws = 3

	_expect(
		state.apply_placement(1, 10, {1: 5, 2: 0}, 1),
		"Player 1's placement should be accepted."
	)
	_expect(state.current_player_id() == 2, "The placement should advance the turn to Player 2.")
	_expect(
		state.player_current_turn_draws == 0,
		"A new player's turn should start with zero draws."
	)

	if failures.is_empty():
		print("Turn draw reset tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
