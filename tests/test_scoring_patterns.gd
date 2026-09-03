extends SceneTree

const MainScene := preload("res://scenes/main.tscn")

var _failures := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Variant = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	var board: TriominoBoard = main.board
	var candidate_center := board.size * 0.5
	var numbers: Array[int] = [1, 2, 3]
	_expect(main.scoring.draw_penalty(0) == 0, "No draw should have no penalty")
	_expect(main.scoring.draw_penalty(1) == 5, "The first draw should cost 5 points")
	_expect(main.scoring.draw_penalty(2) == 10, "The second draw should bring the penalty to 10 points")
	_expect(main.scoring.draw_penalty(3) == 25, "Three unsuccessful draws should cost 25 points")

	_build_bridge(board, candidate_center)
	var bridge_score: Dictionary = main.scoring.placement_score(
		numbers,
		board.get_placement_features(Vector2.ZERO, 0.0)
	)
	_expect(bridge_score.bridge, "Matching all three corners without a hexagon should form a bridge")
	_expect(bridge_score.total == 46, "A bridge should add 40 to the tile value")

	for expected_hexagons in range(1, 4):
		_build_hexagon_neighbors(board, candidate_center, expected_hexagons)
		var score: Dictionary = main.scoring.placement_score(
			numbers,
			board.get_placement_features(Vector2.ZERO, 0.0)
		)
		var expected_bonus: int = main.scoring.HEXAGON_BONUSES[expected_hexagons]
		_expect(score.hexagons == expected_hexagons, "%d completed hexagon(s) should be detected" % expected_hexagons)
		_expect(score.bonus == expected_bonus, "%d hexagon(s) should award %d bonus points" % [expected_hexagons, expected_bonus])
		_expect(score.total == 6 + expected_bonus, "Hexagon total should include the tile value")
		_expect(not score.bridge, "A hexagon completion should not also receive a bridge bonus")

	main.queue_free()
	if _failures == 0:
		print("Bridge and hexagon scoring tests passed.")
		quit()
	else:
		printerr("%d scoring pattern test(s) failed." % _failures)
		quit(1)


func _build_bridge(board: TriominoBoard, candidate_center: Vector2) -> void:
	board.placed_pieces.clear()
	var candidate := {"center": candidate_center, "rotation": 0.0}
	var edge_neighbor := board._candidate_across_edge(candidate, 0)
	board.placed_pieces.append({
		"center": edge_neighbor.center,
		"rotation": edge_neighbor.rotation,
		"numbers": [0, 0, 0]
	})
	var vertices := TriominoPiece.get_triangle_vertices(candidate_center, board.TILE_SIDE, 0.0)
	var radius: float = board.TILE_SIDE / sqrt(3.0)
	var opposite_center: Vector2 = vertices[2] + Vector2.from_angle(deg_to_rad(30.0)) * radius
	board.placed_pieces.append({
		"center": opposite_center,
		"rotation": 300.0,
		"numbers": [0, 0, 0]
	})


func _build_hexagon_neighbors(board: TriominoBoard, candidate_center: Vector2, hexagon_count: int) -> void:
	board.placed_pieces.clear()
	var candidate_vertices := TriominoPiece.get_triangle_vertices(candidate_center, board.TILE_SIDE, 0.0)
	var radius: float = board.TILE_SIDE / sqrt(3.0)
	var occupied_centers: Dictionary = {}
	for vertex_index in hexagon_count:
		var focal_vertex: Vector2 = candidate_vertices[vertex_index]
		for ring_rotation in range(0, 360, 60):
			var direction := Vector2.from_angle(deg_to_rad(-90.0 + ring_rotation)) * radius
			var ring_center: Vector2 = focal_vertex - direction
			if ring_center.distance_to(candidate_center) <= board.TIP_MATCH_TOLERANCE:
				continue
			var center_key := "%.3f:%.3f" % [ring_center.x, ring_center.y]
			if occupied_centers.has(center_key):
				continue
			occupied_centers[center_key] = true
			board.placed_pieces.append({
				"center": ring_center,
				"rotation": float(ring_rotation),
				"numbers": [0, 0, 0]
			})


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)
