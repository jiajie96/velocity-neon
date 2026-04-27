extends Control

var hp_bar: ProgressBar
var hp_label: Label
var xp_bar: ProgressBar
var wave_label: Label
var kills_label: Label
var level_label: Label
var dash_indicator: Label
var ult_indicator: Label
var wave_announce: Label
var upgrade_panel: PanelContainer
var upgrade_buttons: Array[Button] = []
var game_over_panel: PanelContainer
var title_screen: PanelContainer
var controls_label: Label

var _current_choices: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_title_screen()
	_build_top_bar()
	_build_bottom_bar()
	_build_wave_announce()
	_build_upgrade_panel()
	_build_game_over()

	GameState.hp_changed.connect(_on_hp_changed)
	GameState.xp_changed.connect(_on_xp_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.kills_changed.connect(_on_kills_changed)
	GameState.leveled_up.connect(_on_leveled_up)
	GameState.player_died.connect(_on_player_died)

	_on_hp_changed(GameState.hp, GameState.max_hp)
	_on_xp_changed(GameState.xp, GameState.xp_to_next)

# === TITLE SCREEN ===

func _build_title_screen() -> void:
	title_screen = PanelContainer.new()
	title_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.01, 0.005, 0.03, 0.95)
	title_screen.add_theme_stylebox_override("panel", bg)

	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 20)
	title_screen.add_child(center)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size.y = 80
	center.add_child(spacer_top)

	# Title
	var title := Label.new()
	title.text = "VELOCITY NEON"
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "HAPTIC HAVOC"
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.0, 0.7))
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(subtitle)

	var sep := Control.new()
	sep.custom_minimum_size.y = 30
	center.add_child(sep)

	# Controls
	var controls_panel := PanelContainer.new()
	controls_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls_panel.custom_minimum_size = Vector2(500, 0)
	var cp_style := StyleBoxFlat.new()
	cp_style.bg_color = Color(0.03, 0.015, 0.06, 0.8)
	cp_style.border_color = Color(0.0, 0.6, 0.8, 0.3)
	cp_style.border_width_top = 1
	cp_style.border_width_bottom = 1
	cp_style.border_width_left = 1
	cp_style.border_width_right = 1
	cp_style.corner_radius_top_left = 6
	cp_style.corner_radius_top_right = 6
	cp_style.corner_radius_bottom_left = 6
	cp_style.corner_radius_bottom_right = 6
	cp_style.content_margin_left = 30
	cp_style.content_margin_right = 30
	cp_style.content_margin_top = 20
	cp_style.content_margin_bottom = 20
	controls_panel.add_theme_stylebox_override("panel", cp_style)

	var controls_text := Label.new()
	controls_text.text = """HOW TO PLAY

WASD / Arrows    Move on the neon grid
Auto-Aim         Shoots nearest enemy automatically
SPACE            Phase Dash (invincible + fire trail)
Q                Ultimate Ability (area damage burst)
Scroll Wheel     Zoom camera in/out
R                Restart game
ESC              Quit

Survive waves of enemies. Kill them for XP.
Level up to choose powerful upgrades.
Every 5th wave summons a BOSS."""
	controls_text.add_theme_color_override("font_color", Color(0.7, 0.65, 0.85))
	controls_text.add_theme_font_size_override("font_size", 15)
	controls_panel.add_child(controls_text)
	center.add_child(controls_panel)

	var sep2 := Control.new()
	sep2.custom_minimum_size.y = 20
	center.add_child(sep2)

	var start_label := Label.new()
	start_label.name = "StartPrompt"
	start_label.text = "[ PRESS SPACE TO START ]"
	start_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	start_label.add_theme_font_size_override("font_size", 22)
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(start_label)

	# Pulse the start prompt
	var tw := start_label.create_tween()
	tw.set_loops()
	tw.tween_property(start_label, "modulate:a", 0.3, 0.8)
	tw.tween_property(start_label, "modulate:a", 1.0, 0.8)

	title_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(title_screen)

# === TOP BAR ===

func _build_top_bar() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 20)
	margin.custom_minimum_size.y = 80
	add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)

	# HP
	var hp_vbox := VBoxContainer.new()
	hp_vbox.custom_minimum_size.x = 250
	hbox.add_child(hp_vbox)

	hp_label = Label.new()
	hp_label.text = "HP: 100/100"
	hp_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_vbox.add_child(hp_label)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(250, 16)
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.0, 1.0, 0.8, 0.9)
	hp_fill.corner_radius_top_left = 3
	hp_fill.corner_radius_top_right = 3
	hp_fill.corner_radius_bottom_left = 3
	hp_fill.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	hp_bg.corner_radius_top_left = 3
	hp_bg.corner_radius_top_right = 3
	hp_bg.corner_radius_bottom_left = 3
	hp_bg.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	hp_vbox.add_child(hp_bar)

	# XP
	var xp_vbox := VBoxContainer.new()
	xp_vbox.custom_minimum_size.x = 250
	hbox.add_child(xp_vbox)

	level_label = Label.new()
	level_label.text = "LV 1"
	level_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	level_label.add_theme_font_size_override("font_size", 14)
	xp_vbox.add_child(level_label)

	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(250, 12)
	xp_bar.max_value = 80
	xp_bar.value = 0
	xp_bar.show_percentage = false
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(1.0, 0.85, 0.1, 0.9)
	xp_fill.corner_radius_top_left = 2
	xp_fill.corner_radius_top_right = 2
	xp_fill.corner_radius_bottom_left = 2
	xp_fill.corner_radius_bottom_right = 2
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	xp_bg.corner_radius_top_left = 2
	xp_bg.corner_radius_top_right = 2
	xp_bg.corner_radius_bottom_left = 2
	xp_bg.corner_radius_bottom_right = 2
	xp_bar.add_theme_stylebox_override("background", xp_bg)
	xp_vbox.add_child(xp_bar)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Wave & kills
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	hbox.add_child(info_vbox)

	wave_label = Label.new()
	wave_label.text = "WAVE 0"
	wave_label.add_theme_color_override("font_color", Color(0.7, 0.4, 1.0))
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_vbox.add_child(wave_label)

	kills_label = Label.new()
	kills_label.text = "KILLS: 0"
	kills_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.5))
	kills_label.add_theme_font_size_override("font_size", 14)
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_vbox.add_child(kills_label)

# === BOTTOM BAR ===

func _build_bottom_bar() -> void:
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hbox.add_theme_constant_override("separation", 40)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.position.y = -45
	add_child(hbox)

	dash_indicator = Label.new()
	dash_indicator.text = "DASH [SPACE]"
	dash_indicator.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 0.7))
	dash_indicator.add_theme_font_size_override("font_size", 13)
	dash_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(dash_indicator)

	ult_indicator = Label.new()
	ult_indicator.text = "ULT [Q]"
	ult_indicator.add_theme_color_override("font_color", Color(0.9, 0.4, 1.0, 0.7))
	ult_indicator.add_theme_font_size_override("font_size", 13)
	ult_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(ult_indicator)

# === WAVE ANNOUNCE ===

func _build_wave_announce() -> void:
	wave_announce = Label.new()
	wave_announce.text = ""
	wave_announce.add_theme_color_override("font_color", Color(1.0, 0.0, 0.8))
	wave_announce.add_theme_font_size_override("font_size", 40)
	wave_announce.set_anchors_preset(Control.PRESET_CENTER)
	wave_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_announce.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_announce.position = Vector2(-200, -100)
	wave_announce.custom_minimum_size = Vector2(400, 80)
	wave_announce.modulate.a = 0.0
	add_child(wave_announce)

# === UPGRADE PANEL ===

func _build_upgrade_panel() -> void:
	upgrade_panel = PanelContainer.new()
	upgrade_panel.set_anchors_preset(Control.PRESET_CENTER)
	upgrade_panel.custom_minimum_size = Vector2(520, 340)
	upgrade_panel.position = Vector2(-260, -170)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.08, 0.95)
	style.border_color = Color(0.0, 0.8, 1.0, 0.6)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	upgrade_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	upgrade_panel.add_child(vbox)

	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_top", 15)
	title_margin.add_theme_constant_override("margin_left", 15)
	vbox.add_child(title_margin)

	var title := Label.new()
	title.text = "LEVEL UP — CHOOSE UPGRADE"
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_margin.add_child(title)

	var btn_margin := MarginContainer.new()
	btn_margin.add_theme_constant_override("margin_left", 20)
	btn_margin.add_theme_constant_override("margin_right", 20)
	btn_margin.add_theme_constant_override("margin_bottom", 15)
	vbox.add_child(btn_margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	btn_margin.add_child(inner)

	for i in 3:
		var btn := Button.new()
		btn.name = "UpgradeBtn%d" % i
		btn.custom_minimum_size = Vector2(460, 60)
		btn.add_theme_font_size_override("font_size", 15)
		var bn := StyleBoxFlat.new()
		bn.bg_color = Color(0.08, 0.05, 0.15, 0.9)
		bn.border_color = Color(0.5, 0.3, 1.0, 0.5)
		bn.set_border_width_all(1)
		bn.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", bn)
		var bh := StyleBoxFlat.new()
		bh.bg_color = Color(0.15, 0.08, 0.3, 0.95)
		bh.border_color = Color(0.0, 1.0, 0.9, 0.8)
		bh.set_border_width_all(2)
		bh.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("hover", bh)
		btn.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.0, 1.0, 0.9))
		btn.pressed.connect(_on_upgrade_chosen.bind(i))
		inner.add_child(btn)
		upgrade_buttons.append(btn)

	upgrade_panel.visible = false
	upgrade_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(upgrade_panel)

# === GAME OVER ===

func _build_game_over() -> void:
	game_over_panel = PanelContainer.new()
	game_over_panel.set_anchors_preset(Control.PRESET_CENTER)
	game_over_panel.custom_minimum_size = Vector2(420, 220)
	game_over_panel.position = Vector2(-210, -110)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.0, 0.02, 0.95)
	style.border_color = Color(1.0, 0.0, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	game_over_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_panel.add_child(vbox)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)

	var title := Label.new()
	title.text = "SYSTEM FAILURE"
	title.add_theme_color_override("font_color", Color(1.0, 0.0, 0.3))
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var stats := Label.new()
	stats.name = "StatsLabel"
	stats.text = ""
	stats.add_theme_color_override("font_color", Color(0.7, 0.6, 0.8))
	stats.add_theme_font_size_override("font_size", 16)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)

	var hint := Label.new()
	hint.text = "Press R to restart  |  ESC to quit"
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hint.add_theme_font_size_override("font_size", 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	game_over_panel.visible = false
	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(game_over_panel)

# === SIGNAL HANDLERS ===

func _on_hp_changed(current: float, maximum: float) -> void:
	if hp_bar:
		hp_bar.max_value = maximum
		hp_bar.value = current
	if hp_label:
		hp_label.text = "HP: %d/%d" % [ceili(current), ceili(maximum)]

func _on_xp_changed(current: float, needed: float) -> void:
	if xp_bar:
		xp_bar.max_value = needed
		xp_bar.value = current

func _on_wave_changed(wave: int) -> void:
	if wave_label:
		wave_label.text = "WAVE %d" % wave
	if wave_announce:
		var is_boss := wave % 5 == 0
		wave_announce.text = "BOSS WAVE %d" % wave if is_boss else "WAVE %d" % wave
		wave_announce.add_theme_color_override("font_color",
			Color(1.0, 0.3, 0.0) if is_boss else Color(1.0, 0.0, 0.8))
		var tw := create_tween()
		tw.tween_property(wave_announce, "modulate:a", 1.0, 0.3)
		tw.tween_interval(1.5)
		tw.tween_property(wave_announce, "modulate:a", 0.0, 0.5)

func _on_kills_changed(kills: int) -> void:
	if kills_label:
		kills_label.text = "KILLS: %d" % kills

func _on_leveled_up(level: int) -> void:
	if level_label:
		level_label.text = "LV %d" % level
	_show_upgrade_choices()

func _show_upgrade_choices() -> void:
	_current_choices = UpgradeSystem.get_random_choices(3)
	for i in upgrade_buttons.size():
		if i < _current_choices.size():
			var u = _current_choices[i]
			upgrade_buttons[i].text = "  %s  %s  —  %s" % [u.icon, u.title, u.description]
			upgrade_buttons[i].visible = true
		else:
			upgrade_buttons[i].visible = false
	upgrade_panel.visible = true

func _on_upgrade_chosen(index: int) -> void:
	if index >= _current_choices.size():
		return
	Audio.sfx_upgrade()
	UpgradeSystem.apply_upgrade(_current_choices[index])
	upgrade_panel.visible = false
	GameState.upgrade_selected.emit()

func _on_player_died() -> void:
	Audio.play_music("res://assets/audio/music/defeat.ogg", -4.0)
	game_over_panel.visible = true
	var stats_label := game_over_panel.find_child("StatsLabel") as Label
	if stats_label:
		stats_label.text = "Wave %d  |  Kills: %d  |  Level %d" % [
			GameState.wave, GameState.kills, GameState.level]

# === PROCESS ===

func _process(delta: float) -> void:
	_update_indicators()

func _update_indicators() -> void:
	var player: Node = get_tree().get_first_node_in_group("player_node")
	if not player:
		return
	if dash_indicator:
		var cd = player.get("dash_cd_timer")
		if cd != null and cd > 0.0:
			dash_indicator.text = "DASH [%.1fs]" % cd
			dash_indicator.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 0.5))
		else:
			dash_indicator.text = "DASH [SPACE]"
			dash_indicator.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 0.8))
	if ult_indicator:
		var cd = player.get("ult_cd_timer")
		if cd != null and cd > 0.0:
			ult_indicator.text = "ULT [%.0fs]" % cd
			ult_indicator.add_theme_color_override("font_color", Color(0.4, 0.3, 0.5, 0.5))
		else:
			ult_indicator.text = "ULT [Q]"
			ult_indicator.add_theme_color_override("font_color", Color(0.9, 0.4, 1.0, 0.8))

func _unhandled_input(event: InputEvent) -> void:
	if title_screen and title_screen.visible:
		if event is InputEventKey and event.pressed:
			if event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER:
				_dismiss_title()

func _dismiss_title() -> void:
	if not title_screen:
		return
	Audio.sfx_ui_click()
	var tw := create_tween()
	tw.tween_property(title_screen, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		title_screen.visible = false
		title_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		GameState.game_started = true
		Audio.play_music("res://assets/audio/music/neon_runner.mp3", -6.0)
	)
