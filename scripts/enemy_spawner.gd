extends Node

const SPAWN_DISTANCE := 20.0
const WAVE_INTERVAL := 2.5
const SPAWN_INTERVAL_BASE := 0.25
const ENEMIES_PER_WAVE_BASE := 12

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
	# Aggressive scaling: swarm the player harder each wave
	# Wave 1: 20, Wave 5: 62, Wave 10: 142, Wave 15: 252, Wave 20: 392
	_target_this_wave = ENEMIES_PER_WAVE_BASE + wave * 8 + int(wave * wave * 0.8)
	_spawn_interval = maxf(0.06, SPAWN_INTERVAL_BASE / (1.0 + wave * 0.5))
	_spawn_timer = 0.1
	_wave_timer = 0.0

	if wave % 5 == 0:
		_spawn_boss(wave)

func _process(delta: float) -> void:
	if GameState.game_over or GameState.paused_for_upgrade or not GameState.game_started:
		return

	if not _wave_active:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			GameState.next_wave()
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _spawned_this_wave < _target_this_wave:
		# Throttle spawning when too many enemies are alive to prevent lag
		var alive_count := get_tree().get_nodes_in_group("enemies").size()
		if alive_count < 100:
			_spawn_timer = _spawn_interval
			_spawn_enemy()
			_spawned_this_wave += 1
		else:
			_spawn_timer = 0.5  # Wait before checking again

	if _spawned_this_wave >= _target_this_wave:
		var enemies := get_tree().get_nodes_in_group("enemies")
		if enemies.size() == 0:
			_wave_active = false
			_wave_timer = WAVE_INTERVAL
			# Pull all remaining XP orbs to player on wave clear
			GameState.xp_magnet_pulse.emit()
			# Heal on wave clear scales with max HP so Fortify stacks stay relevant
			var wave_heal := maxf(GameState.max_hp * 0.08, minf(5.0 + GameState.wave * 0.5, 15.0))
			if GameState.hp < GameState.max_hp:
				GameState.heal(wave_heal)
				Audio.sfx_wave_heal()
				GameState.wave_heal.emit(wave_heal)
			# Brief invulnerability on wave clear — breathing room between waves
			GameState.invincible = true
			var tree := get_tree()
			if tree:
				tree.create_timer(1.0).timeout.connect(func():
					if not GameState.game_over:
						GameState.invincible = false
				)
			GameState.wave_cleared.emit()

func _spawn_enemy() -> void:
	var player := get_tree().get_first_node_in_group("player_node")
	var spawn_center := Vector3.ZERO
	if player:
		spawn_center = player.global_position

	var angle := randf() * TAU
	# Enemies spawn close — keeps pressure high from the start
	var dist := SPAWN_DISTANCE + maxf(0.0, (3 - GameState.wave)) * 3.0
	var pos := spawn_center + Vector3(cos(angle), 0, sin(angle)) * dist

	pos.x = clampf(pos.x, -48.0, 48.0)
	pos.z = clampf(pos.z, -48.0, 48.0)

	var type := _pick_type()
	_spawn_warning(pos, type)
	_create_enemy(type, pos)

func _pick_type() -> String:
	var wave := GameState.wave
	var roll := randf()
	if wave < 2:
		# Wave 1 is mostly minions — introduce a few warriors in the second half
		if _spawned_this_wave > _target_this_wave / 2 and roll < 0.25:
			return "warrior"
		return "minion"
	elif wave < 4:
		if roll < 0.35:
			return "minion"
		elif roll < 0.55:
			return "warrior"
		elif roll < 0.75:
			return "rogue"
		elif roll < 0.90:
			return "mage"
		else:
			return "exploder"
	elif wave < 7:
		if roll < 0.18:
			return "minion"
		elif roll < 0.32:
			return "warrior"
		elif roll < 0.46:
			return "rogue"
		elif roll < 0.62:
			return "mage"
		elif roll < 0.75:
			return "necromancer"
		elif roll < 0.88:
			return "exploder"
		else:
			return "teleporter"
	elif wave < 12:
		if roll < 0.12:
			return "minion"
		elif roll < 0.24:
			return "warrior"
		elif roll < 0.38:
			return "rogue"
		elif roll < 0.52:
			return "mage"
		elif roll < 0.68:
			return "necromancer"
		elif roll < 0.82:
			return "exploder"
		else:
			return "teleporter"
	else:
		# Wave 12+ — heavy chaos with more necromancers, exploders, teleporters
		if roll < 0.08:
			return "minion"
		elif roll < 0.18:
			return "warrior"
		elif roll < 0.30:
			return "rogue"
		elif roll < 0.42:
			return "mage"
		elif roll < 0.58:
			return "necromancer"
		elif roll < 0.75:
			return "exploder"
		else:
			return "teleporter"

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
		# Boss entrance slow-mo + camera zoom for dramatic flair
		GameState.request_hit_stop(0.15)
		GameState.request_shake(3.0)
		# Temporary zoom-out so player can see the boss arriving
		var cam_rig := get_tree().root.find_child("CameraRig", true, false)
		if cam_rig and cam_rig.has_method("boss_zoom_out"):
			cam_rig.boss_zoom_out()

func _spawn_warning(pos: Vector3, type: String) -> void:
	var container := get_parent().get_node_or_null("Enemies")
	if not container:
		return
	var warn_colors := {
		"minion": Color(0.85, 0.08, 0.35),
		"warrior": Color(0.9, 0.15, 0.15),
		"mage": Color(0.55, 0.1, 0.8),
		"rogue": Color(0.1, 0.75, 0.4),
		"necromancer": Color(0.45, 0.05, 0.7),
		"exploder": Color(0.9, 0.6, 0.05),
		"teleporter": Color(0.1, 0.6, 0.8),
	}
	# Dangerous enemies get bigger, brighter warnings so players can react
	var threat_scale := {
		"minion": 1.0,
		"warrior": 1.2,
		"mage": 1.3,
		"rogue": 1.1,
		"necromancer": 1.6,
		"exploder": 1.5,
		"teleporter": 1.4,
	}
	var color: Color = warn_colors.get(type, Color(0.85, 0.08, 0.35))
	var scale_factor: float = threat_scale.get(type, 1.0)
	var VFX := load("res://scripts/vfx.gd")
	VFX.spawn_warning_pulse(container, pos, color, scale_factor)

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
