class_name TriominoGameHud
extends RefCounted

const INK := Color("#34294f")
const CREAM := Color("#fff8df")
const MUTED := Color("#735b69")
const SUN := Color("#ffd34e")
const PURPLE := Color("#6256b3")
const PLUM := Color("#3d315b")
const WOOD := Color("#c86b38")
const WOOD_DARK := Color("#713923")
const PLAYER_COLORS: Array[Color] = [
	Color("#ffd34e"),
	Color("#67d5c0"),
	Color("#ff8c8c"),
	Color("#8eb8ff"),
]


static func build(root: Control, board: Control) -> Dictionary:
	var old_layout := root.get_node("Layout") as Control
	old_layout.visible = false
	(root.get_node("Background") as ColorRect).color = PURPLE

	var board_area := MarginContainer.new()
	board_area.name = "BoardArea"
	board_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_area.add_theme_constant_override("margin_left", 12)
	board_area.add_theme_constant_override("margin_top", 126)
	board_area.add_theme_constant_override("margin_right", 12)
	board_area.add_theme_constant_override("margin_bottom", 14)
	root.add_child(board_area)

	var board_shell := PanelContainer.new()
	board_shell.name = "BoardShell"
	board_shell.add_theme_stylebox_override("panel", _panel(CREAM, Color("#f0b83f"), 28, 14, 5))
	board_area.add_child(board_shell)
	var board_margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		board_margin.add_theme_constant_override("margin_" + side, 5)
	board_shell.add_child(board_margin)
	board.reparent(board_margin)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var top_margin := MarginContainer.new()
	top_margin.name = "TopBarMargin"
	top_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_margin.offset_left = 12
	top_margin.offset_top = 10
	top_margin.offset_right = -12
	top_margin.offset_bottom = 64
	root.add_child(top_margin)
	var top_panel := PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", _panel(Color("#4b4397"), Color("#8175d4"), 22, 8, 2))
	top_margin.add_child(top_panel)
	var top_padding := _margin(16, 6, 10, 6)
	top_panel.add_child(top_padding)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_padding.add_child(top_row)
	var brand := _label("▲  TRIOMINO!", 21, SUN)
	brand.add_theme_color_override("font_shadow_color", Color("#332c73"))
	brand.add_theme_constant_override("shadow_offset_x", 2)
	brand.add_theme_constant_override("shadow_offset_y", 3)
	top_row.add_child(brand)
	var brand_rule := ColorRect.new()
	brand_rule.custom_minimum_size = Vector2(1, 28)
	brand_rule.color = Color("#8d83dd")
	top_row.add_child(brand_rule)
	var table_label := _label("PLAY • LAUGH • WIN!", 11, Color("#ded9ff"))
	table_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(table_label)
	top_row.add_child(_spacer())
	var turn_panel := PanelContainer.new()
	turn_panel.custom_minimum_size = Vector2(244, 36)
	turn_panel.add_theme_stylebox_override("panel", turn_style(false))
	top_row.add_child(turn_panel)
	var turn_label := _label("★  WHO GOES FIRST?  ★", 15, INK)
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_panel.add_child(turn_label)
	turn_panel.pivot_offset = Vector2(122, 18)
	var badge_bob := turn_panel.create_tween().set_loops()
	badge_bob.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	badge_bob.tween_property(turn_panel, "rotation_degrees", -0.7, 0.7)
	badge_bob.tween_property(turn_panel, "rotation_degrees", 0.7, 0.7)
	var score_caption := _label("MY SCORE", 10, Color("#ded9ff"))
	score_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(score_caption)
	var score_value := _label("0", 26, SUN)
	score_value.custom_minimum_size = Vector2(54, 0)
	score_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(score_value)
	var reset_button := Button.new()
	reset_button.custom_minimum_size = Vector2(104, 34)
	reset_button.text = "New round"
	reset_button.disabled = true
	_style_button(reset_button, Color("#8eb8ff"), INK)
	var fullscreen_button := Button.new()
	fullscreen_button.custom_minimum_size = Vector2(116, 34)
	fullscreen_button.text = "□  Fullscreen"
	fullscreen_button.tooltip_text = "Toggle fullscreen (F11)"
	_style_button(fullscreen_button, Color("#c9a8ef"), INK)
	top_row.add_child(fullscreen_button)
	top_row.add_child(reset_button)

	var player_margin := MarginContainer.new()
	player_margin.name = "PlayerStrip"
	player_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	player_margin.offset_left = 12
	player_margin.offset_top = 68
	player_margin.offset_right = -12
	player_margin.offset_bottom = 120
	root.add_child(player_margin)
	var player_cards := HBoxContainer.new()
	player_cards.name = "PlayerCards"
	player_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	player_cards.add_theme_constant_override("separation", 10)
	player_margin.add_child(player_cards)
	var empty_players := _label("Invite some buddies to the table!  ★", 14, CREAM)
	empty_players.name = "EmptyState"
	player_cards.add_child(empty_players)

	var view_margin := MarginContainer.new()
	view_margin.name = "ViewControls"
	view_margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	view_margin.offset_left = -386
	view_margin.offset_top = 134
	view_margin.offset_right = -26
	view_margin.offset_bottom = 180
	root.add_child(view_margin)
	var view_panel := PanelContainer.new()
	view_panel.add_theme_stylebox_override("panel", _panel(Color("#fff0c9"), Color("#3d315b"), 18, 5, 3))
	view_margin.add_child(view_panel)
	var view_padding := _margin(7, 5, 7, 5)
	view_panel.add_child(view_padding)
	var view_row := HBoxContainer.new()
	view_row.add_theme_constant_override("separation", 6)
	view_padding.add_child(view_row)
	var view_hint := _label("MOVE THE MAT", 10, MUTED)
	view_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	view_row.add_child(view_hint)
	var zoom_out_button := Button.new()
	zoom_out_button.custom_minimum_size = Vector2(36, 32)
	zoom_out_button.text = "−"
	zoom_out_button.tooltip_text = "Zoom out"
	_style_button(zoom_out_button, Color("#c9a8ef"), INK)
	view_row.add_child(zoom_out_button)
	var zoom_label := _label("100%", 11, INK)
	zoom_label.custom_minimum_size = Vector2(46, 0)
	zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zoom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	view_row.add_child(zoom_label)
	var zoom_in_button := Button.new()
	zoom_in_button.custom_minimum_size = Vector2(36, 32)
	zoom_in_button.text = "+"
	zoom_in_button.tooltip_text = "Zoom in"
	_style_button(zoom_in_button, Color("#c9a8ef"), INK)
	view_row.add_child(zoom_in_button)
	var center_view_button := Button.new()
	center_view_button.custom_minimum_size = Vector2(92, 32)
	center_view_button.text = "⌾  Center"
	center_view_button.tooltip_text = "Recenter the play area (C)"
	_style_button(center_view_button, SUN, INK)
	view_row.add_child(center_view_button)

	var event_margin := MarginContainer.new()
	event_margin.name = "GameEventBanner"
	event_margin.set_anchors_preset(Control.PRESET_CENTER_TOP)
	event_margin.offset_left = -226
	event_margin.offset_top = 134
	event_margin.offset_right = 226
	event_margin.offset_bottom = 204
	event_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(event_margin)
	var event_banner := PanelContainer.new()
	event_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_banner.add_theme_stylebox_override("panel", event_style(SUN))
	event_margin.add_child(event_banner)
	var event_padding := _margin(14, 8, 16, 8)
	event_banner.add_child(event_padding)
	var event_row := HBoxContainer.new()
	event_row.add_theme_constant_override("separation", 11)
	event_padding.add_child(event_row)
	var event_icon := _label("★", 28, PURPLE)
	event_icon.custom_minimum_size = Vector2(38, 0)
	event_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	event_row.add_child(event_icon)
	var status_copy := VBoxContainer.new()
	status_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_copy.add_theme_constant_override("separation", 1)
	event_row.add_child(status_copy)
	var status := _label("Pick a tile!", 16, INK)
	status_copy.add_child(status)
	var instructions := _label("Grab one from the box and pop it onto a green spot.", 11, MUTED)
	instructions.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_copy.add_child(instructions)

	var action_dock := MarginContainer.new()
	action_dock.name = "ActionDock"
	action_dock.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action_dock.offset_left = -404
	action_dock.offset_top = -206
	action_dock.offset_right = -18
	action_dock.offset_bottom = -156
	root.add_child(action_dock)
	var action_panel := PanelContainer.new()
	action_panel.add_theme_stylebox_override("panel", _panel(Color("#4b4397"), Color("#fff0c9"), 18, 6, 3))
	action_dock.add_child(action_panel)
	var action_padding := _margin(8, 5, 8, 5)
	action_panel.add_child(action_padding)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	action_padding.add_child(controls)
	var rotate_button := Button.new()
	rotate_button.custom_minimum_size = Vector2(148, 38)
	rotate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotate_button.text = "↻  Rotate  R"
	rotate_button.disabled = true
	_style_button(rotate_button, Color("#ffd34e"), INK)
	controls.add_child(rotate_button)
	var draw_button := Button.new()
	draw_button.custom_minimum_size = Vector2(138, 38)
	draw_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	draw_button.text = "+  Draw tile"
	_style_button(draw_button, Color("#67d5c0"), INK)
	controls.add_child(draw_button)
	var draw_count := _label("0 / 3", 10, CREAM)
	draw_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls.add_child(draw_count)

	var hand_panel := PanelContainer.new()
	hand_panel.name = "HandPanel"
	hand_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hand_panel.offset_top = -148
	hand_panel.clip_contents = true
	hand_panel.add_theme_stylebox_override("panel", _panel(WOOD, WOOD_DARK, 26, 12, 4))
	root.add_child(hand_panel)
	var hand_padding := _margin(14, 7, 14, 9)
	hand_panel.add_child(hand_padding)
	var hand_content := VBoxContainer.new()
	hand_content.add_theme_constant_override("separation", 5)
	hand_padding.add_child(hand_content)

	var hand_header := HBoxContainer.new()
	hand_header.add_theme_constant_override("separation", 9)
	hand_content.add_child(hand_header)
	var tray_title := _label("MY TILES", 14, CREAM)
	hand_header.add_child(tray_title)
	var hand_count := _label("0 TILES", 10, Color("#ffe0b2"))
	hand_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hand_header.add_child(hand_count)
	hand_header.add_child(_spacer())
	var board_count := _label("0 tiles on the playmat", 10, Color("#ffe0b2"))
	board_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hand_header.add_child(board_count)
	var well_count := _label("MYSTERY PILE  0", 10, CREAM)
	well_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hand_header.add_child(well_count)
	var tray_toggle := Button.new()
	tray_toggle.name = "TrayToggle"
	tray_toggle.custom_minimum_size = Vector2(144, 30)
	tray_toggle.text = "▼  Hide my tiles"
	_style_button(tray_toggle, SUN, INK)
	hand_header.add_child(tray_toggle)

	var tray_well := PanelContainer.new()
	tray_well.name = "TrayWell"
	tray_well.custom_minimum_size = Vector2(0, 94)
	tray_well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tray_well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tray_well.add_theme_stylebox_override("panel", _panel(Color("#8f462b"), Color("#62301f"), 14, 0, 3))
	hand_content.add_child(tray_well)
	var tray_padding := _margin(6, 3, 6, 3)
	tray_well.add_child(tray_padding)
	var tray := HBoxContainer.new()
	tray.name = "PieceTray"
	tray.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tray.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tray.add_theme_constant_override("separation", 6)
	tray_padding.add_child(tray)

	var fx_layer := Control.new()
	fx_layer.name = "GameFxLayer"
	fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fx_layer)

	_style_overlays(root)
	root.move_child(root.get_node("LobbyOverlay"), root.get_child_count() - 1)
	root.move_child(root.get_node("WinOverlay"), root.get_child_count() - 1)
	return {
		"piece_tray": tray,
		"score_value": score_value,
		"turn_label": turn_label,
		"turn_panel": turn_panel,
		"player_cards": player_cards,
		"status": status,
		"instructions": instructions,
		"rotate_button": rotate_button,
		"draw_button": draw_button,
		"draw_count": draw_count,
		"board_count": board_count,
		"hand_count": hand_count,
		"well_count": well_count,
		"reset_button": reset_button,
		"fullscreen_button": fullscreen_button,
		"hand_panel": hand_panel,
		"action_dock": action_dock,
		"event_banner": event_banner,
		"event_icon": event_icon,
		"fx_layer": fx_layer,
		"tray_toggle": tray_toggle,
		"tray_well": tray_well,
		"board_area": board_area,
		"zoom_out_button": zoom_out_button,
		"zoom_in_button": zoom_in_button,
		"center_view_button": center_view_button,
		"zoom_label": zoom_label,
	}


static func player_card_style(index: int, active: bool, local: bool = false) -> StyleBoxFlat:
	var background := PLAYER_COLORS[index % PLAYER_COLORS.size()]
	var border := Color("#ffffff") if active else Color("#3d315b")
	if local and not active:
		border = SUN
	return _panel(background, border, 18, 7 if active else 3, 4 if active else 2)


static func turn_style(local_turn: bool) -> StyleBoxFlat:
	return _panel(
		SUN if local_turn else Color("#fff0c9"),
		Color("#ffffff") if local_turn else Color("#3d315b"),
		22,
		5,
		3
	)


static func event_style(accent: Color) -> StyleBoxFlat:
	return _panel(Color("#fff8df"), accent, 18, 7, 4)


static func _style_overlays(root: Control) -> void:
	var lobby := root.get_node("LobbyOverlay") as Control
	(lobby.get_node("Dim") as ColorRect).color = Color(0.24, 0.19, 0.47, 0.94)
	var lobby_panel := lobby.get_node("Center/Panel") as PanelContainer
	lobby_panel.add_theme_stylebox_override("panel", _panel(CREAM, SUN, 28, 18, 6))
	var lobby_content := lobby.get_node("Center/Panel/Margin/Content") as VBoxContainer
	lobby_content.add_theme_constant_override("separation", 11)
	var lobby_title := lobby_content.get_node("Title") as Label
	lobby_title.text = "COME PLAY! ★"
	lobby_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby_title.add_theme_font_size_override("font_size", 32)
	lobby_title.add_theme_color_override("font_color", PLUM)
	lobby_title.add_theme_color_override("font_shadow_color", Color("#f0b83f"))
	lobby_title.add_theme_constant_override("shadow_offset_x", 2)
	lobby_title.add_theme_constant_override("shadow_offset_y", 3)
	var lobby_confetti := _label("●   ▲   ★   ▲   ●", 15, Color("#ff777f"))
	lobby_confetti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby_content.add_child(lobby_confetti)
	lobby_content.move_child(lobby_confetti, 1)
	var lobby_status := lobby_content.get_node("Status") as Label
	lobby_status.text = "Make a table, grab the secret code, and invite your buddies!"
	lobby_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby_status.add_theme_color_override("font_color", MUTED)
	(lobby_content.get_node("NameLabel") as Label).text = "What should your game token say?"
	(lobby_content.get_node("AddressLabel") as Label).text = "Where can your buddies find this table?"
	var or_label := lobby_content.get_node("OrLabel") as Label
	or_label.text = "★  OR JOIN A FRIEND  ★"
	or_label.add_theme_color_override("font_color", PURPLE)
	var player_list := lobby_content.get_node("PlayerList") as Label
	player_list.add_theme_color_override("font_color", PLUM)
	player_list.add_theme_font_size_override("font_size", 14)
	var help := lobby_content.get_node("Help") as Label
	help.add_theme_color_override("font_color", MUTED)
	_style_input(lobby_content.get_node("NameEdit") as LineEdit)
	_style_input(lobby_content.get_node("AddressRow/AddressEdit") as LineEdit)
	_style_input(lobby_content.get_node("CodeRow/LobbyCodeEdit") as LineEdit)
	_style_button(lobby_content.get_node("HostButton") as Button, SUN, INK)
	_style_button(lobby_content.get_node("JoinButton") as Button, Color("#67d5c0"), INK)
	_style_button(lobby_content.get_node("StartButton") as Button, Color("#ff8c8c"), INK)
	_style_button(lobby_content.get_node("LeaveButton") as Button, Color("#ff9d9d"), INK)
	_style_button(lobby_content.get_node("AddressRow/LocalTestButton") as Button, Color("#c9a8ef"), INK)
	_style_button(lobby_content.get_node("CodeRow/CopyButton") as Button, Color("#c9a8ef"), INK)

	var win := root.get_node("WinOverlay") as Control
	(win.get_node("Dim") as ColorRect).color = Color(0.24, 0.19, 0.47, 0.92)
	var win_panel := win.get_node("Center/Panel") as PanelContainer
	win_panel.add_theme_stylebox_override("panel", _panel(Color("#fff0c9"), Color("#ff777f"), 30, 22, 7))
	var win_content := win.get_node("Center/Panel/Margin/Content") as VBoxContainer
	win_content.add_theme_constant_override("separation", 17)
	var eyebrow := win_content.get_node("Eyebrow") as Label
	eyebrow.text = "★  SUPER DUPER WINNER  ★"
	eyebrow.add_theme_color_override("font_color", Color("#e84f67"))
	eyebrow.add_theme_font_size_override("font_size", 16)
	var winner_name := win_content.get_node("WinnerName") as Label
	winner_name.add_theme_color_override("font_color", PLUM)
	winner_name.add_theme_font_size_override("font_size", 38)
	var win_summary := win_content.get_node("WinSummary") as Label
	win_summary.add_theme_color_override("font_color", MUTED)
	var win_confetti := _label("▲  ●  ★  ●  ▲", 21, PURPLE)
	win_confetti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_content.add_child(win_confetti)
	win_content.move_child(win_confetti, win_content.get_child_count() - 2)
	_style_button(win_content.get_node("ContinueButton") as Button, Color("#67d5c0"), INK)


static func _label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


static func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


static func _spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


static func _style_button(button: Button, background: Color, text_color: Color) -> void:
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color(text_color, 0.48))
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _button_box(background, Color("#3d315b"), 12, 0))
	button.add_theme_stylebox_override("hover", _button_box(background.lightened(0.12), Color("#ffffff"), 12, 4))
	button.add_theme_stylebox_override("pressed", _button_box(background.darkened(0.1), Color("#3d315b"), 12, 1))
	button.add_theme_stylebox_override("disabled", _button_box(background.darkened(0.18), Color("#6e5d72"), 12, 0))


static func _style_input(input: LineEdit) -> void:
	input.add_theme_color_override("font_color", INK)
	input.add_theme_color_override("font_placeholder_color", Color("#8f7886"))
	input.add_theme_color_override("caret_color", PURPLE)
	var normal := _panel(Color("#ffffff"), Color("#8f78bd"), 12, 2, 2)
	normal.content_margin_left = 13
	normal.content_margin_right = 13
	var focus := _panel(Color("#ffffff"), PURPLE, 12, 4, 3)
	focus.content_margin_left = 13
	focus.content_margin_right = 13
	input.add_theme_stylebox_override("normal", normal)
	input.add_theme_stylebox_override("focus", focus)


static func _button_box(background: Color, border: Color, radius: int, lift: int) -> StyleBoxFlat:
	var style := _panel(background, border, radius, 3, 2)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 7 + lift
	style.content_margin_bottom = 7 - lift
	return style


static func _panel(
	background: Color,
	border: Color,
	radius: int,
	shadow_size: int = 0,
	border_width: int = 1
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	if shadow_size > 0:
		style.shadow_color = Color(0.01, 0.03, 0.035, 0.32)
		style.shadow_size = shadow_size
		style.shadow_offset = Vector2(0, 4)
	return style
