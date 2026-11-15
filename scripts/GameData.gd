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
			"cost": 0, "hp": 240.0, "atk": 20.0, "speed": 5.4,
			"body_color": Color(0.24, 0.36, 0.18), "armor_color": Color(0.68, 0.45, 0.22),
			"accent_color": Color(0.22, 0.78, 0.85), "weapon": "sabre"
		},
		{
			"id": "medina", "name": "Medina Assassin",
			"style": "Twin Khanjars • Rapid Shadow Strikes",
			"cost": 300, "hp": 205.0, "atk": 17.0, "speed": 6.9,
			"body_color": Color(0.10, 0.16, 0.28), "armor_color": Color(0.32, 0.78, 0.88),
			"accent_color": Color(0.28, 0.90, 1.0), "weapon": "daggers"
		},
		{
			"id": "guardian", "name": "Desert Guardian",
			"style": "Spear & Bronze Shield • Counter Master",
			"cost": 450, "hp": 280.0, "atk": 18.0, "speed": 4.9,
			"body_color": Color(0.45, 0.34, 0.19), "armor_color": Color(0.88, 0.68, 0.28),
			"accent_color": Color(1.0, 0.82, 0.32), "weapon": "spear"
		},
		{
			"id": "phantom", "name": "Blue Phantom",
			"style": "Sidi Bou Said Blade • Ultra Mobility",
			"cost": 650, "hp": 215.0, "atk": 22.0, "speed": 7.2,
			"body_color": Color(0.86, 0.90, 0.96), "armor_color": Color(0.14, 0.48, 0.88),
			"accent_color": Color(0.25, 0.85, 1.0), "weapon": "sabre"
		},
		{
			"id": "roman", "name": "Roman Champion",
			"style": "El Jem Gladius & Shield • Heavy Armor",
			"cost": 800, "hp": 310.0, "atk": 23.0, "speed": 4.6,
			"body_color": Color(0.55, 0.14, 0.14), "armor_color": Color(0.52, 0.56, 0.50),
			"accent_color": Color(0.95, 0.72, 0.25), "weapon": "shield_sword"
		},
		{
			"id": "sahara", "name": "Sahara Hunter",
			"style": "Twin Crescent Blades • Tozeur Fury",
			"cost": 950, "hp": 235.0, "atk": 25.0, "speed": 6.4,
			"body_color": Color(0.58, 0.38, 0.16), "armor_color": Color(0.85, 0.52, 0.20),
			"accent_color": Color(1.0, 0.55, 0.18), "weapon": "daggers"
		}
	]

static func get_boss() -> Dictionary:
	return {
		"id": "executioner", "name": "Mountain Executioner",
		"style": "Chaambi Warlord • 3-Phase Boss",
		"cost": 0, "hp": 390.0, "atk": 23.0, "speed": 4.6,
		"body_color": Color(0.18, 0.22, 0.18), "armor_color": Color(0.45, 0.48, 0.42),
		"accent_color": Color(1.0, 0.32, 0.25), "weapon": "flail_shield", "is_boss": true
	}

static func get_i18n() -> Dictionary:
	return {
		"en": {"title": "SHADOW WARRIORS: TUNISIA", "subtitle": "KASSERINE MOUNTAIN BRIDGE", "victory": "VICTORY!", "defeat": "DEFEAT", "parry": "PERFECT PARRY!", "ko": "ROUND WIN!"},
		"fr": {"title": "GUERRIERS DE L'OMBRE : TUNISIE", "subtitle": "PONT DES MONTAGNES DE KASSERINE", "victory": "VICTOIRE !", "defeat": "DÉFAITE", "parry": "PARADE PARFAITE !", "ko": "MANCHE GAGNÉE !"},
		"ar": {"title": "محاربو الظل: تونس", "subtitle": "جسر جبال القصرين", "victory": "انتصار!", "defeat": "هزيمة", "parry": "تصدي مثالي!", "ko": "فوز بالجولة!"}
	}
