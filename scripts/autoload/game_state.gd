extends Node

signal hp_changed(current: float, maximum: float)
signal xp_changed(current: float, needed: float)
signal leveled_up(level: int)
signal wave_changed(wave: int)
signal kills_changed(kills: int)
signal player_died
signal upgrade_selected
signal hit_stop_requested(duration: float)
signal enemy_killed_at(pos: Vector3)
signal boss_defeated
signal kill_streak(count: int)
signal xp_magnet_pulse
signal perfect_wave(bonus_xp: float)

# Player stats
var hp: float = 80.0
var max_hp: float = 80.0
var speed: float = 6.5
var fire_rate: float = 2.2
var damage: float = 7.0
var projectile_count: int = 1
var projectile_speed: float = 38.0
var magnet_range: float = 3.5
var hp_regen: float = 0.0
var dash_cooldown: float = 2.0
var dash_speed: float = 25.0
var invincible: bool = false

# Special upgrades
var has_shatter: bool = false
var gravity_well_strength: float = 0.0
var overclock_active: bool = false
var crit_chance: float = 0.10

# Weapon upgrades (level 0 = not unlocked)
var railgun_level: int = 0
var scatter_level: int = 0
var chain_level: int = 0
var orbital_level: int = 0
var piercing_level: int = 0

# Progression
var xp: float = 0.0
var level: int = 1
var xp_to_next: float = 80.0

# Session
var wave: int = 0
var kills: int = 0
var game_over: bool = false
var paused_for_upgrade: bool = false
var game_started: bool = false
var time_survived: float = 0.0
var total_damage_dealt: float = 0.0

# Kill streak tracking
var _streak_count: int = 0
var _streak_timer: float = 0.0
const STREAK_WINDOW := 2.0

# Screen shake
var shake_amount: float = 0.0
var shake_direction: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	if game_started and not game_over:
		time_survived += delta
		if _streak_timer > 0.0:
			_streak_timer -= delta
			if _streak_timer <= 0.0:
				_streak_count = 0

# Wave damage tracking (for no-damage bonus)
var _wave_damage_taken: bool = false

func take_damage(amount: float) -> void:
	if invincible or game_over:
		return
	hp = clampf(hp - amount, 0.0, max_hp)
	shake_amount = 2.0 * log(amount + 1.0) / log(10.0)
	_wave_damage_taken = true
	hp_changed.emit(hp, max_hp)
	if amount >= 5.0:
		Audio.sfx_player_hit()
	if hp <= 0.0:
		game_over = true
		player_died.emit()

func heal(amount: float) -> void:
	hp = clampf(hp + amount, 0.0, max_hp)
	hp_changed.emit(hp, max_hp)

func add_xp(amount: float) -> void:
	xp += amount
	xp_changed.emit(xp, xp_to_next)
	if xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = 60.0 + 30.0 * level + 5.0 * sqrt(level)
		Audio.sfx_level_up()
		xp_magnet_pulse.emit()
		leveled_up.emit(level)
		xp_changed.emit(xp, xp_to_next)

func next_wave() -> void:
	# Award bonus XP for surviving previous wave without taking damage
	if wave > 0 and not _wave_damage_taken:
		var bonus := 20.0 + wave * 5.0
		add_xp(bonus)
		perfect_wave.emit(bonus)
	_wave_damage_taken = false
	wave += 1
	Audio.sfx_wave_start()
	wave_changed.emit(wave)
	if wave % 5 == 0:
		# Use epic_boss for wave 10+ bosses, cyberpunk_battle for early bosses
		if wave >= 10:
			Audio.play_music("res://assets/audio/music/epic_boss.ogg", -4.0)
		else:
			Audio.play_music("res://assets/audio/music/cyberpunk_battle.ogg", -4.0)
	elif wave > 1:
		# Rotate gameplay music as waves progress for variety
		if wave >= 20:
			Audio.play_music("res://assets/audio/music/synthwave_hostile_territory.ogg", -5.0)
		elif wave >= 12:
			Audio.play_music("res://assets/audio/music/synthwave_deadly_contracts.ogg", -5.0)
		elif wave >= 7:
			Audio.play_music("res://assets/audio/music/determined_pursuit.ogg", -5.0)
		else:
			Audio.play_music("res://assets/audio/music/neon_runner.mp3", -6.0)

func add_kill() -> void:
	kills += 1
	kills_changed.emit(kills)
	_streak_count += 1
	_streak_timer = STREAK_WINDOW
	if _streak_count >= 2:
		kill_streak.emit(_streak_count)

func add_damage_dealt(amount: float) -> void:
	total_damage_dealt += amount

func request_shake(intensity: float, direction: Vector3 = Vector3.ZERO) -> void:
	# Gentle shake — scaled down from original values for subtlety
	var scaled := intensity * 0.4
	shake_amount = maxf(shake_amount, scaled)
	if direction.length_squared() > 0.01:
		shake_direction = direction.normalized()

func request_hit_stop(duration: float = 0.04) -> void:
	hit_stop_requested.emit(duration)

func reset() -> void:
	hp = 80.0
	max_hp = 80.0
	speed = 6.5
	fire_rate = 2.2
	damage = 7.0
	projectile_count = 1
	projectile_speed = 38.0
	magnet_range = 3.5
	hp_regen = 0.0
	dash_cooldown = 2.0
	dash_speed = 25.0
	invincible = false
	has_shatter = false
	gravity_well_strength = 0.0
	overclock_active = false
	crit_chance = 0.10
	railgun_level = 0
	scatter_level = 0
	chain_level = 0
	orbital_level = 0
	piercing_level = 0
	xp = 0.0
	level = 1
	xp_to_next = 80.0
	wave = 0
	kills = 0
	game_over = false
	paused_for_upgrade = false
	game_started = false
	time_survived = 0.0
	total_damage_dealt = 0.0
	_streak_count = 0
	_streak_timer = 0.0
	shake_amount = 0.0
	shake_direction = Vector3.ZERO
	_wave_damage_taken = false
