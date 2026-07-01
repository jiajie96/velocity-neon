extends Node3D
## Yondu-style "Signal Arrow" (Yaka arrow) — a homing arrow that darts from
## enemy to enemy, dealing damage on each hit. Higher level = faster + more
## damage + more targets (set via metas by the player on spawn).

const TURN_RATE := 9.0       # how sharply it curves toward its target
const HIT_RADIUS := 0.95
const LIFETIME := 4.5
const SEEK_RANGE := 42.0    # match the primary weapon's 40u auto-aim lock (was 32,
                            # which let an arrow fired at a 33-40u target find nothing
                            # and despawn instantly, silently wasting the cooldown)
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
var _color := Color(1.0, 0.82, 0.2)  # warm gold — Yondu's Yaka arrow, also keeps it visually distinct from enemy red mage bolts
var _shadow: MeshInstance3D = null

func _ready() -> void:
	speed = get_meta("speed", 24.0)
	damage = get_meta("damage", 12.0)
	max_targets = get_meta("max_targets", 6)
	var dir: Vector3 = get_meta("direction", Vector3.FORWARD)
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		dir = Vector3.FORWARD
	_vel = dir.normalized() * speed
	position.y = 0.65
	_build_visual()
	_acquire_target()

func _build_visual() -> void:
	# Composite procedural arrow — shaft + cone tip + two crossed fletchings.
	# Built under a single holder so we can spin/rotate everything together.
	var holder := Node3D.new()
	holder.name = "Mesh"
	holder.rotation.x = PI / 2.0  # lay arrow along local +Z (travel axis)
	add_child(holder)

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = _color
	body_mat.emission_enabled = true
	body_mat.emission = _color
	body_mat.emission_energy_multiplier = 6.0

	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.045
	shaft_mesh.bottom_radius = 0.045
	shaft_mesh.height = 0.9
	shaft.mesh = shaft_mesh
	shaft.material_override = body_mat
	holder.add_child(shaft)

	var tip := MeshInstance3D.new()
	var tip_mesh := CylinderMesh.new()
	tip_mesh.top_radius = 0.0
	tip_mesh.bottom_radius = 0.13
	tip_mesh.height = 0.32
	tip.mesh = tip_mesh
	tip.material_override = body_mat
	tip.position.y = 0.61  # forward along the cylinder axis (before rotation)
	holder.add_child(tip)

	# Halo sphere around the body so it reads as energized at distance
	var halo := MeshInstance3D.new()
	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = 0.16
	halo_mesh.height = 0.32
	halo.mesh = halo_mesh
	var halo_mat := StandardMaterial3D.new()
	halo_mat.albedo_color = Color(_color.r, _color.g, _color.b, 0.28)
	halo_mat.emission_enabled = true
	halo_mat.emission = _color
	halo_mat.emission_energy_multiplier = 4.0
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	halo.material_override = halo_mat
	holder.add_child(halo)

	var fletch_mat := StandardMaterial3D.new()
	fletch_mat.albedo_color = _color.darkened(0.1)
	fletch_mat.emission_enabled = true
	fletch_mat.emission = _color
	fletch_mat.emission_energy_multiplier = 4.5
	fletch_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Three fletchings (120° apart) — reads more arrow-like than the old 2-fin cross
	for i in 3:
		var f := MeshInstance3D.new()
		var fmesh := BoxMesh.new()
		fmesh.size = Vector3(0.34, 0.012, 0.22)
		f.mesh = fmesh
		f.material_override = fletch_mat
		f.position.y = -0.42  # at the back of the shaft
		f.rotation.y = (TAU / 3.0) * float(i)
		holder.add_child(f)

	var light := OmniLight3D.new()
	light.light_color = _color
	light.light_energy = 1.8
	light.omni_range = 3.0
	light.omni_attenuation = 2.0
	add_child(light)

	_build_ground_shadow()

func _build_ground_shadow() -> void:
	# Flat dark disc tracked under the arrow each frame. Replaces the harsh
	# blob the engine was rendering and grounds the projectile against the
	# neon floor so it reads as a flying object rather than a floating shape.
	_shadow = MeshInstance3D.new()
	_shadow.name = "Shadow"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.35
	disc.bottom_radius = 0.35
	disc.height = 0.005
	disc.radial_segments = 14
	_shadow.mesh = disc
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.0, 0.0, 0.0, 0.55)
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shadow.material_override = smat
	# Shadow is parented to the scene container so it stays world-aligned
	# even as the arrow rotates to face its target. Add deferred so we have a
	# parent at this point (signal_arrow is added to "Projectiles" by player.gd).
	call_deferred("_attach_shadow")

func _attach_shadow() -> void:
	if _shadow == null:
		return
	var container := get_parent()
	if container:
		container.add_child(_shadow)
		_shadow.global_position = Vector3(global_position.x, 0.04, global_position.z)

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
	position.y = 0.65
	rotation.y = atan2(_vel.x, _vel.z)
	if _shadow and is_instance_valid(_shadow):
		_shadow.global_position = Vector3(global_position.x, 0.04, global_position.z)

	# Trail
	_trail_t -= delta
	if _trail_t <= 0.0:
		_trail_t = TRAIL_INTERVAL
		_spawn_trail()

	# Hit check
	if global_position.distance_to(_target.global_position) < HIT_RADIUS:
		_hit(_target)
		return

	# Safety bounds — respect the active arena (shrinks during boss duels) so a stray
	# arrow that loses its target is cleaned up at the wall instead of flying far past it.
	var bound: float = GameState.arena_radius + 4.0
	if absf(position.x) > bound or absf(position.z) > bound:
		_despawn()

func _target_valid(t) -> bool:
	# NOTE: parameter is intentionally untyped. Godot 4's typed-parameter check
	# raises before the function body runs when `t` is a previously-freed
	# Object, which crashed _process every tick that a target died mid-flight.
	if t == null or not is_instance_valid(t):
		return false
	if not (t is Node3D):
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
	# Shadow lives under the container, not the arrow, so it must be freed
	# explicitly when the arrow expires.
	if _shadow and is_instance_valid(_shadow):
		_shadow.queue_free()
		_shadow = null
	var mesh := get_node_or_null("Mesh") as Node3D
	if mesh:
		var tw := create_tween()
		tw.tween_property(mesh, "scale", Vector3.ZERO, 0.12)
		tw.tween_callback(queue_free)
	else:
		queue_free()
