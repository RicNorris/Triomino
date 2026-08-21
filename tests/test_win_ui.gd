extends SceneTree

const MainScene := preload("res://scenes/main.tscn")

var _failures := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Variant = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.theme != null, "The main scene should use the light theme")
	_expect(main.board.BOARD_COLOR.get_luminance() > 0.75, "The board should use a light background")

	main.state.session_active = true
	main.state.players = {1: "Ricardo"}
	var order: Array[int] = [1]
	main.state.player_order = order
	main.state.player_wins = {1: 2}
	main._apply_winner(1, main.state.player_wins)
	_expect(main.win_overlay.visible, "A win should open the winner window")
	_expect(not main.lobby_overlay.visible, "The lobby should stay hidden behind the winner window")
	_expect(main.winner_name_label.text == "RICARDO WINS!", "The winner window should show the display name")
	_expect(main.win_summary_label.text == "2 lobby wins", "The winner window should show the lobby total")

	main._continue_after_win()
	_expect(not main.win_overlay.visible, "Continue should close the winner window")
	_expect(main.lobby_overlay.visible, "Continue should reveal the lobby")
	main.queue_free()

	if _failures == 0:
		print("Winner window and light theme tests passed.")
		quit()
	else:
		printerr("%d winner UI test(s) failed." % _failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)
