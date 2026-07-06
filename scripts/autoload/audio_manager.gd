extends Node

const MAX_SFX := 16
const MUSIC_FADE_TIME := 1.5

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _fade_tween: Tween
var _xp_pickup_streak: int = 0
var _xp_pickup_decay: float = 0.0

func _process(delta: float) -> void:
	if _xp_pickup_decay > 0.0:
		_xp_pickup_decay -= delta
		if _xp_pickup_decay <= 0.0:
			_xp_pickup_streak = 0

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

var _muted: bool = false

# Toggle all game audio by muting the master bus. Returns the new muted state.
func toggle_mute() -> bool:
	_muted = not _muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), _muted)
	return _muted

func is_muted() -> bool:
	return _muted

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

# Single source of truth for which gameplay track plays at a given wave tier, so
# the wave-change rotation and the post-boss music resume can't drift apart.
# Returns [path, volume_db].
func gameplay_music_for_wave(wave: int) -> Array:
	if wave >= 25:
		return ["res://assets/audio/music/cavern_ambient.ogg", -4.0]
	elif wave >= 20:
		# Reuse lands here, in the rarely-reached late game — every track the player
		# actually spends time with in the early/mid game is now distinct.
		return ["res://assets/audio/music/synthwave_hostile_territory.ogg", -5.0]
	elif wave >= 15:
		return ["res://assets/audio/music/neon_runner.mp3", -5.0]
	elif wave >= 12:
		return ["res://assets/audio/music/synthwave_deadly_contracts.ogg", -5.0]
	elif wave >= 7:
		# Mid-game now gets its own track instead of repeating the early-wave one.
		return ["res://assets/audio/music/synthwave_hostile_territory.ogg", -5.0]
	else:
		return ["res://assets/audio/music/determined_pursuit.ogg", -6.0]

func play_gameplay_music_for_wave(wave: int) -> void:
	var track: Array = gameplay_music_for_wave(wave)
	play_music(track[0], track[1])

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

# Rate-limited SFX for high-frequency sounds (primary fire, per-hit impacts). Without
# this, a stacked fire-rate + multi-shot build fires dozens of shoot/hit sounds a
# second, which fills all 16 voices and starves the sounds that actually matter (crit
# ping, enemy death, streak chimes). Keyed calls collapse to at most one per interval.
var _sfx_throttle: Dictionary = {}

func play_sfx_throttled(key: String, path: String, vol_db: float = 0.0, pitch: float = 1.0, min_interval: float = 0.05) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var last: float = _sfx_throttle.get(key, -999.0)
	if now - last < min_interval:
		return
	_sfx_throttle[key] = now
	play_sfx(path, vol_db, pitch)

func sfx_shoot() -> void:
	# Throttled so an overclocked / high-fire-rate build doesn't machine-gun the pool.
	# Spool-up: the shot pitch climbs a touch as fire rate stacks, so a heavy Rapid Fire
	# build audibly sounds hotter/faster instead of the same blip at 2/sec and 8/sec.
	var rate_ratio: float = GameState.fire_rate / 2.2
	var spool: float = clampf((rate_ratio - 1.0) * 0.16, 0.0, 0.35)
	play_sfx_throttled("shoot", "res://assets/audio/sfx/shoot_generic.ogg", -8.0, randf_range(0.9, 1.05) + spool, 0.05)

func sfx_shoot_railgun() -> void:
	play_sfx("res://assets/audio/sfx/shoot_bone_marksman.ogg", -4.0, 0.7)

func sfx_shoot_scatter() -> void:
	play_sfx_throttled("shoot", "res://assets/audio/sfx/shoot_inferno_warlock.ogg", -6.0, randf_range(0.95, 1.05), 0.05)

func sfx_shoot_chain() -> void:
	play_sfx("res://assets/audio/sfx/shoot_soul_reaper.ogg", -5.0, randf_range(0.9, 1.1))

func sfx_signal_arrow() -> void:
	# Whistling Yaka-arrow launch — high, zippy two-layer tone
	play_sfx("res://assets/audio/sfx/shoot_soul_reaper.ogg", -5.0, 1.7)
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -10.0, 1.9)

func sfx_signal_hit() -> void:
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -12.0, randf_range(1.6, 2.0))

func sfx_enemy_death() -> void:
	var paths := ["res://assets/audio/sfx/enemy_death_01.ogg", "res://assets/audio/sfx/enemy_death_02.ogg"]
	play_sfx(paths[randi() % paths.size()], -4.0, randf_range(0.85, 1.15))

func sfx_player_hit() -> void:
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -2.0, randf_range(0.9, 1.0))

func sfx_wave_start(pitch: float = 1.0) -> void:
	# Pitch climbs gently with wave depth so deeper waves announce themselves with a
	# tenser, higher horn — an audible "this is getting serious" cue.
	play_sfx("res://assets/audio/sfx/wave_start.ogg", -3.0, pitch)

func sfx_level_up(pitch: float = 1.0) -> void:
	# Pitch climbs gently with level so deeper runs' level-ups sound more triumphant
	# (mirrors the wave-start horn treatment).
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -2.0, pitch)

func sfx_ultimate() -> void:
	# Two-layer blast — the pulse plus a down-pitched sub thud so the panic button
	# lands with real low-end weight instead of a single mid tone.
	play_sfx("res://assets/audio/sfx/lucifer_pulse.ogg", 0.0)
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -3.0, 0.4)

func sfx_dash() -> void:
	play_sfx("res://assets/audio/sfx/pact_accept.ogg", -6.0, 1.5)

func sfx_dash_hit() -> void:
	# Meaty thud when a Phase Dash carves through a pack — fires once per dash so it
	# punctuates the slice instead of machine-gunning across every enemy passed.
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -4.0, randf_range(0.7, 0.85))

func sfx_dash_ready() -> void:
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -10.0, 1.6)

func sfx_upgrade() -> void:
	play_sfx("res://assets/audio/sfx/pact_accept.ogg", -3.0)

func sfx_ui_click() -> void:
	play_sfx("res://assets/audio/sfx/ui_click.ogg", -4.0)

func sfx_ui_hover() -> void:
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -8.0, 1.2)

func sfx_boss_defeat() -> void:
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", 0.0, 0.8)

func sfx_boss_enrage() -> void:
	# A guttural enrage roar when the golem drops below 30% HP — a deep down-pitched
	# pulse + a hard sub thud + a snarling layer, distinct from the regular slam so
	# the phase change reads as "this just got worse."
	play_sfx("res://assets/audio/sfx/lucifer_pulse.ogg", 0.0, 0.45)
	play_sfx("res://assets/audio/sfx/enemy_death_02.ogg", -2.0, 0.5)
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -1.0, 0.35)

func sfx_boss_incoming() -> void:
	# Ominous low-end stinger announcing a boss wave — deep pulse, a sub thud,
	# and a slowed wave-horn so the entrance lands before the music swaps.
	play_sfx("res://assets/audio/sfx/lucifer_pulse.ogg", -1.0, 0.55)
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -3.0, 0.4)
	play_sfx("res://assets/audio/sfx/wave_start.ogg", -6.0, 0.7)

func sfx_dice_roll() -> void:
	play_sfx("res://assets/audio/sfx/dice_roll.ogg", -3.0)

func sfx_xp_pickup() -> void:
	# Musical pitch scaling — rapid pickups climb a pentatonic-ish scale
	_xp_pickup_streak = mini(_xp_pickup_streak + 1, 8)
	_xp_pickup_decay = 0.4
	var base_pitch := 1.3
	var pitch_step := 0.08
	var pitch := base_pitch + _xp_pickup_streak * pitch_step
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -12.0, pitch)

func sfx_hit_impact(weapon_type: String = "pulse") -> void:
	# Per-hit impacts are the biggest audio flood — 5 pellets x a fast fire rate can
	# fire 40+ hit sounds a second. Throttle per weapon type so the mix stays punchy
	# without every single bullet impact eating a voice (crits/deaths use their own,
	# un-throttled cues so the moments that matter still cut through).
	match weapon_type:
		"railgun":
			play_sfx_throttled("hit_railgun", "res://assets/audio/sfx/shoot_bone_marksman.ogg", -6.0, randf_range(1.2, 1.5), 0.05)
		"scatter":
			play_sfx_throttled("hit_scatter", "res://assets/audio/sfx/shoot_inferno_warlock.ogg", -10.0, randf_range(1.3, 1.6), 0.05)
		"chain":
			play_sfx_throttled("hit_chain", "res://assets/audio/sfx/shoot_soul_reaper.ogg", -8.0, randf_range(1.1, 1.4), 0.05)
		_:
			play_sfx_throttled("hit_pulse", "res://assets/audio/sfx/core_hit.ogg", -10.0, randf_range(1.1, 1.4), 0.05)

func sfx_golem_slam() -> void:
	play_sfx("res://assets/audio/sfx/core_hit.ogg", 0.0, 0.55)

func sfx_necro_summon() -> void:
	play_sfx("res://assets/audio/sfx/lucifer_pulse.ogg", -8.0, 1.8)

func sfx_golem_rock_throw() -> void:
	# Distinct whoosh-thud for rock throw — deeper than slam, with a throw feel
	play_sfx("res://assets/audio/sfx/shoot_bone_marksman.ogg", -4.0, 0.5)

func sfx_golem_charge() -> void:
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -2.0, 0.4)

func sfx_ult_ready() -> void:
	play_sfx("res://assets/audio/sfx/pact_accept.ogg", -10.0, 1.3)

func sfx_denied() -> void:
	# Soft low "nope" blip for inputs pressed while still on cooldown
	play_sfx("res://assets/audio/sfx/ui_click.ogg", -10.0, 0.6)

func sfx_mage_bolt() -> void:
	play_sfx("res://assets/audio/sfx/shoot_inferno_warlock.ogg", -10.0, randf_range(1.4, 1.6))

func sfx_necro_bolt() -> void:
	play_sfx("res://assets/audio/sfx/shoot_soul_reaper.ogg", -10.0, randf_range(1.3, 1.5))

func sfx_warrior_lunge() -> void:
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -6.0, randf_range(1.1, 1.3))

func sfx_exploder_warn(pitch: float = 1.0) -> void:
	play_sfx("res://assets/audio/sfx/ui_click.ogg", -14.0, pitch)

func sfx_exploder_boom() -> void:
	var paths := ["res://assets/audio/sfx/enemy_death_01.ogg", "res://assets/audio/sfx/enemy_death_02.ogg"]
	play_sfx(paths[randi() % paths.size()], 0.0, 0.5)

func sfx_kill_milestone() -> void:
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -1.0, 1.2)

func sfx_overkill() -> void:
	# Heavy, deep double-thud when a killing blow massively overshoots an enemy's HP —
	# a satisfying "obliterated" punctuation to match the bigger overkill death pop.
	# Rate-limited so a stacked build mowing a pack doesn't machine-gun the low end.
	play_sfx_throttled("overkill", "res://assets/audio/sfx/enemy_death_01.ogg", 0.0, 0.42, 0.12)
	play_sfx_throttled("overkill_sub", "res://assets/audio/sfx/core_hit.ogg", -2.0, 0.3, 0.12)

func sfx_thorns() -> void:
	# Sharp metallic "clang" when Thorns reflects a melee hit back into the attacker —
	# a crisp, bright ping so a tanky reflect build hears its counter-damage land.
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -6.0, randf_range(1.7, 2.0))
	play_sfx("res://assets/audio/sfx/ui_click.ogg", -12.0, 1.8)

func sfx_execute() -> void:
	# Heavy down-pitched "finisher" thud when Executioner lands the killing blow on a
	# low-HP enemy — a distinct, satisfying punctuation separate from the crit ping.
	play_sfx("res://assets/audio/sfx/enemy_death_02.ogg", -2.0, 0.55)
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -4.0, 0.6)

func sfx_shatter() -> void:
	# Brittle "crack" as a Shatter Point bolt bursts into fragments — a short, glassy
	# scatter so the split reads by ear, not just as extra sparks.
	play_sfx_throttled("shatter", "res://assets/audio/sfx/shoot_inferno_warlock.ogg", -8.0, randf_range(1.5, 1.8), 0.06)

func sfx_streak_lost() -> void:
	# Soft descending "combo lost" blip when a kill streak times out — a quiet down-note
	# so dropping a hot streak (and its damage bonus) registers without being punishing.
	play_sfx("res://assets/audio/sfx/ui_click.ogg", -12.0, 0.7)

func sfx_crit() -> void:
	# Bright, crisp two-layer ping so crits cut through the mix
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -7.0, 2.0)
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -11.0, 2.3)

func sfx_streak(pitch: float = 1.0) -> void:
	# Rising chime that climbs as a kill streak escalates
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -8.0, pitch)
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -14.0, pitch * 0.9)

func sfx_enemy_death_typed(enemy_type: String) -> void:
	# Different pitch per enemy type for audio variety
	var paths := ["res://assets/audio/sfx/enemy_death_01.ogg", "res://assets/audio/sfx/enemy_death_02.ogg"]
	var pitch := 1.0
	match enemy_type:
		"minion":
			pitch = randf_range(1.0, 1.2)
		"warrior":
			pitch = randf_range(0.7, 0.85)
		"mage":
			pitch = randf_range(1.1, 1.3)
		"rogue":
			pitch = randf_range(1.2, 1.4)
		"necromancer":
			pitch = randf_range(0.6, 0.75)
		"exploder":
			pitch = randf_range(0.9, 1.0)
		"teleporter":
			pitch = randf_range(1.3, 1.5)
		"healer":
			pitch = randf_range(1.05, 1.2)
		"golem":
			pitch = randf_range(0.4, 0.55)
	play_sfx(paths[randi() % paths.size()], -4.0, pitch)

func sfx_elite_death() -> void:
	# Weightier, brighter death flourish for a slain gold elite — a heavy thud layered
	# with a crisp chime so cracking a high-value target lands harder than a minion pop.
	play_sfx("res://assets/audio/sfx/enemy_death_02.ogg", -1.0, 0.6)
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -8.0, 1.5)
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -10.0, 1.9)

func sfx_orbital_hit() -> void:
	play_sfx("res://assets/audio/sfx/ui_click.ogg", -14.0, randf_range(1.8, 2.2))

func sfx_low_hp_heartbeat() -> void:
	play_sfx("res://assets/audio/sfx/core_hit.ogg", -10.0, 0.35)

func sfx_spawn_warn(pitch: float = 1.0) -> void:
	# Soft, low telegraph blip when a dangerous enemy type is spawning in off-screen —
	# pairs with the bigger warning ring so threats can be reacted to by ear too.
	play_sfx("res://assets/audio/sfx/ui_click.ogg", -18.0, pitch * 0.7)

func sfx_teleporter_blink() -> void:
	play_sfx("res://assets/audio/sfx/pact_accept.ogg", -12.0, randf_range(1.8, 2.2))

func sfx_player_death() -> void:
	play_sfx("res://assets/audio/sfx/lucifer_pulse.ogg", -1.0, 0.5)
	play_sfx("res://assets/audio/sfx/core_hit.ogg", 0.0, 0.3)

func play_defeat_music() -> void:
	play_music("res://assets/audio/music/defeat.ogg", -4.0)

func sfx_wave_heal() -> void:
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -12.0, 1.6)

func sfx_perfect_wave() -> void:
	# Bright ascending two-layer chime — a flawless wave deserves its own fanfare
	# instead of sharing the silent treatment with regular announcements.
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -5.0, 1.5)
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -8.0, 1.8)

func sfx_healer_pulse() -> void:
	# Soft restorative shimmer when a healer mends nearby enemies — audible cue
	# to hunt the healer down even when it's offscreen.
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -12.0, 1.85)
	play_sfx("res://assets/audio/sfx/shoot_soul_reaper.ogg", -16.0, 0.8)

func sfx_guardian_save() -> void:
	# Bright protective swell when Guardian Angel cheats death — a buff chime layered
	# over a low pulse so the save reads as a big, rescuing moment.
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -1.0, 1.1)
	play_sfx("res://assets/audio/sfx/lucifer_pulse.ogg", -4.0, 1.4)
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -8.0, 1.6)

func sfx_health_pickup() -> void:
	# Bright, satisfying chime when grabbing a dropped health orb
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -5.0, 1.4)
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -10.0, 1.5)

func sfx_big_xp_batch() -> void:
	# Satisfying chime when a big batch of XP orbs finishes collecting
	play_sfx("res://assets/audio/sfx/ui_select.ogg", -6.0, 1.0)
	play_sfx("res://assets/audio/sfx/hades_buff.ogg", -14.0, 2.0)

func play_victory_sting() -> void:
	play_sfx("res://assets/audio/music/victory.ogg", -2.0, 1.0)

# Ambient neon hum that shifts pitch with HP
var _hum_player: AudioStreamPlayer

func start_ambient_hum() -> void:
	if _hum_player:
		return
	var stream := _load("res://assets/audio/sfx/lucifer_pulse.ogg")
	if not stream:
		return
	_hum_player = AudioStreamPlayer.new()
	_hum_player.name = "AmbientHum"
	_hum_player.stream = stream
	_hum_player.volume_db = -22.0
	_hum_player.pitch_scale = 0.3
	_hum_player.autoplay = true
	add_child(_hum_player)
	# Loop by reconnecting finished signal
	_hum_player.finished.connect(func(): _hum_player.play())

func update_hum_pitch() -> void:
	if not _hum_player:
		return
	var hp_ratio: float = GameState.hp / maxf(GameState.max_hp, 1.0)
	# Low HP = higher pitch + louder for tension
	var target_pitch: float = lerpf(0.5, 0.25, hp_ratio)
	var target_vol: float = lerpf(-16.0, -24.0, hp_ratio)
	_hum_player.pitch_scale = lerpf(_hum_player.pitch_scale, target_pitch, 0.05)
	_hum_player.volume_db = lerpf(_hum_player.volume_db, target_vol, 0.05)

func stop_ambient_hum() -> void:
	if _hum_player:
		_hum_player.stop()
		_hum_player.queue_free()
		_hum_player = null
