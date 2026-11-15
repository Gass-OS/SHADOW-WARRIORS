extends Node3D

const GameData = preload("res://scripts/GameData.gd")
const AudioSynthScript = preload("res://scripts/AudioSynth.gd")
const Arena3DScript = preload("res://scripts/Arena3D.gd")
const Fighter3DScript = preload("res://scripts/Fighter3D.gd")
const HudWidgets = preload("res://scripts/HudWidgets.gd")

var arena: Node3D
var cam: Camera3D
var audio: Node

var save := {
	"dinars": 500,
	"gems": 25,
	"unlocked": ["kasserini"],
	"weapon_lv": {"kasserini": 1},
	"last_gift_ts": 0,
	"lang": "en",
	"fps": 60
}
const SAVE_PATH := "user://sw_tunisia_save.json"

var selected_idx: int = 0
var game_mode: String = "boss"
var match_active: bool = false
var round_time: float = 99.0
var hitstop: float = 0.0
var shake: float = 0.0
var ai_timer: float = 0.0
var survival_wave: int = 1
var p_rounds: int = 0
var e_rounds: int = 0

var player: Node3D
var enemy: Node3D
var preview_rig: Node3D

var ui_layer: CanvasLayer
var root_ui: Control
var top_currency: Label
var menu_sub_lbl: Label
var menu_title_lbl: Label
var gift_btn: Button
var screen_menu: PanelContainer
var screen_select: PanelContainer
var screen_map: PanelContainer
var screen_settings: PanelContainer
var screen_result: PanelContainer
var combat_hud: Control

var hud_p_name: Label
var hud_e_name: Label
var hud_p_hp: Control
var hud_p_en: Control
var hud_e_hp: Control
var hud_e_en: Control
var hud_p_hp_txt: Label
var hud_e_hp_txt: Label
var hud_p_pips: Label
var hud_e_pips: Label
var hud_timer: Label
var hud_phase: Label
var callout_lbl: Label
var joy_stick: Control
var btn_spc: Control
var btn_ult: Control

var select_detail_lbl: Label
var select_action_btn: Button
var select_upgrade_btn: Button
var result_title: Label
var result_reward: Label

func _ready() -> void:
	_load_save()
	arena = Arena3DScript.new()
	add_child(arena)

	cam = Camera3D.new()
	cam.position = Vector3(0, 2.35, 7.6)
	cam.fov = 44.0
	cam.current = true
	add_child(cam)
	cam.look_at(Vector3(0, 1.25, 0))

	audio = AudioSynthScript.new()
	add_child(audio)

	_build_ui()
	_apply_lang(str(save["lang"]))
	Engine.max_fps = int(save["fps"])

func _load_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				save.merge(parsed, true)

func _persist_save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(save))
	_refresh_currency()

func _refresh_currency() -> void:
	if top_currency != null:
		top_currency.text = "Dinars: %d  |  Gems: %d" % [int(save["dinars"]), int(save["gems"])]
	if gift_btn != null:
		var now_ts: int = int(Time.get_unix_time_from_system())
		var can_claim: bool = (now_ts - int(save.get("last_gift_ts", 0))) >= 3600
		gift_btn.text = "GIFT CHEST READY (+250 Dinars)" if can_claim else "GIFT CLAIMED (Wait 1h)"
		gift_btn.disabled = not can_claim

func _make_btn(txt: String, col: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 44)
	b.modulate = col
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b

func _create_modal_panel(parent: Control, panel_size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11, 0.88)
	sb.border_color = Color(0.95, 0.74, 0.25, 0.88)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = panel_size
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -panel_size.x * 0.5
	p.offset_right = panel_size.x * 0.5
	p.offset_top = -panel_size.y * 0.5
	p.offset_bottom = panel_size.y * 0.5
	parent.add_child(p)
	return p

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	root_ui = Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root_ui)

	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 18
	top_bar.offset_right = -18
	top_bar.offset_top = 8
	top_bar.offset_bottom = 48
	top_bar.add_theme_constant_override("separation", 12)
	root_ui.add_child(top_bar)

	var brand := Label.new()
	brand.text = "SHADOW WARRIORS: TUNISIA"
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(brand)

	top_currency = Label.new()
	top_bar.add_child(top_currency)

	var gear := Button.new()
	gear.text = "Settings"
	gear.focus_mode = Control.FOCUS_NONE
	gear.pressed.connect(_on_open_settings)
	top_bar.add_child(gear)

	screen_menu = _create_modal_panel(root_ui, Vector2(560, 450))
	var m_box := VBoxContainer.new()
	m_box.add_theme_constant_override("separation", 8)
	screen_menu.add_child(m_box)

	menu_sub_lbl = Label.new()
	menu_sub_lbl.modulate = Color(0.96, 0.72, 0.25)
	m_box.add_child(menu_sub_lbl)

	menu_title_lbl = Label.new()
	menu_title_lbl.add_theme_font_size_override("font_size", 24)
	m_box.add_child(menu_title_lbl)

	m_box.add_child(_make_btn("STORY: KASSERINE BOSS (BEST OF 3)", Color(1.0, 0.74, 0.24), func(): _open_select("boss")))
	m_box.add_child(_make_btn("ARENA 1v1 DUEL", Color(0.85, 0.92, 1.0), func(): _open_select("arena")))
	m_box.add_child(_make_btn("SURVIVAL WAVE", Color(0.72, 1.0, 0.80), func(): _open_select("survival")))
	m_box.add_child(_make_btn("TRAINING DOJO", Color(0.80, 0.86, 0.94), func(): _open_select("training")))
	m_box.add_child(_make_btn("TUNISIA MAP (10 REGIONS)", Color(0.95, 0.85, 0.65), _on_open_map))
	gift_btn = _make_btn("GIFT CHEST", Color(0.42, 0.92, 1.0), _on_claim_gift)
	m_box.add_child(gift_btn)
	_refresh_currency()

	screen_select = _create_modal_panel(root_ui, Vector2(720, 410))
	var s_box := VBoxContainer.new()
	s_box.add_theme_constant_override("separation", 10)
	screen_select.add_child(s_box)

	var f_grid := GridContainer.new()
	f_grid.columns = 3
	f_grid.add_theme_constant_override("h_separation", 8)
	f_grid.add_theme_constant_override("v_separation", 8)
	s_box.add_child(f_grid)
	var fighters: Array = GameData.get_fighters()
	for i in fighters.size():
		var f: Dictionary = fighters[i]
		var fb := _make_btn(str(f["name"]), Color(0.92, 0.88, 0.78), _select_fighter.bind(i))
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f_grid.add_child(fb)

	select_detail_lbl = Label.new()
	select_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	s_box.add_child(select_detail_lbl)

	select_upgrade_btn = _make_btn("UPGRADE WEAPON (150 Dinars)", Color(0.95, 0.8, 0.35), _upgrade_selected_weapon)
	s_box.add_child(select_upgrade_btn)

	var s_foot := HBoxContainer.new()
	s_foot.add_theme_constant_override("separation", 12)
	s_box.add_child(s_foot)
	var back_b := _make_btn("BACK", Color(0.8, 0.8, 0.8), _on_back_from_select)
	back_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_action_btn = _make_btn("FIGHT!", Color(1.0, 0.72, 0.25), _on_select_primary_action)
	select_action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s_foot.add_child(back_b)
	s_foot.add_child(select_action_btn)

	screen_map = _create_modal_panel(root_ui, Vector2(700, 440))
	var map_box := VBoxContainer.new()
	map_box.add_theme_constant_override("separation", 12)
	screen_map.add_child(map_box)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	map_box.add_child(grid)
	for r in GameData.get_regions():
		var rl := Label.new()
		rl.text = "%s — %s [%s]" % [str(r["name"]), str(r["boss"]), "OPEN" if bool(r["unlocked"]) else "LOCKED"]
		grid.add_child(rl)
	map_box.add_child(_make_btn("BACK", Color(0.9, 0.9, 0.9), _on_back_to_menu))

	screen_settings = _create_modal_panel(root_ui, Vector2(520, 310))
	var set_box := VBoxContainer.new()
	set_box.add_theme_constant_override("separation", 12)
	screen_settings.add_child(set_box)
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 8)
	set_box.add_child(lang_row)
	for lc in [["English", "en"], ["Français", "fr"], ["العربية", "ar"]]:
		var code: String = lc[1]
		var lb := _make_btn(lc[0], Color(0.9, 0.9, 0.9), _apply_lang.bind(code))
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lang_row.add_child(lb)
	var fps_row := HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", 8)
	set_box.add_child(fps_row)
	for fps_val in [30, 60]:
		var target_fps: int = fps_val
		var fb := _make_btn("%d FPS" % target_fps, Color(0.9, 0.85, 0.7), _set_fps.bind(target_fps))
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fps_row.add_child(fb)
	set_box.add_child(_make_btn("DONE", Color(1.0, 0.75, 0.3), _on_close_settings))

	screen_result = _create_modal_panel(root_ui, Vector2(460, 280))
	var r_box := VBoxContainer.new()
	r_box.add_theme_constant_override("separation", 12)
	screen_result.add_child(r_box)
	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 32)
	r_box.add_child(result_title)
	result_reward = Label.new()
	result_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r_box.add_child(result_reward)
	r_box.add_child(_make_btn("REMATCH", Color(1.0, 0.72, 0.25), _start_match))
	r_box.add_child(_make_btn("MAIN MENU", Color(0.85, 0.85, 0.85), _on_back_to_menu))

	_build_combat_hud(root_ui)
	_show_panel(screen_menu)

func _build_combat_hud(parent: Control) -> void:
	combat_hud = Control.new()
	combat_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	combat_hud.visible = false
	parent.add_child(combat_hud)

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 22
	top.offset_right = -22
	top.offset_top = 46
	top.offset_bottom = 122
	top.add_theme_constant_override("separation", 12)
	combat_hud.add_child(top)

	# Player HUD (Slanted Gold HP + Cyan Energy)
	var p_col := VBoxContainer.new()
	p_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(p_col)
	var p_hdr := HBoxContainer.new()
	p_col.add_child(p_hdr)
	hud_p_pips = Label.new()
	hud_p_pips.modulate = Color(1.0, 0.82, 0.3)
	p_hdr.add_child(hud_p_pips)
	hud_p_name = Label.new()
	hud_p_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_hdr.add_child(hud_p_name)
	hud_p_hp_txt = Label.new()
	p_hdr.add_child(hud_p_hp_txt)

	hud_p_hp = HudWidgets.SWSlantedBar.new()
	hud_p_hp.custom_minimum_size = Vector2(0, 16)
	hud_p_hp.fill_col = Color(0.95, 0.76, 0.22)
	p_col.add_child(hud_p_hp)
	hud_p_en = HudWidgets.SWSlantedBar.new()
	hud_p_en.custom_minimum_size = Vector2(0, 9)
	hud_p_en.fill_col = Color(0.24, 0.84, 0.96)
	p_col.add_child(hud_p_en)

	# Center Timer
	var c_col := VBoxContainer.new()
	c_col.custom_minimum_size = Vector2(82, 0)
	top.add_child(c_col)
	hud_timer = Label.new()
	hud_timer.text = "99"
	hud_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_timer.add_theme_font_size_override("font_size", 30)
	c_col.add_child(hud_timer)
	hud_phase = Label.new()
	hud_phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_col.add_child(hud_phase)

	# Enemy HUD
	var e_col := VBoxContainer.new()
	e_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(e_col)
	var e_hdr := HBoxContainer.new()
	e_col.add_child(e_hdr)
	hud_e_hp_txt = Label.new()
	e_hdr.add_child(hud_e_hp_txt)
	hud_e_name = Label.new()
	hud_e_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_e_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e_hdr.add_child(hud_e_name)
	hud_e_pips = Label.new()
	hud_e_pips.modulate = Color(1.0, 0.42, 0.32)
	e_hdr.add_child(hud_e_pips)

	hud_e_hp = HudWidgets.SWSlantedBar.new()
	hud_e_hp.custom_minimum_size = Vector2(0, 16)
	hud_e_hp.fill_col = Color(0.95, 0.76, 0.22)
	hud_e_hp.flip_rtl = true
	e_col.add_child(hud_e_hp)
	hud_e_en = HudWidgets.SWSlantedBar.new()
	hud_e_en.custom_minimum_size = Vector2(0, 9)
	hud_e_en.fill_col = Color(0.24, 0.84, 0.96)
	hud_e_en.flip_rtl = true
	e_col.add_child(hud_e_en)

	callout_lbl = Label.new()
	callout_lbl.set_anchors_preset(Control.PRESET_CENTER)
	callout_lbl.add_theme_font_size_override("font_size", 36)
	callout_lbl.modulate = Color(0.32, 0.92, 1.0)
	callout_lbl.visible = false
	combat_hud.add_child(callout_lbl)

	# Translucent Xbox-style Virtual Joystick (Bottom Left)
	joy_stick = HudWidgets.SWJoystick.new()
	joy_stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joy_stick.offset_left = 24
	joy_stick.offset_right = 184
	joy_stick.offset_top = -184
	joy_stick.offset_bottom = -24
	combat_hud.add_child(joy_stick)

	# Modern Circular Xbox-Colored Multi-Touch Action Cluster (Bottom Right)
	var pad := GridContainer.new()
	pad.columns = 3
	pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	pad.offset_left = -268
	pad.offset_right = -20
	pad.offset_top = -186
	pad.offset_bottom = -20
	pad.add_theme_constant_override("h_separation", 10)
	pad.add_theme_constant_override("v_separation", 10)
	combat_hud.add_child(pad)

	btn_ult = _circle_btn("ULT", "RB", Color(0.22, 0.88, 1.0), func(): _try_attack("ult"), _on_noop)
	btn_spc = _circle_btn("SPC", "LB", Color(0.75, 0.45, 1.0), func(): _try_attack("spc"), _on_noop)
	var b_jump := _circle_btn("JUMP", "UP", Color(0.92, 0.92, 0.92), _on_jump_pressed, _on_noop)
	var b_block := _circle_btn("PARRY", "B", Color(0.95, 0.28, 0.28), _on_block_down, _on_block_up)
	var b_heavy := _circle_btn("HEAVY", "Y", Color(0.98, 0.78, 0.20), func(): _try_attack("heavy"), _on_noop)
	var b_light := _circle_btn("STRIKE", "X", Color(0.25, 0.65, 1.0), func(): _try_attack("light"), _on_noop)

	for b in [btn_ult, btn_spc, b_jump, b_block, b_heavy, b_light]:
		pad.add_child(b)

	var b_dodge := _circle_btn("DODGE", "A", Color(0.24, 0.86, 0.42), _on_dodge_pressed, _on_noop, 64.0)
	b_dodge.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	b_dodge.offset_left = 194
	b_dodge.offset_right = 258
	b_dodge.offset_top = -88
	b_dodge.offset_bottom = -24
	combat_hud.add_child(b_dodge)

	var exit_b := Button.new()
	exit_b.text = "X"
	exit_b.focus_mode = Control.FOCUS_NONE
	exit_b.set_anchors_preset(Control.PRESET_CENTER_TOP)
	exit_b.offset_left = -18
	exit_b.offset_right = 18
	exit_b.offset_top = 122
	exit_b.offset_bottom = 156
	exit_b.pressed.connect(_on_exit_match)
	combat_hud.add_child(exit_b)

func _circle_btn(lbl: String, sub: String, col: Color, cb_down: Callable, cb_up: Callable, sz: float = 74.0) -> Control:
	var b := HudWidgets.SWCircleBtn.new()
	b.setup_btn(lbl, sub, col, sz)
	b.btn_down.connect(cb_down)
	b.btn_up.connect(cb_up)
	return b

func _on_noop() -> void:
	pass

func _on_claim_gift() -> void:
	save["dinars"] = int(save["dinars"]) + 250
	save["gems"] = int(save["gems"]) + 15
	save["last_gift_ts"] = int(Time.get_unix_time_from_system())
	_persist_save()
	audio.play_parry()

func _on_open_settings() -> void:
	_show_panel(screen_settings)

func _on_close_settings() -> void:
	_show_panel(null if match_active else screen_menu)

func _on_open_map() -> void:
	_show_panel(screen_map)

func _on_back_to_menu() -> void:
	_show_panel(screen_menu)

func _on_back_from_select() -> void:
	_clear_preview()
	_show_panel(screen_menu)

func _on_jump_pressed() -> void:
	if player != null:
		player.jump()

func _on_dodge_pressed() -> void:
	if player != null and player.dodge(joy_stick.axis_x):
		audio.play_whoosh()

func _on_block_down() -> void:
	if player != null:
		player.set_block(true)

func _on_block_up() -> void:
	if player != null:
		player.set_block(false)

func _on_exit_match() -> void:
	match_active = false
	audio.combat_music_active = false
	combat_hud.visible = false
	_show_panel(screen_menu)

func _set_fps(fps_val: int) -> void:
	save["fps"] = fps_val
	Engine.max_fps = fps_val
	_persist_save()

func _try_attack(type: String) -> void:
	if player != null and player.start_attack(type):
		audio.play_whoosh()

func _show_panel(panel: PanelContainer) -> void:
	for p in [screen_menu, screen_select, screen_map, screen_settings, screen_result]:
		p.visible = (p == panel)

func _open_select(mode: String) -> void:
	game_mode = mode
	survival_wave = 1
	p_rounds = 0
	e_rounds = 0
	_select_fighter(selected_idx)
	_show_panel(screen_select)

func _clear_preview() -> void:
	if preview_rig != null:
		preview_rig.queue_free()
		preview_rig = null

func _is_fighter_unlocked(f_id: String) -> bool:
	var arr: Array = save.get("unlocked", ["kasserini"])
	return arr.has(f_id)

func _select_fighter(idx: int) -> void:
	selected_idx = idx
	var f: Dictionary = GameData.get_fighters()[idx]
	var f_id: String = str(f["id"])
	var unlocked: bool = _is_fighter_unlocked(f_id)
	var lv: int = int(save["weapon_lv"].get(f_id, 1))
	select_detail_lbl.text = "%s (%s)\n%s\nHP: %d  |  ATK: %d  |  SPD: %d" % [
		str(f["name"]), ("LV %d" % lv) if unlocked else ("LOCKED - %d Dinars" % int(f["cost"])),
		str(f["style"]), int(float(f["hp"]) + float(lv - 1) * 20.0),
		int(float(f["atk"]) + float(lv - 1) * 4.5), int(float(f["speed"]) * 15.0)
	]
	select_upgrade_btn.visible = unlocked
	select_action_btn.text = "FIGHT!" if unlocked else ("UNLOCK (%d Dinars)" % int(f["cost"]))

	_clear_preview()
	preview_rig = Fighter3DScript.new()
	preview_rig.setup(f, true, lv)
	preview_rig.position = Vector3(0, 0, 2.8)
	add_child(preview_rig)

func _on_select_primary_action() -> void:
	var f: Dictionary = GameData.get_fighters()[selected_idx]
	var f_id: String = str(f["id"])
	if _is_fighter_unlocked(f_id):
		_start_match()
	else:
		var cost: int = int(f["cost"])
		if int(save["dinars"]) >= cost:
			save["dinars"] = int(save["dinars"]) - cost
			var arr: Array = save.get("unlocked", ["kasserini"])
			arr.append(f_id)
			save["unlocked"] = arr
			save["weapon_lv"][f_id] = 1
			_persist_save()
			audio.play_parry()
			_select_fighter(selected_idx)

func _upgrade_selected_weapon() -> void:
	var f_id: String = str(GameData.get_fighters()[selected_idx]["id"])
	if int(save["dinars"]) >= 150:
		save["dinars"] = int(save["dinars"]) - 150
		save["weapon_lv"][f_id] = int(save["weapon_lv"].get(f_id, 1)) + 1
		_persist_save()
		_select_fighter(selected_idx)

func _apply_lang(lang: String) -> void:
	save["lang"] = lang
	var i18n := GameData.get_i18n()
	var dict: Dictionary = i18n.get(lang, i18n["en"])
	var is_rtl := (lang == "ar")
	root_ui.layout_direction = Control.LAYOUT_DIRECTION_RTL if is_rtl else Control.LAYOUT_DIRECTION_LTR
	menu_sub_lbl.text = str(dict["subtitle"])
	menu_title_lbl.text = str(dict["title"])
	_persist_save()

func _start_match() -> void:
	_clear_preview()
	if player != null:
		player.queue_free()
	if enemy != null:
		enemy.queue_free()

	var fighters := GameData.get_fighters()
	var p_cfg: Dictionary = fighters[selected_idx]
	var p_lv: int = int(save["weapon_lv"].get(p_cfg["id"], 1))
	var e_cfg: Dictionary = GameData.get_boss() if game_mode == "boss" else fighters[(selected_idx + survival_wave) % fighters.size()]

	player = Fighter3DScript.new()
	player.setup(p_cfg, true, p_lv)
	player.position = Vector3(-2.6, 0, 0)
	player.hit_landed.connect(_on_hit_landed)
	player.defeated.connect(_on_player_defeated)
	add_child(player)

	enemy = Fighter3DScript.new()
	enemy.setup(e_cfg, false, 1)
	enemy.position = Vector3(2.6, 0, 0)
	enemy.hit_landed.connect(_on_hit_landed)
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)

	hud_p_name.text = str(p_cfg["name"])
	hud_e_name.text = str(e_cfg["name"]) if game_mode != "survival" else "%s (Wave %d)" % [str(e_cfg["name"]), survival_wave]
	hud_p_pips.text = "● ".repeat(p_rounds) + "○ ".repeat(2 - p_rounds)
	hud_e_pips.text = "● ".repeat(e_rounds) + "○ ".repeat(2 - e_rounds)
	round_time = 99.0
	match_active = true
	audio.combat_music_active = true
	_show_panel(null)
	combat_hud.visible = true

func _on_player_defeated(_f: Node3D) -> void:
	_handle_round_end(false)

func _on_enemy_defeated(_f: Node3D) -> void:
	_handle_round_end(true)

func _on_hit_landed(attacker: Node3D, defender: Node3D, atk_data: Dictionary) -> void:
	if defender.state == "dodge" or defender.state == "dead":
		return
	if defender.state == "parry" and not bool(atk_data["unblockable"]):
		audio.play_parry()
		hitstop = 0.12
		shake = 0.24
		defender.energy = minf(100.0, float(defender.energy) + 25.0)
		attacker.state = "hitstun"
		attacker.state_timer = 0.75
		_show_callout(str(GameData.get_i18n()[save["lang"]]["parry"]))
		return

	var blocked: bool = (str(defender.state) == "block") and not bool(atk_data["unblockable"])
	var dmg: float = maxf(2.0, roundf(float(atk_data["damage"]) * 0.18)) if blocked else float(atk_data["damage"])
	if game_mode != "training":
		defender.hp = maxf(0.0, float(defender.hp) - dmg)
	attacker.energy = minf(100.0, float(attacker.energy) + (12.0 if str(atk_data["type"]) == "light" else 18.0))

	audio.play_hit(str(atk_data["type"]) != "light")
	hitstop = 0.04 if str(atk_data["type"]) == "light" else 0.09
	shake = 0.08 if blocked else (0.38 if str(atk_data["type"]) == "ult" else 0.16)

	defender.vx = float(attacker.facing) * (3.0 if blocked else (8.5 if str(atk_data["type"]) == "ult" else 5.2))
	if not blocked:
		defender.state = "hitstun"
		defender.state_timer = 0.24 if str(atk_data["type"]) == "light" else 0.42

	if float(defender.hp) <= 0.0:
		defender.state = "dead"
		defender.emit_signal("defeated", defender)

func _show_callout(txt: String) -> void:
	callout_lbl.text = txt
	callout_lbl.visible = true
	get_tree().create_timer(0.75).timeout.connect(_hide_callout)

func _hide_callout() -> void:
	if callout_lbl != null:
		callout_lbl.visible = false

func _handle_round_end(player_won: bool) -> void:
	if not match_active:
		return
	if game_mode == "survival" and player_won:
		survival_wave += 1
		save["dinars"] = int(save["dinars"]) + 120
		_persist_save()
		_start_match()
		return

	if game_mode == "boss":
		if player_won: p_rounds += 1
		else: e_rounds += 1
		if p_rounds < 2 and e_rounds < 2:
			match_active = false
			_show_callout(str(GameData.get_i18n()[save["lang"]]["ko"]))
			get_tree().create_timer(1.1).timeout.connect(_start_match)
			return

	match_active = false
	audio.combat_music_active = false
	var d: Dictionary = GameData.get_i18n().get(save["lang"], GameData.get_i18n()["en"])
	result_title.text = str(d["victory"]) if player_won else str(d["defeat"])
	var r_dinars: int = (380 if game_mode == "boss" else 160) if player_won else 50
	var r_gems: int = 15 if (player_won and game_mode == "boss") else 0
	save["dinars"] = int(save["dinars"]) + r_dinars
	save["gems"] = int(save["gems"]) + r_gems
	p_rounds = 0
	e_rounds = 0
	_persist_save()
	result_reward.text = "+%d Dinars  |  +%d Gems" % [r_dinars, r_gems]
	get_tree().create_timer(0.85).timeout.connect(_show_result_overlay)

func _show_result_overlay() -> void:
	combat_hud.visible = false
	_show_panel(screen_result)

func _process(delta: float) -> void:
	if preview_rig != null:
		preview_rig.rotation.y += delta * 0.9

	if not match_active or player == null or enemy == null:
		return

	if hitstop > 0.0:
		hitstop -= delta
		return

	var move_x: float = joy_stick.axis_x
	if joy_stick.axis_y < -0.65:
		player.jump()
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_x += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move_x -= 1.0
	if player.state == "idle" and absf(move_x) > 0.12:
		player.vx = clampf(move_x, -1.0, 1.0) * float(player.move_speed)

	player.step_fighter(delta, enemy)
	_step_enemy_ai(delta)
	enemy.step_fighter(delta, player)

	if game_mode != "training":
		round_time = maxf(0.0, round_time - delta)
		hud_timer.text = str(int(ceilf(round_time)))
		if round_time <= 0.0:
			_handle_round_end(float(player.hp) >= float(enemy.hp))
	else:
		hud_timer.text = "INF"

	var mid_x: float = (player.position.x + enemy.position.x) * 0.5
	var span: float = absf(player.position.x - enemy.position.x)
	var target_z: float = clampf(5.6 + span * 0.65, 6.2, 10.5)
	var sx: float = randf_range(-shake, shake) if shake > 0.0 else 0.0
	var sy: float = randf_range(-shake, shake) if shake > 0.0 else 0.0
	shake = maxf(0.0, shake - delta * 1.8)

	cam.position.x = lerpf(cam.position.x, mid_x, delta * 6.0) + sx
	cam.position.z = lerpf(cam.position.z, target_z, delta * 5.0)
	cam.position.y = 1.95 + sy
	cam.look_at(Vector3(cam.position.x, 1.15, 0.0))

	hud_p_hp.set_ratio(float(player.hp) / maxf(1.0, float(player.max_hp)))
	hud_p_en.set_ratio(float(player.energy) / 100.0)
	hud_e_hp.set_ratio(float(enemy.hp) / maxf(1.0, float(enemy.max_hp)))
	hud_e_en.set_ratio(float(enemy.energy) / 100.0)
	hud_p_hp_txt.text = "%d / %d" % [int(player.hp), int(player.max_hp)]
	hud_e_hp_txt.text = "%d / %d" % [int(enemy.hp), int(enemy.max_hp)]
	btn_spc.set_enabled_state(float(player.energy) >= 40.0)
	btn_ult.set_enabled_state(float(player.energy) >= 100.0)

func _step_enemy_ai(delta: float) -> void:
	if enemy.state == "dead" or game_mode == "training":
		return
	var hp_pct: float = float(enemy.hp) / float(enemy.max_hp)
	var phase: int = 3 if hp_pct <= 0.25 else (2 if hp_pct <= 0.6 else 1)
	if bool(enemy.cfg.get("is_boss", false)):
		hud_phase.text = "PHASE %d" % phase
		enemy.armor_mat.emission_enabled = phase >= 2
		enemy.armor_mat.emission = Color(0.85, 0.1, 0.1) if phase == 3 else Color(0.65, 0.3, 0.05)
	else:
		hud_phase.text = "ARENA AI"

	var dist: float = absf(player.position.x - enemy.position.x)
	if dist > 2.0 and enemy.state == "idle":
		var dir: float = 1.0 if player.position.x > enemy.position.x else -1.0
		enemy.vx = dir * float(enemy.move_speed) * (1.22 if phase == 3 else 1.0)

	ai_timer -= delta
	if ai_timer > 0.0:
		return
	ai_timer = 0.22 if phase == 3 else (0.30 if phase == 2 else 0.40)

	if player.state == "attack" and dist < 2.5 and randf() < 0.42:
		enemy.set_block(true)
		get_tree().create_timer(0.38).timeout.connect(_release_enemy_block)
		return

	if dist <= 2.35:
		if float(enemy.energy) >= 100.0 and phase >= 2:
			enemy.start_attack("ult")
			return
		if float(enemy.energy) >= 40.0 and randf() < 0.35:
			enemy.start_attack("spc")
			return
		enemy.start_attack("light" if randf() < 0.6 else "heavy")

func _release_enemy_block() -> void:
	if enemy != null:
		enemy.set_block(false)
