# VELOCITY NEON: HAPTIC HAVOC — Future Improvements

## Controls & Input

### Trackpad-Native Input
- **Raw trackpad gesture integration**: Use macOS IOKit/MultitouchSupport framework via GDExtension to read raw multi-finger gestures (pinch, rotate, 3-finger swipe) instead of mapping to keyboard/mouse events
- **Force Touch support**: Detect pressure levels from Apple Force Touch trackpad — light press for auto-fire, deep press triggers Ultimate ability. Requires native macOS plugin
- **Haptic feedback via Taptic Engine**: Use `NSHapticFeedbackManager` through GDExtension to pulse the trackpad on:
  - Damage taken (heartbeat pattern at low HP)
  - Heavy weapon recoil per shot
  - Explosion impact waves
  - Level-up confirmation pulse
- **Gesture-based movement mode**: Alternative to WASD — single-finger drag on trackpad sets movement vector relative to finger start position (virtual joystick). Toggleable in settings
- **Two-finger aim sweep**: Override auto-aim with two-finger rotation gesture for manual directional control

### Controller Support
- Full gamepad mapping (left stick = move, right stick = aim override, triggers = dash/ultimate)
- Aim assist tuning for analog sticks
- Rumble feedback mirroring trackpad haptics

### Accessibility
- Remappable controls
- One-handed mode (auto-move toward enemies, player only controls dash/ultimate)
- Auto-fire toggle (already implemented) with visual indicator
- Colorblind palette options (deuteranopia, protanopia, tritanopia)

---

## Visual & Audio Polish

### Neon Aesthetic Enhancements
- **HDR bloom spikes**: Brief screen brightness pulse on level-up explosions using Godot's Environment glow_hdr_luminance modulation
- **Neon color bleeding**: Post-process shader that makes bright emissive edges bleed into neighboring pixels (chromatic aberration on hit)
- **Trail rendering**: GPU-based trail meshes behind player during dash instead of discrete sphere particles. Use `ImmediateMesh` or trail shader for smooth ribbons
- **Particle system upgrade**: Replace MeshInstance3D death VFX with GPUParticles3D for higher fidelity — sparks, embers, neon dust clouds
- **Enemy dissolve shader**: On death, enemies dissolve in a scan-line pattern (top-to-bottom) with emissive edge glow before disappearing
- **Ground grid reactive pulse**: Grid lines brighten/ripple outward from impact points (projectile hits, explosions, dash origin)
- ~~**Boss entrance cinematic**: Brief camera zoom-out + slow-mo + screen flash when boss spawns~~ DONE — camera zooms out temporarily on boss spawn with slow-mo

### Screen Effects
- ~~**Screen shake refinement**: Implement directional shake (bias toward damage source direction)~~ DONE — gentle 40% intensity directional shake
- ~~**Damage vignette**: Red pulsing edges when HP < 30%~~ DONE
- ~~**Speed lines**: Radial blur/streak overlay during dash~~ DONE — shader-based radial lines during Phase Dash
- ~~**Kill streak effects**~~ Removed per rebalance — may revisit

### Audio
- ~~**Dynamic soundtrack**~~ PARTIAL — music rotates between 4 tracks as waves progress
- ~~**Dash ready audio cue**: Subtle sound when dash cooldown completes~~ DONE — pitch-shifted ready ping on cooldown complete
- ~~**Ultimate ready audio cue**: Sound when ultimate cooldown completes~~ DONE — pitch-shifted ready ping
- ~~**Necromancer summon SFX**: Audio when necromancer spawns minions~~ DONE — eerie pulse sound
- ~~**Golem charge SFX**: Audio telegraph for boss charge~~ DONE — low rumble before charge
- ~~**Enemy projectile bounds cleanup**: Mage/necro bolts and golem rocks now despawn at arena edges~~ DONE
- **Positional audio**: 3D audio for enemy approach sounds — hear them coming from specific directions
- ~~**Hit confirmation sounds**: Distinct SFX for regular hit, critical hit, shatter split, kill confirm~~ DONE — weapon-specific hit impact SFX (railgun, scatter, chain, pulse each have unique sounds)
- **Boss music**: ~~Dedicated intense track for boss waves (every 5th)~~ DONE — cyberpunk_battle for early bosses, epic_boss for wave 10+
- ~~**Ambient neon hum**: Low background drone that changes pitch with player HP~~ DONE — hum shifts pitch and volume based on HP ratio
- **UI sounds**: ~~Click, hover, upgrade selection, wave start horn, level-up chime~~ DONE — all wired up including hover SFX on upgrade cards

---

## Gameplay Systems

### Combat
- **Weapon types**: Swap between weapon archetypes (railgun, shotgun, laser beam, homing missiles) each with different auto-aim behavior
- ~~**Critical hits**: Random chance for 2x damage with distinct VFX~~ DONE — 10% crit chance, 2x damage, orange CRIT text
- ~~**Combo system**: Rapid kills within time window increase damage multiplier~~ DONE — kill streaks grant an escalating damage bonus (up to +24%) shown live on the streak banner
- ~~**Ricochet upgrade**: Projectiles bounce off arena boundaries~~ DONE — stackable upgrade (2 levels), bounces off arena walls and can re-hit enemies
- ~~**Piercing upgrade**: Projectiles pass through enemies, hitting multiple targets~~ DONE — stackable upgrade (3 levels), damage reduces 25% per pierce
- **Orbital weapons**: Rotating projectiles that orbit the player, damaging on contact
- **Mine layer**: Drop proximity mines during dash trail

### Enemy Variety
- ~~**Skeleton Rogue**: Fast enemy that dodges projectiles by side-stepping~~ DONE — rogues sidestep every ~1.8s
- ~~**Necromancer**: Summons minion skeletons, stays at range. Kill to stop spawns~~ DONE — necromancers maintain distance and summon 2 minions every 5s with purple VFX ring
- **Shield Bearer**: Front-facing shield blocks projectiles — must be hit from behind or with area damage
- ~~**Exploder**: Runs at player and detonates on death/contact for area damage~~ DONE — fast yellow-glowing enemy, detonates on proximity or death with AoE blast VFX, can chain-react with nearby enemies
- ~~**Teleporter**: Blinks to new position periodically, unpredictable movement~~ DONE — teleporters blink every ~2.5s to random positions near the player
- **Healer**: Restores HP to nearby enemies, priority target
- **Elite modifiers**: Random prefix modifiers on enemies (Fast, Armored, Vampiric, Splitting)

### Boss Design
- ~~**Skeleton Golem V2**: Multi-phase fight — phase 1 charges, phase 2 throws rocks, phase 3 enrages~~ PARTIAL — enrage phase implemented (below 30% HP: faster movement, rapid slams, pulsing red glow)
- **Necromancer Lord**: Summons waves, creates projectile barriers, teleports
- **Bone Dragon**: Flies overhead (breaks 2D constraint temporarily), strafes with beam attack
- **Unique boss mechanics**: Each boss should introduce a mechanic the player hasn't seen (dodgeable projectile patterns, safe zones, DPS checks)

### Progression
- **Meta-progression**: Persistent currency earned per run that unlocks permanent upgrades (starting HP, starting speed, new weapon unlocks)
- **Character selection**: Choose between Knight (balanced), Barbarian (melee-focused AOE), Mage (ranged specialist), Rogue (speed/dash specialist)
- **Skill tree**: In-run skill tree branching from upgrade choices — synergies between certain upgrade combinations
- **Artifact system**: Rare drops that provide powerful passive effects for the current run
- **Achievement system**: Track milestones (wave 20 reached, 1000 kills, no-hit wave, etc.)

### Map & Environment
- **Map collapse mechanic**: Every 5 waves, arena shrinks (walls close in), forcing tighter play. Pinch-to-zoom out to see new boundaries
- **Environmental hazards**: Lava cracks, electric fences, moving laser barriers on the ground
- **Destructible cover**: Pillars/walls that provide temporary cover but break after taking damage
- **Biome themes**: Every 10 waves transitions to new visual theme (Neon City → Cyber Dungeon → Digital Void → Neural Core)
- **Procedural arena modifiers**: Random arena mutations per wave (narrow corridors, scattered obstacles, moving platforms)

---

## Performance & Technical

### Optimization
- **MultiMeshInstance3D**: Convert enemy rendering to MultiMesh for 500+ enemy support (currently individual Node3D per enemy)
- **Object pooling**: Pre-allocate projectiles, XP orbs, and VFX nodes instead of creating/destroying each frame
- **LOD system**: Reduce mesh detail for distant enemies
- **Spatial partitioning**: Grid-based spatial hash for nearest-enemy queries instead of iterating all enemies
- **Batch draw calls**: Combine enemy meshes sharing the same material
- **GPU particles**: Replace CPU-side VFX with GPUParticles3D

### Quality of Life
- ~~**Pause menu**: Full pause with resume/restart/settings/quit~~ DONE
- **Settings screen**: Volume sliders, resolution, fullscreen toggle, VFX quality, camera sensitivity
- **Save system**: Save best run stats, unlocked upgrades, settings
- **Run statistics**: ~~Post-run summary (DPS over time, damage taken, upgrades chosen, XP graph)~~ PARTIAL — game over screen shows kills/min, avg DPS, total damage, time survived, performance rating (RECRUIT→LEGENDARY), and full upgrade build summary
- **Minimap**: Optional corner minimap showing enemy positions
- ~~**Damage numbers**: Floating damage text above enemies on hit~~ DONE

### Networking
- **Leaderboard**: Online high score (waves survived, kills, time)
- **Co-op mode**: 2-player split-screen or online co-op on same arena
- **Daily challenge**: Seeded daily run with preset modifiers

---

## Platform & Distribution

### macOS Optimization
- **Metal renderer**: Ensure Godot uses Metal backend for Apple Silicon GPUs
- **Native fullscreen**: Proper macOS fullscreen with menu bar integration
- **App bundle signing**: Notarized .app for distribution outside App Store
- **Mac App Store**: Proper sandboxing and entitlements for App Store submission

### Cross-Platform
- **iOS/iPadOS port**: Touch controls with virtual joystick, works on iPad with trackpad
- **Steam Deck**: Verified controller layout, 800p optimization
- **Web export**: HTML5 export for browser play (itch.io)
- **Android**: Touch controls adaptation

---

## Polish & Juice

### Screen Shake Formula Enhancement
Current: `S = α · log₁₀(D + 1)`
Improved: `S = α · log₁₀(D + 1) · (1 + combo_multiplier × 0.1)` where combo_multiplier rises with kill streak

### Camera Improvements
- ~~**Dynamic zoom**: Camera auto-zooms based on nearest enemy distance — zooms in for close combat, out when enemies approach from distance~~ DONE — gentle dynamic zoom nudges based on nearest enemy
- **Trauma system**: Replace simple shake with trauma-based system (trauma value decays, drives both shake magnitude and rotation)
- **Slow-motion**: Brief 0.1s slow-mo on kill streaks (every 10th kill) or big explosions

### Juice Checklist
- [x] Hit-stop (freeze frame 1-2 frames on heavy hits)
- [x] Enemy knockback on hit
- [x] Player weapon flash/muzzle on fire
- [x] XP orb collection burst particles
- [x] Level-up screen flash + brief invincibility
- [x] Boss HP bar (separate from wave UI)
- [x] Floating damage numbers (color-coded, big hit scaling)
- [x] Low HP danger vignette (red pulsing screen edges)
- [x] Kill streak counter with escalating announcements ("TRIPLE KILL", "MULTI KILL", "KILLING SPREE", "RAMPAGE", "UNSTOPPABLE")
- [x] After-image effect during dash (translucent copies of player)
- [x] Weapon glow intensity scales with fire rate
- [x] Wave clear announcement ("WAVE CLEAR" text between waves)
- [x] Wave start screen pulse (purple flash on new wave)
- [x] Vampire lifesteal VFX (green flash feedback)
- [x] Kill milestone announcements (100, 250, 500, 1000 kills)
- [x] Golem slam telegraph (warning ring before damage)
- [x] Exploder chain reaction hit-stop
- [x] Nano Shield defensive upgrade (damage reduction)
- [x] Necromancer bolt telegraph (purple charge glow)
- [x] Boss defeat bonus XP announcement
- [x] Overclock HP drain warning (pulsing red HP bar)
- [x] Regeneration heal particles (green sparkles)
- [x] XP orb lifetime fade-out (prevents late-game buildup)
- [x] Enemy spawn cap (throttle at 100 alive)
- [x] Enhanced projectile trails at high speed
- [x] Mage and necromancer speed scaling with wave
- [x] Ultimate ready audio cue
- [x] Necromancer summon SFX
- [x] Golem charge telegraph SFX
- [x] Teleporter blink-scatter death VFX
- [x] XP magnet pulse on boss defeat
- [x] Ultimate damage scales with player upgrades
- [x] Enemy contact damage scales with wave
- [x] Overclock self-damage doesn't break perfect wave bonus
- [x] Game over screen shows damage taken and upgrade count
- [x] Kill milestone celebratory SFX
- [x] Overclock pulsing player glow (red/orange light shift)
- [x] Gravity Well visible radius ring (purple pulse)
- [x] Rogue dodge ghost trail (translucent afterimage)
- [x] Scatter + Chain Arc synergy (pellets now chain)
- [x] Dash damage scales with player speed (Swift upgrade reward)
- [x] Orbital Guard hit spark VFX (green flash on hit)
- [x] Enemy death SFX varies by type (unique pitch per enemy)
- [x] Low HP heartbeat audio pulse (rhythmic thump below 25%)
- [x] Mage/Necro bolt trail particles (fading spheres behind enemy projectiles)
- [x] Teleporter blink SFX (warp sound on teleport)
- [x] Player model damage flash (white flash on hit)
- [x] XP orb spawn burst (pop outward before settling)
- [x] Boss enrage arena red pulse (screen edges throb)
- [x] Kill streak slow-mo (brief time-slow on 5+ streaks)
- [x] Threat-scaled spawn warnings (bigger rings for dangerous types)
- [x] Wave spawn progress HUD counter
- [x] Upgrade stat preview (concrete before/after values)
- [x] Mini HP bars above elite enemies (warriors, mages, necromancers, teleporters)
- [x] Nano Shield visual ring (blue pulse around player when damage reduction active)
- [x] Batched XP pickup text (rapid collection shows combined "+X XP")
- [x] Wave number shown in countdown ("WAVE X IN 2.1s")
- [x] Enhanced death VFX (bigger shake, slow-mo, red flash on death)
- [x] Overclock burnout death message (distinct game over title)
- [x] Golem charge end impact VFX (ground slam ring when charge stops)
- [x] Boss speed scales with wave (late-game golems are faster)
- [x] Player death SFX (dramatic explosion on game over)
- [x] Wave heal SFX (chime on between-wave HP recovery)
- [x] XP orb magnetize glow (brighter emission when pulled)
- [x] Ultimate ready screen flash (purple pulse when ult is ready)
- [x] Weapon-colored damage numbers (railgun blue, scatter orange, chain cyan)
- [x] Boss enrage dust trail (red particles behind enraged golem)
- [x] Level-up invincibility shield ring (cyan ring during post-upgrade i-frames)
- [x] Best kill streak shown on game over screen
- [x] Title screen neon color cycle animation
- [x] Scatter + Chain Arc synergy fix (pellets now properly chain to nearby enemies)
- [x] Title screen ambient music (neon_runner.mp3)
- [x] Defeat music on game over
- [x] neon_runner.mp3 in mid-game music rotation (wave 15+)
- [x] Golem enraged 3-rock spread throw pattern
- [x] Rogue dodge frequency scales with wave
- [x] Brief invulnerability on wave clear (1s breathing room)
- [x] Enhanced boss defeat gold flash + punch-in text
- [x] Enemy kills tracked by type for game over breakdown
- [x] Game over shows enemy kill breakdown and total XP earned
- [x] Warrior lunge attack (short burst charge when close to player)
- [x] Executioner upgrade (bonus damage to enemies below 30% HP)
- [x] Capped mage/necro bolt damage scaling (prevents one-shots in late waves)
- [x] XP magnet pulse on exploder chain reactions
- [x] Big XP batch collection SFX (chime on mass orb pickup)
- [x] Game over shows wave reached prominently at top
- [x] All weapon upgrades show concrete stat previews
- [x] XP orb batch state properly resets between runs
- [x] Longer first-wave startup delay (1.2s breathing room)
- [x] Warrior lunge SFX (impact grunt on charge)
- [x] Warrior lunge ground dust VFX (red particles on landing)
- [x] Dash-colored damage numbers (cyan for dash hits)
- [x] Boss HP bar color shift (green→yellow→red as HP drops)
- [x] Ultimate cooldown shows seconds remaining instead of percentage
- [x] Gravity Well purple tint on slowed enemies
- [x] Scatter shot cone flash VFX (brief orange cone on fire)
- [x] Average time per wave shown on game over stats
- [x] Wave clear shows XP orb vacuum count
- [x] Victory sting on wave 10/15/20/25 milestones
- [x] Camera punch on player damage (directional camera kick on hit)
- [x] Warrior lunge cooldown scales with wave (faster lunges in late game)
- [x] Warrior lunge emission properly resets after attack
- [x] Executioner red flash on low-HP kills (distinct from crit flash)
- [x] Floating ambient neon motes across arena floor
- [x] 16-channel SFX pool (up from 12 for richer audio layering)
- [x] Dash count shown on game over screen
- [x] Exploder detonation damage scales with wave progression
- [x] Wave clear heal scales with max HP (rewards Fortify investment)
- [x] Mage retreat position clamped to arena bounds (prevents OOB drift)
- [x] Necromancer retreat position clamped to arena bounds
- [x] Golem slam knockback clamps player inside arena walls
- [x] Golem charge knockback with arena boundary clamping
- [x] Warrior lunge deals contact damage with knockback on hit
- [x] Teleporter blink frequency scales with wave progression
- [x] Exploder chain reaction lightning arc VFX between chained explosions
- [x] Golem rock throw fiery trail particles
- [x] XP bar golden glow pulse on level-up
- [x] Wave milestone banners at waves 10/15/20/25 (VETERAN/ELITE/LEGENDARY/MYTHIC)
- [x] Warrior lunge contact damage with knockback on impact
- [x] Exploder detonation radius danger ring (pulsing visual telegraph)
- [x] Mage strafing orbit movement (circles player instead of standing idle)
- [x] Boss HP bar shows wave-specific label ("SKELETON GOLEM — WAVE X")
- [x] Boss wave dramatic red flash + screenshake on announcement
- [x] Velocity Rounds visual scaling (thicker/brighter trails at high speed)
- [x] Distinct golem rock throw SFX (separate from slam sound)
- [x] Damage i-frame visual indicator (cyan ring flash on hit)
- [x] Golem rock throw ground target indicator (red circle where rock is aimed)
- [x] Wave announcement text scales with wave progression
- [x] Game over power level summary (GEARING UP/ARMED UP/FULLY LOADED/MAXED OUT)
- [x] Health pickup drops (enemies can drop heal orbs; elites likelier, bosses guaranteed; heal scales with max HP)
- [x] Auto-aim target reticle (spinning cyan bracket on the locked-on enemy, scales up for bosses)
- [x] Kill-streak combo damage bonus (escalating, shown on the streak banner)
- [x] Multi-level-up from big XP gains now grants every earned upgrade instead of banking the overflow
- [x] XP orbs auto-magnetize after a few seconds + longer lifetime so XP isn't lost in chaos
- [x] Post-boss music resumes the wave-appropriate track instead of always the early track
- [x] Boss entrance zoom-out now returns to the player's current zoom (respects scroll during the intro)
- [x] Player damage-flash restores the model's original emission instead of permanently recoloring it
- [x] XP bar numeric current/next-XP readout on the HUD
- [x] Title screen controls completeness (Scroll = Zoom, 1/2/3 = Pick upgrade) + version tag
- [x] Empty-upgrade-pool guard (resumes instead of soft-locking when every upgrade is maxed)
- [x] Critical-hit audio ping + extra hit-stop/shake so the 10% crit moments land hard
- [x] Escalating kill-streak chime (pitch climbs at streak milestones 3/5/8/12/16/20/25)
- [x] Green screen-edge flash on health pickup (matches the crit/vampire flash language)
- [x] Phase Dash i-frame grace window — stays invincible briefly past the dash for a reliable escape
- [x] Enemy hit-pop flares the whole model's glow light white on hit (reads on multi-surface skeletons)
- [x] Fixed enemy emission/energy restore so hit and gravity-slowed enemies keep their true resting neon glow (no permanent brightening)
- [x] Punchier muzzle flash (brighter, snaps inward as it fades)
- [x] Unified cyan Phase Dash trail (was clashing orange) to match afterimages, ring, and shockwave
- [x] Wider multi-source damage i-frame window (0.15s -> 0.2s) for fairer hits in dense waves
- [x] Snappier Phase Dash cooldown (2.0s -> 1.75s) for more responsive core mobility
- [x] Vampire lifesteal tuned for late game (1.5 -> 2.5 HP/kill, max 2 -> 3 stacks)

---

## Content Roadmap

### V0.2 — Audio & Polish
- Add SFX for all actions (shoot, hit, kill, dash, level-up, wave start)
- Add background music with intensity layers
- Implement GPUParticles3D for death and hit effects
- Boss HP bar UI
- Damage numbers

### V0.3 — Enemy Variety
- Add Skeleton Rogue and Necromancer enemies
- Add elite enemy modifiers
- Multi-phase Golem boss fight
- Arena shrink mechanic

### V0.4 — Meta-Progression
- Character selection (Knight, Barbarian, Mage, Rogue)
- Persistent currency + permanent upgrades
- Run statistics screen
- Settings menu

### V0.5 — Trackpad Native
- GDExtension for macOS trackpad gestures
- Haptic feedback integration
- Force Touch ability triggers
- Gesture-based movement mode option

### V1.0 — Release
- All 4 biome themes
- 4+ boss types with unique mechanics
- Full achievement system
- Leaderboards
- Steam/App Store ready