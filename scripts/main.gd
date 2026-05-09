extends Node3D

var player: Node3D
var enemy_container: Node3D
var projectile_container: Node3D
var orb_container: Node3D

func _ready() -> void:
	GameState.reset()
	UpgradeSystem.reset_all()
	_build_environment()
	_build_ground()
	_build_arena_walls()
	_build_lighting()
	_build_camera()
	_build_player()
	_build_containers()
	_build_hud()
	_build_spawner()

	GameState.leveled_up.connect(_on_leveled_up)
	GameState.player_died.connect(_on_player_died)
	GameState.upgrade_selected.connect(_on_upgrade_selected)

	_wait_for_start()

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnv"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.01, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.15, 0.1, 0.25)
	env.ambient_light_energy = 0.4
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_strength = 1.1
	env.glow_bloom = 0.25
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_hdr_threshold = 0.7
	env.glow_hdr_scale = 2.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.1
	we.environment = env
	add_child(we)

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	ground.position.y = -0.01

	var shader := load("res://shaders/grid_ground.gdshader") as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("grid_color", Color(0.0, 0.7, 1.0, 0.25))
		mat.set_shader_parameter("accent_color", Color(1.0, 0.0, 0.7, 0.12))
		mat.set_shader_parameter("bg_color", Color(0.015, 0.008, 0.04, 1.0))
		mat.set_shader_parameter("grid_spacing", 2.0)
		ground.material_override = mat
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.04, 0.02, 0.08)
		ground.material_override = mat
	add_child(ground)

func _build_arena_walls() -> void:
	# Neon boundary walls at arena edges so players can see the play area
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(1.0, 0.0, 0.7, 0.15)
	wall_mat.emission_enabled = true
	wall_mat.emission = Color(1.0, 0.0, 0.6)
	wall_mat.emission_energy_multiplier = 2.0
	wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var positions := [
		{"pos": Vector3(0, 1.5, -48), "scale": Vector3(96, 3, 0.05)},
		{"pos": Vector3(0, 1.5, 48), "scale": Vector3(96, 3, 0.05)},
		{"pos": Vector3(-48, 1.5, 0), "scale": Vector3(0.05, 3, 96)},
		{"pos": Vector3(48, 1.5, 0), "scale": Vector3(0.05, 3, 96)},
	]
	for p in positions:
		var wall := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = p["scale"]
		wall.mesh = box
		wall.material_override = wall_mat.duplicate()
		wall.position = p["pos"]
		add_child(wall)

	# Corner glow pillars
	var corners := [
		Vector3(-48, 0, -48), Vector3(48, 0, -48),
		Vector3(-48, 0, 48), Vector3(48, 0, 48),
	]
	for c in corners:
		var pillar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.15
		cyl.bottom_radius = 0.15
		cyl.height = 4.0
		pillar.mesh = cyl
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color(0.0, 0.9, 1.0, 0.7)
		pmat.emission_enabled = true
		pmat.emission = Color(0.0, 0.8, 1.0)
		pmat.emission_energy_multiplier = 4.0
		pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pillar.material_override = pmat
		pillar.position = c + Vector3(0, 2, 0)
		add_child(pillar)
		# Corner light
		var light := OmniLight3D.new()
		light.light_color = Color(0.0, 0.8, 1.0)
		light.light_energy = 1.5
		light.omni_range = 5.0
		light.omni_attenuation = 1.5
		light.position = c + Vector3(0, 2, 0)
		add_child(light)

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "AmbientSun"
	sun.light_color = Color(0.4, 0.35, 0.6)
	sun.light_energy = 0.4
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.shadow_enabled = false
	add_child(sun)

func _build_camera() -> void:
	var rig := Node3D.new()
	rig.name = "CameraRig"
	rig.set_script(load("res://scripts/camera_rig.gd"))
	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.position = Vector3(0, 20, 14)
	cam.rotation_degrees = Vector3(-55, 0, 0)
	cam.fov = 50
	rig.add_child(cam)
	add_child(rig)

func _build_player() -> void:
	player = Node3D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/player.gd"))
	add_child(player)

func _build_containers() -> void:
	enemy_container = Node3D.new()
	enemy_container.name = "Enemies"
	add_child(enemy_container)
	projectile_container = Node3D.new()
	projectile_container.name = "Projectiles"
	add_child(projectile_container)
	orb_container = Node3D.new()
	orb_container.name = "XPOrbs"
	add_child(orb_container)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UILayer"
	canvas.layer = 10
	var hud := Control.new()
	hud.name = "HUD"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.set_script(load("res://scripts/hud.gd"))
	canvas.add_child(hud)
	add_child(canvas)

func _build_spawner() -> void:
	var spawner := Node.new()
	spawner.name = "EnemySpawner"
	spawner.set_script(load("res://scripts/enemy_spawner.gd"))
	add_child(spawner)

func _wait_for_start() -> void:
	while not GameState.game_started:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	GameState.next_wave()

func _process(delta: float) -> void:
	if GameState.game_over:
		return
	if GameState.hp_regen > 0.0 and GameState.hp < GameState.max_hp:
		GameState.heal(GameState.hp_regen * delta)
	if GameState.overclock_active:
		GameState.take_damage(2.0 * delta, true)

func _on_leveled_up(_level: int) -> void:
	get_tree().paused = true
	GameState.paused_for_upgrade = true

func _on_upgrade_selected() -> void:
	get_tree().paused = false
	GameState.paused_for_upgrade = false

func _on_player_died() -> void:
	pass

# Input handling moved to hud.gd (which has PROCESS_MODE_ALWAYS for pause support)
