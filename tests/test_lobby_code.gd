extends SceneTree

const LobbyCodeScript := preload("res://scripts/lobby_code.gd")

var _failures := 0


func _init() -> void:
	var code: String = LobbyCodeScript.encode("127.0.0.1", 28745)
	_expect(code.begins_with("TRI-"), "Lobby codes should be recognizable")
	var decoded: Dictionary = LobbyCodeScript.decode(code)
	_expect(decoded.ok, "A generated lobby code should decode")
	_expect(decoded.get("address") == "127.0.0.1", "The address should survive a round trip")
	_expect(decoded.get("port") == 28745, "The port should survive a round trip")

	var compact_code := code.replace("-", "").to_lower()
	_expect(LobbyCodeScript.decode(compact_code).ok, "Codes should ignore case and separators")
	_expect(not LobbyCodeScript.decode("TRI-NOT-A-CODE").ok, "Invalid characters should be rejected")
	_expect(LobbyCodeScript.encode("999.1.1.1", 28745).is_empty(), "Invalid addresses should be rejected")
	_expect(LobbyCodeScript.encode("127.0.0.1", 70000).is_empty(), "Invalid ports should be rejected")

	if _failures == 0:
		print("Lobby code tests passed.")
		quit()
	else:
		printerr("%d lobby code test(s) failed." % _failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)
