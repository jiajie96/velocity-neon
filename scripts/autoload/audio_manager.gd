extends Node

const MAX_SFX := 12
const MUSIC_FADE_TIME := 1.5

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.volume_db = -6.0
	add_child(_music)
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
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.volume_db = vol_db
	_music.play()

func stop_music() -> void:
	_music.stop()

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
