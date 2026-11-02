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
	var b := Button.new()
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
