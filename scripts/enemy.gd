extends Node3D

const XP_VALUE_BASE := 10.0
const FLASH_DURATION := 0.1

var hp: float = 20.0
var max_hp: float = 20.0
var speed: float = 3.0
var contact_damage: float = 10.0
var xp_value: float = XP_VALUE_BASE
var enemy_type: String = "minion"
var is_boss: bool = false

var _flash_timer: float = 0.0
var _original_color: Color = Color.WHITE
var _mat: StandardMaterial3D
var _dead: bool = false
var _mage_shoot_timer: float = 2.0
const MAGE_SHOOT_CD := 2.5
const MAGE_RANGE := 12.0
const MAGE_PROJ_SPEED := 10.0
const MAGE_PROJ_DAMAGE := 8.0

# Rogue dodge behavior
var _rogue_dodge_timer: float = 1.5
const ROGUE_DODGE_CD := 1.8
const ROGUE_DODGE_DIST := 2.5

# Necromancer summoning behavior
var _necro_summon_timer: float = 4.0
const NECRO_SUMMON_CD := 5.0
const NECRO_SUMMON_COUNT := 2
const NECRO_KEEP_RANGE := 10.0

# Exploder behavior
var _exploder_fuse_lit: bool = false
const EXPLODER_DETONATE_RANGE := 1.8
const EXPLODER_DAMAGE := 30.0
const EXPLODER_RADIUS := 4.0

# Golem slam attack
var _golem_slam_timer: float = 4.0
const GOLEM_SLAM_CD := 5.0
const GOLEM_SLAM_RANGE := 5.0
const GOLEM_SLAM_DAMAGE := 20.0

func _ready() -> void:
	add_to_group("enemies")
	var meta_type: String = get_meta("_enemy_type", "minion")
	var meta_wave: int = get_meta("_enemy_wave", 1)
	setup(meta_type, meta_wave)
	_build_visual()
	_build_hitbox()

func _build_visual() -> void:
	var model_map := {
		"minion": "res://assets/models/Skeleton_Minion.glb",
		"warrior": "res://assets/models/Skeleton_Warrior.glb",
		"mage": "res://assets/models/Skeleton_Mage.glb",
		"rogue": "res://assets/models/Skeleton_Rogue.glb",
		"necromancer": "res://assets/models/Necromancer.glb",
		"exploder": "res://assets/models/Skeleton_Minion.glb",
		"golem": "res://assets/models/Skeleton_Golem.glb",
	}
	var neon_colors := {
		"minion": Color(1.0, 0.0, 0.6),
		"warrior": Color(0.9, 0.0, 0.3),
		"mage": Color(0.7, 0.0, 1.0),
		"rogue": Color(0.0, 1.0, 0.5),
		"necromancer": Color(0.6, 0.0, 0.9),
		"exploder": Color(1.0, 0.8, 0.0),
		"golem": Color(1.0, 0.3, 0.0),
	}
	var neon_color: Color = neon_colors.get(enemy_type, Color(1.0, 0.0, 0.6))
	var model_path: String = model_map.get(enemy_type, "")

	if model_path != "" and ResourceLoader.exists(model_path):
		var scene: PackedScene = load(model_path)
		if scene:
			var inst := scene.instantiate()
			inst.name = "Model"
			var s := 0.5 if not is_boss else 1.0
			inst.scale = Vector3(s, s, s)
			add_child(inst)
			_apply_neon(inst, neon_color)
			_add_glow_light(neon_color)
			return

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	if is_boss:
		var box := BoxMesh.new()
		box.size = Vector3(1.5, 2.5, 1.5)
		mesh_inst.mesh = box
		mesh_inst.position.y = 1.25
	else:
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.3
		capsule.height = 1.0
		mesh_inst.mesh = capsule
		mesh_inst.position.y = 0.5

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = neon_color
	_mat.emission_enabled = true
	_mat.emission = neon_color
	_mat.emission_energy_multiplier = 2.0
	_original_color = neon_color
	mesh_inst.material_override = _mat
	add_child(mesh_inst)
	_add_glow_light(neon_color)

func _apply_neon(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		for i in mi.get_surface_override_material_count():
			var base_mat = mi.mesh.surface_get_material(i) if mi.mesh else null
			if base_mat and base_mat is StandardMaterial3D:
				var m: StandardMaterial3D = base_mat.duplicate()
				m.emission_enabled = true
				m.emission = color * 0.4
				m.emission_energy_multiplier = 1.8
				mi.set_surface_override_material(i, m)
				if _mat == null:
					_mat = m
					_original_color = m.albedo_color
	for child in node.get_children():
		_apply_neon(child, color)

func _add_glow_light(color: Color) -> void:
	var light := OmniLight3D.new()
	light.name = "EnemyGlow"
	light.light_color = color
	light.light_energy = 1.0 if not is_boss else 3.0
	light.omni_range = 3.0 if not is_boss else 6.0
	light.omni_attenuation = 2.0
	light.position.y = 1.0
	add_child(light)

func _build_hitbox() -> void:
	var area := Area3D.new()
	area.name = "Hitbox"
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.7 if not is_boss else 1.5
	col.shape = shape
	col.position.y = 0.7 if not is_boss else 1.5
	area.add_child(col)
	add_child(area)

func _process(delta: float) -> void:
	if _dead:
		return
	var player: Node3D = get_tree().get_first_node_in_group("player_node") as Node3D
	if not player:
		return

	var spd := speed
	if GameState.gravity_well_strength > 0.0:
		var dist := global_position.distance_to(player.global_position)
		if dist < 6.0:
			spd *= maxf(0.3, 1.0 - GameState.gravity_well_strength * (1.0 - dist / 6.0))

	var dir := (player.global_position - global_position)
	dir.y = 0.0
	var dist_to_player := dir.length()
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		# Mages hold position at range and shoot instead of charging in
		if enemy_type == "mage" and dist_to_player < MAGE_RANGE:
			_mage_shoot_timer -= delta
			if _mage_shoot_timer <= 0.0:
				_mage_shoot_timer = MAGE_SHOOT_CD
				_mage_telegraph(dir)
			# Slow approach — mages still drift closer but much slower
			position += dir * spd * 0.3 * delta
		elif enemy_type == "necromancer":
			# Necromancers stay at range and summon minions
			_necro_summon_timer -= delta
			if _necro_summon_timer <= 0.0:
				_necro_summon_timer = NECRO_SUMMON_CD
				_necro_summon()
			if dist_to_player < NECRO_KEEP_RANGE:
				# Back away slowly to maintain distance
				position -= dir * spd * 0.4 * delta
			else:
				position += dir * spd * 0.3 * delta
		elif enemy_type == "rogue":
			# Rogues sidestep periodically to dodge projectiles
			_rogue_dodge_timer -= delta
			if _rogue_dodge_timer <= 0.0:
				_rogue_dodge_timer = ROGUE_DODGE_CD + randf_range(-0.3, 0.3)
				var side := Vector3(-dir.z, 0, dir.x) * (1.0 if randf() > 0.5 else -1.0)
				var dodge_pos := position + side * ROGUE_DODGE_DIST
				dodge_pos.x = clampf(dodge_pos.x, -48.0, 48.0)
				dodge_pos.z = clampf(dodge_pos.z, -48.0, 48.0)
				var tw := create_tween()
				tw.tween_property(self, "position", dodge_pos, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			position += dir * spd * delta
		elif enemy_type == "exploder":
			# Exploders rush fast and detonate when close
			position += dir * spd * delta
			if dist_to_player < EXPLODER_DETONATE_RANGE and not _exploder_fuse_lit:
				_exploder_fuse_lit = true
				_explode()
		elif is_boss:
			# Golem: walk toward player and periodically ground slam when close
			# Enrage below 30% HP — faster movement and slams
			var enraged := hp < max_hp * 0.3
			var boss_spd := spd * (1.6 if enraged else 1.0)
			position += dir * boss_spd * delta
			_golem_slam_timer -= delta
			var slam_cd := GOLEM_SLAM_CD * (0.5 if enraged else 1.0)
			if _golem_slam_timer <= 0.0 and dist_to_player < GOLEM_SLAM_RANGE:
				_golem_slam_timer = slam_cd
				_golem_slam()
		else:
			position += dir * spd * delta
		var model := get_node_or_null("Model")
		if model:
			var target_angle := atan2(dir.x, dir.z)
			model.rotation.y = lerp_angle(model.rotation.y, target_angle, 8.0 * delta)
	position.y = 0.0

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and _mat:
			_mat.emission = _original_color
			_mat.emission_energy_multiplier = 2.0

	# Boss enrage visual — pulsing red glow below 30% HP
	if is_boss and hp < max_hp * 0.3 and _mat:
		var pulse := (sin(_golem_slam_timer * 8.0) + 1.0) * 0.5
		_mat.emission = Color(1.0, 0.1, 0.0).lerp(_original_color, pulse * 0.3)
		_mat.emission_energy_multiplier = lerpf(3.0, 5.0, pulse)

func _mage_telegraph(dir: Vector3) -> void:
	# Brief charge-up glow before firing so players can react
	var glow := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	glow.mesh = sphere
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.7, 0.0, 1.0, 0.6)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.7, 0.0, 1.0)
	glow_mat.emission_energy_multiplier = 8.0
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.material_override = glow_mat
	glow.position = global_position + Vector3(0, 1.2, 0)
	var container := get_parent()
	if container:
		container.add_child(glow)
		var tw := glow.create_tween()
		tw.tween_property(glow, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
		tw.tween_callback(glow.queue_free)
	# Fire bolt after short delay
	var tree := get_tree()
	if tree and not _dead:
		tree.create_timer(0.3).timeout.connect(func():
			if not _dead and is_inside_tree():
				var player: Node3D = get_tree().get_first_node_in_group("player_node") as Node3D
				if player:
					var fresh_dir := (player.global_position - global_position).normalized()
					fresh_dir.y = 0.0
					_fire_mage_bolt(fresh_dir)
		)

func _fire_mage_bolt(dir: Vector3) -> void:
	var container := get_parent().get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var bolt := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	bolt.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.0, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.0, 1.0)
	mat.emission_energy_multiplier = 5.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bolt.material_override = mat
	bolt.position = global_position + Vector3(0, 1.0, 0)
	container.add_child(bolt)
	# Simple area for hitting player
	var area := Area3D.new()
	area.collision_layer = 2
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	area.add_child(col)
	bolt.add_child(area)
	var bolt_dir := dir
	var bolt_spd := MAGE_PROJ_SPEED
	var bolt_dmg := MAGE_PROJ_DAMAGE * (1.0 + GameState.wave * 0.1)
	var bolt_alive := 0.0
	area.area_entered.connect(func(_a: Area3D):
		if not GameState.invincible:
			GameState.take_damage(bolt_dmg)
		bolt.queue_free()
	)
	# Move bolt via tween destination
	var end_pos := bolt.position + bolt_dir * 20.0
	var tw := bolt.create_tween()
	tw.tween_property(bolt, "position", end_pos, 20.0 / bolt_spd)
	tw.tween_callback(bolt.queue_free)

func _necro_summon() -> void:
	var container := get_parent()
	if not container:
		return
	# Limit total enemies to avoid flooding the scene
	var current_enemies := get_tree().get_nodes_in_group("enemies").size()
	if current_enemies > 80:
		return
	# Summon VFX — purple flash ring at feet
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.03
	ring.mesh = cyl
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.6, 0.0, 0.9, 0.7)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.6, 0.0, 0.9)
	ring_mat.emission_energy_multiplier = 5.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	ring.position = global_position
	ring.position.y = 0.2
	container.add_child(ring)
	var rtw := ring.create_tween()
	rtw.set_parallel(true)
	rtw.tween_property(ring, "scale", Vector3(2.5, 1.0, 2.5), 0.4)
	rtw.tween_property(ring_mat, "albedo_color:a", 0.0, 0.4)
	rtw.set_parallel(false)
	rtw.tween_callback(ring.queue_free)
	# Spawn minions around the necromancer
	for i in NECRO_SUMMON_COUNT:
		var angle := TAU / float(NECRO_SUMMON_COUNT) * float(i) + randf() * 0.5
		var offset := Vector3(cos(angle), 0, sin(angle)) * 2.0
		var spawn_pos := global_position + offset
		spawn_pos.x = clampf(spawn_pos.x, -48.0, 48.0)
		spawn_pos.z = clampf(spawn_pos.z, -48.0, 48.0)
		var minion := Node3D.new()
		minion.name = "Enemy_minion"
		minion.set_script(load("res://scripts/enemy.gd"))
		minion.position = spawn_pos
		minion.set_meta("_enemy_type", "minion")
		minion.set_meta("_enemy_wave", GameState.wave)
		container.add_child(minion)

func _golem_slam() -> void:
	# Ground slam AoE attack — damages and knocks back the player
	var player: Node3D = get_tree().get_first_node_in_group("player_node") as Node3D
	if player:
		var dist := global_position.distance_to(player.global_position)
		if dist < GOLEM_SLAM_RANGE and not GameState.invincible:
			GameState.take_damage(GOLEM_SLAM_DAMAGE)
			var kb_dir := (player.global_position - global_position).normalized()
			kb_dir.y = 0.0
			player.position += kb_dir * 3.0
	GameState.request_shake(3.5)
	GameState.request_hit_stop(0.06)
	Audio.sfx_golem_slam()
	# Slam VFX — shockwave ring on the ground
	var container := get_parent()
	if not container:
		return
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.05
	ring.mesh = cyl
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.3, 0.0, 0.8)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.2, 0.0)
	ring_mat.emission_energy_multiplier = 6.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	ring.position = global_position
	ring.position.y = 0.15
	container.add_child(ring)
	var rtw := ring.create_tween()
	rtw.set_parallel(true)
	rtw.tween_property(ring, "scale", Vector3(GOLEM_SLAM_RANGE, 1.0, GOLEM_SLAM_RANGE), 0.3)
	rtw.tween_property(ring_mat, "albedo_color:a", 0.0, 0.4)
	rtw.set_parallel(false)
	rtw.tween_callback(ring.queue_free)

func _explode() -> void:
	# Area damage to player if in range
	var player: Node3D = get_tree().get_first_node_in_group("player_node") as Node3D
	if player:
		var dist := global_position.distance_to(player.global_position)
		if dist < EXPLODER_RADIUS and not GameState.invincible:
			GameState.take_damage(EXPLODER_DAMAGE)
			GameState.request_shake(3.0)
	# Also damage nearby enemies (chain reaction potential)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e != self and e is Node3D and e.has_method("take_damage"):
			var d := global_position.distance_to(e.global_position)
			if d < EXPLODER_RADIUS * 0.6:
				e.take_damage(EXPLODER_DAMAGE * 0.5)
	Audio.sfx_exploder_boom()
	_spawn_explosion_vfx()
	_dead = true
	GameState.add_kill()
	_spawn_xp()
	queue_free()

func _spawn_explosion_vfx() -> void:
	var container := get_parent()
	if not container:
		return
	# Large expanding ring
	for ring_i in 2:
		var ring := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = EXPLODER_RADIUS * (0.3 + ring_i * 0.3)
		cyl.bottom_radius = EXPLODER_RADIUS * (0.3 + ring_i * 0.3)
		cyl.height = 0.04
		ring.mesh = cyl
		var ring_mat := StandardMaterial3D.new()
		ring_mat.albedo_color = Color(1.0, 0.6, 0.0, 0.8 - ring_i * 0.2)
		ring_mat.emission_enabled = true
		ring_mat.emission = Color(1.0, 0.4, 0.0)
		ring_mat.emission_energy_multiplier = 6.0
		ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = ring_mat
		ring.position = global_position
		ring.position.y = 0.3 + ring_i * 0.15
		container.add_child(ring)
		var rtw := ring.create_tween()
		rtw.set_parallel(true)
		rtw.tween_property(ring, "scale", Vector3(2.5, 1.0, 2.5), 0.35 + ring_i * 0.1)
		rtw.tween_property(ring_mat, "albedo_color:a", 0.0, 0.35 + ring_i * 0.1)
		rtw.set_parallel(false)
		rtw.tween_callback(ring.queue_free)
	# Bright flash sphere
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	flash.mesh = sphere
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.8, 0.0, 0.7)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.6, 0.0)
	flash_mat.emission_energy_multiplier = 10.0
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = flash_mat
	flash.position = global_position
	flash.position.y = 0.8
	container.add_child(flash)
	var ftw := flash.create_tween()
	ftw.set_parallel(true)
	ftw.tween_property(flash, "scale", Vector3(3.0, 3.0, 3.0), 0.25)
	ftw.tween_property(flash_mat, "albedo_color:a", 0.0, 0.25)
	ftw.set_parallel(false)
	ftw.tween_callback(flash.queue_free)

func take_damage(amount: float) -> void:
	if _dead:
		return
	# Critical hit check
	var is_crit := randf() < GameState.crit_chance
	var final_amount := amount * (2.0 if is_crit else 1.0)
	hp -= final_amount
	GameState.add_damage_dealt(final_amount)
	_flash_timer = FLASH_DURATION
	if _mat:
		_mat.emission = Color(1.0, 0.6, 0.0) if is_crit else Color.WHITE
		_mat.emission_energy_multiplier = 10.0 if is_crit else 6.0
	# Knockback — crits knock back harder
	var player: Node3D = get_tree().get_first_node_in_group("player_node") as Node3D
	if player:
		var kb_dir := (global_position - player.global_position).normalized()
		kb_dir.y = 0.0
		position += kb_dir * (0.6 if is_crit else 0.3)
	_spawn_damage_number(final_amount, is_crit)
	if hp <= 0.0:
		if enemy_type == "exploder" and not _exploder_fuse_lit:
			_exploder_fuse_lit = true
			_explode()
			return
		_die()

func _spawn_damage_number(amount: float, is_crit: bool = false) -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	var screen_pos := cam.unproject_position(global_position + Vector3(0, 1.8, 0))
	var canvas := get_tree().get_first_node_in_group("hud_node") as Control
	if not canvas:
		return
	var label := Label.new()
	label.text = ("CRIT " if is_crit else "") + str(int(amount))
	var is_big_hit := amount >= 30.0 or is_crit
	if is_crit:
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
		label.add_theme_color_override("font_outline_color", Color(1.0, 0.2, 0.0))
		label.add_theme_constant_override("outline_size", 4)
	elif is_big_hit:
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))
		label.add_theme_color_override("font_outline_color", Color(1.0, 0.0, 0.0))
		label.add_theme_constant_override("outline_size", 3)
	else:
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	label.position = screen_pos + Vector2(randf_range(-20, 20), randf_range(-10, 5))
	label.z_index = 100
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(label)
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 50.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	if is_big_hit or is_crit:
		tw.tween_property(label, "scale", Vector2(1.4, 1.4), 0.08).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.15)
	tw.set_parallel(false)
	tw.tween_callback(label.queue_free)

func _die() -> void:
	_dead = true
	GameState.add_kill()
	Audio.sfx_enemy_death()
	_spawn_xp()
	if is_boss:
		GameState.request_shake(4.0)
		GameState.request_hit_stop(0.1)
		Audio.sfx_boss_defeat()
		Audio.play_victory_sting()
		GameState.boss_defeated.emit()
		# Brief victory moment before resuming normal music
		var tree := get_tree()
		if tree:
			tree.create_timer(3.0).timeout.connect(func():
				if not GameState.game_over:
					Audio.play_music("res://assets/audio/music/neon_runner.mp3", -6.0)
			)
	else:
		GameState.request_shake(1.0)
	_death_vfx()

func _spawn_xp() -> void:
	var orb_container := get_parent().get_parent().get_node_or_null("XPOrbs")
	if not orb_container:
		queue_free()
		return
	var count := 1 if not is_boss else 5
	for i in count:
		var orb := Node3D.new()
		orb.name = "XPOrb"
		orb.set_script(load("res://scripts/xp_orb.gd"))
		var offset := Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
		orb.position = global_position + offset
		orb.set_meta("xp_value", xp_value)
		orb_container.add_child(orb)

func _death_vfx() -> void:
	var container := get_parent()
	if not container:
		queue_free()
		return
	var death_colors := {
		"minion": Color(1.0, 0.0, 0.6),
		"warrior": Color(0.9, 0.0, 0.3),
		"mage": Color(0.7, 0.0, 1.0),
		"rogue": Color(0.0, 1.0, 0.5),
		"necromancer": Color(0.6, 0.0, 0.9),
		"exploder": Color(1.0, 0.8, 0.0),
		"golem": Color(1.0, 0.3, 0.0),
	}
	var color: Color = death_colors.get(enemy_type, Color(1.0, 0.0, 0.6))

	# Expanding ring
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.8 if not is_boss else 2.0
	cyl.bottom_radius = 0.8 if not is_boss else 2.0
	cyl.height = 0.03
	ring.mesh = cyl
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	ring_mat.emission_enabled = true
	ring_mat.emission = color
	ring_mat.emission_energy_multiplier = 5.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	ring.position = global_position
	ring.position.y = 0.3
	container.add_child(ring)
	var rtw := ring.create_tween()
	rtw.set_parallel(true)
	rtw.tween_property(ring, "scale", Vector3(3.0, 1.0, 3.0), 0.3)
	rtw.tween_property(ring_mat, "albedo_color:a", 0.0, 0.3)
	rtw.set_parallel(false)
	rtw.tween_callback(ring.queue_free)

	# Spark burst
	var spark_count := 6 if not is_boss else 12
	for i in spark_count:
		var spark := MeshInstance3D.new()
		var ss := SphereMesh.new()
		ss.radius = 0.06 if not is_boss else 0.12
		spark.mesh = ss
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(color.r, color.g, color.b, 0.9)
		smat.emission_enabled = true
		smat.emission = color
		smat.emission_energy_multiplier = 5.0
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spark.material_override = smat
		spark.position = global_position + Vector3(0, 0.5, 0)
		container.add_child(spark)
		var angle := TAU / float(spark_count) * float(i) + randf() * 0.3
		var spark_dir := Vector3(cos(angle), randf_range(0.3, 1.0), sin(angle))
		spark_dir = spark_dir.normalized() * randf_range(1.5, 3.0)
		var stw := spark.create_tween()
		stw.set_parallel(true)
		stw.tween_property(spark, "position", spark.position + spark_dir, 0.25)
		stw.tween_property(smat, "albedo_color:a", 0.0, 0.25)
		stw.set_parallel(false)
		stw.tween_callback(spark.queue_free)
	queue_free()

func setup(type: String, wave: int) -> void:
	enemy_type = type
	# Soft cap: linear scaling up to wave 15, then diminishing returns
	var wave_scale := 1.0 + minf(wave, 15) * 0.1 + maxf(wave - 15, 0) * 0.04
	match type:
		"minion":
			hp = 15.0 * wave_scale
			speed = 4.5
			xp_value = 8.0
			is_boss = false
		"warrior":
			hp = 35.0 * wave_scale
			speed = 3.5
			xp_value = 15.0
			is_boss = false
		"mage":
			hp = 25.0 * wave_scale
			speed = 2.5
			xp_value = 12.0
			is_boss = false
		"rogue":
			hp = 18.0 * wave_scale
			speed = 6.0
			xp_value = 14.0
			contact_damage = 12.0
			is_boss = false
		"necromancer":
			hp = 45.0 * wave_scale
			speed = 2.0
			xp_value = 25.0
			contact_damage = 15.0
			is_boss = false
		"exploder":
			hp = 12.0 * wave_scale
			speed = 5.5
			xp_value = 12.0
			contact_damage = 15.0
			is_boss = false
		"golem":
			hp = 300.0 * wave_scale
			speed = 1.8
			xp_value = 80.0
			contact_damage = 25.0
			is_boss = true
	max_hp = hp
