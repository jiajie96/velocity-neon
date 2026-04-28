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
- **Boss entrance cinematic**: Brief camera zoom-out + slow-mo + screen flash when boss spawns

### Screen Effects
- **Screen shake refinement**: Implement directional shake (bias toward damage source direction), not just random offset
- **Damage vignette**: Red pulsing edges when HP < 30%
- **Speed lines**: Radial blur/streak overlay during dash
- **Kill streak effects**: Escalating visual intensity (more glow, faster grid pulse) during rapid kill streaks

### Audio
- **Dynamic soundtrack**: Music layers that add/remove instruments based on intensity (enemy count, wave number, HP level)
- **Positional audio**: 3D audio for enemy approach sounds — hear them coming from specific directions
- **Hit confirmation sounds**: Distinct SFX for regular hit, critical hit, shatter split, kill confirm
- **Boss music**: Dedicated intense track for boss waves (every 5th)
- **Ambient neon hum**: Low background drone that changes pitch with player HP
- **UI sounds**: Click, hover, upgrade selection, wave start horn, level-up chime

---

## Gameplay Systems

### Combat
- **Weapon types**: Swap between weapon archetypes (railgun, shotgun, laser beam, homing missiles) each with different auto-aim behavior
- **Critical hits**: Random chance for 2x damage with distinct VFX
- **Combo system**: Rapid kills within time window increase damage multiplier
- **Ricochet upgrade**: Projectiles bounce off arena boundaries
- **Piercing upgrade**: Projectiles pass through enemies, hitting multiple targets
- **Orbital weapons**: Rotating projectiles that orbit the player, damaging on contact
- **Mine layer**: Drop proximity mines during dash trail

### Enemy Variety
- **Skeleton Rogue**: Fast enemy that dodges projectiles by side-stepping
- **Necromancer**: Summons minion skeletons, stays at range. Kill to stop spawns
- **Shield Bearer**: Front-facing shield blocks projectiles — must be hit from behind or with area damage
- **Exploder**: Runs at player and detonates on death/contact for area damage
- **Teleporter**: Blinks to new position periodically, unpredictable movement
- **Healer**: Restores HP to nearby enemies, priority target
- **Elite modifiers**: Random prefix modifiers on enemies (Fast, Armored, Vampiric, Splitting)

### Boss Design
- **Skeleton Golem V2**: Multi-phase fight — phase 1 charges, phase 2 throws rocks, phase 3 enrages
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
- **Pause menu**: Full pause with resume/restart/settings/quit
- **Settings screen**: Volume sliders, resolution, fullscreen toggle, VFX quality, camera sensitivity
- **Save system**: Save best run stats, unlocked upgrades, settings
- **Run statistics**: Post-run summary (DPS over time, damage taken, upgrades chosen, XP graph)
- **Minimap**: Optional corner minimap showing enemy positions
- **Damage numbers**: Floating damage text above enemies on hit

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
- **Dynamic zoom**: Camera auto-zooms based on nearest enemy distance — zooms in for close combat, out when enemies approach from distance
- **Trauma system**: Replace simple shake with trauma-based system (trauma value decays, drives both shake magnitude and rotation)
- **Slow-motion**: Brief 0.1s slow-mo on kill streaks (every 10th kill) or big explosions

### Juice Checklist
- [ ] Hit-stop (freeze frame 1-2 frames on heavy hits)
- [ ] Enemy knockback on hit
- [ ] Player weapon flash/muzzle on fire
- [x] XP orb collection burst particles
- [ ] Level-up screen flash + brief invincibility
- [x] Boss HP bar (separate from wave UI)
- [ ] Kill streak counter with escalating announcements ("DOUBLE KILL", "UNSTOPPABLE")
- [ ] After-image effect during dash (translucent copies of player)
- [ ] Weapon glow intensity scales with fire rate

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
