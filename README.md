<div align="center">

# ⚔️ SHADOW WARRIORS: TUNISIA

### A 3D martial-arts fighting game across Tunisia

[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white)](https://godotengine.org)
[![Android](https://img.shields.io/badge/Android-arm64-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Gass-OS/SHADOW-WARRIORS/actions)
[![Version 0.2.0](https://img.shields.io/badge/version-0.2.0-blue?style=for-the-badge)](https://github.com/Gass-OS/SHADOW-WARRIORS)
[![Build](https://github.com/Gass-OS/SHADOW-WARRIORS/actions/workflows/android-build.yml/badge.svg)](https://github.com/Gass-OS/SHADOW-WARRIORS/actions)

**Master Tunisian martial arts. Defeat the Mountain Executioner. Fight your way across ten regions of Tunisia — from the Kasserine mountains to the Tunis medina.**

</div>

---

## 📖 What it is

**Shadow Warriors: Tunisia** is a 3D arena fighting game built with **Godot 4.7** (Mobile renderer) for **Android**. Three fighters, one boss per region, and a combat system built for touch: light and heavy strikes, block, dodge, a perfect parry window, special attacks and an ultimate finisher — with hit-stop, screen shake and synthesized sound effects.

- 🥋 **3 fighters** — each with their own weapon, stats and style
- 👹 **Boss fights** — the Mountain Executioner, a 3-phase boss with changing attacks
- 🗺️ **10 regions** — Kasserine (unlocked) plus Tunis, Sidi Bou Said, Kairouan, Tozeur, Matmata, Sousse, El Jem, Bizerte and Jebel Chaambi
- 🎮 **Modes** — Story boss fight, arena 1v1 duel, training dojo, survival waves
- 🪙 **Progression** — win dinars and gems, upgrade your weapon, save your progress
- 🌐 **Languages** — English, French and Arabic (full RTL)

---

## 🥋 Choose your warrior

| Fighter | Weapon | Style | HP |
|:---|:---|:---|---:|
| **Kasserini Warrior** | Sabre | Mountain Sabre — high poise & fire cleave | 220 |
| **Medina Assassin** | Twin daggers | Fast acrobatic strikes | 185 |
| **Desert Guardian** | Spear | Bronze shield & spear — counter specialist | 255 |

**Boss — Mountain Executioner** (Chaambi Warlord, 3 phases, cleaver, 380 HP)

## 🗺️ The ten regions

| # | Region | Boss |
|:---:|---|---|
| 1 | **Kasserine** (unlocked) | Mountain Executioner |
| 2 | Tunis Medina | The Medina Shadow |
| 3 | Sidi Bou Said | The Blue Phantom |
| 4 | Kairouan | Ancient Guardian |
| 5 | Tozeur | The Desert King |
| 6 | Matmata | Subterranean Warden |
| 7 | Sousse | Corsair Admiral |
| 8 | El Jem | Emperor of El Jem |
| 9 | Bizerte | Harbor Colossus |
| 10 | Jebel Chaambi | Pharaoh of Shadows |

## 🎮 How to play

- **Move** with the virtual joystick, **fight** with the on-screen buttons: LIGHT, HEAVY, BLOCK, DODGE, SPC (special) and ULT (ultimate)
- **Perfect parry** — block at the exact moment of impact for a slow-mo counter opening
- **Rounds** — 99 seconds on the clock, HP and energy bars, phases as the boss weakens
- **Survival** — waves of enemies, one after another
- **Upgrades** — spend dinars on your weapon between fights; progress saves locally

---

## 📦 Get the game

CI builds the APK on push to `main` — download it from the latest successful run's artifacts ([Actions page](https://github.com/Gass-OS/SHADOW-WARRIORS/actions)).

> The game is not on Google Play — the CI artifact is the way to install it for now.

---

## 🛠️ Build it yourself

```bash
git clone https://github.com/Gass-OS/SHADOW-WARRIORS.git
cd SHADOW-WARRIORS
# Open project.godot with Godot 4.7 — project files live at the repo root
# Android export: arm64-v8a
```

Pushing to `main` triggers the same build in CI — no local Android SDK needed.

### Project details

| | |
|:---|---|
| **Engine** | Godot 4.7, Mobile renderer |
| **Language** | GDScript |
| **Genre** | 3D arena fighting |
| **Orientation** | Landscape 1280×720 |
| **Android** | arm64-v8a |
| **Save data** | `user://sw_tunisia_save.json` |
| **Audio** | Synthesized sound effects (no audio files) |

### Project layout

```
├── scenes/Main.tscn     # the whole game — menu, select, map, combat
├── scripts/
│   ├── Main.gd          # game flow, combat, UI, AI
│   ├── GameData.gd      # fighters, bosses, regions, translations
│   ├── Arena3D.gd       # the 3D arena
│   ├── Fighter3D.gd     # fighter visuals + animation
│   └── AudioSynth.gd    # procedural sound effects
└── icon.svg
```

---

<div align="center">

**Made with Godot in Tunisia 🇹🇳**

*A Gass-OS game — ten regions, one warrior.*

</div>
