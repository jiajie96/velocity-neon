extends Node
## VFX factory — reusable particle and shader-based effects that replace flat mesh rings.
## Call via:  var VFX := preload("res://scripts/vfx.gd")  then  VFX.spawn_*(...)

# ── Shockwave Ring (shader-driven expanding ring) ──────────────────────
static func spawn_shockwave(container: Node, pos: Vector3, color: Color, radius: float = 3.0, duration: float = 0.3, height: float = 0.05) -> void:
	var shader = load("res://shaders/shockwave_ring.gdshader") as Shader
	if not shader:
		# Fallback to simple ring if shader not found
		_spawn_simple_ring(container, pos, color, radius, duration)
		return
	var mesh_inst := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.0, radius * 2.0)
	mesh_inst.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("ring_width", 0.12)
	mat.set_shader_parameter("edge_softness", 0.06)
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	mesh_inst.position.y = height
	container.add_child(mesh_inst)
	var tw := mesh_inst.create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("progress", v), 0.0, 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(mesh_inst.queue_free)

# ── Spark Burst (GPUParticles3D — small bright particles flying outward) ──
static func spawn_spark_burst(container: Node, pos: Vector3, color: Color, count: int = 12, speed: float = 4.0, lifetime: float = 0.3) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = count
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true
	# Process material
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 0.3, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = speed * 0.6
	pmat.initial_velocity_max = speed
	pmat.gravity = Vector3(0, -2.0, 0)
	pmat.damping_min = 3.0
	pmat.damping_max = 5.0
	pmat.scale_min = 0.6
	pmat.scale_max = 1.0
	pmat.color = color
	# Fade out over lifetime
	var color_curve := Gradient.new()
	color_curve.set_color(0, Color(color.r, color.g, color.b, 1.0))
	color_curve.add_point(0.5, Color(color.r, color.g, color.b, 0.6))
	color_curve.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = color_curve
	pmat.color_ramp = tex
	particles.process_material = pmat
	# Draw pass — tiny sphere
	var draw_mesh := SphereMesh.new()
	draw_mesh.radius = 0.04
	draw_mesh.height = 0.08
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = color
	draw_mat.emission_enabled = true
	draw_mat.emission = color
	draw_mat.emission_energy_multiplier = 2.5
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mesh.material = draw_mat
	particles.draw_pass_1 = draw_mesh
	particles.position = pos
	container.add_child(particles)
	# Auto-cleanup after particles finish
	var tree := container.get_tree()
	if tree:
		tree.create_timer(lifetime + 0.1).timeout.connect(particles.queue_free)

# ── Impact Flash (brief bright point light + tiny expanding sphere) ──
static func spawn_impact_flash(container: Node, pos: Vector3, color: Color, energy: float = 2.0, duration: float = 0.12) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 2.0
	light.omni_attenuation = 2.0
	light.position = pos
	container.add_child(light)
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, duration).set_ease(Tween.EASE_OUT)
	tw.tween_callback(light.queue_free)

# ── Particle Trail (for dashes, movement effects) ──
static func spawn_particle_trail(container: Node, pos: Vector3, direction: Vector3, color: Color, count: int = 16, spread_radius: float = 0.5) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = count
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = -direction
	pmat.spread = 25.0
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 3.0
	pmat.gravity = Vector3.ZERO
	pmat.damping_min = 4.0
	pmat.damping_max = 6.0
	pmat.scale_min = 0.5
	pmat.scale_max = 1.2
	pmat.color = color
	var color_curve := Gradient.new()
	color_curve.set_color(0, Color(color.r, color.g, color.b, 0.7))
	color_curve.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = color_curve
	pmat.color_ramp = tex
	particles.process_material = pmat
	var draw_mesh := SphereMesh.new()
	draw_mesh.radius = 0.03
	draw_mesh.height = 0.06
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = color
	draw_mat.emission_enabled = true
	draw_mat.emission = color
	draw_mat.emission_energy_multiplier = 2.0
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mesh.material = draw_mat
	particles.draw_pass_1 = draw_mesh
	particles.position = pos
	container.add_child(particles)
	var tree := container.get_tree()
	if tree:
		tree.create_timer(0.5).timeout.connect(particles.queue_free)

# ── Spawn Warning Pulse (concentric rings fading in, replaces flat cylinder) ──
static func spawn_warning_pulse(container: Node, pos: Vector3, color: Color, scale_factor: float = 1.0) -> void:
	# Two staggered shockwave rings for a radar-pulse look
	spawn_shockwave(container, pos, Color(color.r, color.g, color.b, 0.3), 1.2 * scale_factor, 0.35, 0.05)
	# Delayed second ring
	var tree := container.get_tree()
	if tree:
		tree.create_timer(0.08).timeout.connect(func():
			if container and is_instance_valid(container):
				spawn_shockwave(container, pos, Color(color.r, color.g, color.b, 0.15), 1.6 * scale_factor, 0.4, 0.05)
		)

# ── Fallback simple ring (if shader fails to load) ──
static func _spawn_simple_ring(container: Node, pos: Vector3, color: Color, radius: float, duration: float) -> void:
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.3
	cyl.height = 0.02
	ring.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.4)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	ring.position = pos
	ring.position.y = 0.05
	container.add_child(ring)
	var target_scale := radius / 0.3
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(target_scale, 1.0, target_scale), duration)
	tw.tween_property(mat, "albedo_color:a", 0.0, duration)
	tw.set_parallel(false)
	tw.tween_callback(ring.queue_free)
