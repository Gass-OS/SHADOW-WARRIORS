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
	"fps": 60,
	"ai_difficulty": "normal",
	"wins": 0
}
const SAVE_PATH := "user://sw_tunisia_save.json"

# v0.3.0 AI difficulty table
const AI_DIFF := {
	"easy": {"react": 0.55, "block": 0.15, "spc": 0.10, "use_ult": false, "ult_phase": 99, "dmg": 0.8, "approach": 0.85, "dodge": 0.0},
	"normal": {"react": 0.40, "block": 0.42, "spc": 0.35, "use_ult": true, "ult_phase": 2, "dmg": 1.0, "approach": 1.0, "dodge": 0.0},
	"hard": {"react": 0.18, "block": 0.60, "spc": 0.55, "use_ult": true, "ult_phase": 1, "dmg": 1.15, "approach": 1.15, "dodge": 0.35}
}

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

# --- v0.3.0 intro ---
var intro_active: bool = false
var intro_cards: Array = []
var intro_card_idx: int = 0
var intro_card_t: float = 0.0
var intro_cue_played: bool = false

# --- v0.3.0 fatality ---
var fatality_active: bool = false
var fatality_pending: bool = false
var fatality_bonus: int = 0
var fatality_player_won: bool = false

# --- v0.3.0 ability FX tracking (probe-visible) ---
var bursts_spawned: int = 0
var last_burst_color: Color = Color.WHITE

# --- v0.3.0 joystick auto-defend (hold stick away from enemy) ---
var joy_block_active: bool = false

var player: Node3D
var enemy: Node3D
var preview_rig: Node3D

var ui_layer: CanvasLayer
var root_ui: Control
var top_bar: HBoxContainer
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
var hud_p_st: Control
var hud_e_st: Control
var hud_p_hp_txt: Label
var hud_e_hp_txt: Label
var hud_p_pips: Label
var hud_e_pips: Label
var hud_timer: Label
var hud_phase: Label
var hud_ai_lbl: Label
var callout_lbl: Label
var intro_lbl: Label
var fatality_lbl: Label
var fatality_btn: Control
var flash_rect: ColorRect
var joy_stick: Control
var btn_spc: Control
var btn_ult: Control

var select_detail_lbl: Label
var select_train_hint_lbl: Label
var select_action_btn: Button
var select_upgrade_btn: Button
var diff_btns: Dictionary = {}
var result_title: Label
var result_reward: Label

func _ready() -> void:
	_load_save()
	if not save.has("ai_difficulty"):
		save["ai_difficulty"] = "normal"
	if not save.has("wins"):
		save["wins"] = 0
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
		top_currency.text = "Dinars: %d  |  Gems: %d  |  Wins: %d" % [int(save["dinars"]), int(save["gems"]), int(save.get("wins", 0))]
	if gift_btn != null:
		var now_ts: int = int(Time.get_unix_time_from_system())
		var can_claim: bool = (now_ts - int(save.get("last_gift_ts", 0))) >= 3600
		gift_btn.text = "GIFT CHEST READY (+250 Dinars)" if can_claim else "GIFT CLAIMED (Wait 1h)"
		gift_btn.disabled = not can_claim

func _tr(key: String) -> String:
	var i18n := GameData.get_i18n()
	var dict: Dictionary = i18n.get(str(save.get("lang", "en")), i18n["en"])
	if dict.has(key):
		return str(dict[key])
	return str(i18n["en"].get(key, key))

func _current_diff() -> Dictionary:
	return AI_DIFF.get(str(save.get("ai_difficulty", "normal")), AI_DIFF["normal"])

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

	top_bar = HBoxContainer.new()
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

	screen_select = _create_modal_panel(root_ui, Vector2(720, 500))
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

	# v0.3.1 training hint: any warrior is free to try in the dojo
	select_train_hint_lbl = Label.new()
	select_train_hint_lbl.text = "TRAINING: try any warrior free"
	select_train_hint_lbl.modulate = Color(0.42, 0.92, 1.0)
	select_train_hint_lbl.visible = false
	s_box.add_child(select_train_hint_lbl)

	select_upgrade_btn = _make_btn("UPGRADE WEAPON (150 Dinars)", Color(0.95, 0.8, 0.35), _upgrade_selected_weapon)
	s_box.add_child(select_upgrade_btn)

	# v0.3.0 AI difficulty selector (above FIGHT)
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 8)
	s_box.add_child(diff_row)
	for d_key in ["easy", "normal", "hard"]:
		var db := _make_btn(_tr(d_key).to_upper(), Color(0.85, 0.85, 0.85), _set_difficulty.bind(d_key))
		db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		diff_row.add_child(db)
		diff_btns[d_key] = db
	_refresh_diff_buttons()

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
	top_bar.visible = true
	parent.add_child(combat_hud)

	# Fullscreen flash overlay for ability / fatality FX (mouse ignored)
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	combat_hud.add_child(flash_rect)

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 22
	top.offset_right = -22
	top.offset_top = 14
	top.offset_bottom = 90
	top.add_theme_constant_override("separation", 12)
	combat_hud.add_child(top)

	# Player HUD (Slanted Gold HP + Cyan Energy + Green Stamina)
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
	hud_p_st = HudWidgets.SWSlantedBar.new()
	hud_p_st.custom_minimum_size = Vector2(0, 5)
	hud_p_st.fill_col = Color(0.30, 0.90, 0.35)
	p_col.add_child(hud_p_st)

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
	hud_ai_lbl = Label.new()
	hud_ai_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_ai_lbl.add_theme_font_size_override("font_size", 13)
	hud_ai_lbl.modulate = Color(0.85, 0.85, 0.85)
	hud_ai_lbl.text = "AI: NORMAL"
	c_col.add_child(hud_ai_lbl)

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
	hud_e_st = HudWidgets.SWSlantedBar.new()
	hud_e_st.custom_minimum_size = Vector2(0, 5)
	hud_e_st.fill_col = Color(0.30, 0.90, 0.35)
	hud_e_st.flip_rtl = true
	e_col.add_child(hud_e_st)

	callout_lbl = Label.new()
	callout_lbl.set_anchors_preset(Control.PRESET_CENTER)
	callout_lbl.add_theme_font_size_override("font_size", 36)
	callout_lbl.modulate = Color(0.32, 0.92, 1.0)
	callout_lbl.visible = false
	combat_hud.add_child(callout_lbl)

	# Intro card label (NAME vs NAME / ROUND N / FIGHT!)
	intro_lbl = Label.new()
	intro_lbl.set_anchors_preset(Control.PRESET_CENTER)
	intro_lbl.offset_left = -420
	intro_lbl.offset_right = 420
	intro_lbl.offset_top = -50
	intro_lbl.offset_bottom = 50
	intro_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_lbl.add_theme_font_size_override("font_size", 44)
	intro_lbl.modulate = Color(1.0, 0.82, 0.30)
	intro_lbl.visible = false
	combat_hud.add_child(intro_lbl)

	# Fatality banner label
	fatality_lbl = Label.new()
	fatality_lbl.set_anchors_preset(Control.PRESET_CENTER)
	fatality_lbl.offset_left = -420
	fatality_lbl.offset_right = 420
	fatality_lbl.offset_top = -60
	fatality_lbl.offset_bottom = 60
	fatality_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fatality_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fatality_lbl.add_theme_font_size_override("font_size", 46)
	fatality_lbl.modulate = Color(1.0, 0.25, 0.15)
	fatality_lbl.visible = false
	combat_hud.add_child(fatality_lbl)

	# Fatality button (bottom center, gold/red circle)
	fatality_btn = _circle_btn("FATALITY", "FINISH", Color(1.0, 0.25, 0.15), _on_fatality_pressed, _on_noop, 96.0)
	fatality_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	fatality_btn.offset_left = -48
	fatality_btn.offset_right = 48
	fatality_btn.offset_top = -160
	fatality_btn.offset_bottom = -64
	fatality_btn.visible = false
	combat_hud.add_child(fatality_btn)

	# Translucent Xbox-style Virtual Joystick (Bottom Left)
	joy_stick = HudWidgets.SWJoystick.new()
	joy_stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joy_stick.offset_left = 24
	joy_stick.offset_right = 184
	joy_stick.offset_top = -184
	joy_stick.offset_bottom = -24
	combat_hud.add_child(joy_stick)

	# v0.3.0 action cluster: Xbox-style DIAMOND of exactly 4 circular
	# buttons, bottom-right. Top Y = HEAVY, left X = STRIKE, right B = ULT,
	# bottom A = ABILITY (label = fighter's ability short name). Jump and
	# defend live on the joystick now (up = jump, back = block, down =
	# crouch), so there is no JUMP or PARRY button here. DODGE stays
	# bottom-left near the joystick.
	var pad := Control.new()
	pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	pad.offset_left = -260
	pad.offset_right = -20
	pad.offset_top = -230
	pad.offset_bottom = -20
	combat_hud.add_child(pad)

	btn_ult = _circle_btn("ULT", "B", Color(0.95, 0.28, 0.28), func(): _try_attack("ult"), _on_noop)
	btn_spc = _circle_btn("SPC", "A", Color(0.24, 0.86, 0.42), func(): _try_attack("spc"), _on_noop)
	var b_heavy := _circle_btn("HEAVY", "Y", Color(0.98, 0.78, 0.20), func(): _try_attack("heavy"), _on_noop)
	var b_light := _circle_btn("STRIKE", "X", Color(0.25, 0.65, 1.0), func(): _try_attack("light"), _on_noop)

	# Diamond positions inside the 240x210 pad (buttons are 74px):
	# Y top (83, 0), X left (0, 68), B right (166, 68), A bottom (83, 136)
	b_heavy.position = Vector2(83, 0)
	b_light.position = Vector2(0, 68)
	btn_ult.position = Vector2(166, 68)
	btn_spc.position = Vector2(83, 136)
	pad.add_child(b_heavy)
	pad.add_child(b_light)
	pad.add_child(btn_ult)
	pad.add_child(btn_spc)

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

# --- v0.3.0 ability FX helpers ---

func _ability_color(kind: String) -> Color:
	match kind:
		"fire":
			return Color(1.0, 0.45, 0.10)
		"shadow":
			return Color(0.65, 0.35, 1.0)
		"counter":
			return Color(1.0, 0.82, 0.25)
		"blink":
			return Color(0.30, 0.65, 1.0)
		"quake":
			return Color(0.62, 0.50, 0.34)
		"sand":
			return Color(1.0, 0.62, 0.20)
		"slam":
			return Color(1.0, 0.20, 0.15)
		"lunge":
			return Color(1.0, 0.85, 0.30)
		"cleave":
			return Color(1.0, 0.35, 0.12)
		"tide":
			return Color(0.25, 0.90, 0.95)
		_:
			return Color(0.75, 0.45, 1.0)

func spawn_burst(pos: Vector3, col: Color, count: int = 40, speed: float = 6.0) -> void:
	var p := GPUParticles3D.new()
	p.amount = count
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.9
	p.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = speed * 0.5
	mat.initial_velocity_max = speed
	mat.gravity = Vector3(0, -4, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.12
	p.process_material = mat
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.albedo_color = col
	quad.material = qm
	p.draw_pass_1 = quad
	p.position = pos
	add_child(p)
	bursts_spawned += 1
	last_burst_color = col
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)

func flash_screen(col: Color, alpha: float = 0.22) -> void:
	if flash_rect == null:
		return
	flash_rect.color = Color(col.r, col.g, col.b, alpha)
	var tw := create_tween()
	tw.tween_property(flash_rect, "color:a", 0.0, 0.4)

func _on_attack_started(attacker: Node3D, atk_data: Dictionary) -> void:
	if str(atk_data.get("type", "")) != "spc":
		return
	var kind: String = str(atk_data.get("kind", ""))
	if kind == "":
		return
	var col: Color = _ability_color(kind)
	var foe: Node3D = enemy if attacker == player else player
	# Teleport abilities reposition at cast time (Main knows the opponent)
	if foe != null:
		if kind == "shadow_dash":
			attacker.position.x = clampf(foe.position.x - attacker.facing * 1.2, -8.5, 8.5)
		elif kind == "blink":
			attacker.position.x = clampf(foe.position.x + attacker.facing * 1.2, -8.5, 8.5)
	spawn_burst(Vector3(attacker.position.x, 1.2, 0), col, 40 if kind != "quake" else 70, 6.0 if kind != "quake" else 4.0)
	flash_screen(col, 0.30 if kind == "quake" else 0.22)
	if kind == "quake":
		shake = maxf(shake, 0.5)
	audio.play_ability(kind)

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

func _on_dodge_pressed() -> void:
	if match_active and player != null and player.dodge(joy_stick.axis_x):
		audio.play_whoosh()

func _on_exit_match() -> void:
	match_active = false
	intro_active = false
	joy_block_active = false
	_end_fatality_ui()
	audio.combat_music_active = false
	combat_hud.visible = false
	top_bar.visible = true
	_show_panel(screen_menu)

func _set_fps(fps_val: int) -> void:
	save["fps"] = fps_val
	Engine.max_fps = fps_val
	_persist_save()

func _set_difficulty(d_key: String) -> void:
	save["ai_difficulty"] = d_key
	_persist_save()
	_refresh_diff_buttons()
	_refresh_ai_label()

func _refresh_diff_buttons() -> void:
	var cur: String = str(save.get("ai_difficulty", "normal"))
	for k in diff_btns.keys():
		var b: Button = diff_btns[k]
		b.modulate = Color(1.0, 0.8, 0.3) if str(k) == cur else Color(0.65, 0.65, 0.65)

func _refresh_ai_label() -> void:
	if hud_ai_lbl != null:
		hud_ai_lbl.text = "AI: " + _tr(str(save.get("ai_difficulty", "normal"))).to_upper()

func _try_attack(type: String) -> void:
	if not match_active:
		return
	if player != null and player.start_attack(type):
		if type != "spc":
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

# --- v0.3.1 unlock by wins: grant every fighter whose wins_needed is met ---
func _check_unlocks() -> Array:
	var newly: Array = []
	var wins: int = int(save.get("wins", 0))
	var arr: Array = save.get("unlocked", ["kasserini"])
	for f in GameData.get_fighters():
		var f_id: String = str(f["id"])
		if not arr.has(f_id) and wins >= int(f.get("wins_needed", 0)):
			arr.append(f_id)
			newly.append(str(f["name"]))
			if not (save.get("weapon_lv", {}) as Dictionary).has(f_id):
				(save["weapon_lv"] as Dictionary)[f_id] = 1
	save["unlocked"] = arr
	return newly

func _select_fighter(idx: int) -> void:
	selected_idx = idx
	var f: Dictionary = GameData.get_fighters()[idx]
	var f_id: String = str(f["id"])
	var unlocked: bool = _is_fighter_unlocked(f_id)
	var lv: int = int(save["weapon_lv"].get(f_id, 1))
	var ab: Dictionary = f.get("ability", {})
	var wins: int = int(save.get("wins", 0))
	var wins_needed: int = int(f.get("wins_needed", 0))
	var lock_txt: String = "LV %d" % lv
	if not unlocked:
		lock_txt = "LOCKED — Win %d fight%s to unlock (you have %d win%s)" % [
			wins_needed, "" if wins_needed == 1 else "s",
			wins, "" if wins == 1 else "s"]
	select_detail_lbl.text = "%s (%s)\n%s\n%s\nAbility: %s — %s\nHP: %d  |  ATK: %d  |  SPD: %d" % [
		str(f["name"]), lock_txt,
		str(f["style"]), str(f.get("lore", "")),
		str(ab.get("name", "—")), str(ab.get("desc", "")),
		int(float(f["hp"]) + float(lv - 1) * 20.0),
		int(float(f["atk"]) + float(lv - 1) * 4.5), int(float(f["speed"]) * 15.0)
	]
	select_upgrade_btn.visible = unlocked
	if unlocked:
		select_action_btn.text = "FIGHT!"
		select_action_btn.disabled = false
	elif game_mode == "training":
		select_action_btn.text = "TRY IN TRAINING"
		select_action_btn.disabled = false
	else:
		var remaining: int = wins_needed - wins
		select_action_btn.text = "WIN %d MORE FIGHT%s" % [remaining, "" if remaining == 1 else "S"]
		select_action_btn.disabled = true
	if select_train_hint_lbl != null:
		select_train_hint_lbl.visible = (game_mode == "training")
	if btn_spc != null:
		btn_spc.set_label_txt(str(ab.get("short", "SPC")))

	_clear_preview()
	preview_rig = Fighter3DScript.new()
	preview_rig.setup(f, true, lv)
	preview_rig.position = Vector3(0, 0, 2.8)
	add_child(preview_rig)

func _on_select_primary_action() -> void:
	var f: Dictionary = GameData.get_fighters()[selected_idx]
	var f_id: String = str(f["id"])
	# v0.3.1: no more paying dinars to unlock — wins earn fighters.
	# Training lets anyone try a locked warrior for free.
	if _is_fighter_unlocked(f_id) or game_mode == "training":
		_start_match()

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
	_refresh_ai_label()

# --- v0.3.0 intro ---

func _round_number() -> int:
	return p_rounds + e_rounds + 1

func _build_intro_cards() -> Array:
	var fighters := GameData.get_fighters()
	var p_name: String = str(fighters[selected_idx]["name"])
	var e_cfg: Dictionary = GameData.get_boss() if game_mode == "boss" else fighters[(selected_idx + survival_wave) % fighters.size()]
	var e_name: String = str(e_cfg["name"])
	var vs_card: String = "%s vs %s" % [p_name, e_name]
	if game_mode == "training":
		return [[vs_card, 1.1], ["TRAINING — " + _tr("fight"), 0.7]]
	if game_mode == "survival":
		return [[vs_card, 1.1], ["%s %d" % [_tr("wave"), survival_wave], 0.7], [_tr("fight"), 0.5]]
	if game_mode == "boss" and _round_number() > 1:
		return [["%s %d" % [_tr("round"), _round_number()], 0.7], [_tr("fight"), 0.5]]
	return [[vs_card, 1.1], ["%s %d" % [_tr("round"), _round_number()], 0.7], [_tr("fight"), 0.5]]

func _start_match() -> void:
	_clear_preview()
	_end_fatality_ui()
	joy_block_active = false
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
	player.attack_started.connect(_on_attack_started)
	player.defeated.connect(_on_player_defeated)
	add_child(player)

	enemy = Fighter3DScript.new()
	enemy.setup(e_cfg, false, 1)
	enemy.position = Vector3(2.6, 0, 0)
	enemy.hit_landed.connect(_on_hit_landed)
	enemy.attack_started.connect(_on_attack_started)
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)

	hud_p_name.text = str(p_cfg["name"])
	hud_e_name.text = str(e_cfg["name"]) if game_mode != "survival" else "%s (Wave %d)" % [str(e_cfg["name"]), survival_wave]
	hud_p_pips.text = "● ".repeat(p_rounds) + "○ ".repeat(2 - p_rounds)
	hud_e_pips.text = "● ".repeat(e_rounds) + "○ ".repeat(2 - e_rounds)
	round_time = 99.0
	_refresh_ai_label()
	if btn_spc != null:
		btn_spc.set_label_txt(str(p_cfg.get("ability", {}).get("short", "SPC")))
	audio.combat_music_active = true
	_show_panel(null)
	combat_hud.visible = true
	top_bar.visible = false

	# Intro: camera swoops in from far while the cards play; no input/AI yet.
	match_active = false
	intro_active = true
	intro_cards = _build_intro_cards()
	intro_card_idx = 0
	intro_card_t = 0.0
	intro_cue_played = false
	cam.position = Vector3(0, 3.4, 11.0)
	intro_lbl.text = str(intro_cards[0][0])
	intro_lbl.visible = true

func _advance_intro(delta: float) -> void:
	if intro_card_idx >= intro_cards.size():
		return
	intro_card_t += delta
	var card_dur: float = float(intro_cards[intro_card_idx][1])
	var is_fight_card: bool = intro_card_idx == intro_cards.size() - 1
	if is_fight_card and not intro_cue_played:
		audio.play_tone(880.0, 0.25, 0.32, 220.0, 0)
		intro_cue_played = true
	if intro_card_t >= card_dur:
		intro_card_idx += 1
		intro_card_t = 0.0
		intro_cue_played = false
		if intro_card_idx >= intro_cards.size():
			intro_active = false
			intro_lbl.visible = false
			match_active = true
			round_time = 99.0
		else:
			intro_lbl.text = str(intro_cards[intro_card_idx][0])

func _on_player_defeated(_f: Node3D) -> void:
	_handle_round_end(false)

func _on_enemy_defeated(_f: Node3D) -> void:
	_handle_round_end(true)

func _on_hit_landed(attacker: Node3D, defender: Node3D, atk_data: Dictionary) -> void:
	if defender.state == "dodge" or defender.state == "dead":
		return
	var dist: float = absf(attacker.position.x - defender.position.x)

	# v0.3.0 Bronze Counter: defender in counter stance reflects 1.5x damage
	if str(defender.state) == "counter" and not bool(atk_data["unblockable"]):
		var reflect: float = float(atk_data["damage"]) * 1.5
		if game_mode != "training":
			attacker.hp = maxf(0.0, float(attacker.hp) - reflect)
		attacker.state = "hitstun"
		attacker.state_timer = 0.30
		attacker.vx = float(defender.facing) * 5.0 / attacker.weight_factor()
		defender.state = "idle"
		defender.active_attack = {}
		defender.counter_timer = 0.0
		spawn_burst(Vector3(attacker.position.x, 1.2, 0), Color(1.0, 0.82, 0.25), 30, 5.0)
		flash_screen(Color(1.0, 0.82, 0.25), 0.25)
		audio.play_parry()
		hitstop = 0.10
		shake = 0.20
		if float(attacker.hp) <= 0.0:
			attacker.state = "dead"
			attacker.emit_signal("defeated", attacker)
		return

	# v0.3.0 CLASH: both mid-attack and in each other's range -> cancel both
	if str(defender.state) == "attack" and defender.active_attack.has("range"):
		if dist <= float(defender.active_attack["range"]):
			attacker.state = "idle"
			attacker.active_attack = {}
			defender.state = "idle"
			defender.active_attack = {}
			attacker.vx = -float(attacker.facing) * 3.0
			defender.vx = float(defender.facing) * 3.0
			spawn_burst(Vector3((attacker.position.x + defender.position.x) * 0.5, 1.3, 0), Color(1, 1, 1), 24, 5.0)
			audio.play_parry()
			hitstop = 0.08
			shake = 0.12
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

	# v0.3.0 combo damage scaling (consecutive hits by same attacker within 1.2s)
	if float(attacker.combo_timer) > 0.0:
		attacker.combo_count += 1
	else:
		attacker.combo_count = 1
	attacker.combo_timer = 1.2
	var combo_mult: float = 1.0
	if attacker.combo_count == 2:
		combo_mult = 0.95
	elif attacker.combo_count == 3:
		combo_mult = 0.90
	elif attacker.combo_count >= 4:
		combo_mult = 0.85
	# Getting hit resets the victim's own combo chain
	defender.combo_count = 0
	defender.combo_timer = 0.0

	var blocked: bool = (str(defender.state) == "block") and not bool(atk_data["unblockable"])
	var base_dmg: float = float(atk_data["damage"]) * combo_mult
	# v0.3.0 AI difficulty damage multiplier (enemy attacks only)
	if attacker == enemy:
		base_dmg *= float(_current_diff()["dmg"])
	var chip_mult: float = float(atk_data.get("chip_mult", 1.0))
	var dmg: float = maxf(2.0, roundf(base_dmg * 0.18 * chip_mult)) if blocked else base_dmg
	# v0.3.0 crouch: low stance takes 30% less damage (also applies to chip
	# damage when the crouching defender is also blocking)
	if str(defender.state) == "crouch" or bool(defender.crouch_held):
		dmg *= 0.7
	if game_mode != "training":
		defender.hp = maxf(0.0, float(defender.hp) - dmg)
	attacker.energy = minf(100.0, float(attacker.energy) + (12.0 if str(atk_data["type"]) == "light" else 18.0))

	audio.play_hit(str(atk_data["type"]) != "light")
	hitstop = 0.04 if str(atk_data["type"]) == "light" else 0.09
	shake = 0.08 if blocked else (0.38 if str(atk_data["type"]) == "ult" else 0.16)

	# v0.3.0 weight-based knockback
	var knock_mult: float = float(atk_data.get("knock_mult", 1.0))
	defender.vx = float(attacker.facing) * (3.0 if blocked else (8.5 if str(atk_data["type"]) == "ult" else 5.2)) * knock_mult / defender.weight_factor()
	if blocked:
		# v0.3.0 blockstun: blocked defender cannot act for 0.18s
		defender.blockstun_timer = 0.18
	else:
		defender.state = "hitstun"
		defender.state_timer = 0.24 if str(atk_data["type"]) == "light" else 0.42
		# v0.3.0 ability status effects (only on a clean hit)
		var kind: String = str(atk_data.get("kind", ""))
		if kind == "fire" and game_mode != "training":
			defender.apply_burn(4.0, 3.0)
		elif kind == "sand":
			defender.apply_slow(4.0)
		elif kind == "tide":
			defender.apply_slow(3.0)
		elif kind == "quake":
			shake = maxf(shake, 0.5)
			spawn_burst(Vector3(defender.position.x, 0.3, 0), Color(0.62, 0.50, 0.34), 50, 4.0)

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

# --- v0.3.0 fatality ---

func _begin_fatality(player_won: bool) -> void:
	fatality_active = true
	fatality_pending = true
	fatality_player_won = player_won
	fatality_bonus = 0
	match_active = false
	Engine.time_scale = 0.35
	fatality_lbl.text = _tr("finish_him")
	fatality_lbl.visible = true
	fatality_btn.visible = true
	audio.play_tone(520.0, 0.4, 0.30, 260.0, 0)
	# 4.0s window in real time (ignore the slow-mo time scale)
	get_tree().create_timer(4.0, true, false, true).timeout.connect(_on_fatality_timeout)

func _on_fatality_pressed() -> void:
	if not fatality_pending:
		return
	fatality_pending = false
	fatality_btn.visible = false
	fatality_bonus = 150
	var winner: Node3D = player
	var loser: Node3D = enemy
	winner.play_anim("Punch_Cross", 0.7)
	winner.state = "attack"
	winner.state_timer = 1.6
	loser.state = "dead"
	spawn_burst(Vector3(loser.position.x, 1.2, 0), _ability_color(str(winner.cfg.get("ability", {}).get("kind", ""))), 60, 8.0)
	flash_screen(Color(1.0, 0.2, 0.15), 0.35)
	shake = 0.6
	hitstop = 0.25
	fatality_lbl.text = _tr("fatality")
	audio.play_hit(true)
	audio.play_ability(str(winner.cfg.get("ability", {}).get("kind", "")))
	get_tree().create_timer(1.6, true, false, true).timeout.connect(_finish_fatality_result)

func _on_fatality_timeout() -> void:
	if not fatality_pending:
		return
	fatality_pending = false
	# Window expired: normal KO, result as usual
	_finish_fatality_result()

func _finish_fatality_result() -> void:
	if not fatality_active:
		return
	fatality_active = false
	_end_fatality_ui()
	_show_match_result(fatality_player_won, fatality_bonus)

func _end_fatality_ui() -> void:
	fatality_pending = false
	fatality_active = false
	Engine.time_scale = 1.0
	if fatality_lbl != null:
		fatality_lbl.visible = false
	if fatality_btn != null:
		fatality_btn.visible = false

func _handle_round_end(player_won: bool) -> void:
	if not match_active:
		return
	if game_mode == "survival" and player_won:
		survival_wave += 1
		save["dinars"] = int(save["dinars"]) + 120
		# v0.3.1: clearing a wave counts as a win for fighter unlocks
		save["wins"] = int(save.get("wins", 0)) + 1
		var newly: Array = _check_unlocks()
		_persist_save()
		if newly.size() > 0:
			_show_callout("NEW WARRIOR UNLOCKED: %s!" % " / ".join(newly))
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

	# Match decided: boss + arena winners get the FINISH HIM! window
	if player_won and (game_mode == "boss" or game_mode == "arena"):
		_begin_fatality(true)
		return
	_show_match_result(player_won, 0)

func _show_match_result(player_won: bool, fatality_bonus_amt: int) -> void:
	match_active = false
	audio.combat_music_active = false
	var d: Dictionary = GameData.get_i18n().get(save["lang"], GameData.get_i18n()["en"])
	result_title.text = str(d["victory"]) if player_won else str(d["defeat"])
	var r_dinars: int = (380 if game_mode == "boss" else 160) if player_won else 50
	var r_gems: int = 15 if (player_won and game_mode == "boss") else 0
	r_dinars += fatality_bonus_amt
	save["dinars"] = int(save["dinars"]) + r_dinars
	save["gems"] = int(save["gems"]) + r_gems
	# v0.3.1: a match win earns a win toward fighter unlocks
	var newly_unlocked: Array = []
	if player_won and game_mode != "training":
		save["wins"] = int(save.get("wins", 0)) + 1
		newly_unlocked = _check_unlocks()
	p_rounds = 0
	e_rounds = 0
	_persist_save()
	result_reward.text = "+%d Dinars  |  +%d Gems" % [r_dinars, r_gems]
	if fatality_bonus_amt > 0:
		result_reward.text += "  (includes +%d FATALITY bonus)" % fatality_bonus_amt
	result_reward.text += "\nTotal wins: %d" % int(save.get("wins", 0))
	for n in newly_unlocked:
		result_reward.text += "\nNEW WARRIOR UNLOCKED: %s!" % str(n)
	get_tree().create_timer(0.85).timeout.connect(_show_result_overlay)

func _show_result_overlay() -> void:
	_end_fatality_ui()
	combat_hud.visible = false
	top_bar.visible = true
	_show_panel(screen_result)

func _process(delta: float) -> void:
	if preview_rig != null:
		preview_rig.rotation.y += delta * 0.9

	if fatality_active:
		# Slow-mo cinematic: keep fighters animating, no input / AI / timer
		if player != null and enemy != null:
			player.step_fighter(delta, enemy)
			enemy.step_fighter(delta, player)
		shake = maxf(0.0, shake - delta * 1.8)
		return

	if intro_active:
		if player != null and enemy != null:
			_advance_intro(delta)
			player.step_fighter(delta, enemy)
			enemy.step_fighter(delta, player)
			var mid_x: float = (player.position.x + enemy.position.x) * 0.5
			var span: float = absf(player.position.x - enemy.position.x)
			var target_z: float = clampf(4.6 + span * 0.62, 5.0, 8.2)
			cam.position = cam.position.lerp(Vector3(mid_x, 2.35, target_z), delta * 1.8)
			cam.look_at(Vector3(cam.position.x, 1.05, 0.0))
		return

	if not match_active or player == null or enemy == null:
		return

	if hitstop > 0.0:
		hitstop -= delta
		return

	var move_x: float = joy_stick.axis_x
	if joy_stick.axis_y < -0.65:
		player.jump()
	# v0.3.0 joystick DOWN = crouch (C-crouch idea, touch form)
	if joy_stick.axis_y > 0.65:
		player.set_crouch(true)
	else:
		player.set_crouch(false)
	# v0.3.0 joystick BACK (away from enemy) = auto-defend: hold block in
	# place, no movement. Reuses set_block, so the perfect-parry window
	# still triggers on block start. Mid-attack it does nothing until idle.
	var back_held: bool = joy_stick.axis_x * float(player.facing) < -0.55
	if back_held:
		player.set_block(true)
		move_x = 0.0
	elif joy_block_active and (player.state == "block" or player.state == "parry"):
		player.set_block(false)
	joy_block_active = back_held
	if player.state == "idle" and absf(move_x) > 0.12:
		player.vx = clampf(move_x, -1.0, 1.0) * float(player.effective_speed())

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

	var mid_x2: float = (player.position.x + enemy.position.x) * 0.5
	var span2: float = absf(player.position.x - enemy.position.x)
	var target_z2: float = clampf(4.6 + span2 * 0.62, 5.0, 8.2)
	var sx: float = randf_range(-shake, shake) if shake > 0.0 else 0.0
	var sy: float = randf_range(-shake, shake) if shake > 0.0 else 0.0
	shake = maxf(0.0, shake - delta * 1.8)

	cam.position.x = lerpf(cam.position.x, mid_x2, delta * 6.0) + sx
	cam.position.z = lerpf(cam.position.z, target_z2, delta * 5.0)
	cam.position.y = 1.65 + sy
	cam.look_at(Vector3(cam.position.x, 1.05, 0.0))

	hud_p_hp.set_ratio(float(player.hp) / maxf(1.0, float(player.max_hp)))
	hud_p_en.set_ratio(float(player.energy) / 100.0)
	hud_p_st.set_ratio(float(player.stamina) / 100.0)
	hud_e_hp.set_ratio(float(enemy.hp) / maxf(1.0, float(enemy.max_hp)))
	hud_e_en.set_ratio(float(enemy.energy) / 100.0)
	hud_e_st.set_ratio(float(enemy.stamina) / 100.0)
	hud_p_hp_txt.text = "%d / %d" % [int(player.hp), int(player.max_hp)]
	hud_e_hp_txt.text = "%d / %d" % [int(enemy.hp), int(enemy.max_hp)]
	btn_spc.set_enabled_state(float(player.energy) >= 40.0)
	btn_ult.set_enabled_state(float(player.energy) >= 100.0)

func _step_enemy_ai(delta: float) -> void:
	if enemy.state == "dead" or game_mode == "training":
		return
	var diff: Dictionary = _current_diff()
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
		enemy.vx = dir * float(enemy.effective_speed()) * float(diff["approach"]) * (1.22 if phase == 3 else 1.0)

	ai_timer -= delta
	if ai_timer > 0.0:
		return
	# Normal keeps the phase-based reaction (0.40/0.30/0.22); easy/hard use flat values
	var react: float = float(diff["react"])
	if str(save.get("ai_difficulty", "normal")) == "normal":
		react = 0.22 if phase == 3 else (0.30 if phase == 2 else 0.40)
	ai_timer = react

	# Hard: dodge the player's ult/spc when it comes out in range
	if float(diff["dodge"]) > 0.0 and player.state == "attack" and dist < 2.5:
		var p_type: String = str(player.active_attack.get("type", ""))
		if (p_type == "ult" or p_type == "spc") and randf() < float(diff["dodge"]):
			var away: float = 1.0 if enemy.position.x > player.position.x else -1.0
			if enemy.dodge(away):
				return

	# v0.3.0 Hard only: crouch defensively when the player attacks in range
	if str(save.get("ai_difficulty", "normal")) == "hard" and player.state == "attack" and dist < 2.5 and randf() < 0.12:
		if enemy.state == "idle":
			enemy.set_crouch(true)
			get_tree().create_timer(0.5).timeout.connect(_release_enemy_crouch)
			return

	if player.state == "attack" and dist < 2.5 and randf() < float(diff["block"]):
		enemy.set_block(true)
		get_tree().create_timer(0.38).timeout.connect(_release_enemy_block)
		return

	if dist <= 2.35:
		# Stamina gate: not enough stamina -> idle and regen
		if float(enemy.stamina) < 8.0:
			return
		if float(enemy.energy) >= 100.0 and bool(diff["use_ult"]) and phase >= int(diff["ult_phase"]):
			enemy.start_attack("ult")
			return
		if float(enemy.energy) >= 40.0 and randf() < float(diff["spc"]):
			enemy.start_attack("spc")
			return
		enemy.start_attack("light" if randf() < 0.6 else "heavy")

func _release_enemy_block() -> void:
	if enemy != null:
		enemy.set_block(false)

func _release_enemy_crouch() -> void:
	if enemy != null:
		enemy.set_crouch(false)
