class_name UpgradeSystem

class Upgrade:
	var id: String
	var title: String
	var description: String
	var color: Color
	var icon: String
	var max_stacks: int
	var stacks: int = 0

	func _init(p_id: String, p_title: String, p_desc: String, p_color: Color, p_icon: String = "", p_max: int = 5) -> void:
		id = p_id
		title = p_title
		description = p_desc
		color = p_color
		icon = p_icon
		max_stacks = p_max

	func can_apply() -> bool:
		return stacks < max_stacks

static var _upgrades: Array[Upgrade] = []
static var _initialized: bool = false

static func _ensure_init() -> void:
	if _initialized:
		return
	_initialized = true
	_upgrades = [
		# Stat upgrades
		Upgrade.new("rapid_fire", "RAPID FIRE", "+25% fire rate", Color(1.0, 0.9, 0.2), ">>"),
		Upgrade.new("power_shot", "POWER SHOT", "+20% damage", Color(1.0, 0.3, 0.1), "!!"),
		Upgrade.new("fortify", "FORTIFY", "+30 max HP, heal 30", Color(0.3, 1.0, 0.5), "++"),
		Upgrade.new("swift", "SWIFT", "+12% move speed", Color(0.3, 0.8, 1.0), "~~"),
		Upgrade.new("multi_shot", "MULTI-SHOT", "+1 projectile", Color(0.9, 0.5, 1.0), "**", 4),
		Upgrade.new("magnet", "MAGNET", "+50% pickup range", Color(0.5, 1.0, 0.8), "<>"),
		Upgrade.new("regen", "REGENERATION", "+1.5 HP/sec", Color(0.2, 1.0, 0.3), "HP"),
		Upgrade.new("shatter", "SHATTER POINT", "Bullets split on hit", Color(1.0, 0.6, 0.0), "##", 1),
		Upgrade.new("gravity_well", "GRAVITY WELL", "Slow nearby enemies", Color(0.6, 0.3, 1.0), "()", 3),
		Upgrade.new("overclock", "OVERCLOCK", "2x fire rate, drains HP", Color(1.0, 0.0, 0.3), "OC", 1),
		Upgrade.new("phase_shift", "PHASE SHIFT", "Dash cooldown -25%", Color(0.3, 0.9, 1.0), "<<", 3),
		# Weapon upgrades
		Upgrade.new("railgun", "RAILGUN", "Piercing beam every 2s", Color(0.3, 0.5, 1.0), "==", 3),
		Upgrade.new("scatter", "SCATTER SHOT", "5-pellet burst every 1.5s", Color(1.0, 0.5, 0.0), ".:"),
		Upgrade.new("chain", "CHAIN ARC", "Shots chain to nearby foes", Color(0.4, 0.9, 1.0), "//", 3),
		Upgrade.new("orbital", "ORBITAL GUARD", "Orbiting damage orbs", Color(0.0, 1.0, 0.6), "@@", 3),
		Upgrade.new("piercing", "PIERCING ROUNDS", "Shots pass through enemies", Color(0.9, 0.9, 1.0), "->", 3),
		Upgrade.new("ricochet", "RICOCHET", "Shots bounce off arena walls", Color(0.8, 1.0, 0.3), "<>", 2),
		Upgrade.new("crit_surge", "CRITICAL SURGE", "+5% critical hit chance", Color(1.0, 0.5, 0.0), "!!", 4),
	]

static func get_random_choices(count: int = 3) -> Array[Upgrade]:
	_ensure_init()
	var available: Array[Upgrade] = []
	for u in _upgrades:
		if u.can_apply():
			available.append(u)
	available.shuffle()
	var result: Array[Upgrade] = []
	for i in mini(count, available.size()):
		result.append(available[i])
	return result

static func apply_upgrade(upgrade: Upgrade) -> void:
	upgrade.stacks += 1
	if upgrade.title not in GameState.acquired_upgrades:
		GameState.acquired_upgrades.append(upgrade.title)
	match upgrade.id:
		"rapid_fire":
			GameState.fire_rate *= 1.25
		"power_shot":
			GameState.damage *= 1.20
		"fortify":
			GameState.max_hp += 30.0
			GameState.heal(30.0)
		"swift":
			GameState.speed *= 1.12
		"multi_shot":
			GameState.projectile_count += 1
		"magnet":
			GameState.magnet_range *= 1.5
		"regen":
			GameState.hp_regen += 1.5
		"shatter":
			GameState.has_shatter = true
		"gravity_well":
			GameState.gravity_well_strength += 0.35
		"overclock":
			GameState.overclock_active = true
		"phase_shift":
			GameState.dash_cooldown *= 0.75
		"railgun":
			GameState.railgun_level += 1
		"scatter":
			GameState.scatter_level += 1
		"chain":
			GameState.chain_level += 1
		"orbital":
			GameState.orbital_level += 1
		"piercing":
			GameState.piercing_level += 1
		"ricochet":
			GameState.ricochet_level += 1
		"crit_surge":
			GameState.crit_chance += 0.05

static func reset_all() -> void:
	_initialized = false
	_upgrades.clear()
