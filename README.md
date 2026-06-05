# Velocity Neon: Haptic Havoc

A top-down 3D action roguelike built in Godot 4.6 with a neon cyberpunk aesthetic.

Survive relentless waves of skeleton enemies, level up to choose powerful upgrades, and push deeper into the neon grid.

![Velocity Neon gameplay — a boss fight on the neon grid](screenshots/gameplay.png)

## How to Play

- **WASD / Arrows** — Move
- **Auto-Aim** — Shoots nearest enemy automatically
- **SPACE** — Phase Dash (invincible + brief escape grace + damage trail; banks multiple charges with the Phase Charge upgrade)
- **Q** — Ultimate Ability (area damage burst)
- **Scroll Wheel** — Zoom camera in/out
- **ESC** — Pause menu
- **M** — Mute / unmute all audio
- **R** — Restart (game over)
- **1/2/3** — Quick-select upgrades on level-up

## Features

### Combat
- Auto-aim primary weapon with laser bolt visuals and trail effects, plus a target reticle that marks the enemy you're currently locked onto
- Critical hits (10% base chance, ★ damage text, orange screen flash, crisp crit ping + extra screen shake so they land hard)
- Kill streaks grant an escalating combo damage bonus (up to +24%) shown live on the streak banner (DOUBLE KILL through UNSTOPPABLE)
- Phase Dash with afterimage trail, invincibility, contact damage scaling with speed, and audio-visual ready cue
- Ultimate ability with screen-clearing AoE, multi-ring VFX, damage scaling with upgrades, and outward knockback that shoves enemies away for a panic-button "clear space" feel (bosses resist most of the push)
- Tiered hit VFX: chip hits get a cheap point-light flash while kills earn the full shockwave + spark burst, so sustained fire in dense waves stays smooth without losing impact on the moments that matter
- Heavy Multi-Shot volleys (3+ projectiles) fire a chunkier "scatter" report instead of the single-bolt pulse, so a stacked build sounds as big as it hits

### Weapons & Upgrades (22 upgrades)
- **Primary Stats**: Rapid Fire, Power Shot, Fortify, Swift, Multi-Shot, Magnet
- **Weapons**: Railgun (piercing beam), Signal Arrow (homing Yaka-style arrow that darts enemy-to-enemy — faster and harder-hitting each level), Chain Arc, Orbital Guard
- **Combat**: Piercing Rounds, Ricochet, Shatter Point, Critical Surge, Velocity Rounds, Executioner (bonus damage to low-HP enemies with red execution flash), Adrenaline (outgoing damage rises as *your* HP falls — up to +30% near death, a risk/reward boost that pairs with Vampire and dash i-frames)
- **Defense**: Nano Shield (with visible blue shield ring), Regeneration (+0.7 HP/sec per stack, with heal particle VFX), Vampire (1.75 HP lifesteal per kill, up to 3 stacks)
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
- Dynamic soundtrack that rotates across 9 tracks as waves progress — each early/mid-game wave tier you actually spend time in plays a distinct track (rotation centralized so the post-boss music resume always matches the current tier)
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
- Boss entrance sting (ominous low-end stinger announces a boss wave before the music swaps)
- Heavy Multi-Shot volley SFX (chunky scatter report when firing 3+ projectiles at once)
- Golem charge telegraph SFX (low rumble before charge)
- Golem rock throw SFX (distinct deep whoosh, separate from slam)
- Orbital Guard hit SFX (subtle click when orbitals damage enemies)
- Teleporter blink SFX (high-pitched warp sound on teleport)
- Player death SFX (dramatic low-pitched explosion on game over)
- Master mute toggle — press M (or use the pause-menu MUTE button) to silence/restore all audio via the master bus, with an on-screen indicator
- Warrior lunge SFX (impact grunt when warriors charge)
- Victory sting on wave 10/15/20/25 milestones
- Wave clear heal SFX (subtle chime when HP recovers between waves)
- Health pickup chime (bright two-layer chime when grabbing a dropped heal orb)
- 16-channel SFX pool for rich audio layering

### Visual Polish
- Neon cyberpunk aesthetic with bloom, glow, and emissive materials
- Enemy spawn-in scale pop (regular enemies grow in after their warning ring instead of appearing fully-formed on top of you)
- Auto-aim target reticle (spinning cyan bracket marks the locked-on enemy; scales up for bosses)
- Floating ambient neon motes drifting across the arena floor
- Damage vignette (red pulse at low HP), hit flash on damage taken
- Screen flash on critical hits (orange tint)
- Green screen-edge pulse when grabbing a health pickup
- Punchy muzzle flash on every shot (brighter, snaps inward as it fades)
- Enemy hit-pop flares the whole model's glow white on hit (reads clearly even on multi-surface skeletons), then restores to its true resting neon glow
- Cyan Phase Dash trail unified with the dash afterimages, ring, and shockwave
- Speed lines during Phase Dash (radial shader)
- Directional screen shake on impacts and when you take a hit — bounded and hard-capped so dense swarms stay readable (hit-stop slow-mo is intentionally off to keep frame pacing smooth)
- Boss entrance: ominous warning sting + temporary camera zoom-out so you can read the arena
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
- Orbital Guard hit feedback (the orb flares brighter and pulses larger for a moment when it damages an enemy — allocation-free, so it stays cheap under heavy fire)
- Mage/Necromancer bolt trail particles (fading trail behind enemy projectiles)
- Player model damage flash (white flash on hit for clear feedback)
- XP orb spawn burst (orbs pop outward from kills before settling)
- Boss enrage arena red pulse (screen edge throb during enrage phase)
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
- Player shots ricochet and despawn against the *active* arena edge, so Ricochet bounces correctly off the shrunken boss-fight walls instead of passing through them
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
- Build-tinted bolts — your pulse shots shift color with your build (Piercing → white-cyan, Ricochet → lime-green, both → blended) so upgrades read at a glance

### HUD & UI
- HP bar with color shift (cyan → red at low HP), overclock drain indicator
- XP bar with level counter, upgrade count, and a numeric current/next-XP readout so progress to the next upgrade is visible
- Boss HP bar with wave-specific label ("SKELETON GOLEM — WAVE X"), color shift (green → yellow → red), and enrage warning ("ENRAGED" + pulsing red)
- Boss defeat bonus XP announcement
- Live DPS meter, enemy count, survival timer
- Wave announcements with boss wave callouts
- Kill streak and milestone announcements, plus a draining combo-streak timer bar under the banner that shows how long the kill-streak window (and its damage bonus) has left
- No-damage wave indicator
- Pause menu (resume/restart/mute/quit) with a live MUTE/UNMUTE toggle button and an at-a-glance run summary (current wave, kills, and time survived)
- Floating red "-X" damage number above the player when you take a hit, so you can read how hard it landed
- Gold screen-edge flash on big kill-streak milestones (layered on top of the streak banner and rising audio sting)
- Level-up "powered up" world burst — a golden shockwave + spark flare at the player when an upgrade is confirmed
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
- Enhanced death sequence (screen shake, red flash)
- Mini HP bars above elite enemies for target prioritization

### Game Systems
- Wave-based progression with aggressive scaling (enemy contact damage scales with wave); late-game wave sizes use a softened quadratic curve so the highest waves stay intense without becoming a slog
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
- Snappier Phase Dash cooldown (1.5s) for more responsive mobility
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

## Recent Changes

- **Tighter targeting** — dead enemies now leave the targeting pool the instant they die, so auto-aim, the reticle, the railgun, orbitals, and the Signal Arrow no longer waste a beat on corpses; auto-aim also explicitly ignores dying foes.
- **Ultimate respects the boss arena** — the Ultimate's outward knockback is now clamped to the *active* arena bound, so it can't shove enemies (or the boss) through the shrunken boss-fight walls.
- **More music variety** — the gameplay soundtrack rotation lives in one place now (shared by wave changes and the post-boss resume), and the early/mid waves you actually spend time in each get a distinct track instead of repeating one.
- **Enemy spawn-in pop** — regular enemies grow in over a beat after their warning ring instead of appearing fully-formed on top of you (allocation-free, stays cheap in big waves).
- **Punchier streaks & damage readout** — big kill-streak milestones add a gold screen-edge flash, and taking a hit now floats a red "-X" off the player so you can read how hard you got hit.
- **Pause = progress check** — the pause menu shows your current wave, kills, and run time at a glance.
- **Balance** — Multi-Shot's spread tightens as you stack it (more pellets land on target); Regeneration buffed to +0.7 HP/sec per stack.
- **Solo boss duels** — boss waves now clear the regular swarm and lock the fight into a shrunken, walled arena; the golem is faster so it actually chases you in the smaller space.
- **Boss arena containment** — player shots ricochet/despawn against the *active* arena edge, so Ricochet works off the boss walls instead of passing through them.
- **Smoother dense waves** — per-hit projectile VFX is tiered (chip hits = cheap flash, kills = full shockwave + sparks), cutting the heaviest per-frame allocation during big swarms.
- **Restored hit feel** — bounded, hard-capped screen shake is back (including a kick when you take damage); hit-stop slow-mo stays off to keep frame pacing smooth.
- **Audio** — new boss entrance sting, and heavy Multi-Shot volleys (3+ shots) fire a chunky scatter report; wired the Orbital Guard hit feedback back in as a cheap emission/scale pop.
- **Readability** — pulse bolts tint by your build (Piercing / Ricochet); bigger, brighter XP and health pickups.
- **Balance** — Phase Dash cooldown 1.75s → 1.5s; Vampire 1.0 → 1.75 HP/kill; slightly more generous health-orb drops.

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
  upgrade_system.gd  — 22 upgrade definitions
  projectile.gd      — Bullet physics and VFX
  xp_orb.gd          — XP pickup mechanics
  camera_rig.gd      — Camera follow, shake, zoom
  autoload/
    game_state.gd    — Global state and signals
    audio_manager.gd — 16-channel SFX pool + music system
assets/
  audio/sfx/         — Sound effects (OGG)
  audio/music/       — Background music tracks
  models/            — 3D character models (GLB)
  shaders/           — Grid ground shader
```
