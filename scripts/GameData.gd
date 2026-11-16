extends RefCounted

static func get_regions() -> Array:
	return [
		{"id": "kasserine", "name": "01. Kasserine Bridge", "boss": "Mountain Executioner", "unlocked": true},
		{"id": "tunis", "name": "02. Tunis Medina", "boss": "The Medina Shadow", "unlocked": false},
		{"id": "sidi", "name": "03. Sidi Bou Said", "boss": "The Blue Phantom", "unlocked": false},
		{"id": "kairouan", "name": "04. Kairouan", "boss": "Ancient Guardian", "unlocked": false},
		{"id": "tozeur", "name": "05. Tozeur", "boss": "The Desert King", "unlocked": false},
		{"id": "matmata", "name": "06. Matmata", "boss": "Subterranean Warden", "unlocked": false},
		{"id": "sousse", "name": "07. Sousse", "boss": "Corsair Admiral", "unlocked": false},
		{"id": "eljem", "name": "08. El Jem", "boss": "Emperor of El Jem", "unlocked": false},
		{"id": "bizerte", "name": "09. Bizerte", "boss": "Harbor Colossus", "unlocked": false},
		{"id": "chaambi", "name": "10. Jebel Chaambi", "boss": "Pharaoh of Shadows", "unlocked": false}
	]

static func get_fighters() -> Array:
	return [
		{
			"id": "kasserini", "name": "Kasserini Warrior",
			"style": "Mountain Sabre • Balanced & Fire Cleave",
			"lore": "A mountain sabre-master from Kasserine, sworn to guard the bridge of Chaambi.",
			"cost": 0, "hp": 240.0, "atk": 20.0, "speed": 5.4,
			"body_color": Color(0.24, 0.36, 0.18), "armor_color": Color(0.68, 0.45, 0.22),
			"accent_color": Color(0.22, 0.78, 0.85), "weapon": "sabre",
			"ability": {"id": "fire", "name": "Fire Cleave", "short": "FIRE", "desc": "Burning sabre slash — sets the enemy on fire (+4 dmg/s for 3s).", "cost": 40, "mult": 2.15, "range": 3.25, "kind": "fire"}
		},
		{
			"id": "medina", "name": "Medina Assassin",
			"style": "Twin Khanjars • Rapid Shadow Strikes",
			"lore": "A silent blade of the Tunis medina — no one has ever seen her face twice.",
			"cost": 300, "hp": 205.0, "atk": 17.0, "speed": 6.9,
			"body_color": Color(0.10, 0.16, 0.28), "armor_color": Color(0.32, 0.78, 0.88),
			"accent_color": Color(0.28, 0.90, 1.0), "weapon": "daggers",
			"ability": {"id": "shadow_dash", "name": "Shadow Dash", "short": "SHDW", "desc": "Vanishes and reappears behind the enemy for a backstab.", "cost": 40, "mult": 2.0, "range": 3.25, "kind": "shadow"}
		},
		{
			"id": "guardian", "name": "Desert Guardian",
			"style": "Spear & Bronze Shield • Counter Master",
			"lore": "Last warden of the Kairouan gates — his bronze shield has never broken.",
			"cost": 450, "hp": 280.0, "atk": 18.0, "speed": 4.9,
			"body_color": Color(0.45, 0.34, 0.19), "armor_color": Color(0.88, 0.68, 0.28),
			"accent_color": Color(1.0, 0.82, 0.32), "weapon": "spear",
			"ability": {"id": "bronze_counter", "name": "Bronze Counter", "short": "CNTR", "desc": "2s counter stance — a hit taken reflects 1.5x damage back.", "cost": 40, "mult": 1.0, "range": 2.45, "kind": "counter"}
		},
		{
			"id": "phantom", "name": "Blue Phantom",
			"style": "Sidi Bou Said Blade • Ultra Mobility",
			"lore": "A ghost of the blue village — he strikes from the sea mist and is gone.",
			"cost": 650, "hp": 215.0, "atk": 22.0, "speed": 7.2,
			"body_color": Color(0.86, 0.90, 0.96), "armor_color": Color(0.14, 0.48, 0.88),
			"accent_color": Color(0.25, 0.85, 1.0), "weapon": "sabre",
			"ability": {"id": "phantom_blink", "name": "Phantom Blink", "short": "BLNK", "desc": "Blinks to the other side and spins a full-circle slash.", "cost": 40, "mult": 2.3, "range": 3.25, "kind": "blink"}
		},
		{
			"id": "roman", "name": "Roman Champion",
			"style": "El Jem Gladius & Shield • Heavy Armor",
			"lore": "Champion of the El Jem amphitheatre — the crowd still chants his name.",
			"cost": 800, "hp": 310.0, "atk": 23.0, "speed": 4.6,
			"body_color": Color(0.55, 0.14, 0.14), "armor_color": Color(0.52, 0.56, 0.50),
			"accent_color": Color(0.95, 0.72, 0.25), "weapon": "shield_sword",
			"ability": {"id": "gladius_quake", "name": "Gladius Quake", "short": "QUAKE", "desc": "Ground slam — huge shockwave, triple chip damage through block.", "cost": 40, "mult": 2.4, "range": 3.6, "kind": "quake"}
		},
		{
			"id": "sahara", "name": "Sahara Hunter",
			"style": "Twin Crescent Blades • Tozeur Fury",
			"lore": "A hunter of the Tozeur dunes — she rides the sandstorm into battle.",
			"cost": 950, "hp": 235.0, "atk": 25.0, "speed": 6.4,
			"body_color": Color(0.58, 0.38, 0.16), "armor_color": Color(0.85, 0.52, 0.20),
			"accent_color": Color(1.0, 0.55, 0.18), "weapon": "daggers",
			"ability": {"id": "sandstorm", "name": "Sandstorm", "short": "SAND", "desc": "Summons a sandstorm — slows the enemy (x0.6 speed for 4s).", "cost": 40, "mult": 1.9, "range": 3.25, "kind": "sand"}
		},
		{
			"id": "duelist", "name": "Carthage Duelist",
			"style": "Carthage Sabre • Piercing Lunge",
			"lore": "A duelist of old Carthage — one lunge, one honour, one victor.",
			"cost": 1100, "hp": 220.0, "atk": 24.0, "speed": 6.6,
			"body_color": Color(0.25, 0.15, 0.35), "armor_color": Color(0.75, 0.78, 0.82),
			"accent_color": Color(1.0, 0.8, 0.25), "weapon": "sabre",
			"ability": {"id": "piercing_lunge", "name": "Piercing Lunge", "short": "LNGE", "desc": "Lunges 1.2m forward with a piercing sabre thrust.", "cost": 40, "mult": 2.2, "range": 3.9, "kind": "lunge"}
		},
		{
			"id": "axeman", "name": "Atlas Axeman",
			"style": "Atlas Axe • Mountain Cleave",
			"lore": "A lumberjack of the Atlas foothills — his axe felled mountains, not trees.",
			"cost": 1250, "hp": 300.0, "atk": 26.0, "speed": 4.7,
			"body_color": Color(0.35, 0.28, 0.2), "armor_color": Color(0.6, 0.55, 0.45),
			"accent_color": Color(0.9, 0.3, 0.15), "weapon": "axe",
			"ability": {"id": "mountain_cleave", "name": "Mountain Cleave", "short": "CLVE", "desc": "Slow heavy cleave (0.8s windup) — massive knockback.", "cost": 40, "mult": 2.8, "range": 2.9, "kind": "cleave"}
		},
		{
			"id": "corsair", "name": "Corsair Captain",
			"style": "Sousse Sabre • Tide Slash",
			"lore": "Captain of the Sousse corsairs — the tide itself answers her blade.",
			"cost": 1400, "hp": 230.0, "atk": 23.0, "speed": 6.2,
			"body_color": Color(0.1, 0.25, 0.3), "armor_color": Color(0.2, 0.5, 0.6),
			"accent_color": Color(0.3, 0.9, 0.9), "weapon": "sabre",
			"ability": {"id": "tide_slash", "name": "Tide Slash", "short": "TIDE", "desc": "A wave-like slash — heavy knockback and slows the enemy 3s.", "cost": 40, "mult": 2.1, "range": 3.4, "kind": "tide"}
		}
	]

static func get_boss() -> Dictionary:
	return {
		"id": "executioner", "name": "Mountain Executioner",
		"style": "Chaambi Warlord • 3-Phase Boss",
		"lore": "Warlord of Jebel Chaambi — three phases of fury, one mountain of pain.",
		"cost": 0, "hp": 390.0, "atk": 23.0, "speed": 4.6,
		"body_color": Color(0.18, 0.22, 0.18), "armor_color": Color(0.45, 0.48, 0.42),
		"accent_color": Color(1.0, 0.32, 0.25), "weapon": "flail_shield", "is_boss": true,
		"ability": {"id": "chaambi_slam", "name": "Chaambi Slam", "short": "SLAM", "desc": "A mountain-shaking slam — unblockable at phase 3.", "cost": 40, "mult": 2.6, "range": 3.5, "kind": "slam"}
	}

static func get_i18n() -> Dictionary:
	return {
		"en": {"title": "SHADOW WARRIORS: TUNISIA", "subtitle": "KASSERINE MOUNTAIN BRIDGE", "victory": "VICTORY!", "defeat": "DEFEAT", "parry": "PERFECT PARRY!", "ko": "ROUND WIN!", "finish_him": "FINISH HIM!", "fatality": "FATALITY!", "round": "ROUND", "fight": "FIGHT!", "wave": "WAVE", "easy": "EASY", "normal": "NORMAL", "hard": "HARD"},
		"fr": {"title": "GUERRIERS DE L'OMBRE : TUNISIE", "subtitle": "PONT DES MONTAGNES DE KASSERINE", "victory": "VICTOIRE !", "defeat": "DÉFAITE", "parry": "PARADE PARFAITE !", "ko": "MANCHE GAGNÉE !", "finish_him": "ACHÈVE-LE !", "fatality": "FATALITÉ !", "round": "MANCHE", "fight": "COMBAT !", "wave": "VAGUE", "easy": "FACILE", "normal": "NORMAL", "hard": "DIFFICILE"},
		"ar": {"title": "محاربو الظل: تونس", "subtitle": "جسر جبال القصرين", "victory": "انتصار!", "defeat": "هزيمة", "parry": "تصدي مثالي!", "ko": "فوز بالجولة!", "finish_him": "اقضِ عليه!", "fatality": "ضربة قاضية!", "round": "الجولة", "fight": "قاتل!", "wave": "الموجة", "easy": "سهل", "normal": "عادي", "hard": "صعب"}
	}
