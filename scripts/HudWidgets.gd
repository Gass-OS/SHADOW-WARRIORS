extends RefCounted

class SWJoystick extends Control:
	var axis_x: float = 0.0
	var axis_y: float = 0.0
	var touch_id: int = -1
	var knob_offset: Vector2 = Vector2.ZERO

	func _init() -> void:
		custom_minimum_size = Vector2(150, 150)

	func _gui_input(event: InputEvent) -> void:
		var center: Vector2 = size * 0.5
		var max_r: float = minf(size.x, size.y) * 0.36
		if event is InputEventScreenTouch:
			if event.pressed and touch_id == -1:
				touch_id = event.index
				_set_knob(event.position - center, max_r)
				accept_event()
			elif not event.pressed and event.index == touch_id:
				touch_id = -1
				knob_offset = Vector2.ZERO
				axis_x = 0.0
				axis_y = 0.0
				queue_redraw()
				accept_event()
		elif event is InputEventScreenDrag and event.index == touch_id:
			_set_knob(event.position - center, max_r)
			accept_event()

	func _set_knob(delta: Vector2, max_r: float) -> void:
		if delta.length() > max_r:
			delta = delta.normalized() * max_r
		knob_offset = delta
		axis_x = delta.x / max_r
		axis_y = delta.y / max_r
		queue_redraw()

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var r: float = minf(size.x, size.y) * 0.44
		draw_circle(c, r, Color(0.05, 0.07, 0.1, 0.25))
		draw_arc(c, r, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.65), 2.5, true)
		draw_arc(c, r * 0.62, 0.0, TAU, 36, Color(1.0, 1.0, 1.0, 0.22), 1.5, true)
		# Directional arrows (Xbox D-pad feel)
		for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var p: Vector2 = c + dir * (r * 0.78)
			var perp: Vector2 = Vector2(-dir.y, dir.x) * 7.0
			var tri := PackedVector2Array([p + dir * 7.0, p - dir * 4.0 + perp, p - dir * 4.0 - perp])
			draw_colored_polygon(tri, Color(1, 1, 1, 0.55))
		# Glowing analog thumbstick
		draw_circle(c + knob_offset, r * 0.34, Color(0.95, 0.96, 0.98, 0.72))
		draw_arc(c + knob_offset, r * 0.34, 0.0, TAU, 32, Color(0.35, 0.85, 1.0, 0.85), 2.5, true)

class SWCircleBtn extends Control:
	signal btn_down
	signal btn_up

	var label_txt: String = "X"
	var sub_txt: String = ""
	var ring_col: Color = Color(0.3, 0.8, 1.0)
	var touch_id: int = -1
	var is_down: bool = false
	var is_enabled: bool = true

	func setup_btn(lbl: String, sub: String, col: Color, btn_size: float = 74.0) -> void:
		label_txt = lbl
		sub_txt = sub
		ring_col = col
		custom_minimum_size = Vector2(btn_size, btn_size)

	func set_enabled_state(v: bool) -> void:
		if is_enabled != v:
			is_enabled = v
			queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if not is_enabled:
			return
		if event is InputEventScreenTouch:
			if event.pressed and touch_id == -1:
				touch_id = event.index
				is_down = true
				queue_redraw()
				btn_down.emit()
				accept_event()
			elif not event.pressed and event.index == touch_id:
				touch_id = -1
				is_down = false
				queue_redraw()
				btn_up.emit()
				accept_event()

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var r: float = minf(size.x, size.y) * 0.44
		var alpha: float = 1.0 if is_enabled else 0.32
		var fill_a: float = 0.52 if is_down else 0.26
		draw_circle(c, r, Color(ring_col.r * 0.35, ring_col.g * 0.35, ring_col.b * 0.35, fill_a * alpha))
		draw_arc(c, r, 0.0, TAU, 36, Color(ring_col.r, ring_col.g, ring_col.b, 0.92 * alpha), 3.0, true)
		draw_arc(c, r * 0.82, 0.0, TAU, 32, Color(1, 1, 1, 0.25 * alpha), 1.2, true)
		var font: Font = ThemeDB.fallback_font
		draw_string(font, c + Vector2(-r * 0.5, 4), label_txt, HORIZONTAL_ALIGNMENT_CENTER, r, 16, Color(1, 1, 1, 0.95 * alpha))
		if sub_txt != "":
			draw_string(font, c + Vector2(-r * 0.5, 19), sub_txt, HORIZONTAL_ALIGNMENT_CENTER, r, 10, Color(ring_col.r, ring_col.g, ring_col.b, 0.95 * alpha))

class SWSlantedBar extends Control:
	var ratio: float = 1.0
	var fill_col: Color = Color(0.95, 0.76, 0.2)
	var flip_rtl: bool = false

	func set_ratio(v: float) -> void:
		ratio = clampf(v, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var slant: float = 12.0
		var bg := PackedVector2Array([Vector2(slant, 0), Vector2(w, 0), Vector2(w - slant, h), Vector2(0, h)])
		draw_colored_polygon(bg, Color(0.05, 0.06, 0.08, 0.75))
		var fw: float = maxf(0.0, (w - slant) * ratio)
		if fw > 2.0:
			var fill: PackedVector2Array
			if flip_rtl:
				fill = PackedVector2Array([Vector2(w - fw, 0), Vector2(w, 0), Vector2(w - slant, h), Vector2(maxf(0.0, w - slant - fw), h)])
			else:
				fill = PackedVector2Array([Vector2(slant, 0), Vector2(slant + fw, 0), Vector2(fw, h), Vector2(0, h)])
			draw_colored_polygon(fill, fill_col)
		draw_polyline(PackedVector2Array([bg[0], bg[1], bg[2], bg[3], bg[0]]), Color(1, 1, 1, 0.35), 1.5, true)
