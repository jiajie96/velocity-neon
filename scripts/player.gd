extends Node3D

const DASH_DURATION := 0.2
const DASH_TRAIL_COUNT := 6
const ULTIMATE_COOLDOWN := 12.0
const ULTIMATE_RADIUS := 8.0
const ULTIMATE_DAMAGE := 50.0
const CONTACT_DAMAGE := 10.0
const CONTACT_COOLDOWN := 0.8
const RAILGUN_COOLDOWN := 2.0
const SCATTER_COOLDOWN := 1.5
const ORBITAL_RADIUS := 2.5
const ORBITAL_SPEED := 3.0
const ORBITAL_DAMAGE := 8.0
const ORBITAL_HIT_CD := 0.5

var fire_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cd_timer: float = 0.0
var is_dashing: bool = false
var dash_dir: Vector3 = Vector3.ZERO
var ult_cd_timer: float = 0.0
var contact_cd: float = 0.0
var last_move_dir: Vector3 = Vector3(0, 0, -1)
var railgun_timer: float = 0.0
var scatter_timer: float = 0.0
var _orbital_nodes: Array[MeshInstance3D] = []
var _orbital_angle: float = 0.0
var _orbital_hit_timers: Dictionary = {}
var _model_loaded: bool = false

func _ready() -> void:
	add_to_group("player_node")
	_build_visual()
	_build_hurtbox()
	_build_light()

func _build_visual() -> void:
	var model_path := "res://assets/models/Knight.glb"
	if ResourceLoader.exists(model_path):
		var scene: PackedScene = load(model_path)
		if scene:
			var inst := scene.instantiate()
			inst.name = "Model"
			inst.scale = Vector3(0.6, 0.6, 0.6)
			add_child(inst)
			_apply_neon_tint(inst, Color(0.0, 0.9, 1.0))
			_model_loaded = true
			return
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.3
	mesh_inst.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.85, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.7, 1.0)
	mat.emission_energy_multiplier = 2.5
	mesh_inst.material_override = mat
	mesh_inst.position.y = 0.65
	add_child(mesh_inst)

func _apply_neon_tint(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		for i in mi.get_surface_override_material_count():
			var base_mat = mi.mesh.surface_get_material(i) if mi.mesh else null
			if base_mat and base_mat is StandardMaterial3D:
				var new_mat: StandardMaterial3D = base_mat.duplicate()
				new_mat.emission_enabled = true
				new_mat.emission = color * 0.3
				new_mat.emission_energy_multiplier = 1.5
				mi.set_surface_override_material(i, new_mat)
	for child in node.get_children():
		_apply_neon_tint(child, color)

func _build_hurtbox() -> void:
	var area := Area3D.new()
	area.name = "Hurtbox"
	area.collision_layer = 1
	area.collision_mask = 2
	area.monitoring = true
	area.monitorable = true
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	col.shape = shape
	col.position.y = 0.6
	area.add_child(col)
	add_child(area)

func _build_light() -> void:
	var light := OmniLight3D.new()
	light.name = "PlayerGlow"
	light.light_color = Color(0.0, 0.75, 1.0)
	light.light_energy = 2.5
	light.omni_range = 10.0
	light.omni_attenuation = 1.5
	light.position.y = 1.5
	add_child(light)

func _process(delta: float) -> void:
	if GameState.game_over or GameState.paused_for_upgrade or not GameState.game_started:
		return
	_move(delta)
	_dash(delta)
	_shoot(delta)
	_shoot_railgun(delta)
	_shoot_scatter(delta)
	_update_orbitals(delta)
	_ultimate(delta)
	_check_contact_damage(delta)

func _move(delta: float) -> void:
	if is_dashing:
		return
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_up"):
		dir.z -= 1.0
	if Input.is_action_pressed("move_down"):
		dir.z += 1.0
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		dir.x += 1.0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		last_move_dir = dir
		if _model_loaded:
			var target_angle := atan2(dir.x, dir.z)
			var model := get_node_or_null("Model")
			if model:
				model.rotation.y = lerp_angle(model.rotation.y, target_angle, 10.0 * delta)
	position += dir * GameState.speed * delta
	position.y = 0.0
	position.x = clampf(position.x, -48.0, 48.0)
	position.z = clampf(position.z, -48.0, 48.0)

func _dash(delta: float) -> void:
	dash_cd_timer = maxf(dash_cd_timer - delta, 0.0)
	if is_dashing:
		dash_timer -= delta
		position += dash_dir * GameState.dash_speed * delta
		position.y = 0.0
		position.x = clampf(position.x, -48.0, 48.0)
		position.z = clampf(position.z, -48.0, 48.0)
		if dash_timer <= 0.0:
			is_dashing = false
			GameState.invincible = false
		return
	if Input.is_action_just_pressed("dash") and dash_cd_timer <= 0.0:
		var dir := Vector3.ZERO
		if Input.is_action_pressed("move_up"):
			dir.z -= 1.0
		if Input.is_action_pressed("move_down"):
			dir.z += 1.0
		if Input.is_action_pressed("move_left"):
			dir.x -= 1.0
		if Input.is_action_pressed("move_right"):
			dir.x += 1.0
		if dir.length_squared() < 0.01:
			dir = last_move_dir
		dash_dir = dir.normalized()
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cd_timer = GameState.dash_cooldown
		GameState.invincible = true
		Audio.sfx_dash()
		_spawn_dash_trail()

func _spawn_dash_trail() -> void:
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	for i in DASH_TRAIL_COUNT:
		var p := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.25
		sphere.height = 0.5
		p.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.4, 0.0, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.5, 0.0)
		mat.emission_energy_multiplier = 4.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p.material_override = mat
		p.position = position - dash_dir * (float(i) * 0.6)
		p.position.y = 0.4
		container.add_child(p)
		var tw := p.create_tween()
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.4)
		tw.tween_callback(p.queue_free)

# === PRIMARY WEAPON ===

func _shoot(delta: float) -> void:
	if is_dashing:
		return
	var rate := GameState.fire_rate
	if GameState.overclock_active:
		rate *= 2.0
	fire_timer -= delta
	if fire_timer > 0.0:
		return
	var target := _find_nearest_enemy()
	if not target:
		return
	fire_timer = 1.0 / rate
	var dir_to_target: Vector3 = (target.global_position - global_position)
	dir_to_target.y = 0.0
	dir_to_target = dir_to_target.normalized()
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var count := GameState.projectile_count
	for i in count:
		var spread := 0.0
		if count > 1:
			spread = deg_to_rad(12.0) * (float(i) - float(count - 1) * 0.5)
		var shot_dir := dir_to_target.rotated(Vector3.UP, spread)
		_fire_projectile(container, shot_dir, "pulse")
	Audio.sfx_shoot()
	_spawn_muzzle_flash(dir_to_target)

func _fire_projectile(container: Node, dir: Vector3, weapon_type: String) -> void:
	var proj := Node3D.new()
	proj.name = "Projectile"
	proj.set_script(load("res://scripts/projectile.gd"))
	proj.position = global_position + Vector3(0, 0.8, 0) + dir * 0.5
	proj.set_meta("direction", dir)
	proj.set_meta("speed", GameState.projectile_speed)
	proj.set_meta("damage", GameState.damage)
	proj.set_meta("shatter", GameState.has_shatter)
	proj.set_meta("weapon_type", weapon_type)
	proj.set_meta("chain_level", GameState.chain_level)
	container.add_child(proj)

func _spawn_muzzle_flash(dir: Vector3) -> void:
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	flash.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.5, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.3)
	mat.emission_energy_multiplier = 8.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = mat
	flash.position = global_position + Vector3(0, 0.8, 0) + dir * 0.6
	container.add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.08)
	tw.tween_callback(flash.queue_free)

# === RAILGUN ===

func _shoot_railgun(delta: float) -> void:
	if GameState.railgun_level <= 0:
		return
	railgun_timer -= delta
	if railgun_timer > 0.0:
		return
	var target := _find_nearest_enemy()
	if not target:
		return
	railgun_timer = RAILGUN_COOLDOWN
	var dir: Vector3 = (target.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	var beam_damage := GameState.damage * (1.5 + 0.5 * GameState.railgun_level)
	var origin := global_position + Vector3(0, 0.8, 0)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node3D:
			var to_enemy: Vector3 = e.global_position - origin
			to_enemy.y = 0.0
			var along := to_enemy.dot(dir)
			if along < 0.5 or along > 40.0:
				continue
			var perp := (to_enemy - dir * along).length()
			if perp < 1.2:
				if e.has_method("take_damage"):
					e.take_damage(beam_damage)
	Audio.sfx_shoot_railgun()
	_spawn_railgun_beam(origin, dir)
	GameState.request_shake(2.5, -dir)
	GameState.request_hit_stop(0.05)

func _spawn_railgun_beam(origin: Vector3, dir: Vector3) -> void:
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.08
	cyl.height = 40.0
	beam.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.5, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.6, 1.0)
	mat.emission_energy_multiplier = 8.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = mat
	beam.position = origin + dir * 20.0
	beam.rotation.x = PI / 2.0
	beam.rotation.y = atan2(dir.x, dir.z)
	container.add_child(beam)
	var tw := beam.create_tween()
	tw.set_parallel(true)
	tw.tween_property(beam, "scale:x", 3.0, 0.08)
	tw.tween_property(beam, "scale:z", 3.0, 0.08)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.set_parallel(false)
	tw.tween_callback(beam.queue_free)

# === SCATTER SHOT ===

func _shoot_scatter(delta: float) -> void:
	if GameState.scatter_level <= 0:
		return
	scatter_timer -= delta
	if scatter_timer > 0.0:
		return
	var target := _find_nearest_enemy()
	if not target:
		return
	scatter_timer = SCATTER_COOLDOWN
	var dir: Vector3 = (target.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var pellets := 4 + GameState.scatter_level * 2
	var spread_angle := deg_to_rad(40.0)
	for i in pellets:
		var angle := spread_angle * (float(i) / float(pellets - 1) - 0.5)
		var shot_dir := dir.rotated(Vector3.UP, angle)
		var proj := Node3D.new()
		proj.name = "ScatterPellet"
		proj.set_script(load("res://scripts/projectile.gd"))
		proj.position = global_position + Vector3(0, 0.8, 0) + shot_dir * 0.4
		proj.set_meta("direction", shot_dir)
		proj.set_meta("speed", GameState.projectile_speed * 1.3)
		proj.set_meta("damage", GameState.damage * 0.5)
		proj.set_meta("shatter", false)
		proj.set_meta("weapon_type", "scatter")
		proj.set_meta("chain_level", 0)
		proj.set_meta("lifetime", 1.0)
		container.add_child(proj)
	Audio.sfx_shoot_scatter()
	_spawn_muzzle_flash(dir)
	GameState.request_shake(1.5, -dir)

# === ORBITAL GUARD ===

func _update_orbitals(delta: float) -> void:
	var wanted := GameState.orbital_level
	while _orbital_nodes.size() < wanted:
		var orb := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.25
		orb.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.0, 1.0, 0.6)
		mat.emission_enabled = true
		mat.emission = Color(0.0, 1.0, 0.5)
		mat.emission_energy_multiplier = 4.0
		orb.material_override = mat
		add_child(orb)
		_orbital_nodes.append(orb)
	while _orbital_nodes.size() > wanted:
		var orb: MeshInstance3D = _orbital_nodes.pop_back()
		orb.queue_free()
	if wanted <= 0:
		return
	_orbital_angle += ORBITAL_SPEED * delta
	for i in _orbital_nodes.size():
		var angle := _orbital_angle + (TAU / float(wanted)) * float(i)
		var orb: MeshInstance3D = _orbital_nodes[i]
		orb.position = Vector3(cos(angle) * ORBITAL_RADIUS, 0.6, sin(angle) * ORBITAL_RADIUS)
	var orb_world_positions: Array[Vector3] = []
	for orb in _orbital_nodes:
		orb_world_positions.append(orb.global_position)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for key in _orbital_hit_timers.keys():
		_orbital_hit_timers[key] -= delta
		if _orbital_hit_timers[key] <= 0.0:
			_orbital_hit_timers.erase(key)
	for e in enemies:
		if e is Node3D and e.has_method("take_damage"):
			for orb_pos in orb_world_positions:
				if orb_pos.distance_to(e.global_position) < 1.2:
					var eid := e.get_instance_id()
					if eid not in _orbital_hit_timers:
						e.take_damage(ORBITAL_DAMAGE * (1.0 + GameState.orbital_level * 0.3))
						_orbital_hit_timers[eid] = ORBITAL_HIT_CD
					break

# === ULTIMATE ===

func _ultimate(delta: float) -> void:
	ult_cd_timer = maxf(ult_cd_timer - delta, 0.0)
	if Input.is_action_just_pressed("ultimate") and ult_cd_timer <= 0.0:
		ult_cd_timer = ULTIMATE_COOLDOWN
		_do_ultimate()

func _do_ultimate() -> void:
	Audio.sfx_ultimate()
	GameState.request_shake(6.0)
	GameState.request_hit_stop(0.08)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is Node3D:
			var dist := global_position.distance_to(enemy.global_position)
			if dist < ULTIMATE_RADIUS:
				if enemy.has_method("take_damage"):
					enemy.take_damage(ULTIMATE_DAMAGE)
	_spawn_ult_vfx()

func _spawn_ult_vfx() -> void:
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	for ring_i in 3:
		var ring := MeshInstance3D.new()
		var torus := CylinderMesh.new()
		torus.top_radius = ULTIMATE_RADIUS * (0.5 + ring_i * 0.3)
		torus.bottom_radius = ULTIMATE_RADIUS * (0.5 + ring_i * 0.3)
		torus.height = 0.05
		ring.mesh = torus
		var mat := StandardMaterial3D.new()
		var c := Color(0.0, 1.0, 1.0, 0.8 - ring_i * 0.2)
		mat.albedo_color = c
		mat.emission_enabled = true
		mat.emission = Color(0.0, 1.0, 1.0)
		mat.emission_energy_multiplier = 6.0 - ring_i
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = mat
		ring.position = global_position
		ring.position.y = 0.3 + ring_i * 0.2
		container.add_child(ring)
		var tw := ring.create_tween()
		tw.set_parallel(true)
		tw.tween_property(ring, "scale", Vector3(1.8, 1.0, 1.8), 0.4 + ring_i * 0.1)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.4 + ring_i * 0.1)
		tw.set_parallel(false)
		tw.tween_callback(ring.queue_free)

func _find_nearest_enemy() -> Node3D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node3D = null
	var min_dist := 30.0
	for e in enemies:
		if e is Node3D:
			var d := global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
	return nearest

func _check_contact_damage(delta: float) -> void:
	contact_cd = maxf(contact_cd - delta, 0.0)
	if contact_cd > 0.0 or is_dashing or GameState.invincible:
		return
	var hurtbox: Area3D = get_node_or_null("Hurtbox")
	if not hurtbox:
		return
	var overlaps := hurtbox.get_overlapping_areas()
	if overlaps.size() > 0:
		var enemy := overlaps[0].get_parent()
		var dmg := CONTACT_DAMAGE
		if enemy and enemy.get("contact_damage"):
			dmg = enemy.contact_damage
		contact_cd = CONTACT_COOLDOWN
		GameState.take_damage(dmg)
		var kb_dir: Vector3 = (global_position - enemy.global_position).normalized() if enemy else Vector3.BACK
		kb_dir.y = 0.0
		position += kb_dir * 1.5
		GameState.request_shake(1.5, kb_dir)
