extends Node3D

const ModelLoader = preload("res://scripts/ModelLoader.gd")

signal hit_landed(attacker, defender, atk_data)
signal attack_started(attacker, atk_data)
signal defeated(fighter)

var cfg: Dictionary = {}
var is_player: bool = true
var max_hp: float = 240.0
var hp: float = 240.0
var atk: float = 20.0
var energy: float = 0.0
var move_speed: float = 5.4

# --- v0.3.0 realistic combat ---
var stamina: float = 100.0
const STAMINA_MAX: float = 100.0
const STAMINA_COST := {"light": 8.0, "heavy": 14.0, "dodge": 18.0, "jump": 6.0}
var burn_timer: float = 0.0
var burn_dps: float = 0.0
var slow_timer: float = 0.0
var counter_timer: float = 0.0
var blockstun_timer: float = 0.0
var whiff_timer: float = 0.0
var combo_count: int = 0
var combo_timer: float = 0.0
var crouch_held: bool = false

var facing: float = 1.0
var vx: float = 0.0
var vy: float = 0.0
var state: String = "idle"
var state_timer: float = 0.0
var parry_window: float = 0.0
var active_attack: Dictionary = {}
var has_hit_this_swing: bool = false

var anim_player: AnimationPlayer = null
var current_clip: String = ""
var armor_mat: StandardMaterial3D
var weapon_base_marker: Node3D
var weapon_tip_marker: Node3D
var trail_mesh: ImmediateMesh
var trail_points: Array = []

func setup(fighter_cfg: Dictionary, player_flag: bool, weapon_lv: int = 1) -> void:
	cfg = fighter_cfg
	is_player = player_flag
	var is_boss: bool = bool(cfg.get("is_boss", false))
	var s: float = 1.18 if is_boss else 1.0
	scale = Vector3(s, s, s)
	max_hp = float(cfg["hp"]) + (float(weapon_lv - 1) * 20.0 if is_player else 0.0)
	hp = max_hp
	atk = float(cfg["atk"]) + (float(weapon_lv - 1) * 4.5 if is_player else 0.0)
	move_speed = float(cfg["speed"])
	facing = 1.0 if is_player else -1.0
	stamina = STAMINA_MAX
	burn_timer = 0.0
	burn_dps = 0.0
	slow_timer = 0.0
	counter_timer = 0.0
	blockstun_timer = 0.0
	whiff_timer = 0.0
	combo_count = 0
	combo_timer = 0.0
	crouch_held = false

	_build_quaternius_warrior()
	_build_slash_trail()

func is_exhausted() -> bool:
	return stamina < 20.0

func effective_speed() -> float:
	var sp: float = move_speed
	if slow_timer > 0.0:
		sp *= 0.6
	if is_exhausted():
		sp *= 0.7
	if state == "crouch":
		sp *= 0.3
	return sp

func weight_factor() -> float:
	return maxf(0.5, max_hp / 240.0)

func get_ability() -> Dictionary:
	return cfg.get("ability", {})

func _make_mat(col: Color, metallic: float, rough: float, rim_amt: float = 0.65) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metallic
	m.roughness = rough
	m.rim_enabled = true
	m.rim = rim_amt
	m.rim_tint = 0.45
	return m

func _build_quaternius_warrior() -> void:
	var f_id: String = str(cfg["id"])
	var use_female: bool = f_id in ["medina", "phantom", "sahara", "corsair"]
	var char_path: String = "res://assets/quaternius/characters/%s.gltf" % ("Superhero_Female_FullBody" if use_female else "Superhero_Male_FullBody")

	var char_inst: Node3D = ModelLoader.load_scene(char_path)
	if char_inst == null:
		return
	ModelLoader.fit_to_height(char_inst, 1.85)
	add_child(char_inst)

	armor_mat = _make_mat(cfg["armor_color"], 0.78, 0.28, 0.75)
	var body_mat := _make_mat(cfg["body_color"], 0.15, 0.58, 0.65)
	var accent_mat := _make_mat(cfg.get("accent_color", Color.GOLD), 0.65, 0.30, 0.85)
	var steel_mat := _make_mat(Color(0.92, 0.95, 0.98), 0.94, 0.15, 0.9)

	# Tint character suit subtly per hero identity
	_tint_meshes(char_inst, cfg["body_color"])

	# Attach Universal Animation Library directly onto this character skeleton
	anim_player = ModelLoader.attach_ual_animations(char_inst, "res://assets/quaternius/anims/UAL1_Standard.glb")
	_play_clip("Sword_Idle")

	var skel: Skeleton3D = ModelLoader.find_skeleton(char_inst)
	if skel == null:
		return

	# Pauldrons & Chest Crest on Clavicles / Spine


	# Attach Beard on bearded warriors
	if f_id in ["kasserini", "guardian", "executioner", "axeman"]:
		var head_att := BoneAttachment3D.new()
		head_att.bone_name = "Head"
		skel.add_child(head_att)
		var beard := MeshInstance3D.new()
		var bdm := BoxMesh.new()
		bdm.size = Vector3(0.11, 0.10, 0.08)
		beard.mesh = bdm
		beard.material_override = body_mat
		beard.position = Vector3(0, -0.03, 0.09)
		head_att.add_child(beard)

	# Right Hand Weapon + Slash Trail Markers
	var r_hand := BoneAttachment3D.new()
	r_hand.bone_name = "hand_r"
	skel.add_child(r_hand)

	var w_type: String = str(cfg["weapon"])
	var b_len: float = 1.25 if w_type == "flail_shield" else (1.65 if w_type == "spear" else 1.05)
	var hilt := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.022; hm.bottom_radius = 0.024; hm.height = 0.28
	hilt.mesh = hm; hilt.material_override = accent_mat
	hilt.rotation_degrees = Vector3(90, 0, 0)
	r_hand.add_child(hilt)

	var blade := MeshInstance3D.new()
	var blm := BoxMesh.new()
	blm.size = Vector3(0.045, 0.075, b_len)
	blade.mesh = blm
	blade.material_override = steel_mat
	blade.position = Vector3(0, 0.04, b_len * 0.52)
	r_hand.add_child(blade)

	if w_type == "flail_shield":
		var mace := MeshInstance3D.new()
		var mm := SphereMesh.new(); mm.radius = 0.14; mm.height = 0.28
		mace.mesh = mm; mace.material_override = armor_mat
		mace.position = Vector3(0, 0.04, b_len)
		r_hand.add_child(mace)
	elif w_type == "axe":
		# Axe head: wide flat box at the tip of the haft, like the flail mace
		var axe_head := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(0.07, 0.42, 0.30)
		axe_head.mesh = am
		axe_head.material_override = steel_mat
		axe_head.position = Vector3(0, 0.04, b_len)
		r_hand.add_child(axe_head)
		var axe_butt := MeshInstance3D.new()
		var abm := BoxMesh.new()
		abm.size = Vector3(0.06, 0.16, 0.10)
		axe_butt.mesh = abm
		axe_butt.material_override = armor_mat
		axe_butt.position = Vector3(0, 0.04, b_len - 0.14)
		r_hand.add_child(axe_butt)

	weapon_base_marker = Node3D.new(); weapon_base_marker.position = Vector3(0, 0.04, 0.15); r_hand.add_child(weapon_base_marker)
	weapon_tip_marker = Node3D.new(); weapon_tip_marker.position = Vector3(0, 0.04, b_len); r_hand.add_child(weapon_tip_marker)

	# Left Hand Shield or Offhand Dagger
	var l_hand := BoneAttachment3D.new()
	l_hand.bone_name = "hand_l"
	skel.add_child(l_hand)

	if w_type in ["spear", "shield_sword", "flail_shield"]:
		var shield := MeshInstance3D.new()
		var shm := CylinderMesh.new()
		shm.top_radius = 0.36; shm.bottom_radius = 0.36; shm.height = 0.05
		shield.mesh = shm; shield.material_override = armor_mat
		shield.rotation_degrees = Vector3(0, 0, 90)
		shield.position = Vector3(-0.08, 0.02, 0.06)
		l_hand.add_child(shield)
	elif w_type == "daggers":
		var off := MeshInstance3D.new()
		var om := BoxMesh.new(); om.size = Vector3(0.04, 0.06, 0.72)
		off.mesh = om; off.material_override = steel_mat
		off.position = Vector3(0, 0.04, 0.36)
		l_hand.add_child(off)

func _tint_meshes(node: Node, col: Color) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var mat: Material = mi.get_active_material(s)
				if mat is StandardMaterial3D:
					var dup := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					dup.albedo_color = Color(lerpf(0.65, col.r, 0.45), lerpf(0.65, col.g, 0.45), lerpf(0.65, col.b, 0.45))
					dup.rim_enabled = true
					dup.rim = 0.45
					mi.set_surface_override_material(s, dup)
	for child in node.get_children():
		_tint_meshes(child, col)

func _play_clip(clip_name: String, spd: float = 1.0) -> void:
	if anim_player == null or not anim_player.has_animation(clip_name):
		return
	if current_clip == clip_name and anim_player.is_playing():
		return
	current_clip = clip_name
	anim_player.play(clip_name, 0.1, spd)

# Public clip player for Main.gd (fatality cinematic, intro poses).
func play_anim(clip_name: String, spd: float = 1.0) -> void:
	_play_clip(clip_name, spd)

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
	if blockstun_timer > 0.0 or whiff_timer > 0.0:
		return false
	if type == "spc" and energy < 40.0:
		return false
	if type == "ult" and energy < 100.0:
		return false
	# Stamina costs (ability/ult use energy instead)
	if type == "light" and stamina < float(STAMINA_COST["light"]):
		return false
	if type == "heavy" and stamina < float(STAMINA_COST["heavy"]):
		return false
	if type == "spc":
		energy -= 40.0
	elif type == "ult":
		energy -= 100.0
	elif type == "light":
		stamina -= float(STAMINA_COST["light"])
	elif type == "heavy":
		stamina -= float(STAMINA_COST["heavy"])

	var ability: Dictionary = get_ability()
	var ab_kind: String = str(ability.get("kind", "")) if type == "spc" else ""
	var ab_mult: float = float(ability.get("mult", 2.15)) if type == "spc" else 1.0
	var ab_range: float = float(ability.get("range", 3.25)) if type == "spc" else 3.25

	# Bronze Counter: spc enters a counter stance instead of striking
	if ab_kind == "counter":
		state = "counter"
		counter_timer = 2.0
		state_timer = 2.0
		active_attack = {"type": "spc", "damage": 0.0, "duration": 2.0, "range": 0.0, "unblockable": false, "kind": ab_kind, "knock_mult": 1.0, "chip_mult": 1.0}
		has_hit_this_swing = true
		_play_clip("Crouch_Idle_Loop", 1.0)
		emit_signal("attack_started", self, active_attack)
		return true

	var mult: float = 1.0 if type == "light" else (1.65 if type == "heavy" else (ab_mult if type == "spc" else 3.25))
	var dur: float = 0.36 if type == "light" else (0.58 if type == "heavy" else (0.64 if type == "spc" else 0.88))
	if ab_kind == "cleave":
		dur = 0.8
	if is_exhausted():
		dur *= 1.15
	var atk_range: float = 3.25 if (type == "spc" or type == "ult") else 2.45
	if type == "spc":
		atk_range = ab_range
	var is_unblockable: bool = type == "ult" or (bool(cfg.get("is_boss", false)) and (hp / max_hp) < 0.25 and type == "heavy")
	if ab_kind == "slam" and bool(cfg.get("is_boss", false)) and (hp / max_hp) <= 0.25:
		is_unblockable = true
	var knock_mult: float = 1.0
	var chip_mult: float = 1.0
	if ab_kind == "cleave":
		knock_mult = 2.0
	elif ab_kind == "tide":
		knock_mult = 1.6
	elif ab_kind == "quake":
		knock_mult = 1.3
		chip_mult = 3.0
	active_attack = {"type": type, "damage": roundf(atk * mult), "duration": dur, "range": atk_range, "unblockable": is_unblockable, "kind": ab_kind, "knock_mult": knock_mult, "chip_mult": chip_mult}
	state = "attack"
	state_timer = dur
	has_hit_this_swing = false
	position.x += facing * (0.28 if type == "light" else 0.55)

	# Ability teleports / lunges happen at cast time
	if ab_kind == "shadow_dash" or ab_kind == "blink":
		pass # Main.gd performs the teleport (it knows the opponent)
	elif ab_kind == "lunge":
		position.x = clampf(position.x + facing * 1.2, -8.5, 8.5)

	if type == "light":
		_play_clip("Sword_Attack" if randf() < 0.65 else "Punch_Jab", 1.35)
	elif type == "heavy":
		_play_clip("Sword_Attack", 0.95)
	elif type == "spc":
		_play_clip("Spell_Simple_Shoot", 1.25)
	else:
		_play_clip("Punch_Cross", 0.9)
	emit_signal("attack_started", self, active_attack)
	return true

func set_block(active: bool) -> void:
	if active and (state == "idle" or state == "crouch") and blockstun_timer <= 0.0:
		state = "parry"
		parry_window = 0.19
		_play_clip("Crouch_Idle_Loop", 1.0)
	elif not active and (state == "block" or state == "parry"):
		state = "crouch" if crouch_held else "idle"

# v0.3.0 crouch: low stance, x0.3 speed, damage taken x0.7, idle-like stamina regen.
# Crouch only from idle; block while crouched is allowed (keeps crouch_held).
func set_crouch(active: bool) -> void:
	crouch_held = active
	if active and state == "idle" and blockstun_timer <= 0.0 and whiff_timer <= 0.0:
		state = "crouch"
		_play_clip("Crouch_Idle_Loop", 1.0)
	elif not active and state == "crouch":
		state = "idle"

func dodge(dir: float) -> bool:
	if state != "idle" and state != "block" and state != "parry":
		return false
	if blockstun_timer > 0.0 or whiff_timer > 0.0:
		return false
	if stamina < float(STAMINA_COST["dodge"]):
		return false
	stamina -= float(STAMINA_COST["dodge"])
	state = "dodge"
	state_timer = 0.36
	vx = (dir if absf(dir) > 0.1 else -facing) * 11.8
	_play_clip("Roll", 1.45)
	return true

func jump() -> void:
	if position.y <= 0.02 and state == "idle" and blockstun_timer <= 0.0 and whiff_timer <= 0.0:
		if stamina < float(STAMINA_COST["jump"]):
			return
		stamina -= float(STAMINA_COST["jump"])
		vy = 9.2
		_play_clip("Jump_Start", 1.2)

func apply_burn(dps: float, dur: float) -> void:
	burn_dps = dps
	burn_timer = dur

func apply_slow(dur: float) -> void:
	slow_timer = maxf(slow_timer, dur)

func step_fighter(dt: float, opponent: Node3D) -> void:
	if state == "dead":
		_play_clip("Death01", 1.0)
		_update_slash_trail(false)
		return

	# Status timers
	if burn_timer > 0.0:
		burn_timer -= dt
		hp = maxf(0.0, hp - burn_dps * dt)
		if burn_timer <= 0.0:
			burn_dps = 0.0
		if hp <= 0.0:
			state = "dead"
			emit_signal("defeated", self)
			_update_slash_trail(false)
			return
	if slow_timer > 0.0:
		slow_timer -= dt
	if blockstun_timer > 0.0:
		blockstun_timer -= dt
	if whiff_timer > 0.0:
		whiff_timer -= dt
	if combo_timer > 0.0:
		combo_timer -= dt
		if combo_timer <= 0.0:
			combo_count = 0

	# Stamina regen: 22/s idle/block/parry/counter/crouch, 10/s moving, 0 otherwise
	if state in ["idle", "block", "parry", "counter", "crouch"]:
		var regen: float = 10.0 if (state == "idle" and absf(vx) > 0.45) else 22.0
		stamina = minf(STAMINA_MAX, stamina + regen * dt)

	if opponent != null and (state == "idle" or state == "block" or state == "parry" or state == "counter" or state == "crouch"):
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
	if state == "counter":
		counter_timer -= dt
		if counter_timer <= 0.0:
			state = "idle"
			active_attack = {}
	if state_timer > 0.0:
		state_timer -= dt
		if state == "attack" and not has_hit_this_swing and opponent != null:
			if state_timer < float(active_attack["duration"]) * 0.65:
				var dist: float = absf(position.x - opponent.position.x)
				if dist <= float(active_attack["range"]) and absf(position.y - opponent.position.y) < 1.65:
					has_hit_this_swing = true
					emit_signal("hit_landed", self, opponent, active_attack)
		if state_timer <= 0.0:
			if state == "attack" and not has_hit_this_swing:
				whiff_timer = 0.15
			state = "idle"
			active_attack = {}

	if state == "idle":
		if position.y > 0.15:
			_play_clip("Jump_Loop", 1.0)
		elif absf(vx) > 0.45:
			_play_clip("Jog_Fwd_Loop", 1.15)
		else:
			_play_clip("Sword_Idle", 1.0)
	elif state == "crouch":
		_play_clip("Crouch_Idle_Loop", 1.0)
	elif state == "hitstun":
		_play_clip("Hit_Chest", 1.1)

	_update_slash_trail(state == "attack")

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
