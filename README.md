# Velocity Neon: Haptic Havoc

A top-down 3D action roguelike built in Godot 4.6 with a neon cyberpunk aesthetic.

Survive relentless waves of skeleton enemies, level up to choose powerful upgrades, and push deeper into the neon grid.

## How to Play

- **WASD / Arrows** — Move
- **Auto-Aim** — Shoots nearest enemy automatically
- **SPACE** — Phase Dash (invincible + damage trail)
- **Q** — Ultimate Ability (area damage burst)
- **Scroll Wheel** — Zoom camera in/out
- **ESC** — Pause menu
- **R** — Restart (game over)
- **1/2/3** — Quick-select upgrades on level-up

## Features

### Combat
- Auto-aim primary weapon with laser bolt visuals and trail effects
- Critical hits (10% base chance, orange CRIT text, screen flash)
- Kill streak announcements (DOUBLE KILL through UNSTOPPABLE)
- Phase Dash with afterimage trail, invincibility, contact damage scaling with speed, and audio-visual ready cue
- Ultimate ability with screen-clearing AoE, multi-ring VFX, and damage scaling with upgrades

### Weapons & Upgrades (21 upgrades)
- **Primary Stats**: Rapid Fire, Power Shot, Fortify, Swift, Multi-Shot, Magnet
- **Weapons**: Railgun (piercing beam), Scatter Shot (pellet burst), Chain Arc, Orbital Guard
- **Combat**: Piercing Rounds, Ricochet, Shatter Point, Critical Surge, Velocity Rounds
- **Defense**: Nano Shield, Regeneration (with heal particle VFX), Vampire (lifesteal)
- **Utility**: Phase Shift (dash cooldown), Gravity Well, Overclock (with HP drain warning)

### Enemies (8 types)
- **Skeleton Minion** — basic melee rusher
- **Skeleton Warrior** — tougher, slower
- **Skeleton Mage** — ranged caster with telegraphed fire bolts, speed scales with wave
- **Skeleton Rogue** — fast with periodic sidestep dodge
- **Necromancer** — stays at range, summons minion waves, fires telegraphed purple bolts, speed scales with wave
- **Exploder** — rushes player, detonates on proximity with chain reaction potential
- **Teleporter** — blinks to random positions near the player, unpredictable
- **Skeleton Golem** (Boss, every 5th wave) — multi-phase with slam, rock throw, charge, and enrage below 30% HP. Defeating a boss awards bonus XP

### Audio
- Dynamic soundtrack that rotates across 8+ tracks as waves progress
- Boss-specific music (cyberpunk_battle for early bosses, epic_boss for wave 10+)
- Weapon-specific hit impact SFX (railgun, scatter, chain, pulse)
- Enemy death SFX varies by type (unique pitch ranges per enemy for audio variety)
- Ambient neon hum that shifts pitch based on HP
- Low HP heartbeat pulse (rhythmic thump below 25% HP, increases urgency)
- Kill milestone celebratory SFX (distinct sound at 100/250/500/1000 kills)
- Full UI sound effects (clicks, hovers, upgrade selection, wave start, level-up)
- XP pickup pitch scaling (pentatonic climb on rapid collection)
- Dash ready audio cue when cooldown completes
- Ultimate ready audio cue when cooldown finishes
- Necromancer summon SFX (eerie pulse when minions spawn)
- Golem charge telegraph SFX (low rumble before charge)
- Orbital Guard hit SFX (subtle click when orbitals damage enemies)
- Teleporter blink SFX (high-pitched warp sound on teleport)

### Visual Polish
- Neon cyberpunk aesthetic with bloom, glow, and emissive materials
- Damage vignette (red pulse at low HP), hit flash on damage taken
- Screen flash on critical hits (orange tint)
- Speed lines during Phase Dash (radial shader)
- Directional screen shake with hit-stop on heavy impacts
- Boss entrance slow-mo with temporary camera zoom-out
- Dynamic camera zoom (pulls in for close combat, out for distant threats)
- Floating damage numbers (color-coded, scaled for big hits)
- Enemy death VFX (expanding rings + spark bursts, type-colored)
- Dash afterimages and ready-pulse ring indicator
- Regeneration heal particles (green sparkles rising from player)
- Enhanced projectile trails at high speed (denser, longer-lasting)
- Overclock HP drain warning (pulsing red HP bar border + red HP text)
- Necromancer bolt telegraph (purple charge glow before firing)
- Teleporter blink-scatter death effect (ghost copies flash outward)
- Overclock pulsing player glow (light shifts red/orange during overclock)
- Gravity Well visible radius ring (purple pulsing ring shows slow field area)
- Rogue dodge ghost trail (translucent afterimage on sidestep)
- Orbital Guard hit sparks (green flash when orbitals damage enemies)
- Mage/Necromancer bolt trail particles (fading trail behind enemy projectiles)
- Player model damage flash (white flash on hit for clear feedback)
- XP orb spawn burst (orbs pop outward from kills before settling)
- Boss enrage arena red pulse (screen edge throb during enrage phase)
- Kill streak slow-motion (brief time-slow on 5+ and 8+ streaks)
- Threat-scaled spawn warnings (bigger glow rings for dangerous enemy types)

### HUD & UI
- HP bar with color shift (cyan → red at low HP), overclock drain indicator
- XP bar with level counter and upgrade count
- Boss HP bar with percentage and enrage warning ("ENRAGED" + pulsing red)
- Boss defeat bonus XP announcement
- Live DPS meter, enemy count, survival timer
- Wave announcements with boss wave callouts
- Kill streak and milestone announcements
- No-damage wave indicator
- Pause menu (resume/restart/quit)
- Game over screen with stats (damage dealt/taken, kills/min, DPS), performance rating, build summary, and restart button
- Title screen with controls reference
- Wave spawn progress counter (shows enemies spawned vs total)
- Upgrade stat preview (concrete before/after values on level-up cards)

### Game Systems
- Wave-based progression with aggressive scaling (enemy contact damage scales with wave)
- Overclock HP drain no longer ruins perfect wave bonus
- Perfect wave bonus XP (no damage taken)
- Wave clear heal bonus (small HP recovery between waves)
- XP magnet pulse on level-up, wave clear, kill streaks (3+), and boss defeat
- XP orbs fade out after 15 seconds to prevent late-game buildup
- Enemy spawn throttle (caps at 100 alive enemies to maintain performance)
- Post-game performance rating (RECRUIT → LEGENDARY based on waves survived)
- Arena boundary walls with neon glow pillars

## Running the Game

1. Open the project in Godot 4.6
2. Run the main scene (`main.tscn`)
3. Press SPACE on the title screen to start

## Project Structure

```
scripts/
  player.gd          — Player movement, dash, weapons
  enemy.gd           — Enemy AI (8 types + boss)
  enemy_spawner.gd   — Wave logic and spawn system
  main.gd            — Scene setup
  hud.gd             — All UI rendering
  upgrade_system.gd  — 21 upgrade definitions
  projectile.gd      — Bullet physics and VFX
  xp_orb.gd          — XP pickup mechanics
  camera_rig.gd      — Camera follow, shake, zoom
  autoload/
    game_state.gd    — Global state and signals
    audio_manager.gd — SFX pool + music system
assets/
  audio/sfx/         — Sound effects (OGG)
  audio/music/       — Background music tracks
  models/            — 3D character models (GLB)
  shaders/           — Grid ground shader
```
