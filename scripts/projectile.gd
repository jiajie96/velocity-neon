extends Node3D

const DEFAULT_LIFETIME := 2.5
const HIT_RADIUS := 0.5

var direction: Vector3 = Vector3.FORWARD
var speed: float = 22.0
var damage: float = 10.0
var shatter: bool = false
var weapon_type: String = "pulse"
var chain_level: int = 0
var lifetime: float = DEFAULT_LIFETIME
var _alive: float = 0.0
var _hit: bool = false

var _colors := {
	"pulse": Color(0.3, 0.9, 1.0),
	"scatter": Color(1.0, 0.5, 0.0),
	"chain": Color(0.4, 0.9, 1.0),
}

func _ready() -> void:
	direction = get_meta("direction", Vector3.FORWARD)
	speed = get_meta("speed", 22.0)
	damage = get_meta("damage", 10.0)
	shatter = get_meta("shatter", false)
	weapon_type = get_meta("weapon_type", "pulse")
	chain_level = get_meta("chain_level", 0)
	lifetime = get_meta("lifetime", DEFAULT_LIFETIME)
	_build_visual()
	_build_hitbox()

func _build_visual() -> void:
	var color: Color = _colors.get(weapon_type, Color(1.0, 0.95, 0.3))
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
	mat.emission_energy_multiplier = 8.0 if weapon_type == "pulse" else 5.0
	mesh_inst.material_override = mat
	add_child(mesh_inst)

	if weapon_type != "scatter":
		var light := OmniLight3D.new()
		light.light_color = color
		light.light_energy = 1.2 if weapon_type == "pulse" else 1.5
		light.omni_range = 2.5
		light.omni_attenuation = 2.0
		add_child(light)

	_spawn_trail_timer(color)

func _spawn_trail_timer(color: Color) -> void:
	if weapon_type == "scatter":
		return
	var interval := 0.04
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
	if weapon_type == "pulse":
		# Thin streak segment for laser trail
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.015
		cyl.bottom_radius = 0.02
		cyl.height = 0.4
		p.mesh = cyl
		p.rotation.x = PI / 2.0
		p.rotation.y = atan2(direction.x, direction.z)
	else:
		var sphere := SphereMesh.new()
		sphere.radius = 0.06
		p.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.5)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0 if weapon_type == "pulse" else 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = mat
	p.position = global_position
	p.position.y = position.y
	var container := get_parent()
	if container:
		container.add_child(p)
		var tw := p.create_tween()
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.1)
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

func _on_hit(area: Area3D) -> void:
	if _hit:
		return
	_hit = true
	var enemy := area.get_parent()
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		if chain_level > 0 and weapon_type == "pulse":
			_do_chain(enemy, chain_level)
		GameState.request_hit_stop(0.025)

	if shatter:
		_spawn_shatter_fragments()

	_hit_vfx()
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
	mat.albedo_color = Color(0.4, 0.9, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.9, 1.0)
	mat.emission_energy_multiplier = 6.0
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
		mat.albedo_color = Color(1.0, 0.6, 0.0, 0.9)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.5, 0.0)
		mat.emission_energy_multiplier = 3.0
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

func _hit_vfx() -> void:
	var container := get_parent()
	if not container:
		return
	var color: Color = _colors.get(weapon_type, Color(1.0, 1.0, 0.5))
	# Impact ring
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 0.02
	ring.mesh = cyl
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	ring_mat.emission_enabled = true
	ring_mat.emission = color
	ring_mat.emission_energy_multiplier = 6.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	ring.position = global_position
	ring.position.y = 0.5
	container.add_child(ring)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(3.0, 1.0, 3.0), 0.15)
	tw.tween_property(ring_mat, "albedo_color:a", 0.0, 0.15)
	tw.set_parallel(false)
	tw.tween_callback(ring.queue_free)

	# Spark burst
	for i in 4:
		var spark := MeshInstance3D.new()
		var ss := SphereMesh.new()
		ss.radius = 0.05
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
		var angle := TAU / 4.0 * i + randf() * 0.5
		var spark_dir := Vector3(cos(angle), randf_range(0.2, 0.8), sin(angle)) * 1.5
		var stw := spark.create_tween()
		stw.set_parallel(true)
		stw.tween_property(spark, "position", spark.position + spark_dir, 0.2)
		stw.tween_property(smat, "albedo_color:a", 0.0, 0.2)
		stw.set_parallel(false)
		stw.tween_callback(spark.queue_free)
