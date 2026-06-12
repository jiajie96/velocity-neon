extends Node

signal hp_changed(current: float, maximum: float)
signal xp_changed(current: float, needed: float)
signal leveled_up(level: int)
signal wave_changed(wave: int)
signal kills_changed(kills: int)
signal player_died
# These signals are an autoload event bus — they're emitted/connected from other
# scripts, which the per-class unused-signal check can't see, so silence it here.
@warning_ignore("unused_signal")
signal upgrade_selected
@warning_ignore("unused_signal")
signal hit_stop_requested(duration: float)
@warning_ignore("unused_signal")
signal boss_defeated
signal kill_streak(count: int)
signal xp_magnet_pulse
signal perfect_wave(bonus_xp: float)
@warning_ignore("unused_signal")
signal wave_cleared
signal kill_milestone(count: int)
signal vampire_heal
@warning_ignore("unused_signal")
signal crit_landed
@warning_ignore("unused_signal")
signal boss_bonus_xp(amount: float)
@warning_ignore("unused_signal")
signal wave_heal(amount: float)
@warning_ignore("unused_signal")
signal health_pickup(amount: float)
@warning_ignore("unused_signal")
signal golem_enraged
signal death_by_overclock
signal damage_iframes_started
# Fired when Guardian Angel saves the player from a fatal hit, so the player node
# can play a protective burst.
@warning_ignore("unused_signal")
signal guardian_save

# Player stats
var hp: float = 80.0
var max_hp: float = 80.0
var speed: float = 6.5
var fire_rate: float = 2.2
var damage: float = 7.0
var projectile_count: int = 1
var projectile_speed: float = 38.0
var magnet_range: float = 4.2
var hp_regen: float = 0.0
var dash_cooldown: float = 1.5
var dash_speed: float = 25.0
var dash_max_charges: int = 1   # how many dashes can be banked
var dash_charges: int = 1       # currently available dashes
var invincible: bool = false

# Special upgrades
var has_shatter: bool = false
var gravity_well_strength: float = 0.0
var overclock_active: bool = false
var crit_chance: float = 0.10
var crit_damage: float = 2.0    # Crit multiplier; Critical Surge raises it per stack
var lifesteal: float = 0.0
var damage_reduction: float = 0.0
var execute_bonus: float = 0.0  # Bonus damage multiplier vs low-HP enemies
var adrenaline: bool = false    # Deal more damage the lower the player's HP gets
var xp_gain_mult: float = 1.0   # Greed upgrade — scales all XP gained
var revive_available: bool = false  # Guardian Angel — one-time fatal-hit save

# Weapon upgrades (level 0 = not unlocked)
var railgun_level: int = 0
var signal_arrow_level: int = 0
var chain_level: int = 0
var orbital_level: int = 0
var piercing_level: int = 0
var ricochet_level: int = 0

# Progression
var xp: float = 0.0
var level: int = 1
var xp_to_next: float = 80.0
var pending_levelups: int = 0  # Queued upgrades when one XP gain crosses multiple levels

# Session
var wave: int = 0
var kills: int = 0
var game_over: bool = false
var paused_for_upgrade: bool = false
var game_started: bool = false
var time_survived: float = 0.0
var total_damage_dealt: float = 0.0
var total_damage_taken: float = 0.0

# Acquired upgrades for game over summary
var acquired_upgrades: Array[String] = []

# Enemy kill breakdown for game over stats
var kills_by_type: Dictionary = {}
var total_xp_earned: float = 0.0

# Dash tracking
var total_dashes: int = 0

# Kill streak tracking
var _streak_count: int = 0
var _streak_timer: float = 0.0
const STREAK_WINDOW := 2.0

# Screen shake
var shake_amount: float = 0.0
var shake_direction: Vector3 = Vector3.ZERO

# Boss arena — set true while a boss is alive. Used by the spawner to skip
# regular spawns and by player/enemy movement to clamp inside a smaller ring.
var boss_active: bool = false
var arena_radius: float = 48.0  # default full arena half-extent; shrunk during boss fights

# Persistent best-run record — survives restarts via a tiny config file.
const SAVE_PATH := "user://velocity_neon.cfg"
var best_wave: int = 0
var best_kills: int = 0
var new_record: bool = false

func _ready() -> void:
	_load_best_run()

func _load_best_run() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_wave = cfg.get_value("best_run", "wave", 0)
		best_kills = cfg.get_value("best_run", "kills", 0)

func _check_best_run() -> void:
	# Deepest wave wins; kills break ties. Wave 1 deaths don't count as a record
	# so an instant first-run death doesn't celebrate itself.
	if wave < 2:
		return
	if wave > best_wave or (wave == best_wave and kills > best_kills):
		new_record = true
		best_wave = wave
		best_kills = kills
		var cfg := ConfigFile.new()
		cfg.set_value("best_run", "wave", best_wave)
		cfg.set_value("best_run", "kills", best_kills)
		cfg.save(SAVE_PATH)

func _process(delta: float) -> void:
	if game_started and not game_over:
		time_survived += delta
		if _damage_immunity_timer > 0.0:
			_damage_immunity_timer -= delta
		if _streak_timer > 0.0:
			_streak_timer -= delta
			if _streak_timer <= 0.0:
				_streak_count = 0

# Wave damage tracking (for no-damage bonus)
var _wave_damage_taken: bool = false

var _damage_immunity_timer: float = 0.0
const DAMAGE_IMMUNITY_DURATION := 0.2

func take_damage(amount: float, is_self_damage: bool = false) -> void:
	if invincible or game_over:
		return
	# Brief i-frames after taking a hit to prevent stacked damage from multiple enemies
	if not is_self_damage and _damage_immunity_timer > 0.0:
		return
	# Emit signal so player can flash during i-frames
	if not is_self_damage:
		damage_iframes_started.emit()
	# Apply damage reduction from Nano Shield (not for self-inflicted damage like overclock)
	var reduced := amount * maxf(0.0, 1.0 - (0.0 if is_self_damage else damage_reduction))
	hp = clampf(hp - reduced, 0.0, max_hp)
	total_damage_taken += reduced
	if not is_self_damage:
		_wave_damage_taken = true
		_damage_immunity_timer = DAMAGE_IMMUNITY_DURATION
		# Brief camera kick so taking a hit actually reads. i-frame gated, so this
		# fires at most ~5x/sec even when surrounded.
		if reduced > 0.0:
			request_shake(1.1 + minf(reduced * 0.05, 1.4))
	if amount >= 5.0:
		Audio.sfx_player_hit()
	if hp <= 0.0:
		# Guardian Angel — once per run, a fatal hit leaves the player on a sliver of
		# HP with a protective burst and a moment of i-frames instead of dying.
		if revive_available and not is_self_damage:
			revive_available = false
			hp = maxf(max_hp * 0.35, 1.0)
			invincible = true
			_damage_immunity_timer = DAMAGE_IMMUNITY_DURATION
			guardian_save.emit()
			Audio.sfx_guardian_save()
			request_shake(5.0)
			xp_magnet_pulse.emit()
			var tree := get_tree()
			if tree:
				tree.create_timer(1.5).timeout.connect(func():
					if not game_over:
						invincible = false
				)
			hp_changed.emit(hp, max_hp)
			return
		game_over = true
		_check_best_run()
		if is_self_damage:
			death_by_overclock.emit()
		player_died.emit()
	hp_changed.emit(hp, max_hp)

func heal(amount: float) -> void:
	hp = clampf(hp + amount, 0.0, max_hp)
	hp_changed.emit(hp, max_hp)

func add_xp(amount: float) -> void:
	# Greed scales all XP gained (orbs, perfect-wave and boss bonuses alike)
	amount *= xp_gain_mult
	xp += amount
	total_xp_earned += amount
	# Loop so a single large XP gain (boss bonus, batched orbs) awards every level
	# it crosses, not just one. Each pending level-up offers its own upgrade choice.
	var gained_level := false
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = 60.0 + 30.0 * level + 5.0 * sqrt(level)
		pending_levelups += 1
		gained_level = true
	xp_changed.emit(xp, xp_to_next)
	if gained_level:
		Audio.sfx_level_up()
		xp_magnet_pulse.emit()
		leveled_up.emit(level)

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
		# Rotate gameplay music as waves progress for variety (single source of truth
		# in AudioManager so the post-boss resume can't drift from this rotation).
		Audio.play_gameplay_music_for_wave(wave)

func add_kill(enemy_type: String = "") -> void:
	kills += 1
	if enemy_type != "":
		kills_by_type[enemy_type] = kills_by_type.get(enemy_type, 0) + 1
	kills_changed.emit(kills)
	_streak_count += 1
	_streak_timer = STREAK_WINDOW
	if _streak_count >= 2:
		kill_streak.emit(_streak_count)
	# XP magnet pulse on 3+ kill streaks for satisfying orb collection
	if _streak_count == 3:
		xp_magnet_pulse.emit()
	# Brief slow-mo on big kill streaks for dramatic impact
	if _streak_count == 5 or _streak_count == 8:
		request_hit_stop(0.06)
	# Escalating audio sting at streak milestones — pitch climbs as the streak grows
	if _streak_count in [3, 5, 8, 12, 16, 20, 25]:
		var streak_pitch := 1.0 + minf(float(_streak_count) * 0.04, 1.0)
		Audio.sfx_streak(streak_pitch)
	if lifesteal > 0.0 and hp < max_hp:
		heal(lifesteal)
		vampire_heal.emit()
	# Kill milestone announcements with celebratory SFX
	if kills in [100, 250, 500, 1000, 2000]:
		Audio.sfx_kill_milestone()
		kill_milestone.emit(kills)

func add_damage_dealt(amount: float) -> void:
	total_damage_dealt += amount

# Active kill streaks grant an escalating damage bonus (up to +24%), making the
# combo system mechanically meaningful instead of just a banner.
func get_combo_damage_mult() -> float:
	if _streak_count < 3:
		return 1.0
	return 1.0 + minf(float(_streak_count - 2) * 0.03, 0.24)

func get_combo_bonus_pct() -> int:
	return int(round((get_combo_damage_mult() - 1.0) * 100.0))

func get_streak_count() -> int:
	return _streak_count

# Fraction of the kill-streak window remaining (0..1), or 0 when no streak is active.
func get_streak_progress() -> float:
	if _streak_count < 2:
		return 0.0
	return clampf(_streak_timer / STREAK_WINDOW, 0.0, 1.0)

# Adrenaline: outgoing damage scales up as the player's HP drops, rewarding
# risky low-health play. Ranges from +0% at full HP to +30% near death.
func get_adrenaline_mult() -> float:
	if not adrenaline:
		return 1.0
	var missing := 1.0 - (hp / maxf(max_hp, 1.0))
	return 1.0 + 0.30 * clampf(missing, 0.0, 1.0)

func request_shake(intensity: float, direction: Vector3 = Vector3.ZERO) -> void:
	# Gentle, allocation-free camera shake. Moving the camera costs nothing — the
	# frame hitches in big waves came from per-hit GPU particle bursts (trimmed in
	# projectile.gd), not from this. Scaled down and hard-capped so a dense swarm
	# can't stack many calls into a constant rumble.
	var scaled := intensity * 0.28
	shake_amount = minf(maxf(shake_amount, scaled), 1.6)
	if direction.length_squared() > 0.01:
		shake_direction = direction.normalized()

func request_hit_stop(_duration: float = 0.04) -> void:
	# Still disabled: hit-stop drives Engine.time_scale and tangled with the
	# level-up pause, so it stays off. Screen shake above carries the impact.
	pass

func reset() -> void:
	hp = 80.0
	max_hp = 80.0
	speed = 6.5
	fire_rate = 2.2
	damage = 7.0
	projectile_count = 1
	projectile_speed = 38.0
	magnet_range = 4.2
	hp_regen = 0.0
	dash_cooldown = 1.5
	dash_speed = 25.0
	dash_max_charges = 1
	dash_charges = 1
	invincible = false
	has_shatter = false
	gravity_well_strength = 0.0
	overclock_active = false
	crit_chance = 0.10
	crit_damage = 2.0
	lifesteal = 0.0
	damage_reduction = 0.0
	execute_bonus = 0.0
	adrenaline = false
	xp_gain_mult = 1.0
	revive_available = false
	railgun_level = 0
	signal_arrow_level = 0
	chain_level = 0
	orbital_level = 0
	piercing_level = 0
	ricochet_level = 0
	xp = 0.0
	level = 1
	xp_to_next = 80.0
	pending_levelups = 0
	wave = 0
	kills = 0
	game_over = false
	paused_for_upgrade = false
	game_started = false
	time_survived = 0.0
	total_damage_dealt = 0.0
	total_damage_taken = 0.0
	total_dashes = 0
	_streak_count = 0
	_streak_timer = 0.0
	shake_amount = 0.0
	shake_direction = Vector3.ZERO
	boss_active = false
	arena_radius = 48.0
	new_record = false
	_wave_damage_taken = false
	_damage_immunity_timer = 0.0
	acquired_upgrades.clear()
	kills_by_type.clear()
	total_xp_earned = 0.0
