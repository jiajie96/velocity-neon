# Velocity Neon: Haptic Havoc

A top-down 3D action roguelike built in Godot 4.6 with a neon cyberpunk aesthetic.

Survive relentless waves of skeleton enemies, level up to choose powerful upgrades, and push deeper into the neon grid.

## How to Play

- **WASD / Arrows** — Move
- **Auto-Aim** — Shoots nearest enemy automatically
- **SPACE** — Phase Dash (invincible + brief escape grace + damage trail; banks multiple charges with the Phase Charge upgrade)
- **Q** — Ultimate Ability (area damage burst)
- **Scroll Wheel** — Zoom camera in/out
- **ESC** — Pause menu
- **R** — Restart (game over)
- **1/2/3** — Quick-select upgrades on level-up

## Features

### Combat
- Auto-aim primary weapon with laser bolt visuals and trail effects, plus a target reticle that marks the enemy you're currently locked onto
- Critical hits (10% base chance, ★ damage text, orange screen flash, crisp crit ping + extra hit-stop/shake so they land hard)
- Kill streaks grant an escalating combo damage bonus (up to +24%) shown live on the streak banner (DOUBLE KILL through UNSTOPPABLE)
- Phase Dash with afterimage trail, invincibility, contact damage scaling with speed, and audio-visual ready cue
- Ultimate ability with screen-clearing AoE, multi-ring VFX, and damage scaling with upgrades

### Weapons & Upgrades (21 upgrades)
- **Primary Stats**: Rapid Fire, Power Shot, Fortify, Swift, Multi-Shot, Magnet
- **Weapons**: Railgun (piercing beam), Signal Arrow (homing Yaka-style arrow that darts enemy-to-enemy — faster and harder-hitting each level), Chain Arc, Orbital Guard
- **Combat**: Piercing Rounds, Ricochet, Shatter Point, Critical Surge, Velocity Rounds, Executioner (bonus damage to low-HP enemies with red execution flash)
- **Defense**: Nano Shield (with visible blue shield ring), Regeneration (with heal particle VFX), Vampire (2.5 HP lifesteal per kill, up to 3 stacks)
- **Utility**: Phase Charge (banks an extra dash — stack to hold and chain multiple dashes), Gravity Well

### Enemies (8 types)
- **Skeleton Minion** — basic melee rusher
- **Skeleton Warrior** — tougher, with periodic lunge attacks that deal contact damage + knockback on impact (lunge frequency increases in later waves, SFX + ground dust VFX on landing)
- **Skeleton Mage** — ranged caster with telegraphed fire bolts, strafing orbit movement, speed scales with wave, retreat clamped to arena bounds
- **Skeleton Rogue** — fast with periodic sidestep dodge (dodge frequency increases in later waves)
- **Necromancer** — stays at range, summons minion waves, fires telegraphed purple bolts, speed scales with wave, retreat clamped to arena bounds
- **Exploder** — rushes player, detonates on proximity with chain reaction potential, lightning arc VFX between chained explosions, and pulsing danger ring showing blast radius (explosion damage scales with wave)
- **Teleporter** — blinks to random positions near the player, unpredictable (blink frequency scales with wave)
- **Skeleton Golem** (Boss, every 5th wave) — multi-phase with slam, rock throw with ground target indicator (3-rock spread when enraged, fiery trail particles, distinct throw SFX), charge (with knockback, ground impact VFX), and enrage below 30% HP. Boss speed scales with wave progression. Defeating a boss awards bonus XP with dramatic gold flash
- Non-minion enemies display mini HP bars for target prioritization

### Audio
- Title screen ambient music (neon_runner) with crossfade into gameplay tracks
- Dynamic soundtrack that rotates across 9 tracks as waves progress
- Boss-specific music (cyberpunk_battle for early bosses, epic_boss for wave 10+)
- Defeat music on game over (somber track plays on death)
- Weapon-specific hit impact SFX (railgun, scatter, chain, pulse)
- Enemy death SFX varies by type (unique pitch ranges per enemy for audio variety)
- Ambient neon hum that shifts pitch based on HP
- Low HP heartbeat pulse (rhythmic thump below 25% HP, increases urgency)
- Critical hit ping (bright two-layer chime when a crit lands)
- Escalating kill-streak chime that climbs in pitch at streak milestones (3/5/8/12/16/20/25)
- Kill milestone celebratory SFX (distinct sound at 100/250/500/1000 kills)
- Full UI sound effects (clicks, hovers, upgrade selection, wave start, level-up)
- XP pickup pitch scaling (pentatonic climb on rapid collection)
- Big XP batch collection chime (satisfying sound when collecting many orbs at once)
- Dash ready audio cue when cooldown completes
- Ultimate ready audio cue when cooldown finishes
- Necromancer summon SFX (eerie pulse when minions spawn)
- Golem charge telegraph SFX (low rumble before charge)
- Golem rock throw SFX (distinct deep whoosh, separate from slam)
- Orbital Guard hit SFX (subtle click when orbitals damage enemies)
- Teleporter blink SFX (high-pitched warp sound on teleport)
- Player death SFX (dramatic low-pitched explosion on game over)
- Warrior lunge SFX (impact grunt when warriors charge)
- Victory sting on wave 10/15/20/25 milestones
- Wave clear heal SFX (subtle chime when HP recovers between waves)
- Health pickup chime (bright two-layer chime when grabbing a dropped heal orb)
- 16-channel SFX pool for rich audio layering

### Visual Polish
- Neon cyberpunk aesthetic with bloom, glow, and emissive materials
- Auto-aim target reticle (spinning cyan bracket marks the locked-on enemy; scales up for bosses)
- Floating ambient neon motes drifting across the arena floor
- Damage vignette (red pulse at low HP), hit flash on damage taken
- Screen flash on critical hits (orange tint)
- Green screen-edge pulse when grabbing a health pickup
- Punchy muzzle flash on every shot (brighter, snaps inward as it fades)
- Enemy hit-pop flares the whole model's glow white on hit (reads clearly even on multi-surface skeletons), then restores to its true resting neon glow
- Cyan Phase Dash trail unified with the dash afterimages, ring, and shockwave
- Speed lines during Phase Dash (radial shader)
- Directional screen shake with hit-stop on heavy impacts
- Camera punch on player damage for visceral hit feedback
- Boss entrance slow-mo with temporary camera zoom-out
- Boss wave red flash + screenshake on wave announcement
- Dynamic camera zoom (pulls in for close combat, out for distant threats)
- Floating damage numbers (color-coded, scaled for big hits)
- Enemy death VFX (expanding rings + spark bursts, type-colored)
- Dash afterimages and ready-pulse ring indicator
- Regeneration heal particles (green sparkles rising from player)
- Enhanced projectile trails at high speed (denser, longer-lasting)
- Necromancer bolt telegraph (purple charge glow before firing)
- Teleporter blink-scatter death effect (ghost copies flash outward)
- Gravity Well visible radius ring (purple pulsing ring shows slow field area)
- Rogue dodge ghost trail (translucent afterimage on sidestep)
- Orbital Guard hit sparks (green flash when orbitals damage enemies)
- Mage/Necromancer bolt trail particles (fading trail behind enemy projectiles)
- Player model damage flash (white flash on hit for clear feedback)
- XP orb spawn burst (orbs pop outward from kills before settling)
- Boss enrage arena red pulse (screen edge throb during enrage phase)
- Kill streak slow-motion (brief time-slow on 5+ and 8+ streaks)
- Threat-scaled spawn warnings (bigger glow rings for dangerous enemy types)
- Nano Shield visible ring (blue pulse around player when damage reduction is active)
- Golem charge end ground impact ring (visual punctuation when charge stops)
- Boss enrage dust trail (red particles behind enraged golem for visual intensity)
- XP orb magnetize glow (orbs glow brighter when being pulled toward player)
- Weapon-colored damage numbers (railgun blue, scatter orange, chain cyan, orbital green)
- Level-up invincibility shield ring (cyan pulse ring during post-upgrade i-frames)
- Ultimate ready screen flash (purple screen-edge pulse when ult comes off cooldown)
- Title screen neon color cycle (animated title text with shifting neon colors)
- Enemy projectiles despawn at arena boundaries (prevents stale node buildup)
- Dash-colored damage numbers (cyan) when hitting enemies during Phase Dash
- Scatter shot cone flash (brief orange cone showing pellet spread direction)
- Gravity Well purple tint on slowed enemies (visual feedback for slow field)
- Warrior lunge ground dust (red particles on landing after lunge)
- Executioner red flash on low-HP enemy hits (makes the upgrade feel impactful)
- Warrior lunge emission properly resets after attack completes
- Exploder chain reaction lightning arcs between chained detonations
- Golem rock throw fiery trail particles
- Golem rock throw ground target indicator (red circle showing impact zone)
- Exploder detonation radius danger ring (pulsing warning as they approach)
- Damage i-frame visual indicator (cyan ring flash showing invulnerability window)
- Velocity Rounds visual scaling (faster projectiles have thicker, brighter trails)

### HUD & UI
- HP bar with color shift (cyan → red at low HP), overclock drain indicator
- XP bar with level counter, upgrade count, and a numeric current/next-XP readout so progress to the next upgrade is visible
- Boss HP bar with wave-specific label ("SKELETON GOLEM — WAVE X"), color shift (green → yellow → red), and enrage warning ("ENRAGED" + pulsing red)
- Boss defeat bonus XP announcement
- Live DPS meter, enemy count, survival timer
- Wave announcements with boss wave callouts
- Kill streak and milestone announcements
- No-damage wave indicator
- Pause menu (resume/restart/quit)
- Ultimate cooldown shows seconds remaining (e.g. "ULT [3.2s]") for precise timing
- Wave clear shows XP orb vacuum count (e.g. "WAVE CLEAR +12 ORBS")
- Game over screen with stats (damage dealt/taken, kills/min, DPS, best kill streak, total dashes, avg time/wave), performance rating, power level summary (GEARING UP/ARMED UP/FULLY LOADED/MAXED OUT), build summary, and restart button
- Victory sting plays on reaching wave 10, 15, 20, and 25 milestones
- Victory sting + milestone banner plays on reaching wave 10 (VETERAN), 15 (ELITE), 20 (LEGENDARY), and 25 (MYTHIC)
- XP bar golden glow pulse on level-up for satisfying visual feedback
- Title screen with controls reference
- Wave spawn progress counter (shows enemies spawned vs total)
- Upgrade stat preview (concrete before/after values on level-up cards, including all weapon upgrades)
- Wave countdown shows upcoming wave number and boss wave warnings
- Batched XP pickup text (rapid collection combines into one "+X XP" label)
- Enhanced death sequence (screen shake, slow-mo, red flash)
- Mini HP bars above elite enemies for target prioritization

### Game Systems
- Wave-based progression with aggressive scaling (enemy contact damage scales with wave)
- Health pickups: enemies have a small chance to drop heal orbs (elites likelier, bosses guaranteed) that restore HP scaled to max HP, with green VFX and a chime
- Multi-level-up: large XP gains (boss bonus, batched orbs) award every level crossed, offering each upgrade in turn instead of banking the overflow
- Kill-streak combo damage bonus that ramps with the streak and decays when it ends
- XP orbs auto-magnetize toward the player after a few seconds (and live a little longer) so earned XP isn't lost in chaotic waves
- Warrior lunge cooldown scales with wave for sustained threat in late game
- Exploder detonation damage scales with wave progression
- Perfect wave bonus XP (no damage taken)
- Wave clear heal bonus scales with max HP (rewards Fortify investment)
- Brief invulnerability on wave clear (1s breathing room)
- Phase Dash keeps a short i-frame grace after the dash ends, so phasing through a pack is a reliable escape
- Snappier Phase Dash cooldown (1.75s) for more responsive mobility
- Multi-source damage i-frame window (0.2s) so simultaneous hits in dense waves are fairer
- XP magnet pulse on level-up, wave clear, kill streaks (3+), boss defeat, and exploder chain reactions
- XP orbs fade out after 15 seconds to prevent late-game buildup
- Teleporter blink frequency scales with wave for increased late-game threat
- All knockback effects properly clamped to arena boundaries
- Enemy spawn throttle (caps at 100 alive enemies to maintain performance)
- Post-game performance rating (RECRUIT → LEGENDARY based on waves survived)
- Game over shows wave reached prominently with performance rating
- Game over enemy kill breakdown (top enemy types killed, total XP earned)
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
  camera_rig.gd      — Camera follow, shake, zoom, punch
  autoload/
    game_state.gd    — Global state and signals
    audio_manager.gd — 16-channel SFX pool + music system
assets/
  audio/sfx/         — Sound effects (OGG)
  audio/music/       — Background music tracks
  models/            — 3D character models (GLB)
  shaders/           — Grid ground shader
```
