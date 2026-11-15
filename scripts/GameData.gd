extends RefCounted

static func get_regions() -> Array:
	return [
		{"id": "kasserine", "name": "01. Kasserine", "boss": "Mountain Executioner", "unlocked": true},
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
			"style": "Mountain Sabre • High Poise & Fire Cleave",
			"hp": 220.0, "atk": 18.0, "speed": 5.3,
			"body_color": Color(0.72, 0.34, 0.14), "armor_color": Color(0.95, 0.72, 0.25), "weapon": "sabre"
		},
		{
			"id": "medina", "name": "Medina Assassin",
			"style": "Twin Curved Blades • Fast Acrobatic Strikes",
			"hp": 185.0, "atk": 15.0, "speed": 6.8,
			"body_color": Color(0.11, 0.21, 0.36), "armor_color": Color(0.28, 0.82, 0.88), "weapon": "daggers"
		},
		{
			"id": "guardian", "name": "Desert Guardian",
			"style": "Bronze Shield & Spear • Counter Specialist",
			"hp": 255.0, "atk": 16.0, "speed": 4.8,
			"body_color": Color(0.55, 0.43, 0.24), "armor_color": Color(0.98, 0.82, 0.38), "weapon": "spear"
		}
	]

static func get_boss() -> Dictionary:
	return {
		"id": "executioner", "name": "Mountain Executioner",
		"style": "Chaambi Warlord • 3-Phase Boss",
		"hp": 380.0, "atk": 21.0, "speed": 4.4,
		"body_color": Color(0.18, 0.07, 0.09), "armor_color": Color(0.95, 0.24, 0.28),
		"weapon": "cleaver", "is_boss": true
	}

static func get_i18n() -> Dictionary:
	return {
		"en": {"title": "SHADOW WARRIORS: TUNISIA", "subtitle": "REGION 01 • KASSERINE MOUNTAINS", "victory": "VICTORY!", "defeat": "DEFEAT", "parry": "PERFECT PARRY!"},
		"fr": {"title": "GUERRIERS DE L'OMBRE : TUNISIE", "subtitle": "RÉGION 01 • MONTAGNES DE KASSERINE", "victory": "VICTOIRE !", "defeat": "DÉFAITE", "parry": "PARADE PARFAITE !"},
		"ar": {"title": "محاربو الظل: تونس", "subtitle": "المنطقة 01 • جبال القصرين", "victory": "انتصار!", "defeat": "هزيمة", "parry": "تصدي مثالي!"}
	}
