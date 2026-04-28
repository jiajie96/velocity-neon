extends Node3D

const COLLECT_DISTANCE := 0.8
const MAGNET_SPEED := 12.0
const BOB_SPEED := 3.0
const BOB_HEIGHT := 0.2

var xp_value: float = 10.0
var _magnetized: bool = false
var _time: float = 0.0
var _collected: bool = false

func _ready() -> void:
	xp_value = get_meta("xp_value", 10.0)
	_time = randf() * TAU
	_build_visual()

func _build_visual() -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	var prism := PrismMesh.new()
	prism.size = Vector3(0.3, 0.4, 0.3)
	mesh_inst.mesh = prism

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 1.0, 0.2)
	mat.emission_energy_multiplier = 3.0
	mesh_inst.material_override = mat
	mesh_inst.position.y = 0.5
	add_child(mesh_inst)

	var light := OmniLight3D.new()
	light.light_color = Color(0.2, 1.0, 0.3)
	light.light_energy = 0.6
	light.omni_range = 2.0
	light.omni_attenuation = 2.0
	light.position.y = 0.5
	add_child(light)

func _process(delta: float) -> void:
	if _collected:
		return

	_time += delta

	var mesh := get_node_or_null("Mesh")
	if mesh:
		mesh.position.y = 0.5 + sin(_time * BOB_SPEED) * BOB_HEIGHT
		mesh.rotation.y += delta * 2.0

	var player: Node3D = get_tree().get_first_node_in_group("player_node") as Node3D
	if not player:
		return

	var dist: float = global_position.distance_to(player.global_position)

	if dist < GameState.magnet_range:
		_magnetized = true

	if _magnetized:
		var dir := (player.global_position - global_position).normalized()
		dir.y = 0.0
		position += dir * MAGNET_SPEED * delta
		position.y = 0.0

	if dist < COLLECT_DISTANCE:
		_collect()

func _collect() -> void:
	_collected = true
	GameState.add_xp(xp_value)
	_spawn_collect_burst()

	var mesh := get_node_or_null("Mesh")
	if mesh:
		var tw := create_tween()
		tw.tween_property(mesh, "scale", Vector3.ZERO, 0.15)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func _spawn_collect_burst() -> void:
	var container := get_parent()
	if not container:
		return
	# Ring flash
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.3
	cyl.height = 0.02
	ring.mesh = cyl
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.2, 1.0, 0.3, 0.7)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.1, 1.0, 0.2)
	ring_mat.emission_energy_multiplier = 5.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	ring.position = global_position
	ring.position.y = 0.4
	container.add_child(ring)
	var rtw := ring.create_tween()
	rtw.set_parallel(true)
	rtw.tween_property(ring, "scale", Vector3(3.0, 1.0, 3.0), 0.2)
	rtw.tween_property(ring_mat, "albedo_color:a", 0.0, 0.2)
	rtw.set_parallel(false)
	rtw.tween_callback(ring.queue_free)
	# Spark particles
	for i in 4:
		var spark := MeshInstance3D.new()
		var ss := SphereMesh.new()
		ss.radius = 0.04
		spark.mesh = ss
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.3, 1.0, 0.4, 0.9)
		smat.emission_enabled = true
		smat.emission = Color(0.2, 1.0, 0.3)
		smat.emission_energy_multiplier = 4.0
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spark.material_override = smat
		spark.position = global_position + Vector3(0, 0.4, 0)
		container.add_child(spark)
		var angle := TAU / 4.0 * float(i) + randf() * 0.5
		var spark_dir := Vector3(cos(angle), randf_range(0.3, 0.8), sin(angle)) * randf_range(0.5, 1.0)
		var stw := spark.create_tween()
		stw.set_parallel(true)
		stw.tween_property(spark, "position", spark.position + spark_dir, 0.2)
		stw.tween_property(smat, "albedo_color:a", 0.0, 0.2)
		stw.set_parallel(false)
		stw.tween_callback(spark.queue_free)
