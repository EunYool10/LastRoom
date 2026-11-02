extends Control
## 3단계 — 사건 재구성 및 퇴근

var ep: Dictionary
var S: Dictionary
var qi := 0
var sel_opt := -1
var sel_ev: Array = []
var recon_i := 0
var area: Control
var U := {}


func setup(e: Dictionary, state: Dictionary) -> void:
	ep = e
	S = state
	S.answers = []
	theme = Ui.theme
	Ui.full(self)
	var bg := TextureRect.new()
	bg.texture = Build.tex("ui_cork")
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	Ui.full(bg)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.42)
	Ui.full(shade)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var tl := Ui.vbox(2)
	Ui.pin(tl, 0, 0, 30, 22)
	tl.add_child(Ui.shadow(Ui.label("3단계  사건 재구성", 13, Ui.ACCENT, Ui.spaced)))
	tl.add_child(Ui.shadow(Ui.label("%d장 · %s" % [int(ep.no), ep.title], 23, Ui.TEXT, Ui.serif_b)))
	add_child(tl)
	var q := Ui.button("나가기", 18, func(): Game.quit_to_title(), Ui.sans)
	Ui.pin(q, 1, 0, -30, 26, -1, 1)
	add_child(q)
	area = Control.new()
	area.anchor_right = 1
	area.anchor_bottom = 1
	area.offset_left = 30
	area.offset_top = 92
	area.offset_right = -30
	area.offset_bottom = -26
	add_child(area)
	_show_question()


func _process(dt: float) -> void:
	S.t3 += dt


func _pool() -> Array:
	return S.clues.filter(func(id): return ep.clues.has(id) and not ep.clues[id].get("hint", false))


# ───────────────────────────── 추리
func _show_question() -> void:
	Ui.clear(area)
	var Q: Dictionary = ep.questions[qi]
	sel_opt = -1
	sel_ev = []
	if S.answers.size() <= qi:
		S.answers.append({"wrong": 0, "ev": 0, "done": false})
	var hb := Ui.hbox(30)
	Ui.full(hb)
	area.add_child(hb)
	# 왼쪽: 핀으로 꽂힌 단서 쪽지
	var lv := Ui.vbox(10)
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.size_flags_stretch_ratio = 1.0
	lv.add_child(Ui.shadow(Ui.label("사건 노트에서 근거가 될 쪽지를 두 장까지 고른다", 15, Color("e8dcc6"), Ui.sans_b)))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(grid)
	lv.add_child(sc)
	hb.add_child(lv)
	U.notes = {}
	var pool := _pool()
	if pool.is_empty():
		grid.add_child(Ui.shadow(Ui.label("기록한 단서가 없다. 기억에 의지해 추리할 수밖에 없다.", 17, Ui.TEXT, Ui.serif, true)))
	var i := 0
	for id in pool:
		var c: Dictionary = ep.clues[id]
		var b := Button.new()
		b.text = c.t + "\n" + c.d
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_font_override("font", Ui.serif)
		b.add_theme_font_size_override("font_size", 15)
		_style_note(b, false)
		b.rotation = deg_to_rad([-0.8, 0.6, 0.3, -0.5, 0.9, -0.3][i % 6])
		var cid: String = id
		b.pressed.connect(func(): _toggle_ev(cid))
		grid.add_child(b)
		U.notes[id] = b
		i += 1
	# 오른쪽: 질문지
	var paper := Ui.panel(Ui.paper_box(false, 34))
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper.size_flags_stretch_ratio = 1.15
	var v := Ui.vbox(10)
	v.add_child(Ui.label("추리  %d / %d" % [qi + 1, ep.questions.size()], 14, Ui.INK_DIM, Ui.spaced))
	v.add_child(Ui.label(Q.q, 31, Ui.INK, Ui.serif_b, true))
	v.add_child(Ui.gap(8))
	U.opts = []
	for k in Q.options.size():
		var ob := Ui.ink_button("", 21)
		ob.add_theme_font_override("font", Ui.serif)
		var kk: int = k
		ob.pressed.connect(func(): _pick_opt(kk))
		v.add_child(ob)
		U.opts.append(ob)
	v.add_child(Ui.gap(6))
	U.picked = Ui.label("", 15, Ui.INK_DIM, Ui.sans, true)
	v.add_child(U.picked)
	U.fb = Ui.rich("", 18, Ui.INK, Ui.serif, Ui.serif_b)
	v.add_child(U.fb)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var row := Ui.hbox(0)
	row.alignment = BoxContainer.ALIGNMENT_END
	U.submit = Ui.ink_button("이 추리로 결정한다  ▸", 22, _submit)
	row.add_child(U.submit)
	v.add_child(row)
	paper.add_child(v)
	hb.add_child(paper)
	_paint_opts()


func _style_note(b: Button, on: bool) -> void:
	var n := Ui.paper_box(on, 16)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", Ui.paper_box(true, 16))
	b.add_theme_stylebox_override("pressed", n)
	var col := Ui.RED if on else Ui.INK
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, col)


func _paint_opts() -> void:
	var Q: Dictionary = ep.questions[qi]
	var A: Dictionary = S.answers[qi]
	for k in U.opts.size():
		var b: Button = U.opts[k]
		var letter: String = "ABCD"[k]
		var txt: String = Q.options[k]
		var wrong: bool = A.has("x%d" % k)
		if A.done and k == int(Q.answer):
			b.text = "✓  %s.  %s" % [letter, txt]
			b.add_theme_color_override("font_color", Ui.OK)
			b.add_theme_color_override("font_hover_color", Ui.OK)
		elif wrong:
			b.text = "✕  %s.  %s" % [letter, txt]
			b.disabled = true
			b.add_theme_color_override("font_disabled_color", Color(Ui.INK, 0.35))
		elif k == sel_opt:
			b.text = "●  %s.  %s" % [letter, txt]
			b.add_theme_color_override("font_color", Ui.RED)
		else:
			b.text = "○  %s.  %s" % [letter, txt]
			b.add_theme_color_override("font_color", Ui.INK)


func _pick_opt(k: int) -> void:
	if S.answers[qi].done:
		return
	sel_opt = k
	_paint_opts()


func _toggle_ev(id: String) -> void:
	if S.answers[qi].done:
		return
	if sel_ev.has(id):
		sel_ev.erase(id)
	else:
		if sel_ev.size() >= 2:
			sel_ev.pop_front()
		sel_ev.append(id)
	for k in U.notes:
		_style_note(U.notes[k], sel_ev.has(k))
	var names := []
	for x in sel_ev:
		names.append("「%s」" % ep.clues[x].t)
	U.picked.text = ("근거:  " + "  ".join(names)) if names.size() > 0 else ""
	Sfx.play("paper", 0.4)


func _submit() -> void:
	var Q: Dictionary = ep.questions[qi]
	var A: Dictionary = S.answers[qi]
	if A.done:
		_next()
		return
	if sel_opt < 0:
		U.fb.text = "[color=#a8322a]답을 하나 고른다.[/color]"
		Sfx.play("error", 0.6)
		return
	if sel_opt != int(Q.answer):
		A.wrong += 1
		A["x%d" % sel_opt] = true
		Sfx.play("error", 0.6)
		var w = Q.wrong[sel_opt]
		U.fb.text = "[color=#a8322a][b]단서와 맞지 않는다.[/b][/color]  " + (Ui.bb(w) if w != null else "")
		sel_opt = -1
		_paint_opts()
		return
	var good := 0
	for x in sel_ev:
		if Q.evidence.has(x):
			good += 1
	A.ev = good
	A.done = true
	Sfx.play("clue", 0.7)
	var r := "근거도 정확하다."
	if good == 1:
		r = "근거 하나는 결정적이다."
	elif good == 0:
		r = "추론은 맞았지만, 고른 근거는 결정적이지 않다." if sel_ev.size() > 0 else "추론은 맞았다. 다만 근거를 대지 못했다."
	var hint := ""
	if good < 2:
		var names := []
		for x in Q.evidence:
			if S.clues.has(x) and names.size() < 3:
				names.append(ep.clues[x].t)
		if names.size() > 0:
			hint = "\n[color=#6f665a][font_size=15]결정적인 단서: %s[/font_size][/color]" % ", ".join(names)
	U.fb.text = "[b]맞다.[/b]  " + r + hint
	U.submit.text = "다음 추리  ▸" if qi + 1 < ep.questions.size() else "사건 재구성  ▸"
	_paint_opts()


func _next() -> void:
	qi += 1
	if qi < ep.questions.size():
		_show_question()
	else:
		_show_story(ep.recon, "사건 재구성", "고인의 마지막 물건  ▸", _show_letter)


# ───────────────────────────── 재구성 · 에필로그
func _show_story(lines: Array, title: String, last_label: String, done: Callable) -> void:
	Ui.clear(area)
	recon_i = 0
	var cc := CenterContainer.new()
	Ui.full(cc)
	area.add_child(cc)
	var paper := Ui.panel(Ui.paper_box(false, 48))
	paper.custom_minimum_size = Vector2(780, 0)
	var v := Ui.vbox(14)
	v.add_child(Ui.label(title, 14, Ui.INK_DIM, Ui.spaced))
	var body := Ui.vbox(18)
	v.add_child(body)
	v.add_child(Ui.gap(6))
	var row := Ui.hbox(0)
	row.alignment = BoxContainer.ALIGNMENT_END
	var nb := Ui.ink_button("계속  ▸", 21)
	row.add_child(nb)
	v.add_child(row)
	paper.add_child(v)
	cc.add_child(paper)
	var step := func():
		if recon_i < lines.size():
			var l := Ui.label(lines[recon_i], 20, Ui.INK, Ui.serif, true)
			l.custom_minimum_size = Vector2(680, 0)
			l.modulate.a = 0.0
			body.add_child(l)
			create_tween().tween_property(l, "modulate:a", 1.0, 0.9)
			recon_i += 1
			Sfx.play("paper", 0.5)
			if recon_i == lines.size():
				nb.text = last_label
		else:
			done.call()
	nb.pressed.connect(step)
	step.call()


func _show_letter() -> void:
	Ui.clear(area)
	var d: Dictionary = ep.docs[ep.letter.doc]
	var hb := Ui.hbox(36)
	Ui.full(hb)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_child(hb)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(620, 0)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var paper := Ui.panel(Ui.paper_box(false, 44))
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var txt := Ui.label(d.body, 29, Ui.BLUE_INK, Ui.hand, true)
	txt.add_theme_constant_override("line_spacing", 6)
	paper.add_child(txt)
	sc.add_child(paper)
	hb.add_child(sc)
	U.letter = paper
	var right := Ui.panel(Ui.paper_box(true, 34))
	right.custom_minimum_size = Vector2(400, 0)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := Ui.vbox(12)
	v.add_child(Ui.label("마지막 선택", 14, Ui.INK_DIM, Ui.spaced))
	v.add_child(Ui.label(ep.letter.dilemma, 18, Ui.INK, Ui.serif, true))
	v.add_child(Ui.gap(6))
	v.add_child(Ui.label("이 편지를 어떻게 할까.", 22, Ui.INK, Ui.serif_b))
	v.add_child(Ui.gap(8))
	var b1 := Ui.ink_button("%s에게 전달한다" % ep.letter.to, 21)
	var b2 := Ui.ink_button("태워 없앤다", 21)
	b1.pressed.connect(func(): _choose("deliver", [b1, b2]))
	b2.pressed.connect(func(): _choose("burn", [b1, b2]))
	v.add_child(b1)
	v.add_child(b2)
	right.add_child(v)
	hb.add_child(right)
	Sfx.play("paper", 0.6)


func _choose(c: String, btns: Array) -> void:
	S.choice = c
	for b in btns:
		b.disabled = true
	var p: Control = U.letter
	if c == "burn":
		Sfx.play("burn", 0.9)
		var fx := CPUParticles2D.new()
		fx.amount = 160
		fx.lifetime = 1.8
		fx.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		fx.emission_rect_extents = p.size / 2.0
		fx.gravity = Vector2(0, -90)
		fx.initial_velocity_min = 10.0
		fx.initial_velocity_max = 60.0
		fx.spread = 50.0
		fx.direction = Vector2(0, -1)
		fx.scale_amount_min = 1.5
		fx.scale_amount_max = 4.0
		var ramp := Gradient.new()
		ramp.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
		ramp.colors = PackedColorArray([Color(1.0, 0.85, 0.5, 1), Color(1.0, 0.45, 0.1, 0.9), Color(0.3, 0.1, 0.05, 0)])
		fx.color_ramp = ramp
		add_child(fx)
		fx.global_position = p.global_position + p.size / 2.0
		var tw := create_tween()
		tw.tween_property(p, "modulate", Color(0.9, 0.5, 0.25, 1), 0.9)
		tw.tween_property(p, "modulate", Color(0.15, 0.06, 0.03, 0.0), 2.0)
		tw.tween_interval(0.5)
		tw.tween_callback(func():
			fx.emitting = false
			_epilogue())
	else:
		Sfx.play("deliver", 0.8)
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		p.pivot_offset = p.size / 2.0
		tw.tween_property(p, "scale", Vector2(0.4, 0.4), 1.4)
		tw.tween_property(p, "rotation", deg_to_rad(6), 1.4)
		tw.tween_property(p, "position:x", p.position.x + 700, 1.4)
		tw.tween_property(p, "modulate:a", 0.0, 1.4)
		tw.chain().tween_interval(0.4)
		tw.chain().tween_callback(_epilogue)


func _epilogue() -> void:
	_show_story(ep.endings[S.choice], "편지를 " + ("태웠다" if S.choice == "burn" else "전했다"), "퇴근하기  ▸", func(): Game.finish_episode())
