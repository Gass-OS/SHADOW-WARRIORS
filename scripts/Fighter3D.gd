extends Node3D

signal hit_landed(attacker, defender, atk_data)
signal defeated(fighter)

var cfg: Dictionary = {}
var is_player := true
var max_hp := 220.0
var hp := 220.0
var atk := 18.0
var energy := 0.0
var move_speed := 5.2

var facing := 1.0
var vx := 0.0
var vy := 0.0
var state := "idle"
var state_timer := 0.0
var parry_window := 0.0
var active_attack: Dictionary = {}
var has_hit_this_swing := false
var anim_t := 0.0

var hips: Node3D
var r_shoulder: Node3D
var l_shoulder: Node3D
var l_leg: Node3D
var r_leg: Node3D
var cape: MeshInstance3D
var armor_mat: StandardMaterial3D

func setup(fighter_cfg: Dictionary, player_flag: bool, weapon_lv: int = 1) -> void:
	cfg = fighter_cfg
	is_player = player_flag
	var s := 1.24 if bool(cfg.get("is_boss", false)) else 1.0
	scale = Vector3(s, s, s)
	max_hp = float(cfg["hp"]) + (float(weapon_lv - 1) * 18.0 if is_player else 0.0)
	hp = max_hp
	atk = float(cfg["atk"]) + (float(weapon_lv - 1) * 4.0 if is_player else 0.0)
	move_speed = float(cfg["speed"])
	facing = 1.0 if is_player else -1.0
	_build_rig()

func _build_rig() -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = cfg["body_color"]
	body_mat.roughness = 0.55
	armor_mat = StandardMaterial3D.new()
	armor_mat.albedo_color = cfg["armor_color"]
	armor_mat.metallic = 0.72
	armor_mat.roughness = 0.3
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.76, 0.54, 0.35)
	skin_mat.roughness = 0.7

	hips = Node3D.new()
	hips.position = Vector3(0, 1.05, 0)
	add_child(hips)

	var torso := MeshInstance3D.new()
	var torso_m := CylinderMesh.new()
	torso_m.top_radius = 0.27
	torso_m.bottom_radius = 0.21
	torso_m.height = 0.76
	torso.mesh = torso_m
	torso.material_override = body_mat
	torso.position = Vector3(0, 0.42, 0)
	hips.add_child(torso)

	var chest := MeshInstance3D.new()
	var chest_m := BoxMesh.new()
	chest_m.size = Vector3(0.56, 0.35, 0.32)
	chest.mesh = chest_m
	chest.material_override = armor_mat
	chest.position = Vector3(0, 0.54, 0)
	hips.add_child(chest)

	var head := MeshInstance3D.new()
	var head_m := SphereMesh.new()
	head_m.radius = 0.18
	head.mesh = head_m
	head.material_override = skin_mat
	head.position = Vector3(0, 0.96, 0)
	hips.add_child(head)

	var helm := MeshInstance3D.new()
	var helm_m := CylinderMesh.new()
	helm_m.top_radius = 0.05 if str(cfg["id"]) == "medina" else 0.19
	helm_m.bottom_radius = 0.21
	helm_m.height = 0.22
	helm.mesh = helm_m
	helm.material_override = armor_mat
	helm.position = Vector3(0, 1.08, 0)
	hips.add_child(helm)

	cape = MeshInstance3D.new()
	var cape_m := BoxMesh.new()
	cape_m.size = Vector3(0.44, 0.92, 0.05)
	cape.mesh = cape_m
	cape.material_override = body_mat
	cape.position = Vector3(0, 0.30, -0.20)
	hips.add_child(cape)

	r_shoulder = Node3D.new()
	r_shoulder.position = Vector3(0.35, 0.72, 0)
	hips.add_child(r_shoulder)
	var r_arm := MeshInstance3D.new()
	var arm_m := CylinderMesh.new()
	arm_m.top_radius = 0.08
	arm_m.bottom_radius = 0.07
	arm_m.height = 0.66
	r_arm.mesh = arm_m
	r_arm.material_override = skin_mat
	r_arm.position = Vector3(0, -0.30, 0)
	r_shoulder.add_child(r_arm)

	var blade := MeshInstance3D.new()
	var blade_m := BoxMesh.new()
	var w_type: String = str(cfg["weapon"])
	var b_len := 1.55 if w_type == "cleaver" else (1.85 if w_type == "spear" else 1.15)
	var b_w := 0.22 if w_type == "cleaver" else 0.07
	blade_m.size = Vector3(b_w, 0.05, b_len)
	blade.mesh = blade_m
	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.88, 0.92, 0.96)
	steel_mat.metallic = 0.92
	steel_mat.roughness = 0.18
	blade.material_override = steel_mat
	blade.position = Vector3(0, -0.60, b_len * 0.48)
	r_shoulder.add_child(blade)

	l_shoulder = Node3D.new()
	l_shoulder.position = Vector3(-0.35, 0.72, 0)
	hips.add_child(l_shoulder)
	var l_arm := MeshInstance3D.new()
	l_arm.mesh = arm_m
	l_arm.material_override = skin_mat
	l_arm.position = Vector3(0, -0.30, 0)
	l_shoulder.add_child(l_arm)

	if w_type == "spear":
		var shield := MeshInstance3D.new()
		var shield_m := CylinderMesh.new()
		shield_m.top_radius = 0.42
		shield_m.bottom_radius = 0.42
		shield_m.height = 0.07
		shield.mesh = shield_m
		shield.material_override = armor_mat
		shield.rotation_degrees = Vector3(0, 0, 90)
		shield.position = Vector3(-0.08, -0.42, 0.16)
		l_shoulder.add_child(shield)
	elif w_type == "daggers":
		var off_blade := MeshInstance3D.new()
		var off_m := BoxMesh.new()
		off_m.size = Vector3(0.05, 0.04, 0.8)
		off_blade.mesh = off_m
		off_blade.material_override = steel_mat
		off_blade.position = Vector3(0, -0.58, 0.38)
		l_shoulder.add_child(off_blade)

	var leg_m := CylinderMesh.new()
	leg_m.top_radius = 0.10
	leg_m.bottom_radius = 0.08
	leg_m.height = 0.95
	l_leg = Node3D.new()
	l_leg.position = Vector3(-0.15, 0, 0)
	hips.add_child(l_leg)
	var l_shin := MeshInstance3D.new()
	l_shin.mesh = leg_m
	l_shin.material_override = body_mat
	l_shin.position = Vector3(0, -0.48, 0)
	l_leg.add_child(l_shin)

	r_leg = Node3D.new()
	r_leg.position = Vector3(0.15, 0, 0)
	hips.add_child(r_leg)
	var r_shin := MeshInstance3D.new()
	r_shin.mesh = leg_m
	r_shin.material_override = body_mat
	r_shin.position = Vector3(0, -0.48, 0)
	r_leg.add_child(r_shin)

func start_attack(type: String) -> bool:
	if state != "idle":
		return false
	if type == "spc" and energy < 40.0:
		return false
	if type == "ult" and energy < 100.0:
		return false
	if type == "spc":
		energy -= 40.0
	elif type == "ult":
		energy -= 100.0

	var mult := 1.0 if type == "light" else (1.65 if type == "heavy" else (2.1 if type == "spc" else 3.2))
	var dur := 0.34 if type == "light" else (0.56 if type == "heavy" else (0.62 if type == "spc" else 0.85))
	var is_unblockable := type == "ult" or (bool(cfg.get("is_boss", false)) and (hp / max_hp) < 0.25 and type == "heavy")
	active_attack = {"type": type, "damage": roundf(atk * mult), "duration": dur, "range": 3.2 if (type == "spc" or type == "ult") else 2.35, "unblockable": is_unblockable}
	state = "attack"
	state_timer = dur
	has_hit_this_swing = false
	position.x += facing * (0.22 if type == "light" else 0.45)
	return true

func set_block(active: bool) -> void:
	if active and state == "idle":
		state = "parry"
		parry_window = 0.19
	elif not active and (state == "block" or state == "parry"):
		state = "idle"

func dodge(dir: float) -> bool:
	if state != "idle" and state != "block" and state != "parry":
		return false
	state = "dodge"
	state_timer = 0.34
	vx = (dir if absf(dir) > 0.1 else -facing) * 11.5
	return true

func jump() -> void:
	if position.y <= 0.02 and state == "idle":
		vy = 9.2

func step_fighter(dt: float, opponent: Node3D) -> void:
	anim_t += dt
	if state == "dead":
		rotation.z = lerpf(rotation.z, -facing * 1.45, dt * 6.0)
		position.y = lerpf(position.y, 0.25, dt * 6.0)
		return
	if opponent != null and (state == "idle" or state == "block" or state == "parry"):
		facing = 1.0 if opponent.position.x >= position.x else -1.0
	rotation.y = lerpf(rotation.y, PI / 2.0 if facing > 0.0 else -PI / 2.0, dt * 16.0)
	position.x = clampf(position.x + vx * dt, -8.5, 8.5)
	vx *= pow(0.001, dt)
	position.y += vy * dt
	if position.y > 0.0:
		vy -= 24.0 * dt
	if position.y <= 0.0:
		position.y = 0.0
		vy = 0.0
	if state == "parry":
		parry_window -= dt
		if parry_window <= 0.0:
			state = "block"
	if state_timer > 0.0:
		state_timer -= dt
		if state == "attack" and not has_hit_this_swing and opponent != null:
			if state_timer < float(active_attack["duration"]) * 0.65:
				var dist: float = absf(position.x - opponent.position.x)
				if dist <= float(active_attack["range"]) and absf(position.y - opponent.position.y) < 1.6:
					has_hit_this_swing = true
					emit_signal("hit_landed", self, opponent, active_attack)
		if state_timer <= 0.0:
			state = "idle"
			active_attack = {}
	_animate_rig(dt)

func _animate_rig(dt: float) -> void:
	var r_arm_x := -0.45
	var l_arm_x := -0.50
	var torso_x := 0.08
	var leg_swing := 0.0
	if state == "idle":
		hips.position.y = 1.05 + sin(anim_t * 4.5) * 0.03
		if absf(vx) > 0.4:
			leg_swing = sin(anim_t * 14.0) * 0.55
		r_arm_x = -0.45 + sin(anim_t * 4.5) * 0.08
	elif state == "block" or state == "parry":
		r_arm_x = -1.25
		l_arm_x = -1.30
		torso_x = -0.10
	elif state == "attack" and not active_attack.is_empty():
		var p: float = 1.0 - (state_timer / float(active_attack["duration"]))
		var swing := sin(p * PI)
		r_arm_x = -1.8 + swing * 2.5
		l_arm_x = -0.8 + swing * 1.1
		torso_x = swing * 0.42
		if str(active_attack["type"]) == "ult":
			hips.position.y = 1.05 + swing * 0.65
	elif state == "hitstun":
		torso_x = -0.45
		r_arm_x = 0.4
	elif state == "dodge":
		torso_x = 0.35
		hips.position.y = 0.85

	r_shoulder.rotation.x = lerpf(r_shoulder.rotation.x, r_arm_x, dt * 18.0)
	l_shoulder.rotation.x = lerpf(l_shoulder.rotation.x, l_arm_x, dt * 18.0)
	hips.rotation.x = lerpf(hips.rotation.x, torso_x, dt * 16.0)
	l_leg.rotation.x = leg_swing
	r_leg.rotation.x = -leg_swing
	cape.rotation.x = 0.18 + sin(anim_t * 6.0) * 0.1
