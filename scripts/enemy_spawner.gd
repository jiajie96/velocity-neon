extends Node

const SPAWN_DISTANCE := 20.0
const WAVE_INTERVAL := 1.2
const SPAWN_INTERVAL_BASE := 0.35
const ENEMIES_PER_WAVE_BASE := 8

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
	# Aggressive scaling: more enemies, faster spawns
	# Wave 1: 13, Wave 5: 43, Wave 10: 98, Wave 15: 173, Wave 20: 268
	_target_this_wave = ENEMIES_PER_WAVE_BASE + wave * 5 + int(wave * wave * 0.5)
	_spawn_interval = maxf(0.08, SPAWN_INTERVAL_BASE / (1.0 + wave * 0.4))
	_spawn_timer = 0.1
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
		# Wave 1 is pure minions — ease the player in
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
		if roll < 0.20:
			return "minion"
		elif roll < 0.35:
			return "warrior"
		elif roll < 0.50:
			return "rogue"
		elif roll < 0.70:
			return "mage"
		elif roll < 0.85:
			return "necromancer"
		else:
			return "exploder"
	else:
		if roll < 0.15:
			return "minion"
		elif roll < 0.28:
			return "warrior"
		elif roll < 0.42:
			return "rogue"
		elif roll < 0.60:
			return "mage"
		elif roll < 0.78:
			return "necromancer"
		else:
			return "exploder"

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
		"minion": Color(1.0, 0.0, 0.6),
		"warrior": Color(0.9, 0.0, 0.3),
		"mage": Color(0.7, 0.0, 1.0),
		"rogue": Color(0.0, 1.0, 0.5),
		"necromancer": Color(0.6, 0.0, 0.9),
		"exploder": Color(1.0, 0.8, 0.0),
	}
	var color: Color = warn_colors.get(type, Color(1.0, 0.0, 0.6))
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 0.6
	cyl.height = 0.02
	ring.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.5)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	ring.position = pos
	ring.position.y = 0.05
	container.add_child(ring)
	var tw := ring.create_tween()
	ring.scale = Vector3(0.1, 1.0, 0.1)
	tw.tween_property(ring, "scale", Vector3(1.5, 1.0, 1.5), 0.3)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.set_parallel(false)
	tw.tween_callback(ring.queue_free)

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
