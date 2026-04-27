extends Node3D

const FOLLOW_SPEED := 6.0
const SHAKE_DECAY := 6.0
const ZOOM_SPEED := 2.0
const ZOOM_MIN := 12.0
const ZOOM_MAX := 30.0
const HIT_STOP_SCALE := 0.04

var _target_zoom: float = 20.0
var _current_zoom: float = 20.0
var _shake_offset := Vector3.ZERO
var _punch_offset := Vector3.ZERO
var _initialized := false
var _hit_stop_frames: int = 0

func _ready() -> void:
	GameState.hit_stop_requested.connect(_on_hit_stop)

func _on_hit_stop(duration: float) -> void:
	var frames := maxi(int(duration * 60.0), 2)
	_hit_stop_frames = maxi(_hit_stop_frames, frames)
	Engine.time_scale = HIT_STOP_SCALE

func _process(delta: float) -> void:
	if _hit_stop_frames > 0:
		_hit_stop_frames -= 1
		if _hit_stop_frames <= 0:
			Engine.time_scale = 1.0

	var player: Node3D = get_tree().get_first_node_in_group("player_node") as Node3D
	if not player:
		return

	var target_pos: Vector3 = player.global_position
	target_pos.y = 0.0

	if not _initialized:
		global_position = target_pos
		_initialized = true
	else:
		var pos := global_position
		pos.x = lerpf(pos.x, target_pos.x, FOLLOW_SPEED * delta)
		pos.z = lerpf(pos.z, target_pos.z, FOLLOW_SPEED * delta)
		pos.y = 0.0
		global_position = pos

	# Directional shake with random component
	if GameState.shake_amount > 0.01:
		var dir_bias := GameState.shake_direction
		var random_component := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-0.3, 0.3),
			randf_range(-1.0, 1.0)
		)
		var combined := (random_component * 0.6 + dir_bias * 0.4).normalized()
		_shake_offset = combined * GameState.shake_amount * 0.5
		GameState.shake_amount *= exp(-SHAKE_DECAY * delta)
		if GameState.shake_amount < 0.01:
			GameState.shake_amount = 0.0
			GameState.shake_direction = Vector3.ZERO
	else:
		_shake_offset = _shake_offset.lerp(Vector3.ZERO, 12.0 * delta)

	# Punch decay (fast snap-back)
	_punch_offset = _punch_offset.lerp(Vector3.ZERO, 15.0 * delta)

	# Zoom
	_current_zoom = lerpf(_current_zoom, _target_zoom, ZOOM_SPEED * delta)

	var camera := get_node_or_null("Camera") as Camera3D
	if camera:
		var cam_offset := Vector3(0, _current_zoom, _current_zoom * 0.7)
		camera.position = cam_offset + _shake_offset + _punch_offset
		camera.rotation_degrees.x = -55.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom = maxf(_target_zoom - 1.5, ZOOM_MIN)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom = minf(_target_zoom + 1.5, ZOOM_MAX)
