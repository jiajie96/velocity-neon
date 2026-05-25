extends Node3D
## Health pickup — occasionally dropped by enemies. Magnetizes like XP orbs and
## restores HP when collected, with a green flash and chime.

const COLLECT_DISTANCE := 0.9
const MAGNET_SPEED := 10.0
const BOB_SPEED := 3.0
const BOB_HEIGHT := 0.32
const LIFETIME := 18.0
const FADE_TIME := 3.0

var heal_amount: float = 15.0
var _time: float = 0.0
var _collected: bool = false
var _magnetized: bool = false

func _ready() -> void:
	add_to_group("health_orbs")
	heal_amount = get_meta("heal_amount", 15.0)
	_time = randf() * TAU
	_build_visual()
	GameState.xp_magnet_pulse.connect(_on_magnet_pulse)

func _on_magnet_pulse() -> void:
	_magnetized = true

const HEART_SCENE := preload("res://assets/models/pickups/heart.glb")

func _build_visual() -> void:
	# Heart glb tinted neon green so it still reads as a health pickup
	var holder := HEART_SCENE.instantiate() as Node3D
	holder.name = "Mesh"
	holder.position.y = 0.6
	# Bigger + brighter — old size was easy to miss in the middle of a swarm.
	holder.scale = Vector3.ONE * 0.95
	add_child(holder)
	var green := Color(0.25, 1.0, 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = green
	mat.emission_enabled = true
	mat.emission = green
	mat.emission_energy_multiplier = 4.0
	_tint_glb(holder, mat)
	var light := OmniLight3D.new()
	light.light_color = green
	light.light_energy = 1.1
	light.omni_range = 3.0
	light.omni_attenuation = 2.0
	light.position.y = 0.6
	add_child(light)

func _tint_glb(root: Node, mat: StandardMaterial3D) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = mat
		_tint_glb(child, mat)

func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta

	if _time > LIFETIME + FADE_TIME:
		queue_free()
		return

	var mesh := get_node_or_null("Mesh") as Node3D
	if mesh:
		mesh.position.y = 0.55 + sin(_time * BOB_SPEED) * BOB_HEIGHT
		mesh.rotation.y += delta * 1.5
		if _time > LIFETIME:
			var fade_ratio := 1.0 - (_time - LIFETIME) / FADE_TIME
			_fade_glb(mesh, fade_ratio)

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

func _fade_glb(root: Node, alpha: float) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			var mat := (child as MeshInstance3D).material_override as StandardMaterial3D
			if mat:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color.a = alpha
		_fade_glb(child, alpha)

func _collect() -> void:
	_collected = true
	# Only heal if it actually helps — but still consume the orb for feedback
	GameState.heal(heal_amount)
	GameState.health_pickup.emit(heal_amount)
	Audio.sfx_health_pickup()
	_spawn_collect_vfx()
	_spawn_heal_text()
	var mesh := get_node_or_null("Mesh")
	if mesh:
		var tw := create_tween()
		tw.tween_property(mesh, "scale", Vector3.ZERO, 0.15)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func _spawn_collect_vfx() -> void:
	var container := get_parent()
	if not container:
		return
	var VFX := preload("res://scripts/vfx.gd")
	var heal_color := Color(0.2, 1.0, 0.45)
	VFX.spawn_shockwave(container, global_position, Color(heal_color.r, heal_color.g, heal_color.b, 0.4), 1.2, 0.25, 0.3)
	VFX.spawn_spark_burst(container, global_position + Vector3(0, 0.5, 0), heal_color, 8, 2.5, 0.25)

func _spawn_heal_text() -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	var screen_pos := cam.unproject_position(global_position + Vector3(0, 1.2, 0))
	var canvas := get_tree().get_first_node_in_group("hud_node") as Control
	if not canvas:
		return
	var label := Label.new()
	label.text = "+%d HP" % int(heal_amount)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45, 0.95))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.15, 0.08))
	label.add_theme_constant_override("outline_size", 2)
	label.position = screen_pos + Vector2(-16, 0)
	label.z_index = 95
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(label)
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 32.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(label.queue_free)
