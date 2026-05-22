extends Node3D

const COLLECT_DISTANCE := 0.8
const MAGNET_SPEED := 12.0
const BOB_SPEED := 3.0
const BOB_HEIGHT := 0.2
const LIFETIME := 20.0
const FADE_TIME := 3.0
const AUTO_MAGNET_DELAY := 6.0  # Orbs drift to the player after this long so XP isn't lost in chaos

var xp_value: float = 10.0
var _magnetized: bool = false
var _time: float = 0.0
var _collected: bool = false
var _burst_velocity: Vector3 = Vector3.ZERO
var _burst_timer: float = 0.0
var _shared_mat: StandardMaterial3D = null

func _ready() -> void:
	add_to_group("xp_orbs")
	xp_value = get_meta("xp_value", 10.0)
	_time = randf() * TAU
	_build_visual()
	GameState.xp_magnet_pulse.connect(_on_magnet_pulse)
	# Initial burst outward from spawn point for juicy kill feedback
	var angle := randf() * TAU
	var burst_speed := randf_range(4.0, 8.0)
	_burst_velocity = Vector3(cos(angle), 0, sin(angle)) * burst_speed
	_burst_timer = 0.25

func _on_magnet_pulse() -> void:
	_magnetized = true

const STAR_SCENE := preload("res://assets/models/pickups/star.glb")

func _build_visual() -> void:
	var holder := STAR_SCENE.instantiate() as Node3D
	holder.name = "Mesh"
	holder.position.y = 0.5
	holder.scale = Vector3.ONE * 0.55
	add_child(holder)

	var value_ratio := clampf((xp_value - 8.0) / 72.0, 0.0, 1.0)
	var base_color := Color(0.1, 0.55, 0.25).lerp(Color(0.7, 0.6, 0.15), value_ratio)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.emission_enabled = true
	mat.emission = base_color * 0.5
	mat.emission_energy_multiplier = 1.0 + value_ratio * 1.0
	_shared_mat = mat
	_tint_glb(holder, mat)

	if value_ratio > 0.5:
		var light := OmniLight3D.new()
		light.light_color = base_color
		light.light_energy = 0.2
		light.omni_range = 1.2
		light.omni_attenuation = 2.0
		light.position.y = 0.5
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

	# Flush batched XP text after a brief window
	if _batch_timer > 0.0:
		_batch_timer -= delta
		if _batch_timer <= 0.0:
			_flush_batch_label()

	# Despawn old orbs to prevent buildup in late waves
	if _time > LIFETIME + FADE_TIME:
		queue_free()
		return

	var mesh := get_node_or_null("Mesh") as Node3D
	if mesh:
		mesh.position.y = 0.5 + sin(_time * BOB_SPEED) * BOB_HEIGHT
		mesh.rotation.y += delta * 2.0
		if _shared_mat and _time <= LIFETIME:
			var pulse := (sin(_time * 4.0) + 1.0) * 0.5
			_shared_mat.emission_energy_multiplier = lerpf(0.8, 2.2, pulse)
		if _time > LIFETIME and _shared_mat:
			var fade_ratio := 1.0 - (_time - LIFETIME) / FADE_TIME
			_shared_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_shared_mat.albedo_color.a = fade_ratio

	# Apply initial burst outward (decays quickly)
	if _burst_timer > 0.0:
		_burst_timer -= delta
		position += _burst_velocity * delta
		_burst_velocity *= 0.85  # Rapid deceleration
		position.x = clampf(position.x, -48.0, 48.0)
		position.z = clampf(position.z, -48.0, 48.0)
		position.y = 0.0

	var player: Node3D = get_tree().get_first_node_in_group("player_node") as Node3D
	if not player:
		return

	var dist: float = global_position.distance_to(player.global_position)

	if dist < GameState.magnet_range:
		_magnetized = true
	# Auto-magnetize older orbs so earned XP isn't stranded across the arena
	if _time > AUTO_MAGNET_DELAY:
		_magnetized = true

	if _magnetized and _burst_timer <= 0.0:
		var dir := (player.global_position - global_position).normalized()
		dir.y = 0.0
		position += dir * MAGNET_SPEED * delta
		position.y = 0.0
		if _shared_mat:
			_shared_mat.emission_energy_multiplier = lerpf(_shared_mat.emission_energy_multiplier, 4.5, 8.0 * delta)

	if dist < COLLECT_DISTANCE:
		_collect()

static var _batch_xp: float = 0.0
static var _batch_timer: float = 0.0
static var _batch_label: Label = null

static func reset_batch() -> void:
	_batch_xp = 0.0
	_batch_timer = 0.0
	_batch_label = null

func _collect() -> void:
	_collected = true
	GameState.add_xp(xp_value)
	Audio.sfx_xp_pickup()
	_spawn_collect_burst()
	_batch_xp_text()

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
	var VFX := preload("res://scripts/vfx.gd")
	var collect_color := Color(0.15, 0.65, 0.3)
	# Shader shockwave ring instead of flat cylinder
	VFX.spawn_shockwave(container, global_position, Color(collect_color.r, collect_color.g, collect_color.b, 0.35), 1.0, 0.2, 0.3)
	# GPU particle sparks instead of manual mesh sparks
	VFX.spawn_spark_burst(container, global_position + Vector3(0, 0.4, 0), collect_color, 6, 2.0, 0.2)

func _batch_xp_text() -> void:
	# Combine rapid pickups into one big "+X XP" instead of many small labels
	_batch_xp += xp_value
	_batch_timer = 0.3
	if _batch_label and is_instance_valid(_batch_label):
		# Update existing batch label
		_batch_label.text = "+%d" % int(_batch_xp)
		# Reset its fade timer
		var cam := get_viewport().get_camera_3d()
		if cam:
			var screen_pos := cam.unproject_position(global_position + Vector3(0, 1.2, 0))
			_batch_label.position = screen_pos + Vector2(-15, 0)
		return
	# Spawn a new batch label
	var cam := get_viewport().get_camera_3d()
	if not cam:
		_batch_xp = 0.0
		return
	var screen_pos := cam.unproject_position(global_position + Vector3(0, 1.2, 0))
	var canvas := get_tree().get_first_node_in_group("hud_node") as Control
	if not canvas:
		_batch_xp = 0.0
		return
	var label := Label.new()
	label.text = "+%d" % int(_batch_xp)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.25, 0.8, 0.35, 0.7))
	label.position = screen_pos + Vector2(-15, 0)
	label.z_index = 90
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(label)
	_batch_label = label
	# The label gets cleaned up by the static timer flush below

static func _flush_batch_label() -> void:
	if _batch_label and is_instance_valid(_batch_label):
		var lbl := _batch_label
		_batch_label = null
		# Scale up for big pickups
		if _batch_xp > 30:
			lbl.add_theme_font_size_override("font_size", 16)
		if _batch_xp > 80:
			lbl.add_theme_font_size_override("font_size", 19)
		# Satisfying SFX on big batch collection
		if _batch_xp > 40:
			Audio.sfx_big_xp_batch()
		var tw := lbl.create_tween()
		tw.set_parallel(true)
		tw.tween_property(lbl, "position:y", lbl.position.y - 35.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
		tw.set_parallel(false)
		tw.tween_callback(lbl.queue_free)
	_batch_xp = 0.0

func _spawn_xp_text() -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	var screen_pos := cam.unproject_position(global_position + Vector3(0, 1.2, 0))
	var canvas := get_tree().get_first_node_in_group("hud_node") as Control
	if not canvas:
		return
	var label := Label.new()
	label.text = "+%d" % int(xp_value)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 0.9))
	label.position = screen_pos + Vector2(randf_range(-8, 8), 0)
	label.z_index = 90
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(label)
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 30.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(label.queue_free)
