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
		Upgrade.new("fortify", "FORTIFY", "+15 max HP, heal 15", Color(0.3, 1.0, 0.5), "++"),
		Upgrade.new("bulwark", "TITANIUM PLATING", "+18% max HP & heal", Color(0.4, 0.95, 0.7), "[]", 3),
		Upgrade.new("swift", "SWIFT", "+12% move speed", Color(0.3, 0.8, 1.0), "~~"),
		Upgrade.new("frenzy", "FRENZY", "+15% fire rate & +8% move speed", Color(1.0, 0.55, 0.15), "><", 3),
		Upgrade.new("coolant", "COOLANT", "-12% ultimate cooldown", Color(0.3, 0.9, 1.0), "QQ", 3),
		Upgrade.new("multi_shot", "MULTI-SHOT", "+1 projectile", Color(0.9, 0.5, 1.0), "**", 5),
		Upgrade.new("magnet", "MAGNET", "+50% pickup range", Color(0.5, 1.0, 0.8), "<>"),
		Upgrade.new("regen", "REGENERATION", "+1.6 HP/sec", Color(0.2, 1.0, 0.3), "HP", 3),
		Upgrade.new("shatter", "SHATTER POINT", "Bullets split on hit", Color(1.0, 0.6, 0.0), "##", 1),
		Upgrade.new("gravity_well", "GRAVITY WELL", "Slow nearby enemies", Color(0.6, 0.3, 1.0), "()", 3),
		# Overclock removed — too punishing without guaranteed healing upgrade
		Upgrade.new("dash_charge", "PHASE CHARGE", "+1 dash charge (bank an extra dash)", Color(0.3, 0.9, 1.0), ">>", 3),
		Upgrade.new("phase_blades", "PHASE BLADES", "Phase Dash hits harder & carves wider", Color(0.2, 0.95, 1.0), "//", 2),
		# Weapon upgrades
		Upgrade.new("railgun", "RAILGUN", "Piercing beam every 2s", Color(0.3, 0.5, 1.0), "==", 3),
		Upgrade.new("signal_arrow", "SIGNAL ARROW", "Homing arrow darts enemy to enemy", Color(0.95, 0.15, 0.12), "}>"),
		Upgrade.new("chain", "CHAIN ARC", "Shots chain to nearby foes", Color(0.4, 0.9, 1.0), "//", 3),
		Upgrade.new("orbital", "ORBITAL GUARD", "Orbiting damage orbs", Color(0.0, 1.0, 0.6), "@@", 3),
		Upgrade.new("piercing", "PIERCING ROUNDS", "Shots pass through enemies", Color(0.9, 0.9, 1.0), "->", 3),
		Upgrade.new("ricochet", "RICOCHET", "Shots bounce off arena walls", Color(0.8, 1.0, 0.3), "<>", 2),
		Upgrade.new("crit_surge", "CRITICAL SURGE", "+5% crit chance & +15% crit damage", Color(1.0, 0.5, 0.0), "!!", 4),
		Upgrade.new("vampire", "VAMPIRE", "Heal 3 HP per enemy kill", Color(0.8, 0.0, 0.3), "VV", 3),
		Upgrade.new("nano_shield", "NANO SHIELD", "-12% incoming damage", Color(0.3, 0.7, 1.0), "[]", 4),
		Upgrade.new("velocity_rounds", "VELOCITY ROUNDS", "+20% projectile speed", Color(0.9, 1.0, 0.3), "=>", 3),
		Upgrade.new("executioner", "EXECUTIONER", "+25% damage to enemies under 40% HP", Color(0.9, 0.1, 0.2), "XX", 3),
		Upgrade.new("adrenaline", "ADRENALINE", "More damage the lower your HP", Color(1.0, 0.25, 0.1), "AD", 1),
		Upgrade.new("greed", "GREED", "+20% XP from all sources", Color(1.0, 0.8, 0.1), "$$", 3),
		Upgrade.new("guardian", "GUARDIAN ANGEL", "Survive one fatal hit per run", Color(0.6, 0.9, 1.0), "++", 1),
		Upgrade.new("thorns", "THORNS", "Reflect contact damage back to attackers", Color(0.7, 0.85, 0.9), "><", 2),
		Upgrade.new("giant_slayer", "GIANT SLAYER", "More damage to bosses", Color(1.0, 0.85, 0.3), "><", 3),
		Upgrade.new("scavenger", "SCAVENGER", "More & stronger health drops", Color(0.3, 1.0, 0.55), "++", 2),
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
		# Enrich description with concrete stat preview
		var u: Upgrade = available[i]
		u.description = _stat_preview(u)
		result.append(u)
	return result

static func _stat_preview(u: Upgrade) -> String:
	match u.id:
		"rapid_fire":
			var cur := GameState.fire_rate
			return "+25%% fire rate (%.1f -> %.1f)" % [cur, cur * 1.25]
		"power_shot":
			var cur := GameState.damage
			return "+20%% damage (%.1f -> %.1f)" % [cur, cur * 1.2]
		"fortify":
			return "+15 max HP, heal 15 (HP: %d -> %d)" % [int(GameState.max_hp), int(GameState.max_hp + 15)]
		"swift":
			var cur := GameState.speed
			return "+12%% move speed (%.1f -> %.1f)" % [cur, cur * 1.12]
		"frenzy":
			var fr := GameState.fire_rate
			return "+15%% fire rate & +8%% speed (fire %.1f -> %.1f)" % [fr, fr * 1.15]
		"coolant":
			# Coolant is multiplicative (x0.88) with a 0.6 floor, so a flat "+12 points"
			# preview drifts from reality at higher stacks. Show the true next total.
			var cur_mult := GameState.ult_cd_mult
			var next_mult := maxf(cur_mult * 0.88, 0.6)
			var cur := (1.0 - cur_mult) * 100.0
			var nxt := (1.0 - next_mult) * 100.0
			return "-%d%% ultimate cooldown (%d%% -> %d%% total)" % [int(round(nxt - cur)), int(round(cur)), int(round(nxt))]
		"multi_shot":
			return "+1 projectile (%d -> %d)" % [GameState.projectile_count, GameState.projectile_count + 1]
		"magnet":
			var cur := GameState.magnet_range
			return "+50%% pickup range (%.1f -> %.1f)" % [cur, cur * 1.5]
		"regen":
			var cur := GameState.hp_regen
			return "+1.6 HP/sec (%.1f -> %.1f)" % [cur, cur + 1.6]
		"bulwark":
			return "+18%% max HP & heal (HP: %d -> %d)" % [int(GameState.max_hp), int(GameState.max_hp * 1.18)]
		"dash_charge":
			return "+1 dash charge (%d -> %d)" % [GameState.dash_max_charges, GameState.dash_max_charges + 1]
		"phase_blades":
			var cur := GameState.dash_damage_mult
			return "+80%% Phase Dash damage & wider carve (x%.1f -> x%.1f)" % [cur, cur + 0.8]
		"crit_surge":
			var cur := GameState.crit_chance * 100.0
			return "+5%% crit chance (%d%%->%d%%), +15%% crit dmg (%.2fx->%.2fx)" % [int(cur), int(cur + 5), GameState.crit_damage, GameState.crit_damage + 0.15]
		"vampire":
			var cur := GameState.lifesteal
			return "Heal per kill (+%.1f -> +%.1f)" % [cur, cur + 3.0]
		"nano_shield":
			var cur := GameState.damage_reduction * 100.0
			return "-12%% incoming damage (%d%% -> %d%%)" % [int(cur), mini(int(cur + 12), 48)]
		"velocity_rounds":
			var cur := GameState.projectile_speed
			return "+20%% projectile speed (%.0f -> %.0f)" % [cur, cur * 1.2]
		"railgun":
			var cur := GameState.railgun_level
			var dmg_mult := 1.5 + 0.5 * (cur + 1)
			var rg_cd := 2.0 * maxf(1.0 - 0.15 * float(cur), 0.7)
			return "Piercing beam (Lv %d -> %d, %.1fx dmg, every %.1fs)" % [cur, cur + 1, dmg_mult, rg_cd]
		"signal_arrow":
			var cur := GameState.signal_arrow_level
			var tgts := 4 + (cur + 1) * 2
			return "Yaka arrow (Lv %d -> %d, faster, %d targets)" % [cur, cur + 1, tgts]
		"chain":
			var cur := GameState.chain_level
			return "Chain bounces (Lv %d -> %d targets)" % [cur, cur + 1]
		"orbital":
			var cur := GameState.orbital_level
			return "Orbiting orbs (%d -> %d orbs)" % [cur, cur + 1]
		"piercing":
			var cur := GameState.piercing_level
			return "Pierce through enemies (%d -> %d targets)" % [cur, cur + 1]
		"ricochet":
			var cur := GameState.ricochet_level
			return "Wall bounces (%d -> %d bounces)" % [cur, cur + 1]
		"shatter":
			return "Bullets split into 3 fragments on hit (55% dmg each)"
		"gravity_well":
			var cur := GameState.gravity_well_strength
			return "Slow nearby enemies (%.0f%% -> %.0f%%)" % [cur * 100, (cur + 0.35) * 100]
		"executioner":
			var cur := GameState.execute_bonus
			return "+25%% dmg to enemies below 40%% HP (%.0f%% -> %.0f%%)" % [cur * 100, (cur + 0.25) * 100]
		"adrenaline":
			return "Up to +40%% damage as your HP drops (scales with missing HP)"
		"greed":
			var gcur := (GameState.xp_gain_mult - 1.0) * 100.0
			return "+20%% XP gained (%d%% -> %d%%)" % [int(round(gcur)), int(round(gcur + 20))]
		"guardian":
			return "Cheat death once: survive a fatal hit at 35%% HP"
		"thorns":
			var cur := GameState.thorns * 100.0
			return "Reflect contact damage (%d%% -> %d%%)" % [int(round(cur)), int(round(cur + 25))]
		"giant_slayer":
			var cur := (GameState.boss_damage_mult - 1.0) * 100.0
			return "+30%% damage to bosses (%d%% -> %d%%)" % [int(round(cur)), int(round(cur + 30))]
		"scavenger":
			var drop := GameState.health_drop_mult
			return "Health orbs drop +60%% more often & heal +25%% (drop x%.1f -> x%.1f)" % [drop, drop + 0.6]
		_:
			return u.description

static func apply_upgrade(upgrade: Upgrade) -> void:
	upgrade.stacks += 1
	GameState.acquired_upgrades.append(upgrade.title)
	match upgrade.id:
		"rapid_fire":
			GameState.fire_rate *= 1.25
		"power_shot":
			GameState.damage *= 1.20
		"fortify":
			GameState.max_hp += 15.0
			GameState.heal(15.0)
		"bulwark":
			GameState.max_hp *= 1.18
			GameState.heal(GameState.max_hp * 0.18)
		"swift":
			GameState.speed *= 1.12
		"frenzy":
			GameState.fire_rate *= 1.15
			GameState.speed *= 1.08
		"coolant":
			# Trim the ultimate cooldown; floored so a maxed stack still leaves a real gap.
			GameState.ult_cd_mult = maxf(GameState.ult_cd_mult * 0.88, 0.6)
		"multi_shot":
			GameState.projectile_count += 1
		"magnet":
			GameState.magnet_range *= 1.5
		"regen":
			GameState.hp_regen += 1.6
		"shatter":
			GameState.has_shatter = true
		"gravity_well":
			GameState.gravity_well_strength += 0.35
		# "overclock" removed from upgrade pool
		"dash_charge":
			GameState.dash_max_charges += 1
			GameState.dash_charges += 1
			# Banking a dash also speeds up its recharge (floor 0.8s)
			GameState.dash_cooldown = maxf(GameState.dash_cooldown * 0.92, 0.8)
		"phase_blades":
			GameState.dash_damage_mult += 0.8
		"railgun":
			GameState.railgun_level += 1
		"signal_arrow":
			GameState.signal_arrow_level += 1
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
			GameState.crit_damage += 0.15
		"vampire":
			GameState.lifesteal += 3.0
		"nano_shield":
			GameState.damage_reduction = minf(GameState.damage_reduction + 0.12, 0.48)
		"velocity_rounds":
			GameState.projectile_speed *= 1.20
		"executioner":
			GameState.execute_bonus += 0.25
		"adrenaline":
			GameState.adrenaline = true
		"greed":
			GameState.xp_gain_mult += 0.20
		"guardian":
			GameState.revive_available = true
		"thorns":
			GameState.thorns = minf(GameState.thorns + 0.25, 0.5)
		"giant_slayer":
			GameState.boss_damage_mult += 0.30
		"scavenger":
			GameState.health_drop_mult += 0.6
			GameState.health_heal_mult += 0.25

static func reset_all() -> void:
	_initialized = false
	_upgrades.clear()
