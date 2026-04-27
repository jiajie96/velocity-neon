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

	var mesh := get_node_or_null("Mesh")
	if mesh:
		var tw := create_tween()
		tw.tween_property(mesh, "scale", Vector3.ZERO, 0.15)
		tw.tween_callback(queue_free)
	else:
		queue_free()
