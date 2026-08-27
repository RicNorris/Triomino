extends Control

const PieceScene := preload("res://scripts/triomino_piece.gd")
const LobbyCodeScript := preload("res://scripts/lobby_code.gd")
const PieceCatalogScript := preload("res://scripts/piece_catalog.gd")
const RoundDealerScript := preload("res://scripts/round_dealer.gd")
const ScoringScript := preload("res://scripts/scoring.gd")
const GameStateScript := preload("res://scripts/game_state.gd")
const GameHudScript := preload("res://scripts/game_hud.gd")

const TRAY_TILE_SIZE := Vector2(116.0, 106.0)
const TRAY_TILE_SIDE := 82.0
const HAND_TRAY_BASE_HEIGHT := 218.0
const HAND_TRAY_ROW_HEIGHT := 114.0
const HAND_TRAY_COLLAPSED_HEIGHT := 58.0
const MAX_PIECE_NUMBER := 5
const GAME_PORT := 28745
const MAX_PLAYERS := 4

@onready var network: TriominoMultiplayerSession = $MultiplayerSession
@onready var board: TriominoBoard = $Layout/Board
@onready var piece_tray: Container = $Layout/Sidebar/Margin/Content/Scroll/PieceTray
@onready var score_value_label: Label = $Layout/Sidebar/Margin/Content/ScorePanel/ScoreMargin/ScoreRow/ScoreValue
@onready var turn_label: Label = $Layout/Sidebar/Margin/Content/TurnLabel
@onready var status_label: Label = $Layout/Sidebar/Margin/Content/Status
@onready var instructions_label: Label = $Layout/Sidebar/Margin/Content/Instructions
@onready var rotate_button: Button = $Layout/Sidebar/Margin/Content/PieceControls/RotateButton
@onready var piece_count_label: Label = $Layout/Sidebar/Margin/Content/Footer/PieceCount
@onready var reset_button: Button = $Layout/Sidebar/Margin/Content/Footer/ResetButton
@onready var draw_from_well_button: Button =$Layout/Sidebar/Margin/Content/PieceControls/DrawFromWellButton
@onready var draw_count_label: Label = $Layout/Sidebar/Margin/Content/DrawCountLabel

var turn_panel: PanelContainer
var player_cards_container: HBoxContainer
var hand_count_label: Label
var well_count_label: Label
var hand_panel: PanelContainer
var tray_toggle_button: Button
var tray_well: PanelContainer
var board_area: MarginContainer
var hand_tray_open := true
var hand_tray_height := HAND_TRAY_BASE_HEIGHT
var hand_tray_tween: Tween
var fullscreen_button: Button
var responsive_layout_queued := false
var zoom_out_button: Button
var zoom_in_button: Button
var center_view_button: Button
var zoom_label: Label

@onready var lobby_overlay: Control = $LobbyOverlay
@onready var lobby_status_label: Label = $LobbyOverlay/Center/Panel/Margin/Content/Status
@onready var name_edit: LineEdit = $LobbyOverlay/Center/Panel/Margin/Content/NameEdit
@onready var address_label: Label = $LobbyOverlay/Center/Panel/Margin/Content/AddressLabel
@onready var address_row: HBoxContainer = $LobbyOverlay/Center/Panel/Margin/Content/AddressRow
@onready var address_edit: LineEdit = $LobbyOverlay/Center/Panel/Margin/Content/AddressRow/AddressEdit
@onready var local_test_button: Button = $LobbyOverlay/Center/Panel/Margin/Content/AddressRow/LocalTestButton
@onready var host_button: Button = $LobbyOverlay/Center/Panel/Margin/Content/HostButton
@onready var or_label: Label = $LobbyOverlay/Center/Panel/Margin/Content/OrLabel
@onready var lobby_code_edit: LineEdit = $LobbyOverlay/Center/Panel/Margin/Content/CodeRow/LobbyCodeEdit
@onready var copy_button: Button = $LobbyOverlay/Center/Panel/Margin/Content/CodeRow/CopyButton
@onready var join_button: Button = $LobbyOverlay/Center/Panel/Margin/Content/JoinButton
@onready var lobby_player_list: Label = $LobbyOverlay/Center/Panel/Margin/Content/PlayerList
@onready var start_button: Button = $LobbyOverlay/Center/Panel/Margin/Content/StartButton
@onready var leave_button: Button = $LobbyOverlay/Center/Panel/Margin/Content/LeaveButton
@onready var win_overlay: Control = $WinOverlay
@onready var winner_name_label: Label = $WinOverlay/Center/Panel/Margin/Content/WinnerName
@onready var win_summary_label: Label = $WinOverlay/Center/Panel/Margin/Content/WinSummary
@onready var continue_to_lobby_button: Button = $WinOverlay/Center/Panel/Margin/Content/ContinueButton

var state: TriominoGameState = GameStateScript.new()
var dealer: TriominoRoundDealer = RoundDealerScript.new()
var scoring: TriominoScoring = ScoringScript.new()
var piece_definitions: Array[Array] = []
var tray_pieces: Dictionary = {}
var selected_tray_piece: TriominoPiece
var total_score := 0
var local_display_name := ""
var network_port := GAME_PORT


func _ready() -> void:
	_install_modern_hud()
	resized.connect(_on_main_resized)
	piece_definitions = PieceCatalogScript.generate_complete_set(MAX_PIECE_NUMBER)
	_build_piece_tray()
	_connect_ui_signals()
	_connect_network_signals()
	address_edit.text = _find_lan_ipv4()
	_set_game_controls_enabled(false)
	_refresh_lobby_ui()


func _install_modern_hud() -> void:
	var hud: Dictionary = GameHudScript.build(self, board)
	piece_tray = hud.piece_tray
	score_value_label = hud.score_value
	turn_label = hud.turn_label
	turn_panel = hud.turn_panel
	player_cards_container = hud.player_cards
	status_label = hud.status
	instructions_label = hud.instructions
	rotate_button = hud.rotate_button
	draw_from_well_button = hud.draw_button
	draw_count_label = hud.draw_count
	piece_count_label = hud.board_count
	hand_count_label = hud.hand_count
	well_count_label = hud.well_count
	reset_button = hud.reset_button
	fullscreen_button = hud.fullscreen_button
	hand_panel = hud.hand_panel
	tray_toggle_button = hud.tray_toggle
	tray_well = hud.tray_well
	board_area = hud.board_area
	zoom_out_button = hud.zoom_out_button
	zoom_in_button = hud.zoom_in_button
	center_view_button = hud.center_view_button
	zoom_label = hud.zoom_label


func _connect_ui_signals() -> void:
	board.placement_requested.connect(_on_board_placement_requested)
	board.placed_count_changed.connect(_on_placed_count_changed)
	board.placement_rejected.connect(_on_placement_rejected)
	board.view_changed.connect(_on_board_view_changed)
	rotate_button.pressed.connect(_rotate_selected_piece)
	reset_button.pressed.connect(_on_reset_pressed)
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	zoom_out_button.pressed.connect(board.zoom_out)
	zoom_in_button.pressed.connect(board.zoom_in)
	center_view_button.pressed.connect(board.reset_view)
	draw_from_well_button.pressed.connect(_draw_from_well)
	tray_toggle_button.pressed.connect(_toggle_hand_tray)
	host_button.pressed.connect(_host_lobby)
	join_button.pressed.connect(_join_lobby)
	copy_button.pressed.connect(_copy_lobby_code)
	local_test_button.pressed.connect(_use_localhost)
	start_button.pressed.connect(_start_game)
	leave_button.pressed.connect(_leave_lobby)
	continue_to_lobby_button.pressed.connect(_continue_after_win)


func _connect_network_signals() -> void:
	network.connection_succeeded.connect(_on_connected_to_server)
	network.connection_failed_event.connect(_on_connection_failed)
	network.server_disconnected_event.connect(_on_server_disconnected)
	network.peer_disconnected_event.connect(_on_peer_disconnected)
	network.register_player_requested.connect(_on_register_player_requested)
	network.lobby_state_received.connect(_apply_lobby_state)
	network.join_rejected.connect(_on_join_rejected)
	network.round_started_received.connect(_apply_round_started)
	network.play_requested.connect(_process_play_request)
	network.move_rejected.connect(_on_move_rejected)
	network.placement_received.connect(_apply_placement)
	network.winner_received.connect(_apply_winner)
	network.player_state_received.connect(_apply_player_state)
	network.draw_from_well_requested.connect(_process_draw_from_well_requested)
	network.piece_drawn_received.connect(_apply_piece_drawn)

func _build_piece_tray() -> void:
	for piece_id in piece_definitions.size():
		var piece := PieceScene.new() as TriominoPiece
		piece.custom_minimum_size = TRAY_TILE_SIZE
		piece.configure(piece_id, PieceCatalogScript.typed_numbers(piece_definitions[piece_id]), TRAY_TILE_SIDE)
		piece.selected.connect(_on_tray_piece_selected)
		piece_tray.add_child(piece)
		tray_pieces[piece_id] = piece


func _on_tray_piece_selected(piece: TriominoPiece) -> void:
	if not state.game_started:
		return
	if not _is_local_turn():
		status_label.text = "Wait for your turn"
		instructions_label.text = "%s is choosing a piece." % state.current_player_name()
		return
	var local_peer_id := multiplayer.get_unique_id()
	if not state.has_tray_piece(local_peer_id, piece.piece_id):
		return
	if state.has_used_piece(local_peer_id, piece.piece_id):
		return
	if selected_tray_piece != null:
		selected_tray_piece.set_selected(false)
	selected_tray_piece = piece
	piece.set_selected(true)
	board.select_piece(piece.piece_id, piece.numbers)
	rotate_button.disabled = false
	if board.placed_pieces.is_empty():
		status_label.text = "Great pick! Pop it in the middle ★"
		instructions_label.text = "Spin it with R if you like, then click the big target."
	else:
		status_label.text = "Ooh, nice tile!"
		instructions_label.text = "Green means go! Spin with R until the numbers are happy."


func _rotate_selected_piece() -> void:
	if selected_tray_piece == null or not _is_local_turn():
		return
	selected_tray_piece.rotate_numbers_clockwise()
	board.select_piece(selected_tray_piece.piece_id, selected_tray_piece.numbers)
	status_label.text = "Wheee! One spin clockwise ↻"
	if board.placed_pieces.is_empty():
		instructions_label.text = "Press R again or click the board to place it\nexactly in the center."
	else:
		instructions_label.text = "Green edges match this rotation;\nred edges are blocked."

func _draw_from_well() -> void:
	if not state.game_started or not _is_local_turn():
		return
	if state.player_current_turn_draws == 3:
		return
	draw_from_well_button.disabled = true
	network.send_draw_from_well_request()
	status_label.text = "Checking move…"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_rotate_selected_piece()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_H:
			_toggle_hand_tray()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F11:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C:
			board.reset_view()
			get_viewport().set_input_as_handled()


func _on_board_view_changed(zoom_percent: int) -> void:
	zoom_label.text = "%d%%" % zoom_percent


func _toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var is_fullscreen := current_mode in [
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	]
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	_queue_responsive_layout()


func _toggle_hand_tray() -> void:
	hand_tray_open = not hand_tray_open
	_set_hand_tray_position(true)


func _set_hand_tray_position(animate: bool) -> void:
	if hand_tray_tween != null and hand_tray_tween.is_valid():
		hand_tray_tween.kill()
	var target_top := -hand_tray_height if hand_tray_open else -HAND_TRAY_COLLAPSED_HEIGHT
	var target_bottom := 0.0 if hand_tray_open else hand_tray_height - HAND_TRAY_COLLAPSED_HEIGHT
	var board_target_bottom := -(hand_tray_height - 54.0) if hand_tray_open else 0.0
	if animate:
		hand_tray_tween = create_tween()
		hand_tray_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		hand_tray_tween.set_parallel(true)
		hand_tray_tween.tween_property(hand_panel, "offset_top", target_top, 0.38)
		hand_tray_tween.tween_property(hand_panel, "offset_bottom", target_bottom, 0.38)
		hand_tray_tween.tween_property(board_area, "offset_bottom", board_target_bottom, 0.38)
	else:
		hand_panel.offset_top = target_top
		hand_panel.offset_bottom = target_bottom
		board_area.offset_bottom = board_target_bottom
	_refresh_tray_toggle_copy()


func _refresh_tray_toggle_copy() -> void:
	if hand_tray_open:
		tray_toggle_button.text = "▼  Hide my tiles  H"
	elif _is_local_turn():
		tray_toggle_button.text = "▲  MY TURN! Open  H"
	else:
		tray_toggle_button.text = "▲  Show my tiles  H"


func _on_main_resized() -> void:
	_queue_responsive_layout()


func _queue_responsive_layout() -> void:
	if responsive_layout_queued:
		return
	responsive_layout_queued = true
	_apply_responsive_layout.call_deferred()


func _apply_responsive_layout() -> void:
	responsive_layout_queued = false
	if not is_inside_tree():
		return
	_rebuild_player_cards()
	_update_tray_layout(false)
	var current_mode := DisplayServer.window_get_mode()
	var is_fullscreen := current_mode in [
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	]
	fullscreen_button.text = "↙  Windowed" if is_fullscreen else "□  Fullscreen"


func _on_placement_rejected(reason: String) -> void:
	status_label.text = "Bonk! That spot doesn't fit"
	instructions_label.text = reason + " Try a green spot or give the tile a spin."


func _on_placed_count_changed(count: int) -> void:
	piece_count_label.text = "%d tile%s on the playmat" % [count, "" if count == 1 else "s"]


func _on_reset_pressed() -> void:
	if multiplayer.is_server() and state.session_active:
		_begin_new_round()
	elif not state.session_active:
		_reset_board_and_tray()


func _host_lobby() -> void:
	var cleaned_name := _clean_display_name(name_edit.text)
	if cleaned_name.is_empty():
		lobby_status_label.text = "Enter a display name first."
		return
	var lobby_code: String = LobbyCodeScript.encode(address_edit.text.strip_edges(), network_port)
	if lobby_code.is_empty():
		lobby_status_label.text = "Enter a valid IPv4 address, such as 127.0.0.1 or 192.168.1.20."
		return
	var error := network.host(network_port, MAX_PLAYERS)
	if error != OK:
		lobby_status_label.text = "Could not host on UDP port %d (error %d)." % [network_port, error]
		return
	local_display_name = cleaned_name
	state.create_host(cleaned_name)
	lobby_code_edit.text = lobby_code
	lobby_status_label.text = "Lobby ready. Share this code, then start when everyone has joined."
	_refresh_lobby_ui()


func _join_lobby() -> void:
	var cleaned_name := _clean_display_name(name_edit.text)
	if cleaned_name.is_empty():
		lobby_status_label.text = "Enter a display name first."
		return
	var decoded: Dictionary = LobbyCodeScript.decode(lobby_code_edit.text)
	if not decoded.ok:
		lobby_status_label.text = decoded.error
		return
	var error := network.join(decoded.address, decoded.port)
	if error != OK:
		lobby_status_label.text = "Could not begin connecting (error %d)." % error
		return
	local_display_name = cleaned_name
	state.session_active = true
	lobby_status_label.text = "Connecting to %s…" % decoded.address
	_refresh_lobby_ui()


func _on_connected_to_server() -> void:
	network.send_register_player(local_display_name)
	lobby_status_label.text = "Connected. Waiting for the host."


func _on_register_player_requested(peer_id: int, requested_name: String) -> void:
	if not multiplayer.is_server():
		return
	if state.game_started:
		network.reject_join_for(peer_id, "This lobby already has a game in progress.")
		return
	if state.players.size() >= MAX_PLAYERS and not state.players.has(peer_id):
		network.reject_join_for(peer_id, "The lobby is full.")
		return
	var unique_name := _make_unique_name(_clean_display_name(requested_name))
	if unique_name.is_empty():
		unique_name = "Player %d" % peer_id
	state.register_player(peer_id, unique_name)
	network.broadcast_lobby_state(state.players, state.player_order, state.player_wins)


func _on_join_rejected(reason: String) -> void:
	_leave_lobby(false)
	lobby_status_label.text = reason


func _apply_lobby_state(new_players: Dictionary, new_order: Array[int], new_wins: Dictionary) -> void:
	state.apply_lobby(new_players, new_order, new_wins)
	lobby_status_label.text = "Lobby ready. Waiting for the host to start."
	if multiplayer.is_server():
		lobby_status_label.text = "Lobby ready. Share the code and start when everyone has joined."
	_refresh_lobby_ui()


func _start_game() -> void:
	if multiplayer.is_server() and state.session_active:
		_begin_new_round()


func _begin_new_round() -> void:
	dealer.configure_for_player_count(state.players.size())
	var fresh_scores: Dictionary = {}
	for peer_id in state.player_order:
		fresh_scores[peer_id] = 0
	var fresh_trays := dealer.deal(piece_definitions.size(), state.player_order)
	network.broadcast_round_started(
		state.player_order,
		fresh_scores,
		fresh_trays,
		dealer.piece_well.size()
	)


func _apply_round_started(
	new_order: Array[int],
	fresh_scores: Dictionary,
	fresh_trays: Dictionary,
	well_piece_count: int
) -> void:
	state.begin_round(new_order, fresh_scores, fresh_trays, well_piece_count)
	if not state.player_order.is_empty() and state.player_tray_piece_ids.has(state.player_order[0]):
		dealer.pieces_per_player = state.player_tray_piece_ids[state.player_order[0]].size()
	lobby_overlay.visible = false
	win_overlay.visible = false
	_reset_board_and_tray()
	_set_game_controls_enabled(true)
	_update_game_ui()


func _on_board_placement_requested(
	piece_id: int,
	numbers: Array[int],
	center_offset: Vector2,
	rotation: float
) -> void:
	if not state.game_started or not _is_local_turn():
		return
	network.send_play_request(piece_id, numbers, center_offset, rotation)
	status_label.text = "Checking move…"

func _process_draw_from_well_requested(
	peer_id: int
) -> void:
	if not state.game_started or peer_id != state.current_player_id():
		network.reject_move_for(peer_id, "It is not your turn.")
		return
	if not dealer.has_pieces_in_well():
		network.reject_move_for(peer_id, "The piece well is empty.")
		return
	var piece_id := dealer.draw_piece_from_well()
	if piece_id < 0:
		network.reject_move_for(peer_id, "The piece well is empty.")
		return
	if state.player_current_turn_draws == 3:
		network.reject_move_for(peer_id, "The player can't draw anymore from the well this turn.")
	network.broadcast_piece_drawn(peer_id, piece_id, dealer.piece_well.size())


func _apply_piece_drawn(peer_id: int, piece_id: int, well_piece_count: int) -> void:
	state.add_piece_to_tray(peer_id, piece_id)
	state.well_piece_count = well_piece_count
	state.player_current_turn_draws += 1
	var player_name: String = state.players.get(peer_id, "A player")
	status_label.text = "%s grabbed a mystery tile!" % player_name
	if peer_id == multiplayer.get_unique_id():
		var drawn_piece: TriominoPiece = tray_pieces[piece_id]
		drawn_piece.visible = true
		drawn_piece.set_available(state.game_started)
		_sync_tray_order()
		instructions_label.text = "The new piece was added to your tray. You may still place a piece."
	else:
		instructions_label.text = "%s is still choosing a piece." % player_name
	draw_count_label.text = "%d / 3" % state.player_current_turn_draws
	_update_game_ui()

func _process_play_request(
	peer_id: int,
	piece_id: int,
	numbers: Array[int],
	center_offset: Vector2,
	rotation: float
) -> void:
	if not state.game_started or peer_id != state.current_player_id():
		network.reject_move_for(peer_id, "It is not your turn.")
		return
	if piece_id < 0 or piece_id >= piece_definitions.size():
		network.reject_move_for(peer_id, "That piece does not exist.")
		return
	if not state.has_tray_piece(peer_id, piece_id):
		network.reject_move_for(peer_id, "That piece is not in your tray.")
		return
	if state.has_used_piece(peer_id, piece_id):
		network.reject_move_for(peer_id, "That piece is no longer available.")
		return
	if not PieceCatalogScript.is_valid_rotation(piece_definitions[piece_id], numbers):
		network.reject_move_for(peer_id, "That piece rotation is invalid.")
		return
	if not board.is_network_placement_legal(center_offset, rotation, numbers):
		network.reject_move_for(peer_id, "That placement does not match the board.")
		return
	var board_features := board.get_placement_features(center_offset, rotation)
	var score_breakdown := scoring.placement_score(numbers, board_features, state.player_current_turn_draws)
	var updated_scores := state.player_scores.duplicate()
	updated_scores[peer_id] = int(updated_scores.get(peer_id, 0)) + int(score_breakdown.total)
	var next_turn := (state.current_turn_index + 1) % state.player_order.size()
	network.broadcast_placement(
		peer_id,
		piece_id,
		numbers,
		center_offset,
		rotation,
		score_breakdown,
		updated_scores,
		next_turn
	)



func _on_move_rejected(reason: String) -> void:
	status_label.text = "Oopsie! Try another move"
	instructions_label.text = reason
	_update_draw_button()


func _apply_placement(
	peer_id: int,
	piece_id: int,
	numbers: Array[int],
	center_offset: Vector2,
	rotation: float,
	score_breakdown: Dictionary,
	updated_scores: Dictionary,
	next_turn: int
) -> void:
	if not state.apply_placement(peer_id, piece_id, updated_scores, next_turn):
		return
	board.commit_network_piece(piece_id, numbers, center_offset, rotation)
	var placed_piece: TriominoPiece = tray_pieces[piece_id]
	if peer_id == multiplayer.get_unique_id():
		placed_piece.set_selected(false)
		placed_piece.set_available(false)
		placed_piece.visible = false
	if selected_tray_piece != null:
		selected_tray_piece.set_selected(false)
	selected_tray_piece = null
	rotate_button.disabled = true
	var player_name: String = state.players.get(peer_id, "A player")
	status_label.text = "%s got %d points! ✦" % [player_name, int(score_breakdown.total)]
	if int(score_breakdown.bonus) > 0:
		instructions_label.text = "%d tile points + %d %s bonus" % [
			int(score_breakdown.tile_points),
			int(score_breakdown.bonus),
			score_breakdown.bonus_label
		]
	else:
		instructions_label.text = "%d points from the tile." % int(score_breakdown.tile_points)
	var local_peer_id := multiplayer.get_unique_id()
	var remaining := _remaining_piece_count(local_peer_id)

	if remaining == 0:
		declare_winner(local_peer_id)

	_update_game_ui()


func declare_winner(winner_peer_id: int) -> void:
	if not multiplayer.is_server() or not state.session_active or not state.players.has(winner_peer_id):
		return
	var updated_wins := state.player_wins.duplicate()
	updated_wins[winner_peer_id] = int(updated_wins.get(winner_peer_id, 0)) + 1
	network.broadcast_winner(winner_peer_id, updated_wins)


func _apply_winner(winner_peer_id: int, updated_wins: Dictionary) -> void:
	state.apply_winner(winner_peer_id, updated_wins)
	board.clear_selection()
	if selected_tray_piece != null:
		selected_tray_piece.set_selected(false)
	selected_tray_piece = null
	_set_game_controls_enabled(false)
	var winner_name: String = state.players.get(winner_peer_id, "A player")
	var winner_wins := int(state.player_wins.get(winner_peer_id, 0))
	turn_label.text = "%s WINS!" % winner_name.to_upper()
	winner_name_label.text = "%s WINS!" % winner_name.to_upper()
	win_summary_label.text = "%d lobby win%s" % [winner_wins, "" if winner_wins == 1 else "s"]
	lobby_status_label.text = "%s won the last round." % winner_name
	lobby_overlay.visible = false
	win_overlay.visible = true
	_refresh_lobby_ui()


func _continue_after_win() -> void:
	win_overlay.visible = false
	lobby_overlay.visible = true
	_refresh_lobby_ui()


func _on_peer_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server() or not state.players.has(peer_id):
		return
	state.remove_player(peer_id)
	network.broadcast_player_state(
		state.players,
		state.player_order,
		state.player_scores,
		state.player_wins,
		state.current_turn_index,
		state.game_started
	)


func _apply_player_state(
	new_players: Dictionary,
	new_order: Array[int],
	new_scores: Dictionary,
	new_wins: Dictionary,
	new_turn_index: int,
	round_in_progress: bool
) -> void:
	state.apply_player_snapshot(
		new_players,
		new_order,
		new_scores,
		new_wins,
		new_turn_index,
		round_in_progress
	)
	_refresh_lobby_ui()
	_update_game_ui()


func _on_connection_failed() -> void:
	_leave_lobby(false)
	lobby_status_label.text = "Connection failed. Check the code and the host's firewall/port forwarding."


func _on_server_disconnected() -> void:
	_leave_lobby(false)
	lobby_status_label.text = "The host disconnected."


func _leave_lobby(show_default_message: bool = true) -> void:
	network.close()
	state.clear()
	dealer.clear()
	lobby_overlay.visible = true
	win_overlay.visible = false
	_reset_board_and_tray()
	_set_game_controls_enabled(false)
	if show_default_message:
		lobby_status_label.text = "Host a lobby or join one with a code."
	_refresh_lobby_ui()


func _reset_board_and_tray() -> void:
	board.reset_board()
	total_score = 0
	score_value_label.text = "0"
	selected_tray_piece = null
	rotate_button.disabled = true
	for piece_id in tray_pieces:
		var piece: TriominoPiece = tray_pieces[piece_id]
		piece.configure(
			piece_id,
			PieceCatalogScript.typed_numbers(piece_definitions[piece_id]),
			TRAY_TILE_SIDE
		)
		piece.set_selected(false)
		piece.set_available(true)
	status_label.text = "Waiting for the first move"
	instructions_label.text = "The first player chooses a piece and places it in the center."
	draw_count_label.text = "0 / 3"
	_update_hand_count()


func _set_game_controls_enabled(enabled: bool) -> void:
	reset_button.disabled = not enabled or not multiplayer.is_server()
	var local_peer_id := multiplayer.get_unique_id()
	var has_assigned_tray := state.player_tray_piece_ids.has(local_peer_id)
	for piece_id in tray_pieces:
		var piece: TriominoPiece = tray_pieces[piece_id]
		var belongs_to_local_tray := has_assigned_tray and state.has_tray_piece(local_peer_id, piece_id)
		var was_used := state.has_used_piece(local_peer_id, piece_id)
		piece.visible = belongs_to_local_tray and not was_used
		piece.set_available(enabled and belongs_to_local_tray and not was_used)
	_sync_tray_order()
	rotate_button.disabled = true
	_update_draw_button()


func _sync_tray_order() -> void:
	var local_peer_id := multiplayer.get_unique_id()
	var acquired_piece_ids: Array = state.player_tray_piece_ids.get(local_peer_id, [])
	var target_index := 0
	for piece_id in acquired_piece_ids:
		if not tray_pieces.has(piece_id):
			continue
		var piece: TriominoPiece = tray_pieces[piece_id]
		piece_tray.move_child(piece, target_index)
		target_index += 1


func _update_draw_button() -> void:
	draw_from_well_button.disabled = (
		not state.game_started
		or not _is_local_turn()
		or state.well_piece_count <= 0
		or state.player_current_turn_draws >= 3
	)
	draw_from_well_button.tooltip_text = "%d mystery tiles remaining" % state.well_piece_count
	well_count_label.text = "MYSTERY PILE  %d" % state.well_piece_count
	draw_count_label.text = "%d / 3" % state.player_current_turn_draws


func _update_game_ui() -> void:
	if not state.game_started or state.player_order.is_empty():
		turn_label.text = "★  READY TO PLAY?  ★"
		turn_panel.add_theme_stylebox_override("panel", GameHudScript.turn_style(false))
		score_value_label.text = "0"
		_rebuild_player_cards()
		_update_hand_count()
		_update_draw_button()
		_refresh_tray_toggle_copy()
		return
	var current_name := state.current_player_name()
	turn_label.text = "★  YOUR TURN! GO GO GO!  ★" if _is_local_turn() else "▲  %s'S PICK!" % current_name.to_upper()
	turn_panel.add_theme_stylebox_override("panel", GameHudScript.turn_style(_is_local_turn()))
	total_score = int(state.player_scores.get(multiplayer.get_unique_id(), 0))
	score_value_label.text = str(total_score)
	_rebuild_player_cards()
	_update_hand_count()
	if not _is_local_turn():
		board.clear_selection()
		rotate_button.disabled = true
	_update_draw_button()
	_refresh_tray_toggle_copy()


func _update_hand_count() -> void:
	var local_peer_id := multiplayer.get_unique_id()
	var remaining := _remaining_piece_count(local_peer_id)
	hand_count_label.text = "%d TILE%s" % [remaining, "" if remaining == 1 else "S"]
	_update_tray_layout(state.game_started)


func _update_tray_layout(animate: bool = true) -> void:
	var remaining := _remaining_piece_count(multiplayer.get_unique_id())
	var available_width := tray_well.size.x - 16.0
	if available_width < TRAY_TILE_SIZE.x:
		available_width = maxf(420.0, size.x - 370.0)
	var columns := maxi(1, int(floor((available_width + 8.0) / (TRAY_TILE_SIZE.x + 8.0))))
	var rows := maxi(1, ceili(float(remaining) / float(columns)))
	var rack_height := 118.0 + float(rows - 1) * HAND_TRAY_ROW_HEIGHT
	tray_well.custom_minimum_size.y = rack_height
	var maximum_height := maxf(HAND_TRAY_BASE_HEIGHT, size.y - 188.0)
	hand_tray_height = minf(
		HAND_TRAY_BASE_HEIGHT + float(rows - 1) * HAND_TRAY_ROW_HEIGHT,
		maximum_height
	)
	_set_hand_tray_position(animate)


func _remaining_piece_count(peer_id: int) -> int:
	var tray_ids: Array = state.player_tray_piece_ids.get(peer_id, [])
	var used_ids: Dictionary = state.used_piece_ids_by_player.get(peer_id, {})
	return maxi(0, tray_ids.size() - used_ids.size())


func _rebuild_player_cards() -> void:
	for child in player_cards_container.get_children():
		player_cards_container.remove_child(child)
		child.queue_free()
	if state.player_order.is_empty():
		var empty_state := _hud_label("Invite some buddies to the table!  ★", 14, Color("#fff8df"))
		player_cards_container.add_child(empty_state)
		return

	var local_peer_id := multiplayer.get_unique_id()
	var available_width := get_viewport_rect().size.x - 36.0 - float(maxi(0, state.player_order.size() - 1) * 10)
	var card_width := clampf(available_width / float(state.player_order.size()), 190.0, 292.0)
	for peer_id in state.player_order:
		var card_index := state.player_order.find(peer_id)
		var is_active := peer_id == state.current_player_id() and state.game_started
		var is_local := peer_id == local_peer_id
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(card_width, 58)
		card.add_theme_stylebox_override("panel", GameHudScript.player_card_style(card_index, is_active, is_local))
		card.rotation_degrees = [-1.4, 1.1, -0.8, 1.5][card_index % 4]
		card.pivot_offset = Vector2(card_width * 0.5, 29)
		if is_active:
			card.scale = Vector2(1.035, 1.035)
		player_cards_container.add_child(card)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 11)
		margin.add_theme_constant_override("margin_top", 7)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 7)
		card.add_child(margin)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		margin.add_child(row)

		var avatar := PanelContainer.new()
		avatar.custom_minimum_size = Vector2(38, 38)
		var avatar_style := StyleBoxFlat.new()
		avatar_style.bg_color = Color("#fff8df")
		avatar_style.border_color = Color("#3d315b")
		avatar_style.set_border_width_all(2)
		avatar_style.set_corner_radius_all(19)
		avatar.add_theme_stylebox_override("panel", avatar_style)
		row.add_child(avatar)
		var player_name := str(state.players.get(peer_id, "Player"))
		var avatar_label := _hud_label(player_name.left(1).to_upper(), 16, Color("#3d315b"))
		avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		avatar.add_child(avatar_label)

		var identity := VBoxContainer.new()
		identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		identity.add_theme_constant_override("separation", 0)
		row.add_child(identity)
		var name_suffix := "  (ME!)" if is_local else ""
		var name_label := _hud_label(player_name + name_suffix, 14, Color("#34294f"))
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		identity.add_child(name_label)
		var meta_copy := "▲  × %d tile%s" % [_remaining_piece_count(peer_id), "" if _remaining_piece_count(peer_id) == 1 else "s"]
		if is_active:
			meta_copy = "★ PLAYING!  •  " + meta_copy
		identity.add_child(_hud_label(meta_copy, 10, Color("#4a345a")))

		var score_stack := VBoxContainer.new()
		score_stack.add_theme_constant_override("separation", -2)
		row.add_child(score_stack)
		var score_number := _hud_label(str(int(state.player_scores.get(peer_id, 0))), 22, Color("#34294f"))
		score_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_stack.add_child(score_number)
		var points_label := _hud_label("POINTS!", 8, Color("#5c4962"))
		points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_stack.add_child(points_label)


func _hud_label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _refresh_lobby_ui() -> void:
	name_edit.editable = not state.session_active
	address_label.visible = not state.session_active
	address_row.visible = not state.session_active
	host_button.visible = not state.session_active
	or_label.visible = not state.session_active
	join_button.visible = not state.session_active
	leave_button.visible = state.session_active
	start_button.visible = state.session_active
	start_button.disabled = not state.session_active or not multiplayer.is_server()
	if multiplayer.is_server():
		start_button.text = "Start next round" if state.has_lobby_wins() else "Start game"
	else:
		start_button.text = "Waiting for host…"
	lobby_code_edit.editable = not state.session_active
	copy_button.disabled = lobby_code_edit.text.strip_edges().is_empty()
	if state.players.is_empty():
		lobby_player_list.text = "No players connected"
	else:
		var lines: Array[String] = ["PLAYERS (%d/%d)" % [state.players.size(), MAX_PLAYERS]]
		for peer_id in state.player_order:
			var suffix := " (host)" if peer_id == 1 else ""
			var wins := int(state.player_wins.get(peer_id, 0))
			lines.append("• %s%s — %d win%s" % [
				state.players.get(peer_id, "Player"),
				suffix,
				wins,
				"" if wins == 1 else "s"
			])
		lobby_player_list.text = "\n".join(lines)


func _is_local_turn() -> bool:
	return state.is_peer_turn(multiplayer.get_unique_id())


func _clean_display_name(raw_name: String) -> String:
	return raw_name.strip_edges().replace("\n", " ").replace("\r", " ").substr(0, 24)


func _make_unique_name(requested_name: String) -> String:
	var existing_names: Array[String] = []
	for peer_id in state.players:
		existing_names.append(str(state.players[peer_id]).to_lower())
	if not existing_names.has(requested_name.to_lower()):
		return requested_name
	var suffix := 2
	while existing_names.has((requested_name + " (%d)" % suffix).to_lower()):
		suffix += 1
	return (requested_name + " (%d)" % suffix).substr(0, 24)


func _copy_lobby_code() -> void:
	if not lobby_code_edit.text.is_empty():
		DisplayServer.clipboard_set(lobby_code_edit.text)
		lobby_status_label.text = "Lobby code copied."


func _use_localhost() -> void:
	address_edit.text = "127.0.0.1"
	lobby_status_label.text = "Localhost selected. This code works only on this computer."


func _find_lan_ipv4() -> String:
	for address in IP.get_local_addresses():
		if address.contains(":") or address.begins_with("127.") or address.begins_with("169.254."):
			continue
		return address
	return "127.0.0.1"
