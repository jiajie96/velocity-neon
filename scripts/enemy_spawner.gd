extends Node

const SPAWN_DISTANCE := 22.0
const WAVE_INTERVAL := 2.0
const SPAWN_INTERVAL_BASE := 0.6
const ENEMIES_PER_WAVE_BASE := 5

var _spawned_this_wave: int = 0
var _target_this_wave: int = 0
var _spawn_timer: float = 0.0
var _wave_timer: float = 0.0
var _wave_active: bool = false
var _spawn_interval: float = SPAWN_INTERVAL_BASE

func _ready() -> void:
	GameState.wave_changed.connect(_on_wave_changed)

func _on_wave_changed(wave: int) -> void:
	_wave_active = true
	_spawned_this_wave = 0
	# Gentler scaling: linear base + mild quadratic ramp
	# Wave 1: 8, Wave 5: 27, Wave 10: 60, Wave 15: 105, Wave 20: 165
	_target_this_wave = ENEMIES_PER_WAVE_BASE + wave * 3 + int(wave * wave * 0.3)
	_spawn_interval = maxf(0.12, SPAWN_INTERVAL_BASE / (1.0 + wave * 0.3))
	_spawn_timer = 0.2
	_wave_timer = 0.0

	if wave % 5 == 0:
		_spawn_boss(wave)

func _process(delta: float) -> void:
	if GameState.game_over or GameState.paused_for_upgrade:
		return

	if not _wave_active:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			GameState.next_wave()
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _spawned_this_wave < _target_this_wave:
		_spawn_timer = _spawn_interval
		_spawn_enemy()
		_spawned_this_wave += 1

	if _spawned_this_wave >= _target_this_wave:
		var enemies := get_tree().get_nodes_in_group("enemies")
		if enemies.size() == 0:
			_wave_active = false
			_wave_timer = WAVE_INTERVAL

func _spawn_enemy() -> void:
	var player := get_tree().get_first_node_in_group("player_node")
	var spawn_center := Vector3.ZERO
	if player:
		spawn_center = player.global_position

	var angle := randf() * TAU
	var pos := spawn_center + Vector3(cos(angle), 0, sin(angle)) * SPAWN_DISTANCE

	pos.x = clampf(pos.x, -48.0, 48.0)
	pos.z = clampf(pos.z, -48.0, 48.0)

	var type := _pick_type()
	_create_enemy(type, pos)

func _pick_type() -> String:
	var wave := GameState.wave
	var roll := randf()
	if wave < 3:
		if roll < 0.85:
			return "minion"
		else:
			return "rogue"
	elif wave < 5:
		if roll < 0.50:
			return "minion"
		elif roll < 0.75:
			return "warrior"
		else:
			return "rogue"
	elif wave < 8:
		if roll < 0.35:
			return "minion"
		elif roll < 0.55:
			return "warrior"
		elif roll < 0.75:
			return "rogue"
		else:
			return "mage"
	else:
		if roll < 0.25:
			return "minion"
		elif roll < 0.45:
			return "warrior"
		elif roll < 0.60:
			return "rogue"
		elif roll < 0.80:
			return "mage"
		else:
			return "necromancer"

func _spawn_boss(wave: int) -> void:
	var player := get_tree().get_first_node_in_group("player_node")
	var spawn_center := Vector3.ZERO
	if player:
		spawn_center = player.global_position
	var angle := randf() * TAU
	var pos := spawn_center + Vector3(cos(angle), 0, sin(angle)) * (SPAWN_DISTANCE + 5.0)
	var boss := _create_enemy("golem", pos)
	if boss:
		# Notify HUD to show boss HP bar
		var hud := get_tree().get_first_node_in_group("hud_node")
		if hud and hud.has_method("track_boss"):
			hud.track_boss(boss)

func _create_enemy(type: String, pos: Vector3) -> Node3D:
	var container := get_parent().get_node_or_null("Enemies")
	if not container:
		return null
	var enemy := Node3D.new()
	enemy.name = "Enemy_" + type
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.position = pos
	enemy.set_meta("_enemy_type", type)
	enemy.set_meta("_enemy_wave", GameState.wave)
	container.add_child(enemy)
	return enemy
