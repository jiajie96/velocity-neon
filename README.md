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
- Phase Dash with afterimage trail, invincibility, and contact damage
- Ultimate ability with screen-clearing AoE and multi-ring VFX

### Weapons & Upgrades (21 upgrades)
- **Primary Stats**: Rapid Fire, Power Shot, Fortify, Swift, Multi-Shot, Magnet
- **Weapons**: Railgun (piercing beam), Scatter Shot (pellet burst), Chain Arc, Orbital Guard
- **Combat**: Piercing Rounds, Ricochet, Shatter Point, Critical Surge, Velocity Rounds
- **Defense**: Nano Shield, Regeneration, Vampire (lifesteal)
- **Utility**: Phase Shift (dash cooldown), Gravity Well, Overclock

### Enemies (8 types)
- **Skeleton Minion** — basic melee rusher
- **Skeleton Warrior** — tougher, slower
- **Skeleton Mage** — ranged caster with telegraphed fire bolts
- **Skeleton Rogue** — fast with periodic sidestep dodge
- **Necromancer** — stays at range, summons minion waves, fires bolts
- **Exploder** — rushes player, detonates on proximity with chain reaction potential
- **Teleporter** — blinks to random positions near the player, unpredictable
- **Skeleton Golem** (Boss, every 5th wave) — multi-phase with slam, rock throw, charge, and enrage below 30% HP

### Audio
- Dynamic soundtrack that rotates across 8+ tracks as waves progress
- Boss-specific music (cyberpunk_battle for early bosses, epic_boss for wave 10+)
- Weapon-specific hit impact SFX (railgun, scatter, chain, pulse)
- Ambient neon hum that shifts pitch based on HP
- Full UI sound effects (clicks, hovers, upgrade selection, wave start, level-up)
- XP pickup pitch scaling (pentatonic climb on rapid collection)

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

### HUD & UI
- HP bar with color shift (cyan → red at low HP)
- XP bar with level counter and upgrade count
- Boss HP bar with percentage and enrage warning ("ENRAGED" + pulsing red)
- Live DPS meter, enemy count, survival timer
- Wave announcements with boss wave callouts
- Kill streak and milestone announcements
- No-damage wave indicator
- Pause menu (resume/restart/quit)
- Game over screen with stats, performance rating, build summary, and restart button
- Title screen with controls reference

### Game Systems
- Wave-based progression with aggressive scaling
- Perfect wave bonus XP (no damage taken)
- Wave clear heal bonus (small HP recovery between waves)
- XP magnet pulse on level-up, wave clear, and kill streaks (3+)
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
