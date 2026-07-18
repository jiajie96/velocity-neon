extends Node

const SPAWN_DISTANCE := 20.0
const WAVE_INTERVAL := 2.5
const SPAWN_INTERVAL_BASE := 0.25
const ENEMIES_PER_WAVE_BASE := 12
const BOSS_ARENA_RADIUS := 18.0

var _spawned_this_wave: int = 0
var _target_this_wave: int = 0
var _spawn_timer: float = 0.0
var _wave_timer: float = 0.0
var _wave_active: bool = false
var _spawn_interval: float = SPAWN_INTERVAL_BASE
var _arena_ring: Node3D = null  # parent holding the boss-arena wall meshes
var _was_boss_wave: bool = false
var _warn_sfx_cd: float = 0.0   # rate-limit the dangerous-spawn audio cue

func _ready() -> void:
	GameState.wave_changed.connect(_on_wave_changed)

func _on_wave_changed(wave: int) -> void:
	_wave_active = true
	_spawned_this_wave = 0
	_was_boss_wave = (wave % 5 == 0)
	if _was_boss_wave:
		# Boss waves are now solo duels — no regular spawns until the boss falls.
		_target_this_wave = 0
		_spawn_interval = SPAWN_INTERVAL_BASE
		_spawn_timer = 0.1
		_wave_timer = 0.0
		_spawn_boss(wave)
	else:
		# Aggressive scaling: swarm the player harder each wave, but with a softer
		# quadratic so very late waves stay punchy without becoming a kill grind.
		# Now that elites add per-enemy threat, raw counts ease off a touch in the
		# late game. Wave 1: 20, Wave 5: 64, Wave 10: 137, Wave 15: 233, Wave 20: 352
		_target_this_wave = ENEMIES_PER_WAVE_BASE + wave * 8 + int(wave * wave * 0.45)
		# Gentler onboarding for the first two waves so a fresh run (base stats, no
		# upgrades yet) isn't an instant wall — mid/late scaling is untouched.
		# Wave 1: 16, Wave 2: 20 (was 20 / 29).
		if wave <= 2:
			_target_this_wave = ENEMIES_PER_WAVE_BASE + wave * 4
		elif wave == 3:
			# Bridge the jump from wave 2 (20) to full scaling (wave 3 would be 40) so the
			# first full-difficulty wave isn't a wall right after onboarding. Wave 3: 30.
			_target_this_wave = ENEMIES_PER_WAVE_BASE + wave * 6
		_spawn_interval = maxf(0.06, SPAWN_INTERVAL_BASE / (1.0 + wave * 0.5))
		_spawn_timer = 0.1
		_wave_timer = 0.0

func _process(delta: float) -> void:
	if GameState.game_over or GameState.paused_for_upgrade or not GameState.game_started:
		return

	if _warn_sfx_cd > 0.0:
		_warn_sfx_cd -= delta

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
			# Restore full arena once the boss falls.
			if _was_boss_wave:
				_end_boss_arena()
				_was_boss_wave = false
			# Pull all remaining XP orbs to player on wave clear
			GameState.xp_magnet_pulse.emit()
			# Heal on wave clear scales with max HP so Fortify stacks stay relevant
			var wave_heal := maxf(GameState.max_hp * 0.10, minf(5.0 + GameState.wave * 0.5, 15.0))
			if GameState.hp < GameState.max_hp:
				GameState.heal(wave_heal)
				Audio.sfx_wave_heal()
				GameState.wave_heal.emit(wave_heal)
			# Brief invulnerability on wave clear — breathing room between waves. A touch
			# longer (1.35s) so recovery after a brutal late wave doesn't get clipped by a
			# straggler that spawns right as the next wave ramps.
			GameState.invincible = true
			var tree := get_tree()
			if tree:
				tree.create_timer(1.35).timeout.connect(func():
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
		if _spawned_this_wave * 2 > _target_this_wave and roll < 0.25:
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
		elif roll < 0.73:
			return "necromancer"
		elif roll < 0.79:
			return "healer"
		elif roll < 0.90:
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
		elif roll < 0.64:
			return "necromancer"
		elif roll < 0.71:
			return "healer"
		elif roll < 0.84:
			return "exploder"
		else:
			return "teleporter"
	else:
		# Wave 12+ — heavy chaos with more necromancers, healers, exploders, teleporters
		if roll < 0.08:
			return "minion"
		elif roll < 0.18:
			return "warrior"
		elif roll < 0.30:
			return "rogue"
		elif roll < 0.42:
			return "mage"
		elif roll < 0.54:
			return "necromancer"
		elif roll < 0.62:
			return "healer"
		elif roll < 0.77:
			return "exploder"
		else:
			return "teleporter"

func _spawn_boss(_wave: int) -> void:
	# Boss arena setup — shrink the playable area and pop a visual barrier ring
	# so the fight is a focused 1v1 instead of a stroll around the full map.
	GameState.boss_active = true
	GameState.arena_radius = BOSS_ARENA_RADIUS
	# Ominous entrance sting before the boss music swaps in.
	Audio.sfx_boss_incoming()
	# Boss spawns at world center; player gets re-centered so neither party
	# starts outside the new ring.
	var player := get_tree().get_first_node_in_group("player_node") as Node3D
	if player:
		var p := player.position
		p.x = clampf(p.x, -BOSS_ARENA_RADIUS + 2.0, BOSS_ARENA_RADIUS - 2.0)
		p.z = clampf(p.z, -BOSS_ARENA_RADIUS + 2.0, BOSS_ARENA_RADIUS - 2.0)
		player.position = p
	var boss := _create_enemy("golem", Vector3(0, 0, 0))
	if boss:
		# Notify HUD to show boss HP bar
		var hud := get_tree().get_first_node_in_group("hud_node")
		if hud and hud.has_method("track_boss"):
			hud.track_boss(boss)
		# Temporary zoom-out so player can see the boss arriving
		var cam_rig := get_tree().root.find_child("CameraRig", true, false)
		if cam_rig and cam_rig.has_method("boss_zoom_out"):
			cam_rig.boss_zoom_out()
	_spawn_arena_ring()

func _spawn_arena_ring() -> void:
	if _arena_ring and is_instance_valid(_arena_ring):
		_arena_ring.queue_free()
	var container := get_parent()
	if not container:
		return
	# Four glowing wall segments forming a real square that matches the
	# clampf(±arena_radius) bound. The old circle looked like the boundary
	# but didn't — players hit the corners of the actual square and felt
	# like the wall failed.
	_arena_ring = Node3D.new()
	_arena_ring.name = "BossArenaWalls"
	container.add_child(_arena_ring)
	var r := BOSS_ARENA_RADIUS
	var wall_h := 1.6
	var wall_t := 0.35
	var side_len := r * 2.0 + wall_t
	# (offset, axis-aligned size). z-aligned for north/south, x-aligned for east/west.
	var walls := [
		[Vector3(0, wall_h * 0.5, -r), Vector3(side_len, wall_h, wall_t)],
		[Vector3(0, wall_h * 0.5, r),  Vector3(side_len, wall_h, wall_t)],
		[Vector3(-r, wall_h * 0.5, 0), Vector3(wall_t, wall_h, side_len)],
		[Vector3(r,  wall_h * 0.5, 0), Vector3(wall_t, wall_h, side_len)],
	]
	for w in walls:
		var seg := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = w[1]
		seg.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.18, 0.1, 0.4)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.22, 0.06)
		mat.emission_energy_multiplier = 3.2
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		seg.material_override = mat
		seg.position = w[0]
		_arena_ring.add_child(seg)

func _end_boss_arena() -> void:
	GameState.boss_active = false
	GameState.arena_radius = 48.0
	if _arena_ring and is_instance_valid(_arena_ring):
		_arena_ring.queue_free()
	_arena_ring = null

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
		"teleporter": Color(0.9, 0.2, 0.85),
		"healer": Color(0.15, 0.95, 0.55),
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
		"healer": 1.5,
	}
	var color: Color = warn_colors.get(type, Color(0.85, 0.08, 0.35))
	var scale_factor: float = threat_scale.get(type, 1.0)
	var VFX := preload("res://scripts/vfx.gd")
	VFX.spawn_warning_pulse(container, pos, color, scale_factor)
	# Audible telegraph for the dangerous types so an off-screen threat can be reacted
	# to by ear. Rate-limited so a burst of spawns doesn't machine-gun the cue; lower
	# pitch for the heaviest threats (necromancer/golem) reads as "more dangerous".
	if type in ["necromancer", "exploder", "teleporter", "healer", "golem"] and _warn_sfx_cd <= 0.0:
		_warn_sfx_cd = 0.35
		var warn_pitch := 0.7 if type in ["necromancer", "golem"] else 1.0
		Audio.sfx_spawn_warn(warn_pitch)

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
