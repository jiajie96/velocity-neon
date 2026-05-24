extends Node3D

const DASH_DURATION := 0.2
const DASH_TRAIL_COUNT := 6
const ULTIMATE_COOLDOWN := 12.0
const ULTIMATE_RADIUS := 8.0
const ULTIMATE_DAMAGE := 50.0
const CONTACT_DAMAGE := 10.0
const CONTACT_COOLDOWN := 0.8
const RAILGUN_COOLDOWN := 2.0
const SIGNAL_ARROW_COOLDOWN := 1.6
const ORBITAL_RADIUS := 2.5
const ORBITAL_SPEED := 3.0
const ORBITAL_DAMAGE := 8.0
const ORBITAL_HIT_CD := 0.5
const DASH_AFTERIMAGE_INTERVAL := 0.04
const DASH_DAMAGE := 15.0
const DASH_HIT_RADIUS := 1.5
const DASH_IFRAME_GRACE := 0.1

var fire_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cd_timer: float = 0.0
var _dash_grace_timer: float = 0.0
var is_dashing: bool = false
var dash_dir: Vector3 = Vector3.ZERO
var ult_cd_timer: float = 0.0
var contact_cd: float = 0.0
var last_move_dir: Vector3 = Vector3(0, 0, -1)
var railgun_timer: float = 0.0
var signal_arrow_timer: float = 0.0
var _orbital_nodes: Array[MeshInstance3D] = []
var _orbital_angle: float = 0.0
var _orbital_hit_timers: Dictionary = {}
var _model_loaded: bool = false
var _afterimage_timer: float = 0.0
var _dash_ring: MeshInstance3D
var _dash_ring_mat: StandardMaterial3D
var _dash_hit_enemies: Array[int] = []
var _regen_vfx_timer: float = 0.0
var _ult_was_on_cd: bool = false
var _overclock_pulse_t: float = 0.0
var _gravity_ring: MeshInstance3D
var _gravity_ring_mat: StandardMaterial3D
var _heartbeat_timer: float = 0.0
var _damage_flash_timer: float = 0.0
var _shield_ring: MeshInstance3D
var _shield_ring_mat: StandardMaterial3D
var _shield_pulse_t: float = 0.0
var _target_reticle: Node3D
var _reticle_mats: Array[StandardMaterial3D] = []
var _reticle_pulse_t: float = 0.0
var _beacon: MeshInstance3D
var _beacon_t: float = 0.0

# Procedural animation
var _anim_bob_t: float = 0.0
var _anim_prev_pos: Vector3 = Vector3.ZERO
var _anim_velocity: Vector3 = Vector3.ZERO
var _anim_tilt_x: float = 0.0
var _anim_tilt_z: float = 0.0
var _anim_squash: float = 1.0

func _ready() -> void:
	add_to_group("player_node")
	_build_visual()
	_build_hurtbox()
	_build_light()
	_build_dash_ring()
	_build_gravity_ring()
	_build_shield_ring()
	_build_target_reticle()
	_build_contact_shadow()
	_build_player_beacon()
	GameState.hp_changed.connect(_on_hp_changed)
	GameState.damage_iframes_started.connect(_on_iframes_started)
	# Burst plays once the upgrade is confirmed (and the game un-pauses), so it
	# animates in real time instead of being frozen behind the upgrade screen.
	GameState.upgrade_selected.connect(_on_upgrade_burst)

func _build_visual() -> void:
	var model_path := "res://assets/models/Knight.glb"
	if ResourceLoader.exists(model_path):
		var scene: PackedScene = load(model_path)
		if scene:
			var inst := scene.instantiate()
			inst.name = "Model"
			inst.scale = Vector3(0.6, 0.6, 0.6)
			add_child(inst)
			_apply_neon_tint(inst, Color(0.0, 0.3, 0.5))
			_model_loaded = true
			return
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.3
	mesh_inst.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.3, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.2, 0.35)
	mat.emission_energy_multiplier = 0.6
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
				# Keep the figure dark but give it a clear cyan rim glow so the hero
				# reads against the dark neon floor.
				new_mat.albedo_color = new_mat.albedo_color.darkened(0.2)
				new_mat.emission_enabled = true
				new_mat.emission = Color(0.0, 0.5, 0.8)
				new_mat.emission_energy_multiplier = 0.7
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
	light.light_color = Color(0.0, 0.5, 0.75)
	light.light_energy = 0.4
	light.omni_range = 4.0
	light.omni_attenuation = 2.5
	light.position.y = 1.5
	add_child(light)

func _build_dash_ring() -> void:
	_dash_ring = MeshInstance3D.new()
	_dash_ring.name = "DashRing"
	var torus := CylinderMesh.new()
	torus.top_radius = 0.9
	torus.bottom_radius = 0.9
	torus.height = 0.02
	_dash_ring.mesh = torus
	_dash_ring_mat = StandardMaterial3D.new()
	_dash_ring_mat.albedo_color = Color(0.3, 0.7, 0.9, 0.3)
	_dash_ring_mat.emission_enabled = true
	_dash_ring_mat.emission = Color(0.2, 0.5, 0.7)
	_dash_ring_mat.emission_energy_multiplier = 1.5
	_dash_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dash_ring.material_override = _dash_ring_mat
	_dash_ring.position.y = 0.05
	add_child(_dash_ring)

func _build_gravity_ring() -> void:
	_gravity_ring = MeshInstance3D.new()
	_gravity_ring.name = "GravityRing"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 6.0
	cyl.bottom_radius = 6.0
	cyl.height = 0.01
	_gravity_ring.mesh = cyl
	_gravity_ring_mat = StandardMaterial3D.new()
	_gravity_ring_mat.albedo_color = Color(0.5, 0.2, 1.0, 0.12)
	_gravity_ring_mat.emission_enabled = true
	_gravity_ring_mat.emission = Color(0.5, 0.2, 1.0)
	_gravity_ring_mat.emission_energy_multiplier = 1.5
	_gravity_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_gravity_ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_gravity_ring.material_override = _gravity_ring_mat
	_gravity_ring.position.y = 0.03
	_gravity_ring.visible = false
	add_child(_gravity_ring)

func _build_shield_ring() -> void:
	_shield_ring = MeshInstance3D.new()
	_shield_ring.name = "ShieldRing"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.7
	cyl.bottom_radius = 0.7
	cyl.height = 0.015
	_shield_ring.mesh = cyl
	_shield_ring_mat = StandardMaterial3D.new()
	_shield_ring_mat.albedo_color = Color(0.2, 0.5, 1.0, 0.0)
	_shield_ring_mat.emission_enabled = true
	_shield_ring_mat.emission = Color(0.3, 0.6, 1.0)
	_shield_ring_mat.emission_energy_multiplier = 2.0
	_shield_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shield_ring.material_override = _shield_ring_mat
	_shield_ring.position.y = 0.04
	_shield_ring.visible = false
	add_child(_shield_ring)

func _build_player_beacon() -> void:
	# A small warm-gold chevron hovering over the hero so it's always findable in a
	# swarm — gold contrasts with the cool cyan/red/purple neon palette.
	_beacon = MeshInstance3D.new()
	_beacon.name = "PlayerBeacon"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.18
	cone.height = 0.32
	cone.radial_segments = 4
	_beacon.mesh = cone
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.1)
	mat.emission_energy_multiplier = 4.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beacon.material_override = mat
	_beacon.rotation.x = PI  # point the chevron downward toward the player
	_beacon.position.y = 2.2
	add_child(_beacon)

func _update_player_beacon(delta: float) -> void:
	if not _beacon:
		return
	_beacon_t += delta * 3.0
	_beacon.position.y = 2.2 + sin(_beacon_t) * 0.12

func _build_contact_shadow() -> void:
	# A flat dark disc under the unit mutes the busy grid directly beneath it,
	# separating the silhouette from the floor for readability.
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.6
	disc.bottom_radius = 0.6
	disc.height = 0.01
	disc.radial_segments = 16
	shadow.mesh = disc
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.0, 0.0, 0.42)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shadow.material_override = mat
	shadow.position.y = 0.03
	add_child(shadow)

func _build_target_reticle() -> void:
	# A spinning cyan bracket frame that marks the enemy the primary weapon is
	# auto-aiming at, so the player can read who they're shooting.
	_target_reticle = Node3D.new()
	_target_reticle.name = "TargetReticle"
	_target_reticle.visible = false
	add_child(_target_reticle)
	var cyan := Color(0.2, 0.85, 1.0)
	var edges := [
		Vector3(0, 0, -0.5), Vector3(0, 0, 0.5),
		Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0),
	]
	var sizes := [
		Vector3(0.95, 0.03, 0.1), Vector3(0.95, 0.03, 0.1),
		Vector3(0.1, 0.03, 0.95), Vector3(0.1, 0.03, 0.95),
	]
	for i in edges.size():
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = sizes[i]
		bar.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(cyan.r, cyan.g, cyan.b, 0.5)
		mat.emission_enabled = true
		mat.emission = cyan
		mat.emission_energy_multiplier = 3.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bar.material_override = mat
		bar.position = edges[i]
		_target_reticle.add_child(bar)
		_reticle_mats.append(mat)

func _update_target_reticle(delta: float) -> void:
	if not _target_reticle:
		return
	var target := _find_nearest_enemy()
	if not target:
		_target_reticle.visible = false
		return
	_target_reticle.visible = true
	var rscale := 1.0
	if target.get("is_boss"):
		rscale = 2.6
	_target_reticle.scale = Vector3(rscale, 1.0, rscale)
	_target_reticle.global_position = Vector3(target.global_position.x, 0.12, target.global_position.z)
	_target_reticle.rotation.y += delta * 1.2
	_reticle_pulse_t += delta * 4.0
	var pulse := (sin(_reticle_pulse_t) + 1.0) * 0.5
	var a := lerpf(0.3, 0.7, pulse)
	for mat in _reticle_mats:
		mat.albedo_color.a = a
		mat.emission_energy_multiplier = lerpf(2.0, 4.0, pulse)

func _update_shield_ring(delta: float) -> void:
	if not _shield_ring or not _shield_ring_mat:
		return
	if GameState.damage_reduction > 0.0:
		_shield_ring.visible = true
		_shield_pulse_t += delta * 3.0
		var pulse := (sin(_shield_pulse_t) + 1.0) * 0.5
		var alpha := lerpf(0.1, 0.3, pulse) * minf(GameState.damage_reduction / 0.24, 1.0)
		_shield_ring_mat.albedo_color.a = alpha
		_shield_ring_mat.emission_energy_multiplier = lerpf(1.5, 3.5, pulse)
		# Scale ring slightly with stacks
		var ring_scale := 1.0 + GameState.damage_reduction * 0.5
		_shield_ring.scale = Vector3(ring_scale, 1.0, ring_scale)
	else:
		_shield_ring.visible = false

func _update_procedural_anim(delta: float) -> void:
	var model: Node3D = get_node_or_null("Model") as Node3D
	var mesh: Node3D = get_node_or_null("Mesh") as Node3D
	var target: Node3D = model if model else mesh
	if not target:
		return
	# Compute velocity from position change
	_anim_velocity = (global_position - _anim_prev_pos) / maxf(delta, 0.001)
	_anim_prev_pos = global_position
	var move_speed: float = Vector2(_anim_velocity.x, _anim_velocity.z).length()
	# Vertical bobbing — faster when moving
	var bob_rate: float = 6.0 if move_speed < 1.0 else 10.0 + move_speed * 0.3
	var bob_amp: float = 0.03 if move_speed < 1.0 else 0.06
	_anim_bob_t += delta * bob_rate
	var bob_y: float = sin(_anim_bob_t) * bob_amp
	# Tilt into movement direction (lean forward)
	var target_tilt_x: float = clampf(_anim_velocity.z * -0.015, -0.2, 0.2)
	var target_tilt_z: float = clampf(_anim_velocity.x * 0.015, -0.2, 0.2)
	_anim_tilt_x = lerpf(_anim_tilt_x, target_tilt_x, 8.0 * delta)
	_anim_tilt_z = lerpf(_anim_tilt_z, target_tilt_z, 8.0 * delta)
	# Squash & stretch based on speed changes
	var target_squash: float = 1.0
	if is_dashing:
		target_squash = 0.8  # Flatten during dash
	elif move_speed > 8.0:
		target_squash = 0.92
	# Clamp the lerp weight so a large-delta frame hitch can't overshoot, and clamp
	# the result so the divisions below can never produce an inf/NaN scale (a
	# non-finite Transform3D crashes the renderer with no GDScript error).
	_anim_squash = lerpf(_anim_squash, target_squash, clampf(10.0 * delta, 0.0, 1.0))
	_anim_squash = clampf(_anim_squash, 0.6, 1.4)
	# Apply to model — offset from base position
	if model:
		model.position.y = bob_y
		# Keep rotation.y from the facing logic, add tilt
		var base_rot_y: float = model.rotation.y
		model.rotation = Vector3(_anim_tilt_x, base_rot_y, _anim_tilt_z)
		model.scale = Vector3(1.0 / _anim_squash, _anim_squash, 1.0 / _anim_squash) * 0.6
	elif mesh:
		mesh.position.y = 0.65 + bob_y
		mesh.rotation = Vector3(_anim_tilt_x, 0.0, _anim_tilt_z)

func _update_gravity_ring() -> void:
	if not _gravity_ring or not _gravity_ring_mat:
		return
	if GameState.gravity_well_strength > 0.0:
		_gravity_ring.visible = true
		# Gentle pulse animation
		var pulse := (sin(GameState.time_survived * 2.0) + 1.0) * 0.5
		var alpha: float = lerpf(0.08, 0.18, pulse) * minf(GameState.gravity_well_strength / 0.7, 1.0)
		_gravity_ring_mat.albedo_color.a = alpha
		_gravity_ring_mat.emission_energy_multiplier = lerpf(1.0, 2.5, pulse)
	else:
		_gravity_ring.visible = false

func _update_overclock_visual(delta: float) -> void:
	if not GameState.overclock_active:
		_overclock_pulse_t = 0.0
		return
	_overclock_pulse_t += delta * 6.0
	var pulse := (sin(_overclock_pulse_t) + 1.0) * 0.5
	var glow := get_node_or_null("PlayerGlow") as OmniLight3D
	if glow:
		glow.light_color = Color(0.0, 0.6, 0.9).lerp(Color(1.0, 0.2, 0.0), pulse * 0.6)
		glow.light_energy = lerpf(1.0, 2.5, pulse)

func _update_heartbeat(delta: float) -> void:
	if GameState.game_over:
		return
	var hp_ratio: float = GameState.hp / maxf(GameState.max_hp, 1.0)
	if hp_ratio > 0.25:
		_heartbeat_timer = 0.0
		return
	# Faster heartbeat as HP drops lower
	var beat_interval: float = lerpf(0.6, 1.2, hp_ratio / 0.25)
	_heartbeat_timer -= delta
	if _heartbeat_timer <= 0.0:
		_heartbeat_timer = beat_interval
		Audio.sfx_low_hp_heartbeat()

func _update_dash_ring() -> void:
	if not _dash_ring or not _dash_ring_mat:
		return
	if GameState.dash_charges >= 1:
		# Ready — at least one dash is banked
		_dash_ring.visible = true
		_dash_ring.scale = Vector3(1.0, 1.0, 1.0)
		_dash_ring_mat.albedo_color = Color(0.4, 0.9, 1.0, 0.4)
		_dash_ring_mat.emission = Color(0.3, 0.85, 1.0)
		_dash_ring_mat.emission_energy_multiplier = 3.0
	else:
		# No charges left — show the next one recharging
		_dash_ring.visible = true
		var cd_ratio := dash_cd_timer / maxf(GameState.dash_cooldown, 0.01)
		var ring_scale := 1.0 - clampf(cd_ratio, 0.0, 1.0)
		_dash_ring.scale = Vector3(ring_scale, 1.0, ring_scale)
		_dash_ring_mat.albedo_color = Color(0.4, 0.5, 0.6, 0.25)
		_dash_ring_mat.emission = Color(0.3, 0.4, 0.5)
		_dash_ring_mat.emission_energy_multiplier = 1.5

func _dash_recharged() -> void:
	# A banked dash charge just refilled
	_dash_ready_pulse()
	Audio.sfx_dash_ready()

func _dash_ready_pulse() -> void:
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var VFX := preload("res://scripts/vfx.gd")
	VFX.spawn_shockwave(container, position, Color(0.3, 0.8, 0.95, 0.4), 1.8, 0.25, 0.05)

func _process(delta: float) -> void:
	if GameState.game_over or GameState.paused_for_upgrade or not GameState.game_started:
		return
	_move(delta)
	_dash(delta)
	_shoot(delta)
	_shoot_railgun(delta)
	_shoot_signal_arrow(delta)
	_update_orbitals(delta)
	_ultimate(delta)
	_check_contact_damage(delta)
	_update_weapon_glow()
	_update_dash_ring()
	_update_gravity_ring()
	_update_overclock_visual(delta)
	_update_heartbeat(delta)
	_update_regen_vfx(delta)
	_update_damage_flash(delta)
	_update_shield_ring(delta)
	_update_target_reticle(delta)
	_update_player_beacon(delta)
	_update_procedural_anim(delta)

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
	else:
		# When idle, face the nearest enemy (aim direction)
		if _model_loaded:
			var target := _find_nearest_enemy()
			if target:
				var aim_dir := (target.global_position - global_position)
				aim_dir.y = 0.0
				if aim_dir.length_squared() > 0.01:
					var model := get_node_or_null("Model")
					if model:
						var target_angle := atan2(aim_dir.x, aim_dir.z)
						model.rotation.y = lerp_angle(model.rotation.y, target_angle, 8.0 * delta)
	position += dir * GameState.speed * delta
	position.y = 0.0
	position.x = clampf(position.x, -48.0, 48.0)
	position.z = clampf(position.z, -48.0, 48.0)

func _dash(delta: float) -> void:
	# Brief i-frame grace right after a dash ends so the final frame of phasing
	# through a pack doesn't immediately eat a hit
	if _dash_grace_timer > 0.0:
		_dash_grace_timer -= delta
		if _dash_grace_timer <= 0.0:
			GameState.invincible = false
	# Recharge banked dash charges one at a time
	if GameState.dash_charges < GameState.dash_max_charges:
		dash_cd_timer = maxf(dash_cd_timer - delta, 0.0)
		if dash_cd_timer <= 0.0:
			var was_empty := GameState.dash_charges == 0
			GameState.dash_charges += 1
			# Only flash + chime on 0->1 so refilling extra charges isn't noisy
			if was_empty:
				_dash_recharged()
			if GameState.dash_charges < GameState.dash_max_charges:
				dash_cd_timer = GameState.dash_cooldown
	else:
		dash_cd_timer = 0.0
	if is_dashing:
		dash_timer -= delta
		_afterimage_timer -= delta
		if _afterimage_timer <= 0.0:
			_afterimage_timer = DASH_AFTERIMAGE_INTERVAL
			_spawn_afterimage()
		position += dash_dir * GameState.dash_speed * delta
		position.y = 0.0
		position.x = clampf(position.x, -48.0, 48.0)
		position.z = clampf(position.z, -48.0, 48.0)
		# Dash damage — hit enemies we pass through (scales with speed)
		var scaled_dash_dmg := DASH_DAMAGE * (GameState.speed / 6.5)
		var enemies := get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if e is Node3D and e.has_method("take_damage"):
				var eid := e.get_instance_id()
				if eid not in _dash_hit_enemies:
					if global_position.distance_to(e.global_position) < DASH_HIT_RADIUS:
						e.take_damage(scaled_dash_dmg, "dash")
						_dash_hit_enemies.append(eid)
		if dash_timer <= 0.0:
			is_dashing = false
			# Keep invincibility briefly past the dash for a forgiving escape window
			_dash_grace_timer = DASH_IFRAME_GRACE
		return
	if Input.is_action_just_pressed("dash") and GameState.dash_charges >= 1:
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
		_dash_grace_timer = 0.0
		GameState.dash_charges -= 1
		# Begin recharging the spent charge if a recharge isn't already running
		if dash_cd_timer <= 0.0:
			dash_cd_timer = GameState.dash_cooldown
		GameState.invincible = true
		GameState.total_dashes += 1
		_dash_hit_enemies.clear()
		Audio.sfx_dash()
		_spawn_dash_trail()
		# Launch shockwave at the dash origin for extra oomph
		var dash_container := get_parent().get_node_or_null("Projectiles")
		if dash_container:
			var VFX := preload("res://scripts/vfx.gd")
			VFX.spawn_shockwave(dash_container, position, Color(0.3, 0.8, 1.0, 0.4), 2.0, 0.25, 0.05)

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
		mat.albedo_color = Color(0.2, 0.8, 1.0, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(0.1, 0.7, 1.0)
		mat.emission_energy_multiplier = 4.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p.material_override = mat
		p.position = position - dash_dir * (float(i) * 0.6)
		p.position.y = 0.4
		container.add_child(p)
		var tw := p.create_tween()
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.4)
		tw.tween_callback(p.queue_free)

func _spawn_afterimage() -> void:
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var ghost := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.3
	ghost.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.85, 1.0, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.7, 1.0)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost.material_override = mat
	ghost.position = position
	ghost.position.y = 0.65
	container.add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.tween_callback(ghost.queue_free)

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
	proj.set_meta("piercing", GameState.piercing_level)
	proj.set_meta("ricochet", GameState.ricochet_level)
	container.add_child(proj)

func _spawn_muzzle_flash(dir: Vector3) -> void:
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	flash.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.8, 1.0, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.75, 0.95)
	mat.emission_energy_multiplier = 6.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = mat
	flash.position = global_position + Vector3(0, 0.8, 0) + dir * 0.6
	flash.scale = Vector3(1.3, 1.3, 1.3)
	container.add_child(flash)
	# Quick bright pop that snaps inward as it fades — snappier shooting feel
	var tw := flash.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(flash, "scale", Vector3(0.4, 0.4, 0.4), 0.1).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
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
					e.take_damage(beam_damage, "railgun")
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

# === SIGNAL ARROW ===

func _shoot_signal_arrow(delta: float) -> void:
	if GameState.signal_arrow_level <= 0:
		return
	signal_arrow_timer -= delta
	if signal_arrow_timer > 0.0:
		return
	var target := _find_nearest_enemy()
	if not target:
		return
	signal_arrow_timer = SIGNAL_ARROW_COOLDOWN
	var dir: Vector3 = (target.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var lvl := GameState.signal_arrow_level
	# Yaka-style homing arrow: faster + more damage + more targets per level
	var arrow := Node3D.new()
	arrow.name = "SignalArrow"
	arrow.set_script(load("res://scripts/signal_arrow.gd"))
	arrow.position = global_position + Vector3(0, 0.8, 0) + dir * 0.5
	arrow.set_meta("direction", dir)
	arrow.set_meta("speed", 22.0 + lvl * 6.0)
	arrow.set_meta("damage", GameState.damage * (0.8 + 0.4 * lvl))
	arrow.set_meta("max_targets", 4 + lvl * 2)
	container.add_child(arrow)
	Audio.sfx_signal_arrow()
	_spawn_muzzle_flash(dir)

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
						e.take_damage(ORBITAL_DAMAGE * (1.0 + GameState.orbital_level * 0.3), "orbital")
						_orbital_hit_timers[eid] = ORBITAL_HIT_CD
						Audio.sfx_orbital_hit()
						_spawn_orbital_hit_spark(orb_pos)
					break

func _spawn_orbital_hit_spark(hit_pos: Vector3) -> void:
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var VFX := preload("res://scripts/vfx.gd")
	VFX.spawn_spark_burst(container, Vector3(hit_pos.x, 0.6, hit_pos.z), Color(0.1, 0.8, 0.5), 6, 2.5, 0.15)
	VFX.spawn_impact_flash(container, Vector3(hit_pos.x, 0.6, hit_pos.z), Color(0.1, 0.8, 0.5), 1.0, 0.08)

# === ULTIMATE ===

func _ultimate(delta: float) -> void:
	ult_cd_timer = maxf(ult_cd_timer - delta, 0.0)
	if ult_cd_timer > 0.01:
		_ult_was_on_cd = true
	elif _ult_was_on_cd:
		_ult_was_on_cd = false
		Audio.sfx_ult_ready()
	if Input.is_action_just_pressed("ultimate") and ult_cd_timer <= 0.0:
		# Scale cooldown down slightly as player levels up (min 6s at level 20+)
		var cd_scale := maxf(0.5, 1.0 - (GameState.level - 1) * 0.025)
		ult_cd_timer = ULTIMATE_COOLDOWN * cd_scale
		_do_ultimate()

func _do_ultimate() -> void:
	Audio.sfx_ultimate()
	GameState.request_shake(6.0)
	GameState.request_hit_stop(0.08)
	# Ultimate scales with player damage so it stays relevant in later waves
	var ult_dmg := ULTIMATE_DAMAGE + GameState.damage * 3.0
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is Node3D:
			var e: Node3D = enemy
			var dist := global_position.distance_to(e.global_position)
			if dist < ULTIMATE_RADIUS:
				if e.has_method("take_damage"):
					e.take_damage(ult_dmg)
				# Shove survivors outward so the ultimate doubles as a panic-button
				# that clears breathing room. Bosses resist most of the push.
				var push_dir: Vector3 = e.global_position - global_position
				push_dir.y = 0.0
				if push_dir.length_squared() < 0.01:
					push_dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
				push_dir = push_dir.normalized()
				var falloff := 1.0 - clampf(dist / ULTIMATE_RADIUS, 0.0, 1.0)
				var push_force: float = (2.0 if e.get("is_boss") else 5.5) * (0.4 + falloff)
				e.position += push_dir * push_force
				e.position.x = clampf(e.position.x, -47.0, 47.0)
				e.position.z = clampf(e.position.z, -47.0, 47.0)
	_spawn_ult_vfx()

func _spawn_ult_vfx() -> void:
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var VFX := preload("res://scripts/vfx.gd")
	var ult_color := Color(0.1, 0.8, 0.9)
	# Staggered shockwave rings expanding outward
	for ring_i in 3:
		var delay := ring_i * 0.06
		var alpha := 0.6 - ring_i * 0.15
		var ring_radius := ULTIMATE_RADIUS * (0.6 + ring_i * 0.25)
		var ring_duration := 0.35 + ring_i * 0.08
		var tree := get_tree()
		if tree and delay > 0.0:
			tree.create_timer(delay).timeout.connect(func():
				if container and is_instance_valid(container):
					VFX.spawn_shockwave(container, global_position, Color(ult_color.r, ult_color.g, ult_color.b, alpha), ring_radius, ring_duration, 0.2 + ring_i * 0.15)
			)
		else:
			VFX.spawn_shockwave(container, global_position, Color(ult_color.r, ult_color.g, ult_color.b, alpha), ring_radius, ring_duration, 0.2)
	# Big spark burst at the center
	VFX.spawn_spark_burst(container, global_position + Vector3(0, 0.5, 0), ult_color, 24, 6.0, 0.4)
	# Bright impact flash
	VFX.spawn_impact_flash(container, global_position + Vector3(0, 0.8, 0), ult_color, 3.0, 0.2)

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
		# Spark at the point of contact so melee hits read as real impacts
		var spark_container := get_parent().get_node_or_null("Projectiles")
		if spark_container:
			var VFX := preload("res://scripts/vfx.gd")
			VFX.spawn_spark_burst(spark_container, global_position + Vector3(0, 0.7, 0), Color(1.0, 0.35, 0.2), 8, 3.0, 0.2)

func _update_weapon_glow() -> void:
	var glow := get_node_or_null("PlayerGlow") as OmniLight3D
	if not glow:
		return
	# Subtle glow scaling — kept low to keep player visible
	var rate_ratio := GameState.fire_rate / 2.2
	glow.light_energy = clampf(1.0 + (rate_ratio - 1.0) * 0.3, 1.0, 2.5)
	glow.omni_range = clampf(6.0 + (rate_ratio - 1.0) * 1.0, 6.0, 9.0)
	if rate_ratio > 2.0:
		glow.light_color = Color(0.2, 0.7, 0.9)
	elif rate_ratio > 1.5:
		glow.light_color = Color(0.1, 0.6, 0.85)
	else:
		glow.light_color = Color(0.0, 0.6, 0.9)

func _update_regen_vfx(delta: float) -> void:
	if GameState.hp_regen <= 0.0 or GameState.hp >= GameState.max_hp:
		return
	_regen_vfx_timer -= delta
	if _regen_vfx_timer > 0.0:
		return
	_regen_vfx_timer = 1.0
	# Spawn subtle green heal particles around the player
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	for i in 3:
		var p := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.06
		p.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 1.0, 0.4, 0.7)
		mat.emission_enabled = true
		mat.emission = Color(0.1, 1.0, 0.3)
		mat.emission_energy_multiplier = 3.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p.material_override = mat
		var offset := Vector3(randf_range(-0.5, 0.5), 0.3, randf_range(-0.5, 0.5))
		p.position = global_position + offset
		container.add_child(p)
		var tw := p.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position:y", p.position.y + 1.5, 0.8).set_ease(Tween.EASE_OUT)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.8)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

var _prev_hp: float = -1.0

func _on_hp_changed(current: float, _maximum: float) -> void:
	if _prev_hp > 0.0 and current < _prev_hp:
		_damage_flash_timer = 0.12
		_set_model_flash(true)
	_prev_hp = current

func _update_damage_flash(delta: float) -> void:
	if _damage_flash_timer > 0.0:
		_damage_flash_timer -= delta
		if _damage_flash_timer <= 0.0:
			_set_model_flash(false)

func _set_model_flash(flash_on: bool) -> void:
	var model := get_node_or_null("Model")
	var mesh := get_node_or_null("Mesh")
	var target: Node = model if model else mesh
	if not target:
		return
	_apply_flash_recursive(target, flash_on)

func _on_upgrade_burst() -> void:
	# Golden "powered up" burst at the player on level-up — a tactile world-space
	# reward to complement the HUD flash and the cyan i-frame ring.
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var VFX := preload("res://scripts/vfx.gd")
	var gold := Color(1.0, 0.85, 0.2)
	VFX.spawn_shockwave(container, position, Color(gold.r, gold.g, gold.b, 0.55), 2.8, 0.45, 0.05)
	VFX.spawn_spark_burst(container, position + Vector3(0, 0.7, 0), gold, 20, 5.0, 0.45)
	VFX.spawn_impact_flash(container, position + Vector3(0, 0.9, 0), gold, 2.8, 0.28)

func _on_iframes_started() -> void:
	# Brief cyan shockwave to show i-frames after a hit
	var container := get_parent().get_node_or_null("Projectiles")
	if not container:
		return
	var VFX := preload("res://scripts/vfx.gd")
	VFX.spawn_shockwave(container, position, Color(0.2, 0.7, 0.9, 0.35), 1.2, 0.15, 0.05)

func _apply_flash_recursive(node: Node, flash_on: bool) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		var mat := mi.material_override as StandardMaterial3D
		if mat:
			_flash_material(mat, flash_on)
		else:
			for i in mi.get_surface_override_material_count():
				var smat := mi.get_surface_override_material(i) as StandardMaterial3D
				if smat:
					_flash_material(smat, flash_on)
	for child in node.get_children():
		_apply_flash_recursive(child, flash_on)

func _flash_material(mat: StandardMaterial3D, flash_on: bool) -> void:
	if flash_on:
		# Cache the original emission once so the model's neon look is restored
		# exactly after the flash, instead of being permanently recolored.
		if not mat.has_meta("_orig_emission"):
			mat.set_meta("_orig_emission", mat.emission)
			mat.set_meta("_orig_emission_energy", mat.emission_energy_multiplier)
		mat.emission = Color.WHITE
		mat.emission_energy_multiplier = 8.0
	elif mat.has_meta("_orig_emission"):
		mat.emission = mat.get_meta("_orig_emission")
		mat.emission_energy_multiplier = mat.get_meta("_orig_emission_energy")
