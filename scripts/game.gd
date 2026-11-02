extends Node
## 게임 흐름 · 화면 · 공용 UI

const RoomScript := preload("res://scripts/room.gd")
const InspectScript := preload("res://scripts/inspect.gd")
const BoardScript := preload("res://scripts/board.gd")
const SAVE_PATH := "user://save.json"

var EPISODES: Array = []
var FINAL_TEXT: Array = []
var ep: Dictionary = {}
var S: Dictionary = {}
var save := {}
var settings := {"sens": 1.0, "volume": 0.8, "fullscreen": false}
var stage := ""
var world: Node = null
var board: Control = null
var paused := false
var modal_open := false
var first_entry := false

var ui: CanvasLayer
var screen: Control
var say_label: Label
var say_panel: PanelContainer
var note_panel: PanelContainer
var note_t: Label
var note_d: Label
var toast_box: VBoxContainer
var modal_root: Control
var modal_center: CenterContainer
var modal_close_cb: Callable = Callable()
var modal_key_cb: Callable = Callable()
var fade_rect: ColorRect
var pause_root: Control

var say_q: Array = []
var say_t := 0.0
var note_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Ui.init()
	_load_data()
	_load_save()
	_build_layers()
	var args := OS.get_cmdline_user_args()
	var test := ""
	for a in args:
		if a.begins_with("--autotest="):
			test = a.substr(11)
	if test == "":
		_apply_settings()
	else:
		Sfx.set_master(0.0)
	show_title()
	if test != "":
		var at: Node = load("res://scripts/autotest.gd").new()
		add_child(at)
		var ei := 0
		for a in args:
			if a.begins_with("--ep="):
				ei = int(a.substr(5))
		at.run(test, ei, not args.has("--quick"))


func _load_data() -> void:
	var f := FileAccess.open("res://data/episodes.json", FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	EPISODES = d.EPISODES
	FINAL_TEXT = d.FINAL_TEXT


func _load_save() -> void:
	save = {"done": {}}
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			save = d
	if not save.has("done"):
		save.done = {}
	if save.has("settings"):
		settings.merge(save.settings, true)


func write_save() -> void:
	save.settings = settings
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save))


func _apply_settings() -> void:
	Sfx.set_master(float(settings.volume))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_MAXIMIZED)


# ───────────────────────────── 레이어
func _build_layers() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var fx := CanvasLayer.new()
	fx.layer = 20
	add_child(fx)
	var fxr := Control.new()
	Ui.full(fxr)
	fxr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fxr.theme = Ui.theme
	fx.add_child(fxr)
	say_panel = Ui.panel(Ui.dark_box(0.55, 16, 0.0))
	say_label = Ui.label("", 20, Ui.TEXT, Ui.serif, true)
	say_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	say_label.custom_minimum_size = Vector2(0, 0)
	say_panel.add_child(say_label)
	Ui.pin(say_panel, 0.5, 1, 0, -96, 0, -1)
	say_panel.modulate.a = 0.0
	say_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fxr.add_child(say_panel)
	note_panel = Ui.panel(Ui.paper_box(false, 24))
	note_panel.custom_minimum_size = Vector2(560, 0)
	var nv := Ui.vbox(6)
	note_t = Ui.label("", 14, Ui.RED, Ui.sans_b)
	note_d = Ui.label("", 19, Ui.INK, Ui.serif, true)
	note_d.custom_minimum_size = Vector2(510, 0)
	nv.add_child(note_t)
	nv.add_child(note_d)
	note_panel.add_child(nv)
	Ui.pin(note_panel, 0.5, 1, 0, -150, 0, -1)
	note_panel.modulate.a = 0.0
	note_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fxr.add_child(note_panel)
	toast_box = Ui.vbox(6)
	Ui.pin(toast_box, 0.5, 0, 0, 28, 0, 1)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fxr.add_child(toast_box)
	var ml := CanvasLayer.new()
	ml.layer = 30
	add_child(ml)
	modal_root = Control.new()
	Ui.full(modal_root)
	modal_root.theme = Ui.theme
	modal_root.visible = false
	ml.add_child(modal_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.78)
	Ui.full(dim)
	modal_root.add_child(dim)
	modal_center = CenterContainer.new()
	Ui.full(modal_center)
	modal_root.add_child(modal_center)
	pause_root = Control.new()
	Ui.full(pause_root)
	pause_root.theme = Ui.theme
	pause_root.visible = false
	var pl := CanvasLayer.new()
	pl.layer = 25
	add_child(pl)
	pl.add_child(pause_root)
	var fl := CanvasLayer.new()
	fl.layer = 40
	add_child(fl)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	Ui.full(fade_rect)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(fade_rect)
	var gl := CanvasLayer.new()
	gl.layer = 45
	add_child(gl)
	var grain := ColorRect.new()
	Ui.full(grain)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform float amount = 0.045;\nfloat rnd(vec2 p){ return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }\nvoid fragment(){ vec2 p = floor(FRAGCOORD.xy / 2.0); float n = rnd(p + fract(TIME * 7.13) * 91.7); COLOR = vec4(vec3(n), amount); }"
	var smat := ShaderMaterial.new()
	smat.shader = sh
	grain.material = smat
	gl.add_child(grain)


func _new_screen() -> Control:
	if screen:
		screen.queue_free()
	screen = Control.new()
	Ui.full(screen)
	screen.theme = Ui.theme
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(screen)
	return screen


func _set_world(n: Node) -> void:
	if world:
		world.queue_free()
	world = n
	if n:
		add_child(n)


func fade(cb: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 0.4)
	tw.tween_callback(cb)
	tw.tween_interval(0.1)
	tw.tween_property(fade_rect, "color:a", 0.0, 0.5)


# ───────────────────────────── 타이틀
func _unlocked(i: int) -> bool:
	if OS.get_cmdline_user_args().has("--all"):
		return true
	return i == 0 or save.done.has(EPISODES[i - 1].id)


func show_title() -> void:
	stage = "title"
	_unpause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if board:
		board.queue_free()
		board = null
	var pv := RoomScript.new()
	_set_world(pv)
	pv.setup(EPISODES[0], _new_state(), true)
	var root := _new_screen()
	var shade := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.9), Color(0, 0, 0, 0.6), Color(0, 0, 0, 0.05)])
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	Ui.full(shade)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	var col := Ui.vbox(4)
	Ui.pin(col, 0, 0, 96, 110)
	col.add_child(Ui.label("특수청소부의 기록", 18, Color("a39b8e"), Ui.serif))
	col.add_child(Ui.shadow(Ui.label("마지막 방", 88, Color("efe9df"), Ui.serif_b)))
	col.add_child(Ui.gap(36))
	for i in EPISODES.size():
		col.add_child(_ep_row(i))
	col.add_child(Ui.gap(30))
	for m in [["설정", open_settings], ["조작법", open_help], ["기록 지우기", _reset_save], ["끝내기", func(): get_tree().quit()]]:
		var b := Ui.button(m[0], 20, m[1], Ui.serif, Color("b9b1a4"))
		b.custom_minimum_size = Vector2(160, 0)
		col.add_child(b)
	root.add_child(col)
	var cw := Ui.label("죽음, 고독사, 약물 오남용 같은 무거운 이야기를 다룹니다. 힘들 때는 언제든 쉬어 가세요.", 14, Color(1, 1, 1, 0.38), Ui.sans)
	Ui.pin(cw, 0, 1, 96, -34, 1, -1)
	root.add_child(cw)
	var ver := Ui.label("F11  전체 화면", 13, Color(1, 1, 1, 0.3), Ui.sans)
	Ui.pin(ver, 1, 1, -30, -34, -1, -1)
	root.add_child(ver)


func _ep_row(i: int) -> Control:
	var E: Dictionary = EPISODES[i]
	var open := _unlocked(i)
	var done = save.done.get(E.id)
	var row := Ui.hbox(18)
	var mark := Ui.label("—", 26, Ui.ACCENT, Ui.serif)
	mark.modulate.a = 0.0
	row.add_child(mark)
	var t := "%d장   %s" % [int(E.no), E.title] if open else "%d장   ……" % int(E.no)
	var b := Ui.button(t, 30, func(): show_brief(E), Ui.serif_b, Color("e6e1d8") if open else Color(1, 1, 1, 0.25))
	b.disabled = not open
	b.custom_minimum_size = Vector2(300, 0)
	row.add_child(b)
	var info: String = E.place if open else "앞 장을 마쳐야 열린다"
	if done != null:
		info += "      %s등급 · 편지를 %s" % [done.grade, "태웠다" if done.choice == "burn" else "전했다"]
	var il := Ui.label(info, 17, Color("9b9387") if done == null else Color("c9b48a"), Ui.sans)
	row.add_child(il)
	b.mouse_entered.connect(func(): mark.modulate.a = 1.0 if open else 0.0)
	b.mouse_exited.connect(func(): mark.modulate.a = 0.0)
	return row


func _reset_save() -> void:
	confirm("기록을 지울까?", "끝낸 장과 등급이 모두 사라진다.", "지우기", func():
		save = {"done": {}}
		write_save()
		show_title())


# ───────────────────────────── 의뢰서
func show_brief(E: Dictionary) -> void:
	ep = E
	stage = "brief"
	var root := _new_screen()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	Ui.full(dim)
	root.add_child(dim)
	var cc := CenterContainer.new()
	Ui.full(cc)
	root.add_child(cc)
	var paper := Ui.panel(Ui.paper_box(false, 46))
	paper.custom_minimum_size = Vector2(680, 0)
	var v := Ui.vbox(8)
	var head := Ui.hbox(0)
	head.add_child(Ui.expand(Ui.label("작업 의뢰서", 14, Ui.INK_DIM, Ui.spaced)))
	head.add_child(Ui.label(E.date, 14, Ui.INK_DIM, Ui.sans))
	v.add_child(head)
	var line := ColorRect.new()
	line.color = Color(Ui.INK, 0.22)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	v.add_child(Ui.gap(6))
	var th := Ui.hbox(0)
	var tv := Ui.vbox(2)
	tv.add_child(Ui.label("%d장 · %s" % [int(E.no), E.title], 36, Ui.INK, Ui.serif_b))
	tv.add_child(Ui.label(E.place, 18, Ui.INK_DIM, Ui.serif))
	th.add_child(Ui.expand(tv))
	var st := Ui.stamp("접수", 26)
	st.rotation = deg_to_rad(-11)
	th.add_child(st)
	v.add_child(th)
	v.add_child(Ui.gap(10))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 9)
	var B: Dictionary = E.brief
	for kv in [["고인", B.deceased], ["직업", B.job], ["주소", B.address], ["발견 경위", B.found], ["경찰 소견", B.police], ["의뢰인", B.client]]:
		grid.add_child(Ui.label(kv[0], 14, Ui.INK_DIM, Ui.sans))
		var val := Ui.label(kv[1], 17, Ui.INK, Ui.serif, true)
		val.custom_minimum_size = Vector2(470, 0)
		grid.add_child(val)
	v.add_child(grid)
	v.add_child(Ui.gap(12))
	var q := Ui.label(B.note, 18, Color("5a4f40"), Ui.serif, true)
	q.custom_minimum_size = Vector2(580, 0)
	v.add_child(q)
	v.add_child(Ui.gap(14))
	v.add_child(Ui.label("① 현장 정리     ② 유품 조사     ③ 사건 재구성", 14, Ui.INK_DIM, Ui.sans))
	v.add_child(Ui.gap(16))
	var row := Ui.hbox(30)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(Ui.ink_button("돌아가기", 19, show_title))
	row.add_child(Ui.ink_button("현장으로 간다  ▸", 22, enter_room))
	v.add_child(row)
	paper.add_child(v)
	cc.add_child(paper)


func _new_state() -> Dictionary:
	return {"sorted": {}, "kept": [], "err": {"kept_trash": 0, "lost_keep": 0}, "clues": [], "stains": {}, "spots": {}, "opened": {}, "phone_unlocked": false, "answers": [], "choice": "", "clean_pct": 0.0, "t1": 0.0, "t2": 0.0, "t3": 0.0}


# ───────────────────────────── 1단계
func enter_room() -> void:
	S = _new_state()
	fade(func():
		_new_screen()
		var r := RoomScript.new()
		_set_world(r)
		r.setup(ep, S, false)
		stage = "room"
		first_entry = true
		show_pause(true))


func show_pause(first := false) -> void:
	paused = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.stop_loops()
	if world and world.has_method("release"):
		world.release()
	Ui.clear(pause_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	Ui.full(dim)
	pause_root.add_child(dim)
	var v := Ui.vbox(10)
	Ui.pin(v, 0, 0.5, 120, 0, 1, 0)
	v.add_child(Ui.label(("%d장 · %s" % [int(ep.no), ep.place]) if first else "잠시 멈춤", 44, Color("efe9df"), Ui.serif_b))
	v.add_child(Ui.label("방독 마스크를 쓰고, 문을 연다." if first else "숨을 고른다.", 19, Color("a39b8e"), Ui.serif))
	v.add_child(Ui.gap(22))
	var keys := GridContainer.new()
	keys.columns = 2
	keys.add_theme_constant_override("h_separation", 26)
	keys.add_theme_constant_override("v_separation", 6)
	for kv in [["W A S D", "이동"], ["마우스", "둘러보기"], ["1  2  3", "손 · 소독 분무기 · 스크러버"], ["왼쪽 버튼 누르고 있기", "도구 사용 (스크러버는 마우스를 움직여 문지르기)"], ["E", "집어 보기 · 조사 / 보관함에 넣기"], ["Q", "폐기"], ["F", "손전등"], ["Esc", "멈춤"]]:
		keys.add_child(Ui.label(kv[0], 16, Ui.ACCENT, Ui.sans_b))
		keys.add_child(Ui.label(kv[1], 16, Color("cfc9bf"), Ui.sans))
	v.add_child(keys)
	v.add_child(Ui.gap(26))
	v.add_child(Ui.button("작업 시작" if first else "계속하기", 26, hide_pause, Ui.serif_b))
	if not first:
		v.add_child(Ui.button("설정", 20, open_settings, Ui.serif, Color("b9b1a4")))
	v.add_child(Ui.button("장 선택으로", 20, quit_to_title, Ui.serif, Color("b9b1a4")))
	pause_root.add_child(v)
	pause_root.visible = true


func hide_pause() -> void:
	pause_root.visible = false
	_unpause()
	if stage == "room":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if first_entry:
			first_entry = false
			for l in ep.intro:
				say(l, 3.8)
			if int(ep.no) == 1:
				say("[2] 소독 분무기로 얼룩에 소독약을 뿌리고, [3] 스크러버로 문질러 닦는다.", 5.2)
				say("물건은 [E]로 집어 보관할지 버릴지 정한다. 손전등은 [F].", 4.6)


func _unpause() -> void:
	paused = false
	get_tree().paused = false


func finish_room() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	fade(func():
		_clear_texts()
		var ins := InspectScript.new()
		_set_world(ins)
		stage = "inspect"
		ins.setup(ep, S)
		note("작업실", "보관함에 넣은 물건을 하나씩 돌려 보며 단서를 찾는다. 수상한 곳을 누르면 조사한다. 눈에 안 보이는 흔적은 UV 라이트로 비춰 본다."))


# ───────────────────────────── 2·3단계
func go_board() -> void:
	if stage != "inspect":
		return
	if not world.has_letter():
		note("아직이다", "고인이 마지막으로 남긴 물건을 아직 찾지 못했다. 잠긴 것, 숨겨진 것을 더 살펴보자.")
		Sfx.play("error", 0.6)
		return
	var go := func():
		fade(func():
			_clear_texts()
			_set_world(null)
			_new_screen()
			stage = "board"
			board = BoardScript.new()
			ui.add_child(board)
			board.setup(ep, S))
	var m: int = world.missing()
	if m > 0:
		confirm("아직 찾지 못한 단서가 %d개 있다." % m, "이대로 사건을 재구성할까?", "재구성한다", go, "더 조사한다")
	else:
		go.call()


func quit_to_title() -> void:
	confirm("장 선택으로 돌아갈까?", "이번 작업은 처음부터 다시 해야 한다.", "돌아간다", func():
		pause_root.visible = false
		fade(func():
			_clear_texts()
			show_title()))


func _score() -> Dictionary:
	var clean: float = 25.0 * min(1.0, float(S.clean_pct))
	var sort: float = max(0.0, 25.0 - S.err.kept_trash * 2.0 - S.err.lost_keep * 5.0)
	var all := 0
	var found := 0
	for k in ep.clues:
		if not ep.clues[k].get("hint", false):
			all += 1
			if S.clues.has(k):
				found += 1
	var clues: float = 25.0 * found / max(1, all)
	var ded := 0.0
	var wrong := 0
	var ev := 0
	for a in S.answers:
		ded += max(0.0, 7.5 - 2.5 * a.wrong) + 2.5 * min(2, a.ev)
		wrong += int(a.wrong)
		ev += int(a.ev)
	var total := int(round(clean + sort + clues + ded))
	var grade := "S" if total >= 90 else ("A" if total >= 75 else ("B" if total >= 60 else "C"))
	return {"clean": clean, "sort": sort, "clues": clues, "ded": ded, "total": total, "grade": grade, "found": found, "all": all, "wrong": wrong, "ev": ev, "time": S.t1 + S.t2 + S.t3}


func finish_episode() -> void:
	var r := _score()
	var prev = save.done.get(ep.id)
	var best: int = r.total
	if prev != null:
		best = max(best, int(prev.get("best", prev.get("score", 0))))
	save.done[ep.id] = {"grade": r.grade, "score": r.total, "choice": S.choice, "best": best}
	write_save()
	fade(func():
		if board:
			board.queue_free()
			board = null
		stage = "result"
		_show_result(r))


func _show_result(r: Dictionary) -> void:
	var root := _new_screen()
	var bg := ColorRect.new()
	bg.color = Color("0b0b0c")
	Ui.full(bg)
	root.add_child(bg)
	var cc := CenterContainer.new()
	Ui.full(cc)
	root.add_child(cc)
	var paper := Ui.panel(Ui.paper_box(false, 48))
	paper.custom_minimum_size = Vector2(640, 0)
	var v := Ui.vbox(10)
	var head := Ui.hbox(0)
	var hv := Ui.vbox(2)
	hv.add_child(Ui.label("퇴근 기록", 14, Ui.INK_DIM, Ui.spaced))
	hv.add_child(Ui.label("%d장 · %s" % [int(ep.no), ep.title], 30, Ui.INK, Ui.serif_b))
	hv.add_child(Ui.label(ep.place, 17, Ui.INK_DIM, Ui.serif))
	head.add_child(Ui.expand(hv))
	var st := Ui.stamp(r.grade, 46)
	st.rotation = deg_to_rad(-9)
	head.add_child(st)
	v.add_child(head)
	v.add_child(Ui.gap(10))
	var mm := int(r.time) / 60
	var ss := int(r.time) % 60
	var errs: int = S.err.kept_trash + S.err.lost_keep
	var rows := [
		["현장 정리", "오염 %d%% 제거" % int(S.clean_pct * 100.0)],
		["유품 분류", ("실수 %d건" % errs + (" (유품 폐기 %d)" % S.err.lost_keep if S.err.lost_keep > 0 else "")) if errs > 0 else "실수 없음"],
		["유품 조사", "단서 %d / %d" % [r.found, r.all]],
		["사건 재구성", ("오답 %d번" % r.wrong if r.wrong > 0 else "오답 없음") + "  ·  결정적 근거 %d개" % r.ev],
		["작업 시간", "%d분 %02d초" % [mm, ss]],
		["점수", "%d점" % r.total]]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	for kv in rows:
		grid.add_child(Ui.label(kv[0], 16, Ui.INK_DIM, Ui.sans))
		grid.add_child(Ui.label(kv[1], 18, Ui.INK, Ui.serif_b))
	v.add_child(grid)
	v.add_child(Ui.gap(14))
	v.add_child(Ui.label("고인의 편지 — %s에게 %s" % [ep.letter.to, "전하지 않고 태웠다." if S.choice == "burn" else "전했다."], 17, Ui.INK, Ui.serif, true))
	v.add_child(Ui.gap(4))
	var o := Ui.label(ep.outro, 18, Color("5a4f40"), Ui.serif, true)
	o.custom_minimum_size = Vector2(540, 0)
	v.add_child(o)
	v.add_child(Ui.gap(18))
	var row := Ui.hbox(0)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(Ui.ink_button("퇴근한다  ▸", 22, _after_result))
	v.add_child(row)
	paper.add_child(v)
	cc.add_child(paper)
	Sfx.play("done", 0.6)


func _after_result() -> void:
	var all_done := true
	for E in EPISODES:
		if not save.done.has(E.id):
			all_done = false
	if all_done and not save.get("seen_final", false):
		save.seen_final = true
		write_save()
		fade(_show_final)
		return
	fade(show_title)


func _show_final() -> void:
	stage = "final"
	_set_world(null)
	var root := _new_screen()
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	Ui.full(bg)
	root.add_child(bg)
	var cc := CenterContainer.new()
	Ui.full(cc)
	root.add_child(cc)
	var v := Ui.vbox(26)
	v.custom_minimum_size = Vector2(700, 0)
	var labels := []
	for line in FINAL_TEXT:
		var l := Ui.label(line, 24, Color("e6e1d8"), Ui.serif, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		v.add_child(l)
		labels.append(l)
	v.add_child(Ui.gap(20))
	for E in EPISODES:
		var d = save.done.get(E.id)
		var s := "%d장 · %s   —   %s" % [int(E.no), E.title, ("%s등급 · 편지를 %s" % [d.grade, "태웠다" if d.choice == "burn" else "전했다"]) if d != null else "-"]
		var l := Ui.label(s, 16, Color("9b9387"), Ui.sans)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		v.add_child(l)
		labels.append(l)
	var b := Ui.button("처음으로", 22, func(): fade(show_title), Ui.serif_b)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.modulate.a = 0.0
	v.add_child(b)
	labels.append(b)
	cc.add_child(v)
	var tw := create_tween()
	for l in labels:
		tw.tween_property(l, "modulate:a", 1.0, 1.1)
		tw.tween_interval(0.5)


# ───────────────────────────── 공용 알림
func say(text: String, dur := 0.0) -> void:
	while say_q.size() > 2:
		say_q.pop_front()
	say_q.append([text, dur if dur > 0.0 else max(2.4, text.length() * 0.085)])


func note(title: String, text: String) -> void:
	note_t.text = title
	note_d.text = text
	note_timer = 3.4 + text.length() / 20.0
	create_tween().tween_property(note_panel, "modulate:a", 1.0, 0.2)


func toast(text: String, clue := false) -> void:
	var p := Ui.panel(Ui.dark_box(0.9, 14, 0.12))
	var l := Ui.label(text, 16, Color("f1d6a8") if clue else Ui.TEXT, Ui.sans_b)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_child(p)
	var tw := create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)


func _clear_texts() -> void:
	say_q.clear()
	say_t = 0.0
	say_panel.modulate.a = 0.0
	note_timer = 0.0
	note_panel.modulate.a = 0.0


func add_clue(id: String) -> void:
	if S.is_empty() or not ep.clues.has(id) or S.clues.has(id):
		return
	S.clues.append(id)
	var c: Dictionary = ep.clues[id]
	if stage != "inspect":
		toast(("메모 · " if c.get("hint", false) else "사건 노트에 적었다 · ") + c.t, true)
	Sfx.play("clue", 0.6)
	if world and world.has_method("refresh"):
		world.refresh()


func _process(dt: float) -> void:
	if say_t > 0.0:
		say_t -= dt
		if say_t <= 0.0:
			create_tween().tween_property(say_panel, "modulate:a", 0.0, 0.3)
	elif say_q.size() > 0 and not paused and (stage == "room" or stage == "inspect"):
		var s: Array = say_q.pop_front()
		say_label.text = s[0]
		var tw: float = Ui.serif.get_string_size(s[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		say_label.custom_minimum_size = Vector2(min(tw + 8.0, 860.0), 0)
		say_panel.reset_size()
		Ui.pin(say_panel, 0.5, 1, 0, -96, 0, -1)
		say_t = s[1]
		create_tween().tween_property(say_panel, "modulate:a", 1.0, 0.25)
	if note_timer > 0.0:
		note_timer -= dt
		if note_timer <= 0.0:
			create_tween().tween_property(note_panel, "modulate:a", 0.0, 0.3)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F11:
			settings.fullscreen = not settings.fullscreen
			_apply_settings()
			write_save()
			get_viewport().set_input_as_handled()
			return
		if modal_open:
			if event.physical_keycode == KEY_ESCAPE:
				close_modal()
			elif modal_key_cb.is_valid():
				modal_key_cb.call(event)
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_ESCAPE:
			if stage == "room":
				if pause_root.visible:
					hide_pause()
				elif not world.exiting:
					show_pause(false)
				get_viewport().set_input_as_handled()
			elif stage == "inspect" or stage == "board":
				quit_to_title()
				get_viewport().set_input_as_handled()


# ───────────────────────────── 모달
func open_modal(content: Control, on_close: Callable = Callable()) -> void:
	for c in modal_center.get_children():
		c.queue_free()
	modal_center.add_child(content)
	modal_root.visible = true
	modal_open = true
	modal_close_cb = on_close
	modal_key_cb = Callable()
	if stage == "room":
		paused = true
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_modal(silent := false) -> void:
	modal_root.visible = false
	modal_open = false
	modal_key_cb = Callable()
	for c in modal_center.get_children():
		c.queue_free()
	var cb := modal_close_cb
	modal_close_cb = Callable()
	if stage == "room" and not pause_root.visible:
		_unpause()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if cb.is_valid() and not silent:
		cb.call()


func _buttons_row(items: Array, on_paper := true) -> HBoxContainer:
	var row := Ui.hbox(30)
	row.alignment = BoxContainer.ALIGNMENT_END
	for it in items:
		row.add_child(Ui.ink_button(it[0], it[2] if it.size() > 2 else 19, it[1]) if on_paper else Ui.button(it[0], it[2] if it.size() > 2 else 19, it[1], Ui.serif_b))
	return row


func confirm(title: String, text: String, yes: String, cb: Callable, no := "그만둔다") -> void:
	var p := Ui.panel(Ui.paper_box(false, 38))
	p.custom_minimum_size = Vector2(480, 0)
	var v := Ui.vbox(10)
	v.add_child(Ui.label(title, 24, Ui.INK, Ui.serif_b, true))
	v.add_child(Ui.label(text, 17, Ui.INK_DIM, Ui.serif, true))
	v.add_child(Ui.gap(14))
	v.add_child(_buttons_row([[no, func(): close_modal()], [yes, func():
		close_modal(true)
		cb.call()]]))
	p.add_child(v)
	open_modal(p)


func open_help() -> void:
	var p := Ui.panel(Ui.dark_box(0.96, 36, 0.1))
	var v := Ui.vbox(12)
	v.add_child(Ui.label("조작법", 30, Ui.TEXT, Ui.serif_b))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 7)
	for kv in [["1단계 · 현장 정리", ""], ["W A S D / 마우스", "이동 / 둘러보기"], ["1 · 2 · 3, 휠", "손 · 소독 분무기 · 스크러버"], ["왼쪽 버튼 누르고 있기", "도구 사용. 소독약을 먼저 뿌려야 잘 닦인다"], ["E / Q / X", "집어 보기 · 보관 / 폐기 / 내려놓기"], ["F", "손전등"], ["", ""], ["2단계 · 유품 조사", ""], ["끌기 / 휠", "돌려 보기 / 확대"], ["클릭", "수상한 곳 조사"], ["U / H / R", "UV 라이트 / 단서 위치 / 정면"], ["", ""], ["3단계 · 사건 재구성", ""], ["쪽지 · 보기 선택", "답과 근거 단서(최대 2장)를 고른다"], ["", ""], ["Esc / F11", "멈춤 / 전체 화면"]]:
		var head: bool = kv[1] == "" and kv[0] != ""
		grid.add_child(Ui.label(kv[0], 17 if head else 16, Ui.ACCENT if head else Color("e6e1d8"), Ui.serif_b if head else Ui.sans_b))
		grid.add_child(Ui.label(kv[1], 16, Color("cfc9bf"), Ui.sans))
	v.add_child(grid)
	v.add_child(Ui.gap(8))
	v.add_child(_buttons_row([["닫기", func(): close_modal()]], false))
	p.add_child(v)
	open_modal(p)


func open_settings() -> void:
	var p := Ui.panel(Ui.dark_box(0.96, 36, 0.1))
	p.custom_minimum_size = Vector2(520, 0)
	var v := Ui.vbox(14)
	v.add_child(Ui.label("설정", 30, Ui.TEXT, Ui.serif_b))
	for spec in [["마우스 감도", "sens", 0.3, 2.5], ["소리 크기", "volume", 0.0, 1.0]]:
		var row := Ui.hbox(20)
		var l := Ui.label(spec[0], 17, Color("cfc9bf"), Ui.sans)
		l.custom_minimum_size = Vector2(130, 0)
		row.add_child(l)
		var s := HSlider.new()
		s.min_value = spec[2]
		s.max_value = spec[3]
		s.step = 0.05
		s.value = float(settings[spec[1]])
		s.custom_minimum_size = Vector2(260, 24)
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var key: String = spec[1]
		s.value_changed.connect(func(val):
			settings[key] = val
			if key == "volume":
				Sfx.set_master(val)
			if key == "sens" and world and stage == "room":
				world.sens = 0.0022 * val)
		row.add_child(s)
		v.add_child(row)
	var fs := CheckButton.new()
	fs.text = "전체 화면"
	fs.button_pressed = settings.fullscreen
	fs.add_theme_font_override("font", Ui.sans)
	fs.add_theme_font_size_override("font_size", 17)
	fs.toggled.connect(func(on):
		settings.fullscreen = on
		_apply_settings())
	v.add_child(fs)
	v.add_child(Ui.gap(6))
	v.add_child(_buttons_row([["닫기", func():
		write_save()
		close_modal()]], false))
	p.add_child(v)
	open_modal(p)


func open_doc(id: String) -> void:
	var d: Dictionary = ep.docs[id]
	Sfx.play("paper", 0.6)
	var style: String = d.get("style", "paper")
	var p := Ui.panel(Ui.paper_box(style == "bank" or style == "receipt", 44))
	var v := Ui.vbox(10)
	var w := 600.0
	if style == "receipt":
		w = 420.0
	if style != "letter":
		v.add_child(Ui.label(d.title, 25, Ui.INK, Ui.serif_b, true))
		var line := ColorRect.new()
		line.color = Color(Ui.INK, 0.25)
		line.custom_minimum_size = Vector2(0, 1)
		v.add_child(line)
	var body: Control
	if style == "letter" or style == "hand":
		body = Ui.rich(Ui.bb(d.body), 29, Ui.BLUE_INK, Ui.hand, Ui.hand)
	else:
		body = Ui.rich(Ui.bb(d.body), 18, Ui.INK, Ui.serif, Ui.serif_b)
	body.custom_minimum_size = Vector2(w, 0)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(w + 12, min(get_viewport().get_visible_rect().size.y * 0.62, 600.0))
	sc.add_child(body)
	v.add_child(sc)
	v.add_child(_buttons_row([["닫기", func(): close_modal()]]))
	p.add_child(v)
	open_modal(p)
	if d.has("clue"):
		get_tree().create_timer(0.45).timeout.connect(func(): add_clue(d.clue))


# ───────────────────────────── 휴대폰
func open_phone() -> void:
	var P: Dictionary = ep.phone
	if P.pattern != null and not S.phone_unlocked:
		open_pattern(P.pattern, func():
			S.phone_unlocked = true
			Sfx.play("unlock", 0.8)
			get_tree().create_timer(0.2).timeout.connect(func(): _show_phone(0)))
		return
	_show_phone(0)


func _phone_shell(P: Dictionary, ai: int) -> Array:
	var flip: bool = P.skin == "flip"
	var outer := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("101a14") if flip else Color("0d0f14")
	sb.border_color = Color("8d9096") if flip else Color("1d1f25")
	sb.set_border_width_all(10)
	sb.set_corner_radius_all(18 if flip else 34)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 18
	sb.content_margin_bottom = 16
	outer.add_theme_stylebox_override("panel", sb)
	outer.custom_minimum_size = Vector2(360, min(640.0, get_viewport().get_visible_rect().size.y * 0.8))
	var v := Ui.vbox(10)
	var tabs := Ui.hbox(6)
	for i in P.apps.size():
		var on: bool = i == ai
		var b := Ui.button(P.apps[i].name, 15, Callable(), Ui.sans_b, Color("111111") if on else Color("a7abb3"), Color("111111") if on else Color("e6e1d8"))
		b.flat = false
		var st := StyleBoxFlat.new()
		st.bg_color = (Color("7fd49a") if flip else Color("e8e4dc")) if on else Color(1, 1, 1, 0.06)
		st.set_corner_radius_all(14)
		st.content_margin_left = 12
		st.content_margin_right = 12
		st.content_margin_top = 5
		st.content_margin_bottom = 5
		for k in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(k, st)
		var idx: int = i
		b.pressed.connect(func():
			Sfx.play("click", 0.5)
			_show_phone(idx))
		tabs.add_child(b)
	v.add_child(tabs)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := Ui.vbox(6)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(body)
	v.add_child(sc)
	outer.add_child(v)
	var wrap := Ui.vbox(14)
	wrap.add_child(outer)
	var close := Ui.button("닫기", 19, func(): close_modal(), Ui.serif_b)
	close.alignment = HORIZONTAL_ALIGNMENT_CENTER
	wrap.add_child(close)
	return [wrap, body, sc]


func _entry_box(title: String, sub: String, strong := false) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(1, 1, 1, 0.05)
	st.set_corner_radius_all(12)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", st)
	var v := Ui.vbox(3)
	v.add_child(Ui.label(title, 16, Color("f1d6a8") if strong else Color("e6e1d8"), Ui.sans_b, true))
	if sub != "":
		v.add_child(Ui.label(sub, 13, Color("8b8f98"), Ui.sans))
	p.add_child(v)
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return p


func _show_phone(ai: int) -> void:
	var P: Dictionary = ep.phone
	var app: Dictionary = P.apps[ai]
	var parts := _phone_shell(P, ai)
	var body: VBoxContainer = parts[1]
	match String(app.type):
		"threads":
			for ti in app.threads.size():
				var th: Dictionary = app.threads[ti]
				var last := ""
				for m in th.msgs:
					if m.has("t"):
						last = m.t
				var e := _entry_box(th.name, last)
				var k: int = ti
				e.gui_input.connect(func(ev):
					if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
						_show_thread(ai, k))
				body.add_child(e)
		"list":
			for en in app.entries:
				var e := _entry_box(en.title, en.get("sub", ""), en.get("strong", false))
				if en.has("body"):
					var bl := Ui.label(en.body, 15, Color("d7d3cb"), Ui.sans, true)
					bl.custom_minimum_size = Vector2(280, 0)
					bl.visible = false
					e.get_child(0).add_child(bl)
					var entry: Dictionary = en
					e.gui_input.connect(func(ev):
						if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
							bl.visible = not bl.visible
							Sfx.play("click", 0.5)
							if entry.has("clue"):
								get_tree().create_timer(0.3).timeout.connect(func(): add_clue(entry.clue)))
				body.add_child(e)
			if app.has("clue"):
				get_tree().create_timer(0.5).timeout.connect(func(): add_clue(app.clue))
		_:
			for cap in app.entries:
				var row := Ui.hbox(12)
				var sw := ColorRect.new()
				sw.color = Color("2a2e36")
				sw.custom_minimum_size = Vector2(58, 58)
				row.add_child(sw)
				var l := Ui.label(cap, 14, Color("c9c5bd"), Ui.sans, true)
				l.custom_minimum_size = Vector2(230, 0)
				row.add_child(l)
				body.add_child(row)
	open_modal(parts[0])


func _show_thread(ai: int, ti: int) -> void:
	var P: Dictionary = ep.phone
	var th: Dictionary = P.apps[ai].threads[ti]
	var parts := _phone_shell(P, ai)
	var body: VBoxContainer = parts[1]
	var sc: ScrollContainer = parts[2]
	var head := Ui.hbox(10)
	head.add_child(Ui.button("‹  목록", 15, func(): _show_phone(ai), Ui.sans_b, Color("a7abb3")))
	head.add_child(Ui.label(th.name, 17, Color("e6e1d8"), Ui.sans_b))
	body.add_child(head)
	var flip: bool = P.skin == "flip"
	for m in th.msgs:
		if m.has("d"):
			var dl := Ui.label(m.d, 12, Color("6f747d"), Ui.sans)
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			body.add_child(dl)
			continue
		var me: bool = m.get("me", 0) == 1
		var row := Ui.hbox(0)
		row.alignment = BoxContainer.ALIGNMENT_END if me else BoxContainer.ALIGNMENT_BEGIN
		var bub := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = (Color("7fd49a") if flip else Color("c9a466")) if me else Color("262a33")
		st.set_corner_radius_all(14)
		st.content_margin_left = 12
		st.content_margin_right = 12
		st.content_margin_top = 8
		st.content_margin_bottom = 8
		bub.add_theme_stylebox_override("panel", st)
		var l := Ui.label(m.t, 15, Color("1a140b") if me else Color("e6e1d8"), Ui.sans, true)
		var tw: float = Ui.sans.get_string_size(m.t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		l.custom_minimum_size = Vector2(min(230.0, tw + 4.0), 0)
		bub.add_child(l)
		row.add_child(bub)
		body.add_child(row)
	open_modal(parts[0])
	Sfx.play("click", 0.5)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(sc):
		sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value)
	if th.has("clue"):
		get_tree().create_timer(0.6).timeout.connect(func(): add_clue(th.clue))


# ───────────────────────────── 패턴 잠금
class PatternPad extends Control:
	var sol: Array = []
	var on_ok: Callable
	var msg: Label
	var path: Array = []
	var cur = null
	var drawing := false
	var state := ""
	var tries := 0

	func _init(s: Array, ok: Callable, m: Label) -> void:
		for x in s:
			sol.append(int(x))
		on_ok = ok
		msg = m
		custom_minimum_size = Vector2(300, 300)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _pt(i: int) -> Vector2:
		return Vector2(50 + (i % 3) * 100, 50 + (i / 3) * 100)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.08, 0.1))
		var col := Color("e8e4dc")
		if state == "bad":
			col = Color("e0605a")
		elif state == "ok":
			col = Color("7fd49a")
		if path.size() > 0:
			var pts := PackedVector2Array()
			for i in path:
				pts.append(_pt(i))
			if drawing and cur != null:
				pts.append(cur)
			if pts.size() > 1:
				draw_polyline(pts, Color(col, 0.75), 6.0, true)
		for i in range(9):
			var on: bool = path.has(i)
			draw_circle(_pt(i), 12.0 if on else 8.0, col if on else Color(1, 1, 1, 0.4))

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				state = ""
				drawing = true
				path = []
				_try(e.position)
				cur = e.position
			else:
				drawing = false
				cur = null
				_check()
			queue_redraw()
		elif e is InputEventMouseMotion and drawing:
			cur = e.position
			_try(cur)
			queue_redraw()

	func _try(p: Vector2) -> void:
		for i in range(9):
			if path.has(i):
				continue
			if p.distance_to(_pt(i)) < 34.0:
				if path.size() > 0:
					var a: int = path[-1]
					var ra := a / 3
					var ca := a % 3
					var rb := i / 3
					var cb := i % 3
					if (ra + rb) % 2 == 0 and (ca + cb) % 2 == 0:
						var mid := (ra + rb) / 2 * 3 + (ca + cb) / 2
						if not path.has(mid):
							path.append(mid)
				path.append(i)
				Sfx.play("click", 0.4)

	func _check() -> void:
		if path.size() < 2:
			path = []
			return
		if path == sol:
			state = "ok"
			msg.text = "잠금 해제"
			queue_redraw()
			await get_tree().create_timer(0.35).timeout
			on_ok.call()
		else:
			tries += 1
			state = "bad"
			Sfx.play("error", 0.6)
			msg.text = "패턴이 맞지 않는다." + (" 어딘가에 힌트가 남아 있을지도 모른다." if tries >= 3 else "")
			queue_redraw()
			await get_tree().create_timer(0.65).timeout
			if state == "bad":
				path = []
				state = ""
				queue_redraw()


func open_pattern(sol: Array, ok: Callable) -> void:
	var p := Ui.panel(Ui.dark_box(0.98, 30, 0.1))
	var v := Ui.vbox(14)
	var t := Ui.label("패턴을 그려 잠금 해제", 17, Ui.ACCENT, Ui.sans_b)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var msg := Ui.label("점을 이어 그린다.", 15, Ui.DIM, Ui.sans, true)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pad := PatternPad.new(sol, func():
		close_modal(true)
		ok.call(), msg)
	v.add_child(pad)
	v.add_child(msg)
	var b := Ui.button("그만두기", 18, func(): close_modal(), Ui.serif_b)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	p.add_child(v)
	open_modal(p)


# ───────────────────────────── 숫자 자물쇠
func open_combo(code: String, ok: Callable) -> void:
	var vals := [0, 0, 0, 0]
	var cursor := [0]
	var p := Ui.panel(Ui.dark_box(0.98, 34, 0.1))
	var v := Ui.vbox(14)
	var t := Ui.label("숫자 자물쇠", 17, Ui.ACCENT, Ui.sans_b)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var wheels := Ui.hbox(14)
	wheels.alignment = BoxContainer.ALIGNMENT_CENTER
	var digits := []
	var msg := Ui.label("네 자리 숫자. 키보드로도 넣을 수 있다.", 15, Ui.DIM, Ui.sans, true)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var show := func():
		for i in range(4):
			digits[i].text = str(vals[i])
			digits[i].add_theme_color_override("font_color", Color("f2d7a4") if i == cursor[0] else Color("b89a6a"))
	for i in range(4):
		var col := Ui.vbox(4)
		var up := Ui.button("▲", 18, Callable(), Ui.sans, Ui.DIM)
		up.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var dg := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color("3a2a1c")
		st.border_color = Color("6b5132")
		st.set_border_width_all(1)
		st.set_corner_radius_all(6)
		st.content_margin_left = 18
		st.content_margin_right = 18
		st.content_margin_top = 6
		st.content_margin_bottom = 6
		dg.add_theme_stylebox_override("panel", st)
		var dl := Ui.label("0", 40, Color("f2d7a4"), Ui.serif_b)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dg.add_child(dl)
		digits.append(dl)
		var dn := Ui.button("▼", 18, Callable(), Ui.sans, Ui.DIM)
		dn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var k: int = i
		up.pressed.connect(func():
			vals[k] = (vals[k] + 1) % 10
			cursor[0] = k
			Sfx.play("click", 0.5)
			show.call())
		dn.pressed.connect(func():
			vals[k] = (vals[k] + 9) % 10
			cursor[0] = k
			Sfx.play("click", 0.5)
			show.call())
		col.add_child(up)
		col.add_child(dg)
		col.add_child(dn)
		wheels.add_child(col)
	v.add_child(wheels)
	v.add_child(msg)
	var try_open := func():
		var s := ""
		for x in vals:
			s += str(x)
		if s == code:
			msg.text = "딸깍 — 열렸다."
			get_tree().create_timer(0.3).timeout.connect(func():
				close_modal(true)
				ok.call())
		else:
			msg.text = "딸깍. 열리지 않는다."
			Sfx.play("error", 0.6)
			var tw := create_tween()
			for dx in [-8, 8, -6, 6, 0]:
				tw.tween_property(wheels, "position:x", wheels.position.x + dx, 0.05)
	var row := Ui.hbox(30)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(Ui.button("그만두기", 18, func(): close_modal(), Ui.serif, Ui.DIM))
	row.add_child(Ui.button("열어 본다", 20, try_open, Ui.serif_b))
	v.add_child(row)
	p.add_child(v)
	open_modal(p)
	show.call()
	modal_key_cb = func(e: InputEventKey):
		var kc: int = e.physical_keycode
		if kc >= KEY_0 and kc <= KEY_9:
			vals[cursor[0]] = kc - KEY_0
			cursor[0] = (cursor[0] + 1) % 4
			Sfx.play("click", 0.5)
		elif kc >= KEY_KP_0 and kc <= KEY_KP_9:
			vals[cursor[0]] = kc - KEY_KP_0
			cursor[0] = (cursor[0] + 1) % 4
			Sfx.play("click", 0.5)
		elif kc == KEY_LEFT:
			cursor[0] = (cursor[0] + 3) % 4
		elif kc == KEY_RIGHT:
			cursor[0] = (cursor[0] + 1) % 4
		elif kc == KEY_UP:
			vals[cursor[0]] = (vals[cursor[0]] + 1) % 10
		elif kc == KEY_DOWN:
			vals[cursor[0]] = (vals[cursor[0]] + 9) % 10
		elif kc == KEY_ENTER or kc == KEY_KP_ENTER:
			try_open.call()
		show.call()
