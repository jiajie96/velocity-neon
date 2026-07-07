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
- ~~**Boss entrance cinematic**: Brief camera zoom-out + slow-mo + screen flash when boss spawns~~ DONE — camera zooms out + ominous entrance sting on boss spawn (slow-mo dropped to keep frame pacing smooth)

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
- ~~**Upgrade payoff cues**: distinct SFX for Thorns reflect, Executioner finisher, Shatter split~~ DONE — Thorns clangs off the attacker, Executioner kills land a heavy finisher thud, Shatter bolts crack on split
- ~~**Combo lost cue**: audible note when a meaningful kill streak times out~~ DONE — soft descending blip + "COMBO LOST" banner
- ~~**Fire-rate spool-up**: primary-fire pitch climbs as fire rate stacks~~ DONE
- **Positional audio (still pending)**: 3D audio for enemy approach sounds — hear them coming from specific directions

---

## Gameplay Systems

### Combat
- **Weapon types**: Swap between weapon archetypes (railgun, shotgun, laser beam, homing missiles) each with different auto-aim behavior
- ~~**Critical hits**: Random chance for 2x damage with distinct VFX~~ DONE — 10% crit chance, 2x damage, orange CRIT text
- ~~**Combo system**: Rapid kills within time window increase damage multiplier~~ DONE — kill streaks grant an escalating damage bonus (up to +40%) shown live on the streak banner; the streak window is a forgiving 2.5s
- ~~**Ricochet upgrade**: Projectiles bounce off arena boundaries~~ DONE — stackable upgrade (2 levels); bolts phase through enemies and keep bouncing off the walls until their bounces are spent, re-hitting foes on each pass
- ~~**Piercing upgrade**: Projectiles pass through enemies, hitting multiple targets~~ DONE — stackable upgrade (3 levels), damage reduces 25% per pierce
- **Orbital weapons**: Rotating projectiles that orbit the player, damaging on contact
- **Mine layer**: Drop proximity mines during dash trail
- ~~**Hybrid / ability upgrades**~~ DONE (first pass) — **Frenzy** (+15% fire rate & +8% move speed/stack, aggression hybrid) and **Coolant** (−12% Ultimate cooldown/stack, floored) added to the pool for more build variety

### Enemy Variety
- ~~**Skeleton Rogue**: Fast enemy that dodges projectiles by side-stepping~~ DONE — rogues sidestep every ~1.8s
- ~~**Necromancer**: Summons minion skeletons, stays at range. Kill to stop spawns~~ DONE — necromancers maintain distance and summon 2 minions every 5s with purple VFX ring
- **Shield Bearer**: Front-facing shield blocks projectiles — must be hit from behind or with area damage
- ~~**Exploder**: Runs at player and detonates on death/contact for area damage~~ DONE — fast yellow-glowing enemy, detonates on proximity or death with AoE blast VFX, can chain-react with nearby enemies
- ~~**Teleporter**: Blinks to new position periodically, unpredictable movement~~ DONE — teleporters blink every ~2.5s to random positions near the player
- ~~**Healer**: Restores HP to nearby enemies, priority target~~ DONE — hangs back (wave 4+), pulses 14% max-HP heals to up to 3 wounded enemies every 4s with a green ring + shimmer SFX telegraph (heal % trimmed from 18% so packed waves are less of a grind)
- ~~**Elite modifiers**: Random prefix modifiers on enemies (Fast, Armored, Vampiric, Splitting)~~ PARTIAL — a basic gold-marked "Elite" tier exists (wave 6+, small wave-scaling chance): ~1.9× HP, faster, +contact damage, ~2.2× XP, likelier heal drop, larger build + gold rim glow + chevron + always-on HP bar. Elites now also **Split** — every elite bursts into 2 fresh minions on death (capped to the alive-enemy limit; spawned minions are never elite). Elite kills now land distinct feedback too — an extra shake + camera punch and their own weighty death flourish. Other distinct named-prefix effects (Vampiric, Armored, etc.) still pending

### Boss Design
- ~~**Skeleton Golem V2**: Multi-phase fight — phase 1 charges, phase 2 throws rocks, phase 3 enrages~~ PARTIAL — enrage phase implemented (below 30% HP: faster movement, rapid slams, pulsing red glow), plus a halfway-point beat (shake + zoom-kick the first time the boss drops past 50% HP) so the fight has a clear midpoint before enrage
- **Necromancer Lord**: Summons waves, creates projectile barriers, teleports
- **Bone Dragon**: Flies overhead (breaks 2D constraint temporarily), strafes with beam attack
- **Unique boss mechanics**: Each boss should introduce a mechanic the player hasn't seen (dodgeable projectile patterns, safe zones, DPS checks)

### Progression
- **Meta-progression**: Persistent currency earned per run that unlocks permanent upgrades (starting HP, starting speed, new weapon unlocks)
- **Character selection**: Choose between Knight (balanced), Barbarian (melee-focused AOE), Mage (ranged specialist), Rogue (speed/dash specialist)
- **Skill tree**: In-run skill tree branching from upgrade choices — synergies between certain upgrade combinations
- **Artifact system**: Rare drops that provide powerful passive effects for the current run
- **Achievement system**: Track milestones (wave 20 reached, 1000 kills, no-hit wave, etc.)
- ~~**Comeback / anti-death-spiral mechanics**~~ DONE — Last Stand (extra ~15% damage reduction under 20% HP), mercy health-orb drops that scale up as HP falls, a ~10% heal on flawless waves, a small heal on every level-up (~6% max HP) and a ~25% heal after each boss kill so climbing/surviving both buy recovery room, a kill-streak window that stretches while critically wounded so a desperate push can keep its combo, and a Guardian Angel revive that shoves the swarm back to buy recovery room

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
- **Settings screen**: Volume sliders, resolution, fullscreen toggle, VFX quality, camera sensitivity — PARTIAL: master mute toggle (M key, plus a MUTE button in the pause menu) is implemented; full settings still pending
- **Save system**: ~~Save best run stats~~ PARTIAL — best run (deepest wave + kills) persists to disk, shown on title screen with a NEW RECORD banner on game over; unlocked upgrades and settings still pending
- **Run statistics**: ~~Post-run summary (DPS over time, damage taken, upgrades chosen, XP graph)~~ PARTIAL — game over screen shows kills/min, avg DPS, total damage, time survived, performance rating (RECRUIT→LEGENDARY), and full upgrade build summary
- ~~**Minimap**: Optional corner minimap showing enemy positions~~ DONE — corner radar plots the swarm relative to the player (bosses orange, elites gold, off-radar contacts clamp to the edge)
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
- [~] Hit-stop (freeze frame on heavy hits) — later disabled to keep frame pacing smooth in big waves; bounded screen shake now carries impact
- [x] Enemy knockback on hit
- [x] Player weapon flash/muzzle on fire
- [x] XP orb collection burst particles
- [x] Boss enrage juice — camera punch + stronger shake + red shockwave burst on the sub-30% phase change
- [x] Railgun camera punch (zoom-kick recoil on the piercing beam)
- [x] Health-orb pickup camera punch (small zoom-kick on heal)
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
- [x] Orbital Guard hit feedback (allocation-free emission/scale pop; was a per-hit particle spark)
- [x] Enemy death SFX varies by type (unique pitch per enemy)
- [x] Low HP heartbeat audio pulse (rhythmic thump below 25%)
- [x] Mage/Necro bolt trail particles (fading spheres behind enemy projectiles)
- [x] Teleporter blink SFX (warp sound on teleport)
- [x] Player model damage flash (white flash on hit)
- [x] XP orb spawn burst (pop outward before settling)
- [x] Boss enrage arena red pulse (screen edges throb)
- [~] Kill streak slow-mo (brief time-slow on 5+ streaks) — removed when hit-stop was disabled for frame pacing
- [x] Threat-scaled spawn warnings (bigger rings for dangerous types)
- [x] Wave spawn progress HUD counter
- [x] Upgrade stat preview (concrete before/after values)
- [x] Mini HP bars above elite enemies (warriors, mages, necromancers, teleporters)
- [x] Nano Shield visual ring (blue pulse around player when damage reduction active)
- [x] Batched XP pickup text (rapid collection shows combined "+X XP")
- [x] Wave number shown in countdown ("WAVE X IN 2.1s")
- [x] Enhanced death VFX (bigger shake, red flash on death; slow-mo dropped for frame pacing)
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
- [~] Camera punch on player damage — superseded by the bounded directional screen shake on hit
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
- [x] Critical-hit audio ping + extra screen shake so the 10% crit moments land hard (hit-stop dropped for frame pacing)
- [x] Escalating kill-streak chime (pitch climbs at streak milestones 3/5/8/12/16/20/25)
- [x] Green screen-edge flash on health pickup (matches the crit/vampire flash language)
- [x] Phase Dash i-frame grace window — stays invincible briefly past the dash for a reliable escape
- [x] Enemy hit-pop flares the whole model's glow light white on hit (reads on multi-surface skeletons)
- [x] Fixed enemy emission/energy restore so hit and gravity-slowed enemies keep their true resting neon glow (no permanent brightening)
- [x] Punchier muzzle flash (brighter, snaps inward as it fades)
- [x] Unified cyan Phase Dash trail (was clashing orange) to match afterimages, ring, and shockwave
- [x] Wider multi-source damage i-frame window (0.15s -> 0.2s) for fairer hits in dense waves
- [x] Snappier Phase Dash cooldown (2.0s -> 1.75s -> 1.5s) for more responsive core mobility
- [x] Vampire lifesteal tuned (1.5 -> 2.5 -> 1.0 -> 1.75 HP/kill, max 3 stacks)
- [x] Master mute toggle (M key) with on-screen indicator + title-screen control hint
- [x] Pause-menu MUTE / UNMUTE button (mouse access to audio toggle)
- [x] Level-up "powered up" world burst (golden shockwave + sparks at the player on upgrade)
- [x] ADRENALINE upgrade — outgoing damage rises as the player's HP falls (up to +30% near death)
- [x] Ultimate now knocks enemies outward (panic-button "clear space" feel; bosses resist)
- [x] Combo streak timer bar under the streak banner (shows the kill-streak window draining)
- [x] Smoother sustained fire — primary-fire hit-stop now only triggers on kills, not every bullet (no more high-fire-rate slow-motion stutter)
- [x] Hit-stop no longer leaks into the upgrade/pause screen (resets time scale on pause, so upgrade-card animations no longer crawl)
- [x] Health-orb pickup fix — heal orbs now magnetize and heal on contact (were only collectible during their fade-out)
- [x] Softer late-game wave-size scaling for better pacing (quadratic term 0.8 -> 0.6)
- [x] Solo boss duels — boss waves clear the swarm and lock the fight into a shrunken walled arena (faster golem to compensate)
- [x] Tiered per-hit projectile VFX — kills get the full shockwave + spark burst, chip hits get just a cheap light flash (cuts the heaviest per-frame allocation in dense waves)
- [x] Restored bounded directional screen shake (hard-capped) + camera kick when the player takes a hit; hit-stop stays off for frame pacing
- [x] Projectile ricochet/despawn respects the active arena radius (Ricochet now bounces off the boss-fight walls instead of passing through)
- [x] Heavy Multi-Shot volleys (3+ projectiles) fire a chunky scatter SFX instead of the single-bolt pulse
- [x] Orbital Guard hit feedback restored as an allocation-free emission/scale pop (no per-hit particle alloc)
- [x] Boss entrance warning sting before the boss music swaps in
- [x] Build-tinted pulse bolts (Piercing → white-cyan, Ricochet → lime-green, both → blended) for at-a-glance build readability
- [x] Snappier Phase Dash cooldown (1.75s -> 1.5s)
- [x] Vampire lifesteal rebalanced (1.0 -> 1.75 HP/kill)
- [x] Slightly more generous health-orb drops (4%/8% -> 5%/10%)
- [x] Dead enemies leave the targeting group the instant they die (auto-aim, reticle, railgun, orbitals, and Signal Arrow no longer waste a frame on corpses); auto-aim also explicitly skips dying foes
- [x] Ultimate knockback clamps to the *active* arena radius so it can't shove enemies/boss through the shrunken boss-fight walls
- [x] Gameplay music rotation centralized in AudioManager (single source of truth shared by wave changes and the post-boss resume); early/mid wave tiers each get a distinct track instead of repeating the early one
- [x] Enemy spawn-in scale pop — regular enemies grow in after their warning ring (allocation-free; bosses keep their dedicated entrance)
- [x] Gold screen-edge flash on big kill-streak milestones (5/8/12/16/20/25)
- [x] Floating red "-X" damage number above the player on hit (readability for how hard a hit landed)
- [x] Pause menu shows live run stats (current wave / kills / time survived)
- [x] Multi-Shot spread tightens as projectile count grows (stacked Multi-Shot lands more pellets on target)
- [x] Regeneration buffed (0.5 -> 0.7 HP/sec per stack)
- [x] GUARDIAN ANGEL upgrade — one-time per-run death save (fatal hit leaves you at 35% HP + protective burst + brief i-frames)
- [x] GREED upgrade — +20% XP from all sources, stackable to 3
- [x] Ricochet rework — bolts now phase through enemies and keep bouncing off walls until bounces are spent (was near-useless, died on first contact)
- [x] Critical Surge now also scales crit damage (+0.15x per stack on top of +5% crit chance)
- [x] Gravity Well vulnerability — slowed enemies take +18% damage (offensive payoff for the slow)
- [x] Titanium Plating upgrade — +18% max HP & heal per stack (percentage HP that scales into late waves)
- [x] Auto-aim lock range widened (30 -> 40 units) so the gun doesn't go quiet on on-screen foes
- [x] Ultimate base cooldown trimmed (10s -> 8.5s)
- [x] Regeneration buffed (0.9 -> 1.1 HP/sec per stack); Vampire buffed (1.75 -> 2.25 HP/kill)
- [x] Phase Charge also trims dash cooldown (~8% per stack, floor 0.8s)
- [x] Damage-scaled enemy knockback — heavier hits shove enemies further (capped; bosses resist)
- [x] Crit screen-shake escalates with the active kill streak (roadmap shake formula)
- [x] Softer early boss HP curve so wave 5/10 golems aren't a slog
- [x] Bigger base pickup range (3.5 -> 4.2) + sooner XP auto-magnetize (6s -> 4s) so earned XP isn't stranded
- [x] Healer enemy (wave 4+ support — heals nearby wounded enemies, green ring + shimmer telegraph, priority target)
- [x] Upgrade reroll (one per level-up screen — button or R key swaps all three choices)
- [x] Persistent best-run record (title screen shows personal best; gold NEW RECORD banner + sting on game over)
- [x] Hit-knockback clamped to the active arena (heavy hits no longer shove enemies through the walls)
- [x] Guardian Angel HUD badge while the death save is banked
- [x] Pause menu full build stat sheet (DMG / fire rate / proj / crit + DR / regen / lifesteal / XP / Guardian)
- [x] Ultimate damage numbers tinted purple ("ult" weapon hint)
- [x] Perfect wave chime (the no-damage bonus was text-only)
- [x] Railgun stacks also reduce its cooldown (2.0s -> 1.7s -> 1.4s, shown on the upgrade card)
- [x] Shatter Point buff (fragments 40% -> 55% dmg, fly farther, bigger hit radius)
- [x] Golem slam knockback clamps to the *active* arena radius (was hardcoded ±48, shoving the player through the shrunken boss-duel walls); same fix applied to warrior lunge, rogue dodge, and necromancer summon spawns
- [x] Health orbs no longer magnetize/collect at full HP — a heal drop now waits (or fades) instead of being wasted when you don't need it
- [x] Dedicated boss-enrage roar SFX (deep down-pitched pulse + sub thud + snarl) instead of reusing the plain slam sound when the golem drops below 30% HP
- [x] THORNS upgrade — reflect 25%/50% of contact damage back into enemies that touch you (defensive brawler pick, 2 stacks)
- [x] Regeneration buffed (0.7 -> 0.9 HP/sec per stack) to keep pace with rising max HP
- [x] Ultimate "not ready" feedback — pressing Q on cooldown plays a quiet rate-limited denied blip so the input registers
- [x] Ultimate base cooldown trimmed (12s -> 10s, floor ~5s at high level) so the panic button is available a little more often
- [x] Exploder blast damage now falls off with distance (100% at center -> 40% at the edge) so spacing matters and edge clips aren't near-one-shots
- [x] Orbital Guard buffed (8 -> 10 damage, hit cooldown 0.5s -> 0.45s)
- [x] Low-HP danger glow — the player's own light bleeds red and pulses faster below 25% HP, reinforcing the heartbeat audio and damage vignette
- [x] Exploder contact fuse — exploders arm a ~0.45s telegraphed fuse on contact (urgent beep + danger ring) instead of an instant unavoidable blast; killing one still detonates it (chain reactions preserved)
- [x] GIANT SLAYER upgrade — +22% damage to bosses per stack (×3) so under-geared builds can still close out a long golem fight
- [x] SCAVENGER upgrade — health orbs drop more often (×0.6/stack) and heal more (+25%/stack), a sustain pick for long runs (×2 stacks)
- [x] Elite enemy variant (wave 6+) — gold-marked tougher/higher-value enemies as priority/reward targets
- [x] Dash-strike feedback — Phase Dash carving through a pack lands a meaty thud + small camera kick the first time it connects each dash
- [x] Phase Dash i-frame grace bumped 0.1s → 0.15s for more reliable escapes
- [x] Orbital Guard orbs now cast a small glow light so the defensive ring reads on the dark floor
- [x] Health orbs auto-magnetize after a few seconds when you're below max HP, so a stray heal isn't stranded
- [x] Ultimate also vacuums loose XP/health orbs (panic clear doubles as a reward collect)
- [x] Softer late-game wave-size curve (quadratic term 0.6 → 0.45) so deep runs stay punchy without a kill grind
- [x] PHASE BLADES upgrade — +80%/stack Phase Dash carve damage + a wider carve radius (×2), a real payoff for a dash-centric build
- [x] Camera zoom-punch wired up (was dormant dead code) — quick kick on Ultimate, boss defeat, and Guardian Angel save
- [x] Kill-streak world burst — gold shockwave + sparks at the player on streak milestones (10/15/20/25), plus a camera punch
- [x] Green heal flash on the player when HP rises (orb pickup / Fortify / wave-clear / Guardian); 3-HP threshold skips the regen trickle so it doesn't strobe
- [x] Urgent low-HP locator beacon — the gold chevron bleeds red and bobs faster below 25% HP
- [x] Audible spawn-warning blip for dangerous types (necro/exploder/teleporter/healer/golem), rate-limited, lower-pitched for the heaviest threats
- [x] Signal Arrow cadence scales with level (1.6s → ~1.3s → ~1.1s), matching the Railgun cadence treatment
- [x] Ultimate blast radius scales gently with level (capped) so the panic button stays relevant in dense late waves
- [x] Per-instance enemy speed jitter (±10%) so a swarm reads as individuals instead of a lockstep grid
- [x] Vampire lifesteal world spark — rate-limited green pop above the player when a lifesteal heal lands
- [x] Fixed Titanium Plating upgrade card preview (the `bulwark` stat-preview arm was mis-indented dead code, so the card silently fell back to the generic description instead of the concrete HP before/after)
- [x] Ultimate grants a brief i-frame window on cast (0.55s) so the panic button can actually save a surrounded player; only applied when not already invincible so it can't cut a wave-clear window short
- [x] Ultimate base cooldown trimmed (8.5s -> 8.0s)
- [x] Priority-target reticle tint — the auto-aim reticle bleeds green on a healer / purple on a necromancer so the player learns to focus supports
- [x] Build-tinted muzzle flash (Piercing -> white-cyan, Ricochet -> lime-green, both -> blended) to match the bolt palette
- [x] Ricochet wall-bounce spark — each wall bounce flashes + spark-bursts + a tiny shake so the ricochet reads instead of silently turning
- [x] Perfect (no-damage) wave clear lands a camera punch + shake on top of the chime/banner
- [x] Wave-start horn pitch climbs gently with wave depth (audible escalation)
- [x] Gentler first-two-wave onboarding (16 / 20 enemies) so a fresh run with base stats isn't an instant wall; mid/late scaling untouched
- [x] XP-orb spawn burst clamps to the *active* arena radius so a kill's orbs don't fling out past the shrunken boss-fight walls
- [x] Level-up lands a camera punch + light shake so a new level reads as a tactile power spike, not just a screen flash
- [x] Kill-streak combo damage ceiling raised (+24% -> +30%, slightly steeper per-kill ramp) so deep streaks matter more
- [x] No-damage wave bonus XP buffed (20 + 5×wave -> 25 + 6×wave) to better reward flawless aggressive play
- [x] Phase Dash base cooldown trimmed (1.5s -> 1.4s) for snappier mobility
- [x] Post-hit i-frame window widened (0.20s -> 0.25s) so a tight swarm stacks fewer simultaneous hits
- [x] Snappier XP-orb collection (magnet speed 12 -> 15, auto-magnet delay 4s -> 3s) so earned XP isn't left lying around mid-fight
- [x] Wounded players pull heal orbs in faster and sooner (magnet speed 10 -> 13, auto-magnet delay 5s -> 3.5s)
- [x] Ultimate panic i-frame window lengthened (0.4s -> 0.55s) so the escape is reliable even at low frame times
- [x] Laser bolt size scales with damage (clamped) so a stacked Power Shot build fires visibly chunkier, longer bolts
- [x] Gravity Well vulnerability bumped (+18% -> +25% damage on slowed enemies) so the slow field has a stronger offensive payoff

- [x] Corner minimap radar (player-centered; bosses orange, elites gold, off-radar contacts clamp to the edge)
- [x] Splitting elites — a slain gold elite bursts into 2 fresh minions (capped to the alive limit; minions are never elite, so no runaway)
- [x] Health-orb pickup grants a brief 0.5s i-frame window (clutch heal in a swarm isn't instantly re-eaten)
- [x] Fixed Regeneration to grant the +1.3 HP/sec its card promised (was a silent +1.1); Vampire to +2.5 HP/kill (was +2.25)
- [x] Base crit chance raised (10% -> 12%); Executioner window widened (sub-30% -> sub-35% HP)
- [x] Ultimate base cooldown trimmed (7.5s -> 7.0s); base pickup range bumped (4.2 -> 4.6); faster first level-up (80 -> 70 XP)
- [x] Rate-limited primary-fire + per-hit impact SFX so a high-fire-rate/Multi-Shot build no longer floods and starves the 16-voice SFX pool (crit/death/streak cues stay audible)
- [x] Fixed Signal Arrow fizzling — seek range 32 -> 42 to match the 40u auto-aim lock (arrows fired at a 33-40u target no longer find nothing and despawn instantly); arrow despawn bound now respects the active (boss) arena radius
- [x] Softened the wave-3 difficulty spike (~30 enemies instead of 40) so the first full-scaling wave isn't a wall; between-wave breathing-room invuln extended (1.0s -> 1.2s)
- [x] Auto-aim reticle priority tints — orange-red on exploders (kill before the fuse), gold on elites (high-value splitting target), on top of the existing healer/necro tints
- [x] Orbital Guard base damage 10 -> 12; Chain Arc reach 8.0 -> 9.5 for more reliable chaining
- [x] Ultimate SFX gets a low-end sub-boom layer; level-up chime pitch climbs gently with level for a more triumphant deep run
- [x] Boss HP bar numeric readout (live "cur / max HP" alongside the % so a boss fight reads as a DPS check)
- [x] Wave 30 "APEX" milestone banner + victory sting (deep runs past MYTHIC were previously unmarked)
- [x] Game-over "APEX" top performance tier for reaching wave 30+
- [x] Guardian Angel HUD save banner (bright "★ GUARDIAN ANGEL — SAVED ★" callout + cyan flash when the death-save triggers, so it isn't missed in the chaos)
- [x] Overkill finisher SFX (a deep "obliterated" thud when a killing blow massively overshoots an enemy's HP, layered on the existing bigger death pop; rate-limited)
- [x] Kill-streak audio sting extended to a 30-kill milestone (matches the existing 30-streak world burst)
- [x] Pause menu shows saved best run + an "ON PACE FOR A RECORD" flag when the current run is beating it
- [x] Card clarity fixes — Vampire reads its true +3 HP/kill, Executioner spells out its "under 35% HP" window, and Coolant's preview shows the real multiplicative (floored) cooldown reduction instead of a misleading flat number

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