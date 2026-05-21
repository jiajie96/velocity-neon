# Velocity Neon — Free Asset Sourcing & Integration Guide

A curated, Godot‑4.6‑specific plan for enriching **Velocity Neon: Haptic Havoc** with free
art and audio. Every source below is **CC0** (public domain, no attribution required) or
clearly flagged otherwise. Covers all four focus areas: **characters/enemies, environment/map,
VFX/particles, audio/music**.

> **Note on downloading:** this assistant environment can't pull binary files (`.glb` / `.png`
> / `.ogg`) from the web. So this guide gives you exact links, licenses, and ready‑to‑paste
> Godot code so each asset works the moment you drop the files into the project folder.

---

## 0. Start here — you already own a 79‑model library

The big win is that **20 May 2026 added 79 CC0 models + a full UI kit that aren't wired into
the game yet** (see the companion *Asset Additions Report*). Use these first — they're already
on disk under `assets/models/…`, already imported by Godot, and cost nothing extra.

Highest‑value quick wins (paste‑ready code in §5):

| Idea | Asset already on disk | Replaces / adds |
|------|----------------------|-----------------|
| Health drop = a real heart | `assets/models/pickups/heart.glb` | the procedural green “+” |
| XP orb = a gem/crystal | `assets/models/pickups/detail-crystal.glb` or `tile-crystal.glb` or `star.glb` | the prism “fruit” |
| Arena depth & readability | `environment/` columns, crystals, coffins, candles | empty floor |
| Weapon visual on the hero | `weapons/blaster-a … h.glb` | (new) |
| New enemy types | `characters/` ghost, vampire, zombie | reuse `enemy.gd` model map |

---

## 1. Licensing cheat‑sheet

- **CC0 / Public Domain** — use freely, commercial OK, **no credit required**. (Kenney, Quaternius,
  KayKit, Poly Haven, ambientCG, FreePD, Pixabay, Sonniss GDC bundle, Kenney audio.)
- **CC‑BY** — free, commercial OK, **must credit** the author. (Many Freesound clips, Incompetech.)
- Always keep a line per asset in **`ATTRIBUTION.md`** / **`assets/CREDITS.md`** even for CC0 —
  it documents provenance and makes a future licence audit trivial.

---

## 2. Characters & enemies

| Source | What you get | License | Link |
|--------|--------------|---------|------|
| **KayKit – Skeletons** (this project's current enemies are this style) | Skeleton minion/warrior/mage/rogue + animations | CC0 | https://kaylousberg.itch.io/kaykit-skeletons |
| **KayKit – Adventurers** | Knight/rogue/mage/barbarian heroes — perfect for the planned character‑select | CC0 | https://kaylousberg.itch.io/kaykit-adventurers |
| **KayKit – Complete** | Everything KayKit in one download | CC0 (pay‑what‑you‑want) | https://kaylousberg.itch.io/kaykit-complete |
| **Quaternius – Ultimate Monsters / Animated Animals** | Dozens of rigged creatures for new enemy variety (healer, shielder, etc.) | CC0 | https://quaternius.com/ |
| **Kenney – Mini Characters / Blocky Characters** | Simple animated humanoids, great for swarm enemies | CC0 | https://kenney.nl/assets/tag:characters |
| **Poly Pizza** | Search‑and‑grab individual low‑poly models (aggregates Quaternius/Kenney) | mostly CC0 (check per‑model) | https://poly.pizza/ |

**Fit:** KayKit matches your existing skeletons exactly, so new KayKit enemies will look native.
Quaternius monsters are ideal for the roadmap's *Healer* and *Shield Bearer* enemy types.

**Integrate:** drop the `.glb` into `assets/models/`, then add a line to the `model_map` and
`neon_colors` dictionaries in `scripts/enemy.gd › _build_visual()`, and a stat block in `setup()`.
The existing `_apply_neon()` already re‑tints any imported model to the neon palette.

---

## 3. Environment & map (also helps readability)

| Source | What you get | License | Link |
|--------|--------------|---------|------|
| **KayKit – Dungeon Pack Remastered** | Pillars, walls, props, torches — matches the skeleton theme | CC0 | https://kaylousberg.itch.io/kaykit-dungeon-remastered |
| **Kenney – environment / platformer / city kits** | Huge variety of modular pieces | CC0 | https://kenney.nl/assets |
| **Quaternius – 150+ Nature, Cyberpunk, Sci‑Fi kits** | Trees, rocks, neon‑city props | CC0 | https://quaternius.com/ |
| **Poly Haven** | 2,000+ CC0 **textures + HDRIs** | CC0 | https://polyhaven.com/textures |
| **ambientCG** | 2,000+ CC0 seamless **PBR textures** | CC0 | https://ambientcg.com/ |

**Readability tip (ties into today's contrast work):** the single biggest map‑readability upgrade
is to replace the flat shader floor with a **darker, lower‑contrast PBR texture** (a subtle metal
grid or concrete from ambientCG/Poly Haven) so bright units pop. Use it as the `albedo_texture`
on the ground `StandardMaterial3D` and keep the emissive grid lines faint. Scattering a few dark
`environment/` props (columns, crystals) around the arena edge also frames the play space.

---

## 4. VFX & particles

| Source | What you get | License | Link |
|--------|--------------|---------|------|
| **Kenney – Particle Pack** (80 textures; likely the source of your current set) | Smoke, sparks, flames, magic, muzzle, flares | CC0 | https://kenney.nl/assets/particle-pack |
| **Kenney – Particle Pack, Godot‑ready fork** | Same pack pre‑packaged for Godot | CC0 | https://github.com/Calinou/kenney-particle-pack |
| **Kenney – Smoke Particles** | Extra high‑res smoke puffs | CC0 | https://kenney.nl/assets/smoke-particles |
| **OpenGameArt – particle/FX search** | Community FX sheets (filter to CC0) | mixed (filter CC0) | https://opengameart.org/ |

**Fit:** you already use Kenney‑style textures (`spark_04`, `circle_05`, `muzzle_01`…). Grabbing
the full pack gives consistent extras for the new cast‑flash / impact bursts added today
(`glow_soft`, `ring_thin`, `starburst_6` are already in `assets/vfx/particles/`).

**Integrate:** drop `.png` into `assets/vfx/particles/`, then reference it as the `texture` of a
`GPUParticles3D` draw‑pass material, or as `albedo_texture` on the existing
`scripts/vfx.gd` spark/flash meshes. They import as textures automatically.

---

## 5. Audio & music

| Source | What you get | License | Link |
|--------|--------------|---------|------|
| **Kenney – audio packs** (UI, impact, sci‑fi, music jingles) | Clean CC0 SFX that match the art | CC0 | https://kenney.nl/assets/tag:audio |
| **Sonniss – GDC Game Audio Bundle** | 7+ GB pro SFX, current year + a 200 GB archive | Royalty‑free, no attribution | https://gdc.sonniss.com/ |
| **Freesound** | 500k+ clips; filter to CC0 | CC0 or CC‑BY (filter!) | https://freesound.org/ |
| **Pixabay – music & SFX** | No‑attribution tracks/effects | Pixabay licence (free, commercial) | https://pixabay.com/music/search/cc0/ |
| **FreePD** (Kevin MacLeod) | Full CC0 music tracks | CC0 | https://freepd.com/ |
| **Tallbeard – Music Loop Bundle** | 200+ seamless game loops | CC0 | https://tallbeard.itch.io/music-loop-bundle |

**Fit:** you already rotate 9 tracks and have a 16‑voice SFX pool. Tallbeard loops and FreePD are
the fastest way to add more **boss / biome‑specific** tracks; Kenney/Sonniss cover any missing SFX
(e.g. a dedicated dash‑whoosh, shield‑break, pickup variations).

**Integrate (this is already drop‑in):** `scripts/autoload/audio_manager.gd › play_music()` and
`play_sfx()` both call `_load()`, which guards with `ResourceLoader.exists()`. So you can:
1. Drop `my_track.ogg` into `assets/audio/music/`.
2. Add one line to the wave‑music rotation in `scripts/autoload/game_state.gd › next_wave()`
   (and to `_wave_tier_music()` in `enemy.gd`), e.g. `Audio.play_music("res://assets/audio/music/my_track.ogg", -5.0)`.
   No other plumbing needed. New SFX: add a one‑line `func sfx_xxx()` wrapper in `audio_manager.gd`.

> Prefer **`.ogg`** for music/SFX in Godot (smaller, looping‑friendly). Convert `.wav`/`.mp3`
> with `ffmpeg -i in.wav -c:a libvorbis -q:a 5 out.ogg`.

---

## 6. Paste‑ready integration snippets

These are written against the current scripts and are safe (each guards with `ResourceLoader.exists`
and falls back to the existing procedural look if the model is missing).

### 6a. Health drop → real heart model (`scripts/health_orb.gd › _build_visual`)
Replace the body of `_build_visual()` with:
```gdscript
func _build_visual() -> void:
	var green := Color(0.2, 1.0, 0.45)
	var model_path := "res://assets/models/pickups/heart.glb"
	if ResourceLoader.exists(model_path):
		var scene: PackedScene = load(model_path)
		if scene:
			var inst := scene.instantiate()
			inst.name = "Mesh"
			inst.scale = Vector3.ONE * 0.45      # tune to taste
			inst.position.y = 0.55
			add_child(inst)
			_add_orb_light(green)
			return
	# --- fallback: the current procedural “+” (keep the existing code here) ---
```
Then make the bob/rotate in `_process` tolerant of a model root (it has no `material_override`):
guard the fade block with `if child is MeshInstance3D and child.material_override:` (already true
in the current code) — a GLB root is a `Node3D`, so the existing `for child in mesh.get_children()`
loop simply finds the model's mesh surfaces and still works.

### 6b. XP orb → crystal model at **uniform** size (`scripts/xp_orb.gd › _build_visual`)
At the very top of `_build_visual()`:
```gdscript
	var model_path := "res://assets/models/pickups/detail-crystal.glb"  # or tile-crystal / star
	if ResourceLoader.exists(model_path):
		var scene: PackedScene = load(model_path)
		if scene:
			var inst := scene.instantiate()
			inst.name = "Mesh"
			inst.scale = Vector3.ONE * 0.30      # uniform — no per‑value scaling
			inst.position.y = 0.5
			add_child(inst)
			return
	# --- fallback: current uniform prism (already implemented today) ---
```
(The `_process` pulse reads `mesh.material_override`; with a GLB, leave the pulse off or tint the
model's surface materials once on spawn — see §6d.)

### 6c. Arena set‑dressing for depth/readability (new, optional — in `scripts/main.gd`)
```gdscript
func _build_decor() -> void:
	var props := ["environment/column-large", "environment/detail-crystal-large",
		"environment/cross-column", "environment/coffin"]
	for i in 14:
		var p := "res://assets/models/%s.glb" % props[i % props.size()]
		if not ResourceLoader.exists(p): continue
		var inst := (load(p) as PackedScene).instantiate()
		var ang := TAU * i / 14.0
		inst.position = Vector3(cos(ang), 0, sin(ang)) * randf_range(38.0, 46.0)  # ring near walls
		inst.scale = Vector3.ONE * 1.5      # tune after first look
		add_child(inst)
```
Call `_build_decor()` from `_ready()`. Keep props **outside the ~36‑unit combat radius** so they
never block gameplay. *Verify scale in‑editor first* — kit scales vary.

### 6d. Re‑tint any imported model to the neon palette
`enemy.gd` already has `_apply_neon(node, color)` and the player has `_apply_neon_tint(node, color)`.
Call the relevant one right after `add_child(inst)` to make new models glow in‑theme.

---

## 7. Godot 4.6 import checklist

1. Copy files into `assets/…`; open the project once so Godot generates `.import` files.
2. **Models:** select the `.glb` → *Import* tab → confirm scale; most kits import at 1 unit ≈ 1 m.
   This project scales characters to **0.5** and the player to **0.6** — match that.
3. **Textures (particles/ground):** set *Mipmaps On* for ground, *Fix Alpha Border* for sprites.
4. **Audio:** import `.ogg` as *AudioStreamOggVorbis*; tick **Loop** for music.
5. **Commit the binaries too** — when you reference a new asset in code, `git add` the asset **and**
   its `.import` file so the repo stays consistent (several of yesterday's models are currently
   untracked: `git status` will show them).
6. Add an attribution line to `ATTRIBUTION.md`.

---

## 8. Suggested first batch (fast, high‑impact, all CC0)

1. **Heart model** for health drops (§6a) — already on disk.
2. **Crystal model** for XP orbs (§6b) — already on disk, uniform size.
3. **Ground texture** from ambientCG (dark grid/metal) for unit/background contrast.
4. **2–3 Tallbeard / FreePD loops** for more boss & late‑wave music variety.
5. **KayKit Adventurers** to unlock the planned character‑select feature.

---

*Sources verified via web search, May 2026. All links point to the official project pages; confirm
the licence shown on each page at download time — a few itch.io creators offer CC0 art alongside
separately‑licensed extras.*
