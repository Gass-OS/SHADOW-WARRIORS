extends Node3D

signal hit_landed(attacker, defender, atk_data)
signal defeated(fighter)

var cfg: Dictionary = {}
var is_player: bool = true
var max_hp: float = 240.0
var hp: float = 240.0
var atk: float = 20.0
var energy: float = 0.0
var move_speed: float = 5.4

var facing: float = 1.0
var vx: float = 0.0
var vy: float = 0.0
var state: String = "idle"
var state_timer: float = 0.0
var parry_window: float = 0.0
var active_attack: Dictionary = {}
var has_hit_this_swing: bool = false
var anim_t: float = 0.0

# Multi-joint articulated skeleton nodes
var hips: Node3D
var spine: Node3D
var head_grp: Node3D
var r_shoulder: Node3D
var r_elbow: Node3D
var l_shoulder: Node3D
var l_elbow: Node3D
var l_hip: Node3D
var l_knee: Node3D
var r_hip: Node3D
var r_knee: Node3D
var sash: MeshInstance3D
var armor_mat: StandardMaterial3D

# 3D Weapon Slash Trail
var weapon_base_marker: Node3D
var weapon_tip_marker: Node3D
var trail_mesh: ImmediateMesh
var trail_points: Array = []

func setup(fighter_cfg: Dictionary, player_flag: bool, weapon_lv: int = 1) -> void:
	cfg = fighter_cfg
	is_player = player_flag
	var s: float = 1.18 if bool(cfg.get("is_boss", false)) else 1.0
	scale = Vector3(s, s, s)
	max_hp = float(cfg["hp"]) + (float(weapon_lv - 1) * 20.0 if is_player else 0.0)
	hp = max_hp
	atk = float(cfg["atk"]) + (float(weapon_lv - 1) * 4.5 if is_player else 0.0)
	move_speed = float(cfg["speed"])
	facing = 1.0 if is_player else -1.0
	_build_articulated_skeleton()
	_build_slash_trail()

func _make_mat(col: Color, metallic: float, rough: float, rim_amt: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metallic
	m.roughness = rough
	m.rim_enabled = true
	m.rim = rim_amt
	m.rim_tint = 0.45
	return m

func _limb_capsule(radius: float, height: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = height
	mi.mesh = cap
	mi.material_override = mat
	return mi

func _build_articulated_skeleton() -> void:
	var body_mat := _make_mat(cfg["body_color"], 0.12, 0.62)
	armor_mat = _make_mat(cfg["armor_color"], 0.78, 0.28, 0.75)
	var accent_mat := _make_mat(cfg.get("accent_color", Color.GOLD), 0.55, 0.35, 0.8)
	var skin_mat := _make_mat(Color(0.75, 0.53, 0.35), 0.02, 0.68)
	var boot_mat := _make_mat(Color(0.22, 0.15, 0.10), 0.15, 0.75)
	var steel_mat := _make_mat(Color(0.90, 0.94, 0.98), 0.94, 0.16, 0.9)

	hips = Node3D.new()
	hips.position = Vector3(0, 0.98, 0)
	add_child(hips)

	var pelvis := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.36, 0.20, 0.24)
	pelvis.mesh = pm
	pelvis.material_override = armor_mat
	hips.add_child(pelvis)

	# Armored Skirt / Gambeson Flap
	sash = MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.21
	sm.bottom_radius = 0.30
	sm.height = 0.52
	sash.mesh = sm
	sash.material_override = body_mat
	sash.position = Vector3(0, -0.22, 0)
	hips.add_child(sash)

	# Spine & Armored Chest
	spine = Node3D.new()
	spine.position = Vector3(0, 0.12, 0)
	hips.add_child(spine)

	var torso := _limb_capsule(0.19, 0.62, body_mat)
	torso.position = Vector3(0, 0.28, 0)
	spine.add_child(torso)

	var chest := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.48, 0.34, 0.30)
	chest.mesh = cm
	chest.material_override = armor_mat
	chest.position = Vector3(0, 0.42, 0)
	spine.add_child(chest)

	var belt := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.42, 0.10, 0.28)
	belt.mesh = bm
	belt.material_override = accent_mat
	belt.position = Vector3(0, 0.08, 0)
	spine.add_child(belt)

	# Head & Neck
	head_grp = Node3D.new()
	head_grp.position = Vector3(0, 0.68, 0)
	spine.add_child(head_grp)

	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.165
	head.mesh = hm
	head.material_override = skin_mat
	head.position = Vector3(0, 0.12, 0)
	head_grp.add_child(head)

	var hair_or_helm := MeshInstance3D.new()
	var hhm := CylinderMesh.new()
	hhm.top_radius = 0.06 if str(cfg["id"]) == "medina" else 0.17
	hhm.bottom_radius = 0.19
	hhm.height = 0.18
	hair_or_helm.mesh = hhm
	hair_or_helm.material_override = armor_mat if bool(cfg.get("is_boss", false)) else _make_mat(Color(0.14, 0.10, 0.08), 0.1, 0.7)
	hair_or_helm.position = Vector3(0, 0.22, -0.02)
	head_grp.add_child(hair_or_helm)

	# Right Arm (Upper -> Elbow -> Forearm -> Weapon)
	r_shoulder = Node3D.new()
	r_shoulder.position = Vector3(0.30, 0.52, 0)
	spine.add_child(r_shoulder)

	var r_pauldron := MeshInstance3D.new()
	var paul_m := SphereMesh.new()
	paul_m.radius = 0.125
	r_pauldron.mesh = paul_m
	r_pauldron.material_override = armor_mat
	r_shoulder.add_child(r_pauldron)

	var r_upper := _limb_capsule(0.068, 0.34, body_mat)
	r_upper.position = Vector3(0, -0.16, 0)
	r_shoulder.add_child(r_upper)

	r_elbow = Node3D.new()
	r_elbow.position = Vector3(0, -0.32, 0)
	r_shoulder.add_child(r_elbow)

	var r_fore := _limb_capsule(0.058, 0.32, accent_mat)
	r_fore.position = Vector3(0, -0.15, 0)
	r_elbow.add_child(r_fore)

	var r_hand := Node3D.new()
	r_hand.position = Vector3(0, -0.32, 0)
	r_elbow.add_child(r_hand)

	var w_type: String = str(cfg["weapon"])
	var b_len: float = 1.35 if w_type == "flail_shield" else (1.75 if w_type == "spear" else 1.15)
	var blade := MeshInstance3D.new()
	var blm := BoxMesh.new()
	blm.size = Vector3(0.06, 0.09, b_len)
	blade.mesh = blm
	blade.material_override = steel_mat
	blade.position = Vector3(0, 0, b_len * 0.5)
	r_hand.add_child(blade)

	if w_type == "flail_shield":
		var mace_head := MeshInstance3D.new()
		var mm := SphereMesh.new()
		mm.radius = 0.18
		mace_head.mesh = mm
		mace_head.material_override = armor_mat
		mace_head.position = Vector3(0, 0, b_len)
		r_hand.add_child(mace_head)

	weapon_base_marker = Node3D.new()
	weapon_base_marker.position = Vector3(0, 0, 0.18)
	r_hand.add_child(weapon_base_marker)
	weapon_tip_marker = Node3D.new()
	weapon_tip_marker.position = Vector3(0, 0, b_len)
	r_hand.add_child(weapon_tip_marker)

	# Left Arm (Upper -> Elbow -> Forearm -> Shield/Offhand)
	l_shoulder = Node3D.new()
	l_shoulder.position = Vector3(-0.30, 0.52, 0)
	spine.add_child(l_shoulder)

	var l_pauldron := MeshInstance3D.new()
	l_pauldron.mesh = paul_m
	l_pauldron.material_override = armor_mat
	l_shoulder.add_child(l_pauldron)

	var l_upper := _limb_capsule(0.068, 0.34, body_mat)
	l_upper.position = Vector3(0, -0.16, 0)
	l_shoulder.add_child(l_upper)

	l_elbow = Node3D.new()
	l_elbow.position = Vector3(0, -0.32, 0)
	l_shoulder.add_child(l_elbow)

	var l_fore := _limb_capsule(0.058, 0.32, accent_mat)
	l_fore.position = Vector3(0, -0.15, 0)
	l_elbow.add_child(l_fore)

	if w_type in ["spear", "shield_sword", "flail_shield"]:
		var shield := MeshInstance3D.new()
		var shm := CylinderMesh.new()
		shm.top_radius = 0.42
		shm.bottom_radius = 0.42
		shm.height = 0.06
		shield.mesh = shm
		shield.material_override = armor_mat
		shield.rotation_degrees = Vector3(0, 0, 90)
		shield.position = Vector3(-0.10, -0.22, 0.14)
		l_elbow.add_child(shield)
	elif w_type == "daggers":
		var off := MeshInstance3D.new()
		var om := BoxMesh.new()
		om.size = Vector3(0.05, 0.07, 0.78)
		off.mesh = om
		off.material_override = steel_mat
		off.position = Vector3(0, -0.32, 0.36)
		l_elbow.add_child(off)

	# Left & Right Legs (Hip -> Thigh -> Knee -> Shin -> Boot)
	l_hip = Node3D.new()
	l_hip.position = Vector3(-0.14, -0.04, 0)
	hips.add_child(l_hip)
	var l_thigh := _limb_capsule(0.092, 0.48, body_mat)
	l_thigh.position = Vector3(0, -0.22, 0)
	l_hip.add_child(l_thigh)
	l_knee = Node3D.new()
	l_knee.position = Vector3(0, -0.45, 0)
	l_hip.add_child(l_knee)
	var l_shin := _limb_capsule(0.078, 0.46, boot_mat)
	l_shin.position = Vector3(0, -0.22, 0)
	l_knee.add_child(l_shin)
	var l_boot := MeshInstance3D.new()
	var btm := BoxMesh.new()
	btm.size = Vector3(0.14, 0.12, 0.28)
	l_boot.mesh = btm
	l_boot.material_override = boot_mat
	l_boot.position = Vector3(0, -0.46, 0.06)
	l_knee.add_child(l_boot)

	r_hip = Node3D.new()
	r_hip.position = Vector3(0.14, -0.04, 0)
	hips.add_child(r_hip)
	var r_thigh := _limb_capsule(0.092, 0.48, body_mat)
	r_thigh.position = Vector3(0, -0.22, 0)
	r_hip.add_child(r_thigh)
	r_knee = Node3D.new()
	r_knee.position = Vector3(0, -0.45, 0)
	r_hip.add_child(r_knee)
	var r_shin := _limb_capsule(0.078, 0.46, boot_mat)
	r_shin.position = Vector3(0, -0.22, 0)
	r_knee.add_child(r_shin)
	var r_boot := MeshInstance3D.new()
	r_boot.mesh = btm
	r_boot.material_override = boot_mat
	r_boot.position = Vector3(0, -0.46, 0.06)
	r_knee.add_child(r_boot)

func _build_slash_trail() -> void:
	trail_mesh = ImmediateMesh.new()
	var trail_node := MeshInstance3D.new()
	trail_node.mesh = trail_mesh
	trail_node.top_level = true
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var ac: Color = cfg.get("accent_color", Color(0.4, 0.9, 1.0))
	tm.albedo_color = Color(ac.r, ac.g, ac.b, 0.65)
	trail_node.material_override = tm
	add_child(trail_node)

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

	var mult: float = 1.0 if type == "light" else (1.65 if type == "heavy" else (2.15 if type == "spc" else 3.25))
	var dur: float = 0.34 if type == "light" else (0.56 if type == "heavy" else (0.62 if type == "spc" else 0.85))
	var is_unblockable: bool = type == "ult" or (bool(cfg.get("is_boss", false)) and (hp / max_hp) < 0.25 and type == "heavy")
	active_attack = {"type": type, "damage": roundf(atk * mult), "duration": dur, "range": 3.25 if (type == "spc" or type == "ult") else 2.45, "unblockable": is_unblockable}
	state = "attack"
	state_timer = dur
	has_hit_this_swing = false
	position.x += facing * (0.28 if type == "light" else 0.55)
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
	vx = (dir if absf(dir) > 0.1 else -facing) * 11.8
	return true

func jump() -> void:
	if position.y <= 0.02 and state == "idle":
		vy = 9.2

func step_fighter(dt: float, opponent: Node3D) -> void:
	anim_t += dt
	if state == "dead":
		rotation.z = lerpf(rotation.z, -facing * 1.45, dt * 6.0)
		position.y = lerpf(position.y, 0.25, dt * 6.0)
		_update_slash_trail(false)
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
				if dist <= float(active_attack["range"]) and absf(position.y - opponent.position.y) < 1.65:
					has_hit_this_swing = true
					emit_signal("hit_landed", self, opponent, active_attack)
		if state_timer <= 0.0:
			state = "idle"
			active_attack = {}
	_animate_skeleton(dt)
	_update_slash_trail(state == "attack")

func _animate_skeleton(dt: float) -> void:
	# Martial Arts Combat Stance defaults (knees bent, arms raised)
	var hip_y: float = 0.88
	var spine_x: float = 0.16
	var spine_y: float = -0.18
	var r_sh_x: float = -0.75
	var r_elb_x: float = -0.85
	var l_sh_x: float = -0.95
	var l_elb_x: float = -0.95
	var l_hip_x: float = -0.45
	var l_kn_x: float = 0.65
	var r_hip_x: float = 0.35
	var r_kn_x: float = 0.35

	if state == "idle":
		hip_y = 0.88 + sin(anim_t * 4.5) * 0.03
		r_sh_x = -0.75 + sin(anim_t * 4.5) * 0.08
		if absf(vx) > 0.4:
			var stride: float = sin(anim_t * 15.0)
			l_hip_x = -0.25 + stride * 0.55
			r_hip_x = -0.25 - stride * 0.55
			l_kn_x = maxf(0.15, -stride * 0.65 + 0.45)
			r_kn_x = maxf(0.15, stride * 0.65 + 0.45)
	elif state == "block" or state == "parry":
		l_sh_x = -1.45
		l_elb_x = -0.55
		r_sh_x = -1.10
		spine_x = 0.05
	elif state == "attack" and not active_attack.is_empty():
		var p: float = 1.0 - (state_timer / float(active_attack["duration"]))
		var sw: float = sin(p * PI)
		spine_x = 0.25 + sw * 0.32
		spine_y = -0.55 + sw * 1.15
		r_sh_x = -2.1 + sw * 2.65
		r_elb_x = -0.25
		l_hip_x = -0.75
		l_kn_x = 0.85
		r_hip_x = 0.55
		if str(active_attack["type"]) == "ult":
			hip_y = 0.92 + sw * 0.72
	elif state == "hitstun":
		spine_x = -0.35
		r_sh_x = 0.35
	elif state == "dodge":
		spine_x = 0.45
		hip_y = 0.74

	hips.position.y = lerpf(hips.position.y, hip_y, dt * 16.0)
	spine.rotation.x = lerpf(spine.rotation.x, spine_x, dt * 16.0)
	spine.rotation.y = lerpf(spine.rotation.y, spine_y, dt * 18.0)
	r_shoulder.rotation.x = lerpf(r_shoulder.rotation.x, r_sh_x, dt * 20.0)
	r_elbow.rotation.x = lerpf(r_elbow.rotation.x, r_elb_x, dt * 20.0)
	l_shoulder.rotation.x = lerpf(l_shoulder.rotation.x, l_sh_x, dt * 18.0)
	l_elbow.rotation.x = lerpf(l_elbow.rotation.x, l_elb_x, dt * 18.0)
	l_hip.rotation.x = lerpf(l_hip.rotation.x, l_hip_x, dt * 16.0)
	l_knee.rotation.x = lerpf(l_knee.rotation.x, l_kn_x, dt * 16.0)
	r_hip.rotation.x = lerpf(r_hip.rotation.x, r_hip_x, dt * 16.0)
	r_knee.rotation.x = lerpf(r_knee.rotation.x, r_kn_x, dt * 16.0)
	sash.rotation.x = 0.12 + sin(anim_t * 6.0) * 0.08

func _update_slash_trail(active: bool) -> void:
	if trail_mesh == null:
		return
	if active and weapon_base_marker != null and weapon_tip_marker != null:
		trail_points.append([weapon_base_marker.global_position, weapon_tip_marker.global_position])
		if trail_points.size() > 8:
			trail_points.pop_front()
	elif trail_points.size() > 0:
		trail_points.pop_front()

	trail_mesh.clear_surfaces()
	if trail_points.size() >= 2:
		trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for pt in trail_points:
			trail_mesh.surface_add_vertex(pt[0])
			trail_mesh.surface_add_vertex(pt[1])
		trail_mesh.surface_end()
