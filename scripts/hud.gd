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
var boss_bar_container: Control
var boss_bar: ProgressBar
var boss_name_label: Label
var _boss_ref: WeakRef = WeakRef.new()
var _vignette: ColorRect
var _vignette_mat: ShaderMaterial
var _vignette_pulse: float = 0.0
var _levelup_flash: ColorRect
var _overclock_label: Label
var _regen_label: Label
var _pause_panel: PanelContainer
var _streak_label: Label
var _wave_timer_label: Label
var _speed_lines: ColorRect
var _speed_lines_mat: ShaderMaterial
var _enemy_count_label: Label
var _dps_label: Label
var _dps_window: Array[float] = []
var _dps_timer: float = 0.0
var _no_damage_label: Label

var _current_choices: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud_node")
	_build_title_screen()
	_build_top_bar()
	_build_bottom_bar()
	_build_wave_announce()
	_build_upgrade_panel()
	_build_game_over()
	_build_boss_bar()
	_build_danger_vignette()
	_build_levelup_flash()
	_build_overclock_indicator()
	_build_regen_indicator()
	_build_streak_label()
	_build_wave_timer_label()
	_build_speed_lines()
	_build_enemy_count_label()
	_build_dps_label()
	_build_no_damage_label()
	_build_pause_menu()

	GameState.hp_changed.connect(_on_hp_changed)
	GameState.xp_changed.connect(_on_xp_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.kills_changed.connect(_on_kills_changed)
	GameState.leveled_up.connect(_on_leveled_up)
	GameState.player_died.connect(_on_player_died)
	GameState.boss_defeated.connect(_on_boss_defeated)
	GameState.kill_streak.connect(_on_kill_streak)
	GameState.perfect_wave.connect(_on_perfect_wave)

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
ESC              Pause / Menu
R                Restart (game over)

Survive relentless waves of enemies. Kill them for XP.
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

# === UPGRADE PANEL (3-column card layout) ===

var _card_containers: Array[PanelContainer] = []
var _card_icons: Array[Label] = []
var _card_titles: Array[Label] = []
var _card_descs: Array[Label] = []
var _card_stacks: Array[Label] = []

func _build_upgrade_panel() -> void:
	upgrade_panel = PanelContainer.new()
	upgrade_panel.set_anchors_preset(Control.PRESET_CENTER)
	upgrade_panel.custom_minimum_size = Vector2(720, 420)
	upgrade_panel.position = Vector2(-360, -210)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.01, 0.06, 0.95)
	style.border_color = Color(0.0, 0.8, 1.0, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 20
	upgrade_panel.add_theme_stylebox_override("panel", style)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	upgrade_panel.add_child(outer)

	var title := Label.new()
	title.text = "LEVEL UP"
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)

	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 16)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(cards_row)

	for i in 3:
		var card := PanelContainer.new()
		card.name = "Card%d" % i
		card.custom_minimum_size = Vector2(210, 320)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.05, 0.03, 0.12, 0.95)
		card_style.border_color = Color(0.5, 0.3, 1.0, 0.5)
		card_style.set_border_width_all(2)
		card_style.set_corner_radius_all(8)
		card_style.content_margin_left = 12
		card_style.content_margin_right = 12
		card_style.content_margin_top = 12
		card_style.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", card_style)

		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 8)
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(card_vbox)

		# Icon area — large neon glow icon
		var icon_panel := PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(180, 120)
		var icon_bg := StyleBoxFlat.new()
		icon_bg.bg_color = Color(0.03, 0.015, 0.06, 0.9)
		icon_bg.set_corner_radius_all(6)
		icon_bg.border_color = Color(0.3, 0.2, 0.6, 0.3)
		icon_bg.set_border_width_all(1)
		icon_panel.add_theme_stylebox_override("panel", icon_bg)

		var icon_label := Label.new()
		icon_label.name = "Icon"
		icon_label.text = ">>"
		icon_label.add_theme_font_size_override("font_size", 48)
		icon_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_panel.add_child(icon_label)
		card_vbox.add_child(icon_panel)
		_card_icons.append(icon_label)

		# Title
		var title_label := Label.new()
		title_label.name = "Title"
		title_label.text = "UPGRADE"
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_vbox.add_child(title_label)
		_card_titles.append(title_label)

		# Description
		var desc_label := Label.new()
		desc_label.name = "Desc"
		desc_label.text = "Does something cool"
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.8))
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.custom_minimum_size.y = 36
		card_vbox.add_child(desc_label)
		_card_descs.append(desc_label)

		# Stacks indicator
		var stacks_label := Label.new()
		stacks_label.name = "Stacks"
		stacks_label.text = ""
		stacks_label.add_theme_font_size_override("font_size", 11)
		stacks_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.65))
		stacks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(stacks_label)
		_card_stacks.append(stacks_label)

		# Invisible button overlay for click handling
		var btn := Button.new()
		btn.name = "UpgradeBtn%d" % i
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		# Transparent styles
		var btn_normal := StyleBoxFlat.new()
		btn_normal.bg_color = Color(0, 0, 0, 0)
		btn.add_theme_stylebox_override("normal", btn_normal)
		var btn_hover := StyleBoxFlat.new()
		btn_hover.bg_color = Color(0.0, 1.0, 0.9, 0.08)
		btn_hover.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("hover", btn_hover)
		var btn_pressed := StyleBoxFlat.new()
		btn_pressed.bg_color = Color(0.0, 1.0, 0.9, 0.15)
		btn_pressed.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.pressed.connect(_on_upgrade_chosen.bind(i))
		# Mouse enter/exit for card glow effect
		btn.mouse_entered.connect(_on_card_hover.bind(i, true))
		btn.mouse_exited.connect(_on_card_hover.bind(i, false))
		card.add_child(btn)
		upgrade_buttons.append(btn)
		_card_containers.append(card)

		cards_row.add_child(card)

	upgrade_panel.visible = false
	upgrade_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(upgrade_panel)

func _on_card_hover(index: int, entered: bool) -> void:
	if index >= _card_containers.size():
		return
	if entered:
		Audio.sfx_ui_hover()
	var card := _card_containers[index]
	var panel_style := card.get_theme_stylebox("panel") as StyleBoxFlat
	if not panel_style:
		return
	if entered:
		var u_color := Color(0.0, 1.0, 0.9)
		if index < _current_choices.size():
			u_color = _current_choices[index].color
		panel_style.border_color = Color(u_color.r, u_color.g, u_color.b, 0.9)
		panel_style.bg_color = Color(0.08, 0.05, 0.18, 0.98)
	else:
		panel_style.border_color = Color(0.5, 0.3, 1.0, 0.5)
		panel_style.bg_color = Color(0.05, 0.03, 0.12, 0.95)

# === BOSS HP BAR ===

func _build_boss_bar() -> void:
	boss_bar_container = Control.new()
	boss_bar_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar_container.position = Vector2(-200, 70)
	boss_bar_container.custom_minimum_size = Vector2(400, 40)
	boss_bar_container.visible = false
	add_child(boss_bar_container)

	boss_name_label = Label.new()
	boss_name_label.text = "GOLEM"
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.0))
	boss_name_label.add_theme_font_size_override("font_size", 14)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.position = Vector2(0, 0)
	boss_name_label.custom_minimum_size = Vector2(400, 20)
	boss_bar_container.add_child(boss_name_label)

	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size = Vector2(400, 12)
	boss_bar.position = Vector2(0, 22)
	boss_bar.max_value = 100
	boss_bar.value = 100
	boss_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.3, 0.0, 0.9)
	fill.set_corner_radius_all(3)
	boss_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.05, 0.02, 0.8)
	bg.border_color = Color(1.0, 0.3, 0.0, 0.4)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(3)
	boss_bar.add_theme_stylebox_override("background", bg)
	boss_bar_container.add_child(boss_bar)

func _build_danger_vignette() -> void:
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.color = Color(0, 0, 0, 0)

	var shader_code := """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	float dist = distance(UV, vec2(0.5));
	float vignette = smoothstep(0.25, 0.7, dist);
	float alpha = vignette * intensity * (0.6 + 0.4 * pulse);
	COLOR = vec4(0.9, 0.05, 0.05, alpha * 0.55);
}
"""
	var shader := Shader.new()
	shader.code = shader_code
	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = shader
	_vignette_mat.set_shader_parameter("intensity", 0.0)
	_vignette_mat.set_shader_parameter("pulse", 0.0)
	_vignette.material = _vignette_mat
	add_child(_vignette)

func _build_levelup_flash() -> void:
	_levelup_flash = ColorRect.new()
	_levelup_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_levelup_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_levelup_flash.color = Color(0.0, 1.0, 0.9, 0.0)
	add_child(_levelup_flash)

func _build_overclock_indicator() -> void:
	_overclock_label = Label.new()
	_overclock_label.text = "OVERCLOCK ACTIVE"
	_overclock_label.add_theme_font_size_override("font_size", 13)
	_overclock_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.3, 0.9))
	_overclock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overclock_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_overclock_label.position = Vector2(-100, -70)
	_overclock_label.custom_minimum_size = Vector2(200, 20)
	_overclock_label.visible = false
	_overclock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overclock_label)

func _build_regen_indicator() -> void:
	_regen_label = Label.new()
	_regen_label.text = "+HP"
	_regen_label.add_theme_font_size_override("font_size", 12)
	_regen_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 0.0))
	_regen_label.position = Vector2(275, 10)
	_regen_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_regen_label)

func _build_streak_label() -> void:
	_streak_label = Label.new()
	_streak_label.text = ""
	_streak_label.add_theme_font_size_override("font_size", 30)
	_streak_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0, 0.0))
	_streak_label.add_theme_color_override("font_outline_color", Color(1.0, 0.3, 0.0))
	_streak_label.add_theme_constant_override("outline_size", 3)
	_streak_label.set_anchors_preset(Control.PRESET_CENTER)
	_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_streak_label.position = Vector2(-150, 60)
	_streak_label.custom_minimum_size = Vector2(300, 40)
	_streak_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_streak_label)

func _build_wave_timer_label() -> void:
	_wave_timer_label = Label.new()
	_wave_timer_label.text = ""
	_wave_timer_label.add_theme_font_size_override("font_size", 16)
	_wave_timer_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8, 0.7))
	_wave_timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_wave_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_timer_label.position = Vector2(-100, 50)
	_wave_timer_label.custom_minimum_size = Vector2(200, 20)
	_wave_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wave_timer_label)

func _build_speed_lines() -> void:
	_speed_lines = ColorRect.new()
	_speed_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_speed_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speed_lines.color = Color(0, 0, 0, 0)
	var shader_code := """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 center = vec2(0.5);
	vec2 dir = UV - center;
	float dist = length(dir);
	float angle = atan(dir.y, dir.x);
	float lines = abs(sin(angle * 20.0));
	float radial = smoothstep(0.15, 0.5, dist);
	float alpha = lines * radial * intensity * 0.35;
	COLOR = vec4(0.3, 0.85, 1.0, alpha);
}
"""
	var shader := Shader.new()
	shader.code = shader_code
	_speed_lines_mat = ShaderMaterial.new()
	_speed_lines_mat.shader = shader
	_speed_lines_mat.set_shader_parameter("intensity", 0.0)
	_speed_lines.material = _speed_lines_mat
	add_child(_speed_lines)

func _build_enemy_count_label() -> void:
	_enemy_count_label = Label.new()
	_enemy_count_label.text = ""
	_enemy_count_label.add_theme_font_size_override("font_size", 13)
	_enemy_count_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.6, 0.7))
	_enemy_count_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_enemy_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enemy_count_label.position = Vector2(-170, 68)
	_enemy_count_label.custom_minimum_size = Vector2(150, 20)
	_enemy_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_enemy_count_label)

func _build_dps_label() -> void:
	_dps_label = Label.new()
	_dps_label.text = ""
	_dps_label.add_theme_font_size_override("font_size", 12)
	_dps_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3, 0.6))
	_dps_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_dps_label.position = Vector2(20, 68)
	_dps_label.custom_minimum_size = Vector2(120, 20)
	_dps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dps_label)

func _build_no_damage_label() -> void:
	_no_damage_label = Label.new()
	_no_damage_label.text = "NO DAMAGE"
	_no_damage_label.add_theme_font_size_override("font_size", 12)
	_no_damage_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 0.6))
	_no_damage_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_no_damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_no_damage_label.position = Vector2(-170, 86)
	_no_damage_label.custom_minimum_size = Vector2(150, 20)
	_no_damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_no_damage_label.visible = false
	add_child(_no_damage_label)

func _build_pause_menu() -> void:
	_pause_panel = PanelContainer.new()
	_pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	_pause_panel.custom_minimum_size = Vector2(320, 220)
	_pause_panel.position = Vector2(-160, -110)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.01, 0.06, 0.95)
	style.border_color = Color(0.0, 0.8, 1.0, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	_pause_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_pause_panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	vbox.add_child(spacer)

	var btn_style_normal := StyleBoxFlat.new()
	btn_style_normal.bg_color = Color(0.05, 0.03, 0.12, 0.9)
	btn_style_normal.border_color = Color(0.3, 0.2, 0.6, 0.5)
	btn_style_normal.set_border_width_all(1)
	btn_style_normal.set_corner_radius_all(6)
	btn_style_normal.content_margin_top = 8
	btn_style_normal.content_margin_bottom = 8

	var btn_style_hover := StyleBoxFlat.new()
	btn_style_hover.bg_color = Color(0.08, 0.05, 0.18, 0.95)
	btn_style_hover.border_color = Color(0.0, 1.0, 0.9, 0.8)
	btn_style_hover.set_border_width_all(1)
	btn_style_hover.set_corner_radius_all(6)
	btn_style_hover.content_margin_top = 8
	btn_style_hover.content_margin_bottom = 8

	for item in [["RESUME", "_on_pause_resume"], ["RESTART", "_on_pause_restart"], ["QUIT", "_on_pause_quit"]]:
		var btn := Button.new()
		btn.text = item[0]
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", Color(0.8, 0.75, 0.95))
		btn.add_theme_color_override("font_hover_color", Color(0.0, 1.0, 0.9))
		btn.add_theme_stylebox_override("normal", btn_style_normal.duplicate())
		btn.add_theme_stylebox_override("hover", btn_style_hover.duplicate())
		btn.add_theme_stylebox_override("pressed", btn_style_hover.duplicate())
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(Callable(self, item[1]))
		btn.mouse_entered.connect(func(): Audio.sfx_ui_hover())
		vbox.add_child(btn)

	_pause_panel.visible = false
	_pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_pause_panel)

func _on_pause_resume() -> void:
	Audio.sfx_ui_click()
	_pause_panel.visible = false
	get_tree().paused = false

func _on_pause_restart() -> void:
	Audio.sfx_ui_click()
	_pause_panel.visible = false
	get_tree().paused = false
	GameState.reset()
	get_tree().reload_current_scene()

func _on_pause_quit() -> void:
	get_tree().quit()

func toggle_pause() -> void:
	if GameState.game_over or GameState.paused_for_upgrade or not GameState.game_started:
		return
	if _pause_panel.visible:
		_on_pause_resume()
	else:
		Audio.sfx_ui_click()
		_pause_panel.visible = true
		get_tree().paused = true

func _on_boss_defeated() -> void:
	if not _levelup_flash:
		return
	# Gold flash for boss defeat
	_levelup_flash.color = Color(1.0, 0.8, 0.0, 0.5)
	var tw := create_tween()
	tw.tween_property(_levelup_flash, "color:a", 0.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# Show "BOSS DEFEATED" via wave announce label
	if wave_announce:
		wave_announce.text = "BOSS DEFEATED"
		wave_announce.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		wave_announce.modulate.a = 1.0
		wave_announce.scale = Vector2(1.3, 1.3)
		var stw := create_tween()
		stw.tween_property(wave_announce, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)
		stw.tween_interval(1.5)
		stw.tween_property(wave_announce, "modulate:a", 0.0, 0.5)

func _on_kill_streak(count: int) -> void:
	if not _streak_label:
		return
	var streak_names := {
		2: "DOUBLE KILL",
		3: "TRIPLE KILL",
		4: "MULTI KILL",
		5: "KILLING SPREE",
		6: "RAMPAGE",
	}
	var text: String = streak_names.get(count, "UNSTOPPABLE x%d" % count) if count <= 6 else "UNSTOPPABLE x%d" % count
	if count < 2:
		return
	_streak_label.text = text
	_streak_label.modulate.a = 1.0
	var font_size := mini(30 + (count - 2) * 4, 48)
	_streak_label.add_theme_font_size_override("font_size", font_size)
	var tw := create_tween()
	tw.tween_property(_streak_label, "modulate:a", 1.0, 0.05)
	tw.tween_interval(0.8)
	tw.tween_property(_streak_label, "modulate:a", 0.0, 0.4)

func _on_perfect_wave(bonus_xp: float) -> void:
	if not wave_announce:
		return
	wave_announce.text = "PERFECT WAVE! +%d XP" % int(bonus_xp)
	wave_announce.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	wave_announce.modulate.a = 1.0
	wave_announce.scale = Vector2(1.2, 1.2)
	var tw := create_tween()
	tw.tween_property(wave_announce, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.5)
	tw.tween_property(wave_announce, "modulate:a", 0.0, 0.5)

func _trigger_levelup_flash() -> void:
	if not _levelup_flash:
		return
	_levelup_flash.color = Color(0.0, 1.0, 0.9, 0.45)
	var tw := create_tween()
	tw.tween_property(_levelup_flash, "color:a", 0.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _update_danger_vignette(delta: float) -> void:
	if not _vignette_mat:
		return
	var hp_ratio := GameState.hp / maxf(GameState.max_hp, 1.0)
	var target_intensity := 0.0
	if hp_ratio < 0.3 and not GameState.game_over:
		target_intensity = (1.0 - hp_ratio / 0.3)
	var current := _vignette_mat.get_shader_parameter("intensity") as float
	_vignette_mat.set_shader_parameter("intensity", lerpf(current, target_intensity, 5.0 * delta))
	if target_intensity > 0.01:
		_vignette_pulse += delta * (3.0 + target_intensity * 2.0)
		_vignette_mat.set_shader_parameter("pulse", (sin(_vignette_pulse) + 1.0) * 0.5)
	else:
		_vignette_pulse = 0.0
		_vignette_mat.set_shader_parameter("pulse", 0.0)

func _update_boss_bar() -> void:
	var boss: Node3D = _boss_ref.get_ref() as Node3D
	if boss and not boss.is_queued_for_deletion() and boss.get("hp") != null:
		boss_bar.max_value = boss.max_hp
		boss_bar.value = boss.hp
		if not boss_bar_container.visible:
			boss_bar_container.visible = true
			boss_bar_container.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(boss_bar_container, "modulate:a", 1.0, 0.3)
	else:
		if boss_bar_container.visible:
			var tw := create_tween()
			tw.tween_property(boss_bar_container, "modulate:a", 0.0, 0.4)
			tw.tween_callback(func(): boss_bar_container.visible = false)
			_boss_ref = WeakRef.new()

func track_boss(boss_node: Node3D) -> void:
	_boss_ref = weakref(boss_node)
	var type_name: String = boss_node.get("enemy_type") if boss_node.get("enemy_type") else "BOSS"
	boss_name_label.text = type_name.to_upper()
	boss_bar.max_value = boss_node.max_hp
	boss_bar.value = boss_node.hp
	boss_bar_container.visible = true
	boss_bar_container.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(boss_bar_container, "modulate:a", 1.0, 0.3)

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
		# Shift HP bar color from cyan to red when low
		var ratio := current / maxf(maximum, 1.0)
		var fill_style := hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_style:
			if ratio < 0.3:
				fill_style.bg_color = Color(1.0, 0.15, 0.1, 0.9)
			elif ratio < 0.5:
				var t := (ratio - 0.3) / 0.2
				fill_style.bg_color = Color(1.0, 0.15, 0.1).lerp(Color(0.0, 1.0, 0.8), t)
				fill_style.bg_color.a = 0.9
			else:
				fill_style.bg_color = Color(0.0, 1.0, 0.8, 0.9)
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
		if is_boss:
			wave_announce.text = ">> BOSS WAVE %d <<" % wave
			wave_announce.add_theme_color_override("font_color", Color(1.0, 0.3, 0.0))
			wave_announce.add_theme_font_size_override("font_size", 46)
		else:
			wave_announce.text = "WAVE %d" % wave
			wave_announce.add_theme_color_override("font_color", Color(1.0, 0.0, 0.8))
			wave_announce.add_theme_font_size_override("font_size", 40)
		wave_announce.scale = Vector2(1.3, 1.3) if is_boss else Vector2(1.0, 1.0)
		var tw := create_tween()
		if is_boss:
			tw.tween_property(wave_announce, "modulate:a", 1.0, 0.15)
			tw.tween_property(wave_announce, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_interval(2.0)
			tw.tween_property(wave_announce, "modulate:a", 0.0, 0.5)
		else:
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
	Audio.sfx_dice_roll()
	_current_choices = UpgradeSystem.get_random_choices(3)
	for i in 3:
		if i < _current_choices.size():
			var u = _current_choices[i]
			_card_containers[i].visible = true
			_card_icons[i].text = u.icon
			_card_icons[i].add_theme_color_override("font_color", u.color)
			_card_titles[i].text = u.title
			_card_titles[i].add_theme_color_override("font_color", u.color.lerp(Color.WHITE, 0.4))
			_card_descs[i].text = u.description
			if u.max_stacks > 1:
				_card_stacks[i].text = "%d / %d" % [u.stacks, u.max_stacks]
			else:
				_card_stacks[i].text = ""
			# Reset card border on show
			var panel_style := _card_containers[i].get_theme_stylebox("panel") as StyleBoxFlat
			if panel_style:
				panel_style.border_color = Color(u.color.r, u.color.g, u.color.b, 0.4)
			upgrade_buttons[i].visible = true
		else:
			_card_containers[i].visible = false
			upgrade_buttons[i].visible = false
	upgrade_panel.visible = true

func _on_upgrade_chosen(index: int) -> void:
	if index >= _current_choices.size():
		return
	Audio.sfx_upgrade()
	UpgradeSystem.apply_upgrade(_current_choices[index])
	upgrade_panel.visible = false
	_trigger_levelup_flash()
	# Brief invincibility so player doesn't die instantly after picking
	GameState.invincible = true
	get_tree().create_timer(1.5).timeout.connect(func(): GameState.invincible = false)
	GameState.upgrade_selected.emit()

func _on_player_died() -> void:
	Audio.play_music("res://assets/audio/music/defeat.ogg", -4.0)
	Audio.stop_ambient_hum()
	game_over_panel.visible = true
	var stats_label := game_over_panel.find_child("StatsLabel") as Label
	if stats_label:
		var mins := int(GameState.time_survived) / 60
		var secs := int(GameState.time_survived) % 60
		var dmg_text := _format_damage(GameState.total_damage_dealt)
		var kpm := GameState.kills / maxf(GameState.time_survived / 60.0, 0.01)
		var avg_dps := GameState.total_damage_dealt / maxf(GameState.time_survived, 1.0)
		stats_label.text = "Wave %d  |  Kills: %d  |  Level %d\nSurvived %d:%02d  |  Damage: %s\nKills/min: %.1f  |  Avg DPS: %s" % [
			GameState.wave, GameState.kills, GameState.level, mins, secs, dmg_text,
			kpm, _format_damage(avg_dps)]

func _format_damage(amount: float) -> String:
	if amount >= 1000000:
		return "%.1fM" % (amount / 1000000.0)
	elif amount >= 1000:
		return "%.1fK" % (amount / 1000.0)
	return str(int(amount))

# === PROCESS ===

func _process(delta: float) -> void:
	_update_indicators()
	_update_boss_bar()
	_update_danger_vignette(delta)
	_update_overclock_indicator(delta)
	_update_regen_indicator(delta)
	_update_wave_timer()
	_update_speed_lines(delta)
	_update_enemy_count()
	_update_dps(delta)
	_update_no_damage_indicator()
	Audio.update_hum_pitch()

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

var _overclock_pulse_t: float = 0.0

func _update_overclock_indicator(delta: float) -> void:
	if not _overclock_label:
		return
	if GameState.overclock_active and not GameState.game_over:
		_overclock_label.visible = true
		_overclock_pulse_t += delta * 4.0
		var alpha := 0.5 + 0.5 * sin(_overclock_pulse_t)
		_overclock_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.3, alpha))
	else:
		_overclock_label.visible = false
		_overclock_pulse_t = 0.0

var _regen_tick_t: float = 0.0

func _update_regen_indicator(delta: float) -> void:
	if not _regen_label:
		return
	if GameState.hp_regen > 0.0 and GameState.hp < GameState.max_hp and not GameState.game_over:
		_regen_tick_t += delta
		if _regen_tick_t >= 1.0:
			_regen_tick_t -= 1.0
			_regen_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 0.8))
			var tw := create_tween()
			tw.tween_property(_regen_label, "theme_override_colors/font_color:a", 0.0, 0.6)
	else:
		_regen_tick_t = 0.0

func _update_wave_timer() -> void:
	if not _wave_timer_label:
		return
	var spawner := get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.get("_wave_active") != null:
		if not spawner._wave_active and spawner._wave_timer > 0.0:
			_wave_timer_label.text = "NEXT WAVE IN %.1f" % spawner._wave_timer
			_wave_timer_label.visible = true
		else:
			_wave_timer_label.visible = false
	else:
		_wave_timer_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if title_screen and title_screen.visible:
		if event is InputEventKey and event.pressed:
			if event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER:
				_dismiss_title()
		return
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_ESCAPE:
			if GameState.game_over:
				GameState.reset()
				get_tree().reload_current_scene()
			elif not GameState.paused_for_upgrade:
				toggle_pause()
		elif event.physical_keycode == KEY_R:
			if GameState.game_over:
				GameState.reset()
				get_tree().reload_current_scene()

func _dismiss_title() -> void:
	if not title_screen:
		return
	Audio.sfx_ui_click()
	Audio.start_ambient_hum()
	var tw := create_tween()
	tw.tween_property(title_screen, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		title_screen.visible = false
		title_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		GameState.game_started = true
		Audio.play_music("res://assets/audio/music/neon_runner.mp3", -6.0)
	)

func _update_speed_lines(_delta: float) -> void:
	if not _speed_lines_mat:
		return
	var player := get_tree().get_first_node_in_group("player_node")
	var target := 0.0
	if player and player.get("is_dashing") and player.is_dashing:
		target = 1.0
	var current: float = _speed_lines_mat.get_shader_parameter("intensity")
	_speed_lines_mat.set_shader_parameter("intensity", lerpf(current, target, 12.0 * _delta))

func _update_enemy_count() -> void:
	if not _enemy_count_label:
		return
	if not GameState.game_started or GameState.game_over:
		_enemy_count_label.text = ""
		return
	var count := get_tree().get_nodes_in_group("enemies").size()
	if count > 0:
		_enemy_count_label.text = "ENEMIES: %d" % count
	else:
		_enemy_count_label.text = ""

func _update_dps(delta: float) -> void:
	if not _dps_label:
		return
	if not GameState.game_started or GameState.game_over:
		_dps_label.text = ""
		return
	_dps_timer += delta
	if _dps_timer >= 0.5:
		_dps_timer = 0.0
		_dps_window.append(GameState.total_damage_dealt)
		# Keep 10 snapshots (5 seconds of data)
		if _dps_window.size() > 10:
			_dps_window.remove_at(0)
		if _dps_window.size() >= 2:
			var dmg_diff: float = _dps_window[-1] - _dps_window[0]
			var time_span: float = (_dps_window.size() - 1) * 0.5
			var dps: float = dmg_diff / maxf(time_span, 0.01)
			if dps >= 1000.0:
				_dps_label.text = "DPS: %.1fK" % (dps / 1000.0)
			else:
				_dps_label.text = "DPS: %d" % int(dps)

func _update_no_damage_indicator() -> void:
	if not _no_damage_label:
		return
	if not GameState.game_started or GameState.game_over:
		_no_damage_label.visible = false
		return
	# Show "NO DAMAGE" when the player hasn't taken damage this wave
	if GameState.wave > 0 and not GameState._wave_damage_taken:
		_no_damage_label.visible = true
	else:
		_no_damage_label.visible = false
