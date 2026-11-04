class_name Ui
extends RefCounted
## 화면 요소 공통 (글꼴, 종이, 글자 버튼)

const TEXT := Color("e6e1d8")
const DIM := Color("8f897f")
const ACCENT := Color("c9a463")
const PAPER := Color("ece5d6")
const INK := Color("2a2620")
const INK_DIM := Color("6f665a")
const BLUE_INK := Color("2a2f55")
const RED := Color("a8322a")
const OK := Color("6f9a7a")

static var sans: Font
static var sans_b: Font
static var serif: Font
static var serif_b: Font
static var hand: Font
static var spaced: Font
static var theme: Theme


static func init() -> void:
	sans = load("res://assets/fonts/NanumGothic-Regular.ttf")
	sans_b = load("res://assets/fonts/NanumGothic-Bold.ttf")
	serif = load("res://assets/fonts/NanumMyeongjo-Regular.ttf")
	serif_b = load("res://assets/fonts/NanumMyeongjo-Bold.ttf")
	hand = load("res://assets/fonts/NanumPenScript-Regular.ttf")
	var sp := FontVariation.new()
	sp.base_font = sans
	sp.spacing_glyph = 3
	spaced = sp
	theme = Theme.new()
	theme.default_font = sans
	theme.default_font_size = 18
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		theme.set_stylebox(st, "Button", empty)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", ACCENT)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	theme.set_color("font_hover_pressed_color", "Button", ACCENT)
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.28))
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("default_color", "RichTextLabel", TEXT)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(1, 1, 1, 0.22)
	grab.content_margin_left = 3
	grab.content_margin_right = 3
	for sb in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", sb, StyleBoxEmpty.new())
		theme.set_stylebox("grabber", sb, grab)
		theme.set_stylebox("grabber_highlight", sb, grab)
		theme.set_stylebox("grabber_pressed", sb, grab)
	var sl := StyleBoxFlat.new()
	sl.bg_color = Color(1, 1, 1, 0.15)
	sl.content_margin_top = 2
	sl.content_margin_bottom = 2
	theme.set_stylebox("slider", "HSlider", sl)
	var gr := StyleBoxFlat.new()
	gr.bg_color = ACCENT
	gr.content_margin_top = 2
	gr.content_margin_bottom = 2
	theme.set_stylebox("grabber_area", "HSlider", gr)
	theme.set_stylebox("grabber_area_highlight", "HSlider", gr)


static func full(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## 화면 기준점(ax, ay: 0~1)에 붙이고 (ox, oy)만큼 띄운다. gx/gy: -1 앞으로, 0 양쪽, 1 뒤로 자람
static func pin(c: Control, ax: float, ay: float, ox: float, oy: float, gx := 1, gy := 1) -> Control:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = ox
	c.offset_right = ox
	c.offset_top = oy
	c.offset_bottom = oy
	var dirs := [Control.GROW_DIRECTION_BEGIN, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END]
	c.grow_horizontal = dirs[gx + 1]
	c.grow_vertical = dirs[gy + 1]
	return c


static func label(text: String, size := 18, color := TEXT, font: Font = null, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func shadow(l: Control, outline := 0) -> Control:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	return l


static func rich(bb: String, size := 18, color := TEXT, font: Font = null, bold: Font = null) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", color)
	if font:
		r.add_theme_font_override("normal_font", font)
	if bold:
		r.add_theme_font_override("bold_font", bold)
	r.text = bb
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


static func bb(s: String) -> String:
	## **굵게** → [b]굵게[/b]
	var out := s.replace("[", "[lb]")
	var re := RegEx.new()
	re.compile("\\*\\*(.+?)\\*\\*")
	return re.sub(out, "[b]$1[/b]", true)


static func button(text: String, size := 20, cb: Callable = Callable(), font: Font = null, color := TEXT, hover := ACCENT) -> Button:
	var b := HitButton.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_hover_color", hover)
	b.add_theme_color_override("font_pressed_color", hover)
	b.add_theme_color_override("font_hover_pressed_color", hover)
	if font:
		b.add_theme_font_override("font", font)
	if cb.is_valid():
		b.pressed.connect(func():
			Sfx.play("ui", 0.5)
			cb.call())
	return b


static func paper_box(dark := false, margin := 30) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = Build.tex("ui_paper_dark" if dark else "ui_paper")
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.85
	s.content_margin_bottom = margin * 0.85
	return s


static func dark_box(alpha := 0.88, margin := 22, border := 0.08) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.055, 0.06, 0.07, alpha)
	s.border_color = Color(1, 1, 1, border)
	s.set_border_width_all(1 if border > 0 else 0)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.8
	s.content_margin_bottom = margin * 0.8
	return s


static func panel(style: StyleBox) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style)
	return p


static func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func gap(h := 10) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func expand(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func clear(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()


## 종이 위에 놓이는 잉크색 글자 버튼
static func ink_button(text: String, size := 20, cb: Callable = Callable()) -> Button:
	return button(text, size, cb, serif_b, INK, RED)


## 종이 양식에 인쇄된 네모 칸 버튼 (잉크 테두리, 누르면 빨간 펜 색)
static func form_button(text: String, size := 16, cb: Callable = Callable()) -> Button:
	var b := button(text, size, cb, sans_b, INK, RED)
	b.flat = false
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(0, 44)
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var active: bool = st in ["hover", "pressed", "hover_pressed"]
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(INK, 0.07 if active else 0.0)
		sb.border_color = Color(RED, 0.85) if active else Color(INK, 0.2 if st == "disabled" else 0.5)
		sb.set_border_width_all(1)
		sb.border_width_bottom = 2
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_disabled_color", Color(INK, 0.35))
	return b


## 종이 위 잉크 줄
static func rule(alpha := 0.18, h := 1) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(INK, alpha)
	r.custom_minimum_size = Vector2(0, h)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func vrule(alpha := 0.2) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(INK, alpha)
	r.custom_minimum_size = Vector2(1, 0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## 빨간 도장
static func stamp(text: String, size := 34) -> Control:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = Color(RED, 0.78)
	s.set_border_width_all(3)
	s.set_corner_radius_all(60)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", s)
	var l := label(text, size, Color(RED, 0.85), serif_b)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## 양식에서 고른 칸: 빨간 펜으로 동그라미를 친다
class InkChoice extends Button:
	var on := false
	var _seed := 0.0

	func _init(t: String, fs := 18) -> void:
		text = t
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_theme_font_override("font", Ui.serif_b)
		add_theme_font_size_override("font_size", fs)
		custom_minimum_size = Vector2(max(76.0, Ui.serif_b.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 38.0), 48)
		_seed = randf() * 10.0
		set_on(false)

	func set_on(v: bool) -> void:
		on = v
		var c := Ui.INK if on else Color(Ui.INK, 0.42)
		for k in ["font_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			add_theme_color_override(k, c)
		add_theme_color_override("font_hover_color", Ui.INK if on else Ui.RED)
		queue_redraw()

	func _draw() -> void:
		if not on:
			return
		var c := size / 2.0
		var rx := size.x * 0.5 - 5.0
		var ry := size.y * 0.5 - 6.0
		var pts := PackedVector2Array()
		var n := 44
		for i in n + 7:
			var a := -2.2 + TAU * float(i) / n
			var w := 1.0 + 0.05 * sin(a * 2.0 + _seed) + 0.04 * float(i) / n
			pts.append(c + Vector2(cos(a) * rx * w, sin(a) * ry * w))
		draw_polyline(pts, Color(Ui.RED, 0.82), 2.2, true)


## 눈금자 모양 조절기: 끌거나 눌러서 값을 고른다
class InkRuler extends Control:
	signal changed(v: float)
	signal released
	var lo := 0.0
	var hi := 1.0
	var step := 0.1
	var value := 0.0
	var _drag := false

	func _init(a: float, b: float, s: float, v: float) -> void:
		lo = a
		hi = b
		step = s
		value = clamp(v, a, b)
		custom_minimum_size = Vector2(250, 46)
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func set_value(v: float) -> void:
		v = clamp(lo + snapped(v - lo, step), lo, hi)
		if is_equal_approx(v, value):
			return
		value = v
		queue_redraw()
		changed.emit(value)

	func _x(v: float) -> float:
		return 12.0 + (size.x - 24.0) * (v - lo) / max(0.0001, hi - lo)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			_drag = e.pressed
			if e.pressed:
				set_value(lo + (e.position.x - 12.0) / max(1.0, size.x - 24.0) * (hi - lo))
			else:
				released.emit()
			accept_event()
		elif e is InputEventMouseMotion and _drag:
			set_value(lo + (e.position.x - 12.0) / max(1.0, size.x - 24.0) * (hi - lo))
			accept_event()

	func _draw() -> void:
		var y := size.y * 0.5
		var x0 := 12.0
		var x1 := size.x - 12.0
		var n := int(round((hi - lo) / step))
		while n > 24:
			n = int(n * 0.5)
		for i in n + 1:
			var x: float = lerp(x0, x1, float(i) / n)
			var big := i == 0 or i == n or i * 2 == n
			draw_line(Vector2(x, y), Vector2(x, y - (13.0 if big else 7.0)), Color(Ui.INK, 0.65 if big else 0.4), 1.4 if big else 1.0)
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(Ui.INK, 0.75), 1.6)
		var xm := _x(value)
		draw_line(Vector2(x0, y + 0.5), Vector2(xm, y + 0.5), Color(Ui.RED, 0.8), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(xm, y + 2), Vector2(xm - 8, y + 16), Vector2(xm + 8, y + 16)]), Color(Ui.RED, 0.9))


## 서류철 색인: 고른 탭에 빨간 펜 밑줄
class InkTab extends Button:
	var on := false

	func _init(t: String) -> void:
		text = t
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_theme_font_override("font", Ui.serif_b)
		add_theme_font_size_override("font_size", 21)
		custom_minimum_size = Vector2(150, 54)
		set_on(false)

	func set_on(v: bool) -> void:
		on = v
		var c := Ui.INK if on else Color(Ui.INK, 0.45)
		for k in ["font_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			add_theme_color_override(k, c)
		add_theme_color_override("font_hover_color", Ui.INK if on else Ui.RED)
		queue_redraw()

	func _draw() -> void:
		if not on:
			return
		var w := Ui.serif_b.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
		var y := size.y * 0.5 + 15.0
		var pts := PackedVector2Array()
		for i in 13:
			var f := float(i) / 12.0
			pts.append(Vector2(-3.0 + f * (w + 10.0), y + sin(f * 7.0) * 1.2 - f * 2.0))
		draw_polyline(pts, Color(Ui.RED, 0.8), 2.4, true)


## 유품 꼬리표: 끈 구멍이 뚫린 종이 카드. 고르면 빨간 테두리
class TagButton extends Button:
	var on := false
	var dim := false

	func _init(t: String, is_dim := false) -> void:
		text = t
		dim = is_dim
		flat = false
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		clip_text = true
		text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		add_theme_font_override("font", Ui.serif_b)
		add_theme_font_size_override("font_size", 16)
		custom_minimum_size = Vector2(196, 54)
		set_on(false)

	func set_on(v: bool) -> void:
		on = v
		var bg := Color("d6cfc1") if dim else Color("e7ddc9")
		for st in ["normal", "hover", "pressed", "hover_pressed"]:
			var s := StyleBoxFlat.new()
			s.bg_color = bg if st == "normal" else bg.darkened(0.05)
			s.border_color = Color(Ui.RED, 0.9) if on else Color(Ui.INK, 0.3 if st == "normal" else 0.55)
			s.set_border_width_all(2 if on else 1)
			s.content_margin_left = 34
			s.content_margin_right = 10
			s.shadow_color = Color(0, 0, 0, 0.14)
			s.shadow_size = 2
			s.shadow_offset = Vector2(1, 2)
			add_theme_stylebox_override(st, s)
		var c := Color(Ui.INK, 0.62) if dim else Ui.INK
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			add_theme_color_override(k, c)
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(17, size.y * 0.5)
		draw_circle(c, 7.5, Color(Ui.INK, 0.1))
		draw_arc(c, 7.5, 0, TAU, 24, Color(Ui.INK, 0.38), 1.0, true)
		draw_circle(c, 3.6, Color("2b2622"))


## 비어 있는 자리: 점선 테두리
class Dashed extends PanelContainer:
	func _init() -> void:
		var s := StyleBoxEmpty.new()
		s.content_margin_left = 24
		s.content_margin_right = 24
		s.content_margin_top = 18
		s.content_margin_bottom = 18
		add_theme_stylebox_override("panel", s)

	func _draw() -> void:
		var a := Vector2(1, 1)
		var b := size - Vector2(1, 1)
		var col := Color(Ui.INK, 0.35)
		draw_dashed_line(a, Vector2(b.x, a.y), col, 1.5, 7.0)
		draw_dashed_line(Vector2(b.x, a.y), b, col, 1.5, 7.0)
		draw_dashed_line(b, Vector2(a.x, b.y), col, 1.5, 7.0)
		draw_dashed_line(Vector2(a.x, b.y), a, col, 1.5, 7.0)


## 마지막 방 표지: 닫힌 문과 문틈 · 문 아래로 새어 나오는 불빛 (앱 아이콘과 같은 그림)
class DoorMark extends Control:
	var glow := 1.0:
		set(v):
			glow = v
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# 기준 단위: 문틀 너비 100, 높이 132. 아래로 불빛이 60만큼 번진다
		var s := minf(size.x / 150.0, size.y / 196.0)
		var o := Vector2(size.x * 0.5 - 50.0 * s, (size.y - 196.0 * s) * 0.5)
		var r := func(x: float, y: float, w: float, h: float) -> Rect2: return Rect2(o + Vector2(x, y) * s, Vector2(w, h) * s)
		var a := clampf(glow, 0.0, 1.0)
		var floor_y := 132.0
		# 바닥으로 번지는 불빛
		var spill := PackedVector2Array([o + Vector2(6, floor_y) * s, o + Vector2(100, floor_y) * s, o + Vector2(144, floor_y + 60) * s, o + Vector2(-22, floor_y + 60) * s])
		var warm := Color(1.0, 0.77, 0.44)
		draw_polygon(spill, PackedColorArray([Color(warm, 0.55 * a), Color(warm, 0.55 * a), Color(warm, 0.0), Color(warm, 0.0)]))
		# 문틀
		draw_rect(r.call(0, 0, 100, floor_y), Color("5a4a3b"))
		# 문틈 불빛
		draw_rect(r.call(85, 6, 9, floor_y - 6), Color("3a2e24").lerp(Color("ffe4ae"), a))
		# 문짝
		draw_rect(r.call(6, 6, 79, floor_y - 6), Color("e9e1d1"))
		draw_rect(r.call(6, 6, 18, floor_y - 6), Color(0, 0, 0, 0.07))
		# 문 아래 불빛 한 줄
		draw_rect(r.call(6, floor_y - 2, 88, 2), Color(Color("ffd99a"), a))
		# 문 판 두 칸 · 손잡이
		var ink := Color("b5a68e")
		draw_rect(r.call(19, 15, 50, 42), ink, false, max(1.0, 1.6 * s))
		draw_rect(r.call(19, 66, 50, 54), ink, false, max(1.0, 1.6 * s))
		draw_circle(o + Vector2(75, 70) * s, 3.2 * s, Color("2a2620"))


## 점선 줄 (양식의 칸 나눔)
class DotRule extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(0, 2)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_dashed_line(Vector2(0, 1), Vector2(size.x, 1), Color(Ui.INK, 0.3), 1.0, 3.0)


## 공책처럼 줄이 그어진 칸 (손글씨 비고)
class Lined extends PanelContainer:
	func _init() -> void:
		var s := StyleBoxEmpty.new()
		s.content_margin_left = 4
		s.content_margin_top = 8
		s.content_margin_bottom = 6
		add_theme_stylebox_override("panel", s)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var y := 56.0
		while y < size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(Ui.BLUE_INK, 0.16), 1.0)
			y += 31.0


## 클립보드에 끼운 종이: 위 가운데에 쇠 집게
class ClipPaper extends PanelContainer:
	func _init() -> void:
		add_theme_stylebox_override("panel", Ui.paper_box(false, 36))

	func _draw() -> void:
		var cx := size.x * 0.5
		var plate := StyleBoxFlat.new()
		plate.bg_color = Color("9d998f")
		plate.set_corner_radius_all(10)
		plate.shadow_color = Color(0, 0, 0, 0.35)
		plate.shadow_size = 6
		plate.shadow_offset = Vector2(0, 3)
		draw_style_box(plate, Rect2(cx - 86, -32, 172, 48))
		var top := StyleBoxFlat.new()
		top.bg_color = Color("c8c3ba")
		top.set_corner_radius_all(8)
		draw_style_box(top, Rect2(cx - 78, -26, 156, 22))
		draw_rect(Rect2(cx - 86, 9, 172, 7), Color("767269"))
		draw_circle(Vector2(cx, -15), 6.5, Color("3a3732"))


## 클립보드 판
static func board_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("4b3727")
	s.border_color = Color("2f2219")
	s.set_border_width_all(2)
	s.set_corner_radius_all(16)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 42
	s.content_margin_bottom = 22
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 8)
	return s


## 글자만 보이는 버튼: 글자 둘레보다 넉넉한 곳(옆으로 16, 위아래로 4)까지 눌린다.
## 글자 사이 빈틈을 눌러 '씹히는' 일이 없게 한다
class HitButton extends Button:
	func _has_point(p: Vector2) -> bool:
		return Rect2(Vector2(-16, -4), size + Vector2(32, 8)).has_point(p)


## 둥근 도장: 겹테두리 원 안에 글자 (끝낸 의뢰의 등급)
class RoundStamp extends Control:
	var text := ""
	var ink := Color(0.66, 0.2, 0.16, 0.86)

	func _init(t: String, d := 48.0) -> void:
		text = t
		custom_minimum_size = Vector2(d, d)
		pivot_offset = Vector2(d, d) * 0.5
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) * 0.5 - 2.0
		draw_arc(c, r, 0, TAU, 48, ink, maxf(2.0, r * 0.09), true)
		draw_arc(c, r * 0.8, 0, TAU, 48, Color(ink, ink.a * 0.65), maxf(1.0, r * 0.04), true)
		var fs := int(r * 1.0)
		var w := Ui.serif_b.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(Ui.serif_b, c + Vector2(-w / 2.0, fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
