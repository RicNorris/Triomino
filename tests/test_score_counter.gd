extends SceneTree

const MainScene := preload("res://scenes/main.tscn")

var _failures := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Variant = MainScene.instantiate()
	root.add_child(main)
	await process_frame

	_expect(main.total_score == 0, "Score should start at zero")
	_expect(main.score_value_label.text == "0", "Counter should initially display zero")
	main.add_score(7)
	_expect(main.total_score == 7, "add_score should update the total")
	_expect(main.score_value_label.text == "7", "add_score should update the visible counter")
	main._on_reset_pressed()
	_expect(main.total_score == 0, "Reset should clear the score")
	_expect(main.score_value_label.text == "0", "Reset should clear the visible counter")

	main.queue_free()
	if _failures == 0:
		print("Score counter tests passed.")
		quit()
	else:
		printerr("%d score counter test(s) failed." % _failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)
