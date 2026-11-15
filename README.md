# Shadow Warriors: Tunisia 🇹🇳

3D martial-arts fighting game set across iconic Tunisian regions—engineered with a modular **Unreal Engine 5 (5.7+) C++ architecture** for Android and accompanied by an immediately playable **3D WebGL vertical slice (`WebPrototype/`)**.

## Repository Layout
- `Source/` — UE5 C++ combat state machine (`USWCombatComponent`), 3-phase Boss AI (`ASWBossAIController`), Progression & SaveGame subsystem (`USWProgressionSubsystem`), 10-Region World Map data (`SWWorldData.h`), and Mobile/Localization PlayerController.
- `Config/` — Android API 35 targeting, Vulkan/ES3.1 settings, and Snapdragon/Mali DeviceProfiles.
- `Content/Localization/` — English, French, and Arabic (RTL) string tables.
- `.github/workflows/android-build.yml` — Self-hosted Unreal Automation Tool Android APK CI pipeline.
- `WebPrototype/` — Playable 3D Kasserine vertical slice (Three.js + Web Audio synthesized SFX + Touch Controls).

## Play the 3D Vertical Slice Right Now (Android / Termux / PC)
```bash
cd WebPrototype
python -m http.server 8080

Open http://127.0.0.1:8080 in Chrome on Android (or any desktop browser).

Unreal Engine 5 Android Build Instructions

1.  Install Unreal Engine 5.7 or 5.8 with Android support, Visual Studio 2022,
    Android Studio Koala+, SDK API 34/35, NDK r27c, and OpenJDK 21.
2.  Right-click ShadowWarriorsTunisia.uproject → Generate Visual Studio project
    files.
3.  Wire skeletal meshes, AnimMontages (with hit-window AnimNotifies), and
    USWFighterProfileAsset DataAssets inside UE5 Editor.
4.  Package via Platforms → Android → Android (ASTC). EOF


---

### Part B: Create the Real, Playable 3D Vertical Slice (`WebPrototype/`)

This gives you an actual 3D game running smoothly at 30/60 FPS on your Android browser with:
- **Real 3D Kasserine Mountain Arena** (sandstone ruins, mountain peaks, flickering torches, wind dust particles, dynamic camera zoom + hit shake).
- **3 Playable Articulated 3D Fighters** (*Kasserini Warrior*, *Medina Assassin*, *Desert Guardian*) + **3-Phase Boss** (*The Mountain Executioner*).
- **Responsive Combat:** 3-hit Light combo, Heavy strike, Jump, Block + **0.18s Perfect Parry** (slow-mo spark burst + counter stagger), Dodge with invulnerability frames, Special Attack, and Ultimate Finisher!
- **Mobile Touch Controls** (virtual joystick + action buttons) **+ Keyboard Controls**, **Graphics/FPS Preset**, **Live XP & Dinar Upgrades**, and **English / French / Arabic (Full RTL)** switching.

Run this in `~/SHADOW-WARRIORS`:

```bash
cat << 'EOF' > WebPrototype/index.html
<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>Shadow Warriors: Tunisia — Kasserine 3D Vertical Slice</title>
  <link rel="stylesheet" href="style.css" />
  <script type="importmap">
    {
      "imports": {
        "three": "https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.module.js"
      }
    }
  </script>
</head>
<body>
  <canvas id="game-canvas"></canvas>

  <!-- TOP GLOBAL BAR -->
  <div id="top-bar" class="glass-bar">
    <div class="brand-badge">🇹🇳 <span data-i18n="gameTitle">SHADOW WARRIORS: TUNISIA</span></div>
    <div class="currency-group">
      <span class="pill">🪙 <b id="dinars-val">500</b></span>
      <span class="pill">💎 <b id="gems-val">25</b></span>
      <button id="btn-settings" class="icon-btn" title="Settings">⚙️</button>
    </div>
  </div>

  <!-- MAIN MENU SCREEN -->
  <section id="screen-menu" class="overlay-screen active">
    <div class="menu-card">
      <div class="subtitle" data-i18n="regionBadge">REGION 01 • KASSERINE MOUNTAINS</div>
      <h1 data-i18n="gameTitle">SHADOW WARRIORS: TUNISIA</h1>
      <p class="tagline" data-i18n="tagline">Master Tunisian martial arts. Defeat the Mountain Executioner.</p>
      <div class="menu-actions">
        <button class="btn primary" id="go-select" data-i18n="playBoss">STORY: KASSERINE BOSS</button>
        <button class="btn secondary" id="go-arena" data-i18n="arenaDuel">ARENA 1v1 DUEL</button>
        <button class="btn secondary" id="go-training" data-i18n="training">TRAINING DOJO</button>
        <button class="btn ghost" id="go-map" data-i18n="worldMap">TUNISIA WORLD MAP (10 REGIONS)</button>
      </div>
    </div>
  </section>

  <!-- FIGHTER SELECTION SCREEN -->
  <section id="screen-select" class="overlay-screen">
    <div class="select-panel">
      <h2 data-i18n="chooseFighter">CHOOSE YOUR WARRIOR</h2>
      <div id="fighter-cards" class="fighter-cards"></div>
      <div id="fighter-details" class="fighter-details">
        <div id="selected-name" class="detail-title"></div>
        <div id="selected-style" class="detail-sub"></div>
        <div class="detail-stats">
          <span id="stat-hp">HP: 220</span>
          <span id="stat-atk">ATK: 18</span>
          <span id="stat-spd">SPD: 90</span>
          <span id="stat-lv">LV: 1</span>
        </div>
        <button id="btn-upgrade" class="btn small">⬆️ <span data-i18n="upgradeWeapon">UPGRADE WEAPON</span> (150 🪙)</button>
      </div>
      <div class="select-footer">
        <button class="btn ghost" id="back-menu-from-select" data-i18n="back">BACK</button>
        <button class="btn primary" id="btn-start-fight" data-i18n="fight">FIGHT!</button>
      </div>
    </div>
  </section>

  <!-- TUNISIA WORLD MAP MODAL -->
  <section id="screen-map" class="overlay-screen">
    <div class="map-panel">
      <h2 data-i18n="worldMap">TUNISIA WORLD MAP (10 REGIONS)</h2>
      <div id="map-grid" class="map-grid"></div>
      <button class="btn ghost" id="back-menu-from-map" data-i18n="back">BACK</button>
    </div>
  </section>

  <!-- SETTINGS MODAL -->
  <section id="screen-settings" class="overlay-screen">
    <div class="settings-panel">
      <h2 data-i18n="settings">SETTINGS</h2>
      <div class="setting-row">
        <label data-i18n="language">Language</label>
        <div class="seg-group">
          <button class="seg active" data-lang="en">English</button>
          <button class="seg" data-lang="fr">Français</button>
          <button class="seg" data-lang="ar">العربية</button>
        </div>
      </div>
      <div class="setting-row">
        <label data-i18n="graphics">Graphics Quality</label>
        <div class="seg-group">
          <button class="seg" data-gfx="low">Low</button>
          <button class="seg active" data-gfx="med">Medium</button>
          <button class="seg" data-gfx="high">High</button>
        </div>
      </div>
      <div class="setting-row">
        <label data-i18n="fpsCap">Target FPS</label>
        <div class="seg-group">
          <button class="seg" data-fps="30">30 FPS</button>
          <button class="seg active" data-fps="60">60 FPS</button>
        </div>
      </div>
      <button class="btn primary" id="close-settings" data-i18n="done">DONE</button>
    </div>
  </section>

  <!-- COMBAT HUD -->
  <div id="combat-hud" class="hidden">
    <div class="hud-top">
      <div class="fighter-bar player">
        <div class="bar-label"><span id="hud-p-name">Kasserini Warrior</span> <span id="hud-p-hp-txt">220/220</span></div>
        <div class="hp-track"><div id="hud-p-hp" class="hp-fill"></div></div>
        <div class="en-track"><div id="hud-p-en" class="en-fill"></div></div>
      </div>
      <div class="hud-center">
        <div id="hud-timer">99</div>
        <div id="hud-phase" class="phase-tag">PHASE 1</div>
      </div>
      <div class="fighter-bar enemy">
        <div class="bar-label"><span id="hud-e-name">Mountain Executioner</span> <span id="hud-e-hp-txt">360/360</span></div>
        <div class="hp-track"><div id="hud-e-hp" class="hp-fill enemy-fill"></div></div>
        <div class="en-track"><div id="hud-e-en" class="en-fill"></div></div>
      </div>
    </div>

    <div id="combat-callout" class="callout hidden"></div>
    <div id="floating-fx"></div>

    <!-- VIRTUAL TOUCH CONTROLS -->
    <div class="touch-controls">
      <div class="left-pad">
        <div id="joystick-zone" class="joystick-base">
          <div id="joystick-knob" class="joystick-knob"></div>
        </div>
        <button class="t-btn jump-btn" id="btn-jump">⬆️</button>
      </div>

      <div class="right-pad">
        <button class="t-btn ult" id="btn-ult" data-i18n="ult">ULT</button>
        <button class="t-btn spc" id="btn-spc" data-i18n="spc">SPC</button>
        <button class="t-btn dodge" id="btn-dodge" data-i18n="dodge">DODGE</button>
        <button class="t-btn block" id="btn-block" data-i18n="block">BLOCK</button>
        <button class="t-btn heavy" id="btn-heavy" data-i18n="heavy">HEAVY</button>
        <button class="t-btn light" id="btn-light" data-i18n="light">LIGHT</button>
      </div>
    </div>
    <button id="btn-exit-match" class="exit-match-btn">✖</button>
  </div>

  <!-- VICTORY / DEFEAT OVERLAY -->
  <section id="screen-result" class="overlay-screen">
    <div class="result-card">
      <h1 id="result-title">VICTORY</h1>
      <p id="result-reward"></p>
      <div class="menu-actions">
        <button class="btn primary" id="btn-rematch" data-i18n="rematch">REMATCH</button>
        <button class="btn secondary" id="btn-result-menu" data-i18n="mainMenu">MAIN MENU</button>
      </div>
    </div>
  </section>

  <script type="module" src="game.js"></script>
</body>
</html>
