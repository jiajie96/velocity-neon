extends Node

const MAX_SFX := 12
const MUSIC_FADE_TIME := 1.5

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _fade_tween: Tween

func _ready() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.name = "MusicA"
	_music_a.volume_db = -6.0
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.name = "MusicB"
	_music_b.volume_db = -80.0
	add_child(_music_b)
	_active_music = _music_a
	for i in MAX_SFX:
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		add_child(p)
		_sfx_pool.append(p)

func _load(path: String) -> AudioStream:
	if path in _cache:
		return _cache[path]
	if ResourceLoader.exists(path):
		var s: AudioStream = load(path)
		_cache[path] = s
		return s
	return null

func play_music(path: String, vol_db: float = -6.0) -> void:
	var stream := _load(path)
	if not stream:
		return
	if _active_music.stream == stream and _active_music.playing:
		return

	# Kill any running fade to avoid conflicts
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	var old := _active_music
	var incoming := _music_b if _active_music == _music_a else _music_a
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(incoming, "volume_db", vol_db, MUSIC_FADE_TIME)
	_fade_tween.tween_property(old, "volume_db", -80.0, MUSIC_FADE_TIME)
	_fade_tween.chain().tween_callback(func(): old.stop())

	_active_music = incoming

func stop_music() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_music_a.stop()
	_music_b.stop()

func play_sfx(path: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := _load(path)
	if not stream:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = vol_db
			p.pitch_scale = pitch
			p.play()
			return

func sfx_shoot() -> void:
	play_sfx("res://assets/audio/sfx/shoot_generic.ogg", -8.0, randf_range(0.9, 1.1))

func sfx_shoot_railgun() -> void:
	play_sfx("res://assets/audio/sfx/shoot_bone_marksman.ogg", -4.0, 0.7)

func sfx_shoot_scatter() -> void:
	play_sfx("res://assets/audio/sfx/shoot_inferno_warlock.ogg", -6.0, randf_range(0.95, 1.05))

func sfx_shoot_chain() -> void:
	play_sfx("res://assets/audio/sfx/shoot_soul_reaper.ogg", -5.0, randf_range(0.9, 1.1))

func sfx_enemy_death() -> void:
	var paths := ["res://assets/audio/sfx/enemy_death_01.ogg", "res://assets/audio/sfx/enemy_death_02.ogg"]
	play_sfx(paths[randi() % paths.size()], -4.0, randf_range(0.85, 1.15))

func sfx_player_hit() -> void:
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -2.0, randf_range(0.9, 1.0))

func sfx_wave_start() -> void:
	play_sfx("res://assets/audio/sfx/wave_start.ogg", -3.0)

func sfx_level_up() -> void:
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -2.0)

func sfx_ultimate() -> void:
	play_sfx("res://assets/audio/sfx/lucifer_pulse.ogg", 0.0)

func sfx_dash() -> void:
	play_sfx("res://assets/audio/sfx/pact_accept.ogg", -6.0, 1.5)

func sfx_upgrade() -> void:
	play_sfx("res://assets/audio/sfx/pact_accept.ogg", -3.0)

func sfx_ui_click() -> void:
	play_sfx("res://assets/audio/sfx/ui_click.ogg", -4.0)
