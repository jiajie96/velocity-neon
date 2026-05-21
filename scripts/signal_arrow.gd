extends Node3D
## Yondu-style "Signal Arrow" (Yaka arrow) — a homing arrow that darts from
## enemy to enemy, dealing damage on each hit. Higher level = faster + more
## damage + more targets (set via metas by the player on spawn).

const TURN_RATE := 9.0       # how sharply it curves toward its target
const HIT_RADIUS := 0.95
const LIFETIME := 4.5
const SEEK_RANGE := 32.0
const TRAIL_INTERVAL := 0.03

var speed: float = 24.0
var damage: float = 12.0
var max_targets: int = 6
var _vel: Vector3 = Vector3.FORWARD
var _target: Node3D = null
var _hit_ids: Array[int] = []
var _hits_done: int = 0
var _alive: float = 0.0
var _trail_t: float = 0.0
var _done: bool = false
var _color := Color(0.95, 0.18, 0.12)

func _ready() -> void:
	speed = get_meta("speed", 24.0)
	damage = get_meta("damage", 12.0)
	max_targets = get_meta("max_targets", 6)
	var dir: Vector3 = get_meta("direction", Vector3.FORWARD)
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		dir = Vector3.FORWARD
	_vel = dir.normalized() * speed
	position.y = 0.8
	_build_visual()
	_acquire_target()

func _build_visual() -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	var bolt := CylinderMesh.new()
	bolt.top_radius = 0.03      # pointed tip (front, +Z)
	bolt.bottom_radius = 0.09   # fletching end (back)
	bolt.height = 0.75
	mesh_inst.mesh = bolt
	mesh_inst.rotation.x = PI / 2.0  # lay the arrow along local +Z (travel axis)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color
	mat.emission_enabled = true
	mat.emission = _color
	mat.emission_energy_multiplier = 6.0
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	var light := OmniLight3D.new()
	light.light_color = _color
	light.light_energy = 1.8
	light.omni_range = 3.0
	light.omni_attenuation = 2.0
	add_child(light)

func _process(delta: float) -> void:
	if _done:
		return
	_alive += delta
	if _alive > LIFETIME:
		_despawn()
		return

	# Re-acquire if the current target is gone or already consumed
	if not _target_valid(_target):
		_acquire_target()
		if _target == null:
			_despawn()
			return

	# Homing steer toward the target, keeping a constant speed
	var to_t := _target.global_position - global_position
	to_t.y = 0.0
	var desired := to_t.normalized() * speed
	_vel = _vel.lerp(desired, clampf(TURN_RATE * delta, 0.0, 1.0))
	if _vel.length() < 0.01:
		_vel = desired
	_vel = _vel.normalized() * speed
	position += _vel * delta
	position.y = 0.8
	rotation.y = atan2(_vel.x, _vel.z)

	# Trail
	_trail_t -= delta
	if _trail_t <= 0.0:
		_trail_t = TRAIL_INTERVAL
		_spawn_trail()

	# Hit check
	if global_position.distance_to(_target.global_position) < HIT_RADIUS:
		_hit(_target)
		return

	# Safety bounds
	if absf(position.x) > 52.0 or absf(position.z) > 52.0:
		_despawn()

func _target_valid(t: Node3D) -> bool:
	if t == null or not is_instance_valid(t):
		return false
	if t.is_queued_for_deletion():
		return false
	if t.get("_dead"):
		return false
	return true

func _acquire_target() -> void:
	var best: Node3D = null
	var best_d := SEEK_RANGE
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D) or not e.has_method("take_damage"):
			continue
		if e.get_instance_id() in _hit_ids:
			continue
		if e.get("_dead"):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	_target = best

func _hit(enemy: Node3D) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, "signal")
	_hit_ids.append(enemy.get_instance_id())
	_hits_done += 1
	Audio.sfx_signal_hit()
	GameState.request_hit_stop(0.02)
	_spawn_hit_vfx(enemy.global_position)
	if _hits_done >= max_targets:
		_despawn()
		return
	_acquire_target()
	if _target == null:
		_despawn()

func _spawn_hit_vfx(pos: Vector3) -> void:
	var container := get_parent()
	if not container:
		return
	var VFX := preload("res://scripts/vfx.gd")
	VFX.spawn_spark_burst(container, Vector3(pos.x, 0.7, pos.z), _color, 8, 3.0, 0.2)
	VFX.spawn_impact_flash(container, Vector3(pos.x, 0.7, pos.z), _color, 1.8, 0.1)

func _spawn_trail() -> void:
	var container := get_parent()
	if not container:
		return
	var p := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.07
	p.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(_color.r, _color.g, _color.b, 0.5)
	mat.emission_enabled = true
	mat.emission = _color
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = mat
	p.position = global_position
	container.add_child(p)
	var tw := p.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.18)
	tw.tween_callback(p.queue_free)

func _despawn() -> void:
	if _done:
		return
	_done = true
	var mesh := get_node_or_null("Mesh") as MeshInstance3D
	if mesh:
		var tw := create_tween()
		tw.tween_property(mesh, "scale", Vector3.ZERO, 0.12)
		tw.tween_callback(queue_free)
	else:
		queue_free()
