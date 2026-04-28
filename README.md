# VELOCITY NEON: HAPTIC HAVOC

A neon cyberpunk survivor game built with **Godot 4.6** — optimized for MacBook trackpad.

![Godot 4.6](https://img.shields.io/badge/Godot-4.6-blue?logo=godotengine)
![GDScript](https://img.shields.io/badge/Language-GDScript-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## About

3D world with 2D degrees of freedom — characters move on the XZ plane while the camera looks down at a ~55° angle. Survive endless waves of skeleton enemies, collect XP, level up, and choose upgrades to build an overpowered loadout.

## Controls

| Input | Action |
|-------|--------|
| **WASD / Arrows** | Move on the neon grid |
| **Auto-Aim** | Always targets nearest enemy |
| **Space** | Phase Dash — invincible + fire trail |
| **Q** | Ultimate — area damage burst |
| **Scroll Wheel** | Zoom camera in/out |
| **R** | Restart (game over) |
| **ESC** | Restart (game over) / Quit |

## Features

### Combat
- **Auto-aim targeting** — always locks onto the nearest enemy
- **4 weapon systems** — Pulse Cannon (default), Railgun (piercing beam), Scatter Shot (shotgun cone), Chain Arc (bouncing lightning), Orbital Guard (orbiting damage spheres)
- **Phase Dash** — invincibility frames with a fire trail that damages enemies
- **Ultimate Ability** — area-of-effect burst with screen shake and hit-stop

### Enemies
Six enemy types, each with a unique 3D model and neon glow:
- **Minion** — basic skeleton, low HP, moderate speed
- **Warrior** — armored, slow, high HP
- **Mage** — ranged specialist, purple glow
- **Rogue** — fast and agile, green glow
- **Necromancer** — tanky caster, appears in later waves
- **Golem** (Boss) — massive, spawns every 5th wave

### Progression
- Kill enemies to drop **XP orbs**
- Level up to choose **1 of 3 random upgrades**
- Upgrades include: fire rate, damage, max HP, move speed, projectile count, magnet range, HP regen, shatter-point, gravity well, overclock, and all 4 weapon unlocks

### Visuals & Audio
- **Neon cyberpunk aesthetic** — dark ground with animated grid shader, emissive materials, bloom/glow post-processing
- **Screen shake** with logarithmic scaling: `S = α · log₁₀(D + 1)`
- **Hit-stop** — brief time freeze on heavy hits for impact feel
- **Directional camera shake** — biased toward damage source
- **Boss HP bar** — dedicated top-center health bar during boss waves with fade-in/out
- **XP orb collect burst** — green ring flash + spark particles on orb pickup
- **Synthwave soundtrack** — gameplay and boss music with smooth crossfading between tracks
- **Full SFX** — shooting, impacts, deaths, level-ups, dashes, UI clicks

## Running

1. Install [Godot 4.6+](https://godotengine.org/download) (standard edition)
2. Clone this repo
3. Open `project.godot` in Godot
4. Press **F5** to run

```bash
git clone https://github.com/jiajie96/velocity-neon.git
```

## Project Structure

```
velocity_neon/
├── assets/
│   ├── audio/          # Music (OGG/MP3) + SFX (OGG)
│   ├── models/         # KayKit GLB models + textures
│   └── vfx/particles/  # Particle texture PNGs
├── scenes/
│   └── main.tscn       # Minimal root scene
├── scripts/
│   ├── autoload/
│   │   ├── audio_manager.gd   # SFX pool + music player
│   │   └── game_state.gd      # Global state singleton
│   ├── camera_rig.gd          # Camera follow + shake + hit-stop
│   ├── enemy.gd               # Enemy AI + death VFX
│   ├── enemy_spawner.gd       # Wave system
│   ├── hud.gd                 # UI + title screen + upgrades
│   ├── main.gd                # World builder
│   ├── player.gd              # Player + weapons
│   ├── projectile.gd          # Projectile + chain + VFX
│   ├── upgrade_system.gd      # Upgrade definitions
│   └── xp_orb.gd              # XP pickup
├── shaders/
│   └── grid_ground.gdshader   # Animated neon grid
├── ATTRIBUTION.md
├── FUTURE_IMPROVEMENTS.md
└── project.godot
```

## Credits

### 3D Models
- [KayKit Adventurers & Skeletons](https://kaylousberg.itch.io/) by Kay Lousberg

### Music (CC-BY 4.0)
- "Neon Runner" by Eric Matyas
- "Retro Synthwave Loops" by Tomasz Kucza (Magnesus)
- "Cyberpunk Battle" by Alexandr Zhelanov

See [ATTRIBUTION.md](ATTRIBUTION.md) for full details.
