extends Node3D

const DEFAULT_LIFETIME := 2.5
const HIT_RADIUS := 0.5

var direction: Vector3 = Vector3.FORWARD
var speed: float = 22.0
var damage: float = 10.0
var shatter: bool = false
var weapon_type: String = "pulse"
var chain_level: int = 0
var piercing: int = 0
var ricochet: int = 0
var lifetime: float = DEFAULT_LIFETIME
var _alive: float = 0.0
var _hit: bool = false
var _pierce_count: int = 0
var _pierced_enemies: Array[int] = []
var _bounce_count: int = 0

var _colors := {
	"pulse": Color(0.2, 0.7, 0.9),
	"scatter": Color(0.9, 0.45, 0.1),
	"chain": Color(0.3, 0.7, 0.9),
}

func _ready() -> void:
	direction = get_meta("direction", Vector3.FORWARD)
	speed = get_meta("speed", 22.0)
	damage = get_meta("damage", 10.0)
	shatter = get_meta("shatter", false)
	weapon_type = get_meta("weapon_type", "pulse")
	chain_level = get_meta("chain_level", 0)
	piercing = get_meta("piercing", 0)
	ricochet = get_meta("ricochet", 0)
	lifetime = get_meta("lifetime", DEFAULT_LIFETIME)
	_build_visual()
	_build_hitbox()

func _build_visual() -> void:
	var color: Color = _colors.get(weapon_type, Color(1.0, 0.95, 0.3))
	# Tint pulse bolts by the active build so upgrades read at a glance:
	# Piercing -> bright white-cyan, Ricochet -> lime-green, both -> blended.
	if weapon_type == "pulse":
		if piercing > 0 and ricochet > 0:
			color = Color(0.7, 1.0, 0.7)
		elif piercing > 0:
			color = Color(0.75, 0.95, 1.0)
		elif ricochet > 0:
			color = Color(0.7, 1.0, 0.35)
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"

	if weapon_type == "scatter":
		var sphere := SphereMesh.new()
		sphere.radius = 0.1
		sphere.height = 0.2
		mesh_inst.mesh = sphere
	elif weapon_type == "pulse":
		# Thin laser bolt — elongated cylinder pointing in travel direction
		var bolt := CylinderMesh.new()
		bolt.top_radius = 0.03
		bolt.bottom_radius = 0.03
		bolt.height = 0.8
		mesh_inst.mesh = bolt
		# Rotate cylinder to lie along travel direction
		mesh_inst.rotation.x = PI / 2.0
		mesh_inst.rotation.y = atan2(direction.x, direction.z)
	else:
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.4
		mesh_inst.mesh = sphere
		mesh_inst.scale = Vector3(1.0, 1.0, 2.0)
		mesh_inst.rotation.y = atan2(direction.x, direction.z)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0 if weapon_type == "pulse" else 3.0
	mesh_inst.material_override = mat
	add_child(mesh_inst)

	if weapon_type != "scatter":
		var light := OmniLight3D.new()
		light.light_color = color
		# Faster projectiles glow brighter for visual feedback on Velocity Rounds
		var spd_glow := clampf(speed / 38.0, 1.0, 2.0)
		light.light_energy = (0.6 if weapon_type == "pulse" else 0.8) * spd_glow
		light.omni_range = 1.8 + (spd_glow - 1.0) * 0.5
		light.omni_attenuation = 2.0
		add_child(light)

	_spawn_trail_timer(color)

func _spawn_trail_timer(color: Color) -> void:
	if weapon_type == "scatter":
		return
	# Faster projectiles leave denser trails for a more impactful feel
	var interval := maxf(0.02, 0.04 - (speed - 38.0) * 0.001)
	var timer := Timer.new()
	timer.wait_time = interval
	timer.autostart = true
	timer.timeout.connect(func():
		if is_inside_tree():
			_spawn_trail_particle(color)
	)
	add_child(timer)

func _spawn_trail_particle(color: Color) -> void:
	var p := MeshInstance3D.new()
	# Scale trail thickness with projectile speed — Velocity Rounds feel more powerful
	var speed_factor := clampf(speed / 38.0, 1.0, 2.5)
	if weapon_type == "pulse":
		# Thin streak segment for laser trail
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.015 * speed_factor
		cyl.bottom_radius = 0.02 * speed_factor
		cyl.height = 0.4 * speed_factor
		p.mesh = cyl
		p.rotation.x = PI / 2.0
		p.rotation.y = atan2(direction.x, direction.z)
	else:
		var sphere := SphereMesh.new()
		sphere.radius = 0.06 * speed_factor
		p.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.5)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = (2.5 if weapon_type == "pulse" else 2.0) * speed_factor
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = mat
	p.position = global_position
	p.position.y = position.y
	var container := get_parent()
	if container:
		container.add_child(p)
		# Faster projectiles have longer-lasting trails
		var trail_duration := clampf(0.08 + (speed - 38.0) * 0.003, 0.08, 0.2)
		var tw := p.create_tween()
		tw.tween_property(mat, "albedo_color:a", 0.0, trail_duration)
		tw.tween_callback(p.queue_free)

func _build_hitbox() -> void:
	var area := Area3D.new()
	area.name = "HitArea"
	area.collision_layer = 4
	area.collision_mask = 2
	area.monitoring = true
	area.monitorable = false
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = HIT_RADIUS
	col.shape = shape
	area.add_child(col)
	area.area_entered.connect(_on_hit)
	add_child(area)

func _process(delta: float) -> void:
	_alive += delta
	if _alive > lifetime:
		queue_free()
		return
	position += direction * speed * delta
	position.y = lerpf(position.y, 0.8, 5.0 * delta)
	# Bounce/despawn against the *active* arena edge — this shrinks during boss
	# fights, so ricochet now works off the boss walls instead of sailing through
	# them to the full-map bound.
	var bound: float = GameState.arena_radius
	# Despawn projectiles that leave arena bounds (no ricochet left)
	if ricochet <= 0 or _bounce_count >= ricochet:
		if absf(position.x) > bound + 2.0 or absf(position.z) > bound + 2.0:
			queue_free()
			return
	# Ricochet — bounce off arena walls
	if ricochet > 0 and _bounce_count < ricochet:
		var bounced := false
		if position.x < -bound:
			position.x = -bound
			direction.x = absf(direction.x)
			bounced = true
		elif position.x > bound:
			position.x = bound
			direction.x = -absf(direction.x)
			bounced = true
		if position.z < -bound:
			position.z = -bound
			direction.z = absf(direction.z)
			bounced = true
		elif position.z > bound:
			position.z = bound
			direction.z = -absf(direction.z)
			bounced = true
		if bounced:
			_bounce_count += 1
			_pierced_enemies.clear()  # Can hit same enemies again after bouncing

func _on_hit(area: Area3D) -> void:
	var enemy := area.get_parent()
	if not enemy or not enemy.has_method("take_damage"):
		return
	# Skip enemies we already pierced through
	var eid := enemy.get_instance_id()
	if eid in _pierced_enemies:
		return
	_pierced_enemies.append(eid)

	# Check if we can pierce further
	var can_pierce := piercing > 0 and _pierce_count < piercing
	if not can_pierce:
		if _hit:
			return
		_hit = true

	enemy.take_damage(damage, weapon_type)
	if chain_level > 0 and weapon_type in ["pulse", "scatter"]:
		_do_chain(enemy, chain_level)
	# Only freeze-frame on kills. Firing many bullets per second (high fire rate +
	# multi-shot) used to trigger a hit-stop on every single impact, which stacked
	# into near-constant slow-motion and made sustained fire feel choppy. Crits
	# still freeze via the enemy's own take_damage, so impactful moments still land.
	var killed: bool = is_instance_valid(enemy) and bool(enemy.get("_dead"))
	if killed:
		GameState.request_hit_stop(0.04)
	Audio.sfx_hit_impact(weapon_type)
	_hit_vfx(killed)

	if can_pierce:
		_pierce_count += 1
		# Reduce damage slightly per pierce
		damage *= 0.75
	else:
		if shatter:
			_spawn_shatter_fragments()
		queue_free()

func _do_chain(source_enemy: Node3D, bounces: int) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var chained: Array[Node3D] = [source_enemy]
	var current: Node3D = source_enemy
	var chain_dmg := damage * 0.6

	for _i in bounces:
		var nearest: Node3D = null
		var min_dist := 8.0
		for e in enemies:
			if e is Node3D and e not in chained and e.has_method("take_damage"):
				var d := current.global_position.distance_to(e.global_position)
				if d < min_dist:
					min_dist = d
					nearest = e
		if not nearest:
			break
		nearest.take_damage(chain_dmg)
		_spawn_chain_arc(current.global_position, nearest.global_position)
		chained.append(nearest)
		current = nearest
		chain_dmg *= 0.7

	if chained.size() > 1:
		Audio.sfx_shoot_chain()

func _spawn_chain_arc(from: Vector3, to: Vector3) -> void:
	var container := get_parent()
	if not container:
		return
	var mid := (from + to) * 0.5
	mid.y = 1.0
	var dist := from.distance_to(to)
	var arc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.04
	cyl.height = dist
	arc.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.7, 0.9, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.7, 0.9)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc.material_override = mat
	arc.position = mid
	var dir := (to - from).normalized()
	arc.rotation.x = PI / 2.0
	arc.rotation.y = atan2(dir.x, dir.z)
	container.add_child(arc)
	var tw := arc.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.15)
	tw.tween_callback(arc.queue_free)

func _spawn_shatter_fragments() -> void:
	var container := get_parent()
	if not container:
		return
	for i in 3:
		var frag := Node3D.new()
		frag.name = "Fragment"
		frag.position = global_position
		var mesh_inst := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.08
		mesh_inst.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.5, 0.1, 0.6)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.4, 0.1)
		mat.emission_energy_multiplier = 2.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_inst.material_override = mat
		frag.add_child(mesh_inst)
		var frag_area := Area3D.new()
		frag_area.collision_layer = 4
		frag_area.collision_mask = 2
		frag_area.monitoring = true
		frag_area.monitorable = false
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.3
		col.shape = shape
		frag_area.add_child(col)
		frag.add_child(frag_area)
		var angle := TAU / 3.0 * i + randf() * 0.5
		var frag_dir := Vector3(cos(angle), 0, sin(angle))
		var frag_damage := damage * 0.4
		container.add_child(frag)
		frag_area.area_entered.connect(func(a: Area3D):
			var e := a.get_parent()
			if e and e.has_method("take_damage"):
				e.take_damage(frag_damage)
		)
		var tw := frag.create_tween()
		tw.tween_property(frag, "position", frag.position + frag_dir * 3.0, 0.3)
		tw.tween_callback(frag.queue_free)

func _hit_vfx(killed: bool = false) -> void:
	var container := get_parent()
	if not container:
		return
	var color: Color = _colors.get(weapon_type, Color(1.0, 1.0, 0.5))
	var VFX := preload("res://scripts/vfx.gd")
	if killed:
		# Kills earn the full, juicy impact — shockwave ring + spark burst + flash.
		VFX.spawn_shockwave(container, global_position, Color(color.r, color.g, color.b, 0.5), 1.5, 0.18, 0.4)
		VFX.spawn_spark_burst(container, global_position + Vector3(0, 0.5, 0), color, 8, 3.0, 0.25)
		VFX.spawn_impact_flash(container, global_position + Vector3(0, 0.5, 0), color, 1.5, 0.1)
	else:
		# Chip hits get just the cheap point-light flash. Spawning a GPUParticles
		# node + shader plane on every single bullet impact was the heaviest
		# remaining per-frame allocation; sustained fire could fire it dozens of
		# times a second. The enemy's own white hit-flash still sells the hit.
		VFX.spawn_impact_flash(container, global_position + Vector3(0, 0.5, 0), color, 1.2, 0.08)
