extends Node
## 게임 흐름 · 화면 · 공용 UI

const RoomScript := preload("res://scripts/room.gd")
const InspectScript := preload("res://scripts/inspect.gd")
const BoardScript := preload("res://scripts/board.gd")
const SAVE_PATH := "user://save.json"
const VERSION := "1.3.1"
const CONTACT := "eunyool100208@gmail.com"

var EPISODES: Array = []
var FINAL_TEXT: Array = []
var UPDATES: Array = []
var TERMS: Dictionary = {}
var ep: Dictionary = {}
var S: Dictionary = {}
var save := {}
const DEFAULT_SETTINGS := {"sens": 1.0, "volume": 0.8, "sfx": 1.0, "amb": 1.0, "fullscreen": false, "bright": 1.0, "fov": 72.0, "quality": "high", "bob": true, "calm": false, "breath": true, "invert": false, "pad": 1.0, "crouch_hold": true, "bg_mute": false, "autoupdate": true}
## 기록 파일 · 백업 코드에서 읽은 값이 이 범위 · 보기를 벗어나면 기본값을 쓴다
const SETTING_RANGE := {"sens": [0.3, 2.5], "volume": [0.0, 1.0], "sfx": [0.0, 1.0], "amb": [0.0, 1.0], "bright": [0.6, 1.6], "fov": [60.0, 90.0], "pad": [0.85, 1.2]}
const SETTING_CHOICES := {"quality": ["low", "mid", "high"]}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var save_path := SAVE_PATH
var testing := false
var stage := ""
var world: Node = null
var board: Control = null
var paused := false
var modal_open := false
var first_entry := false
var touch := false

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
var modal_locked := false
var fade_rect: ColorRect
var pause_root: Control

var say_q: Array = []
var say_t := 0.0
var note_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 점검용 실행 인자는 개발 중에만 받는다. 내보낸 게임은 무시한다
	var args := OS.get_cmdline_user_args() if OS.is_debug_build() else PackedStringArray()
	var test := ""
	for a in args:
		if a.begins_with("--autotest="):
			test = a.substr(11)
	testing = test != ""
	if testing:
		save_path = "user://save_test.json"
	touch = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") 		or (OS.has_feature("web_macos") and DisplayServer.is_touchscreen_available()) or args.has("--touch")
	Ui.init()
	_set_window_icon()
	_load_data()
	_load_save()
	_build_layers()
	if test == "":
		_apply_settings()
		_clean_update_dir()
	else:
		Sfx.set_master(0.0)
	if test == "" or args.has("--introtest"):
		play_intro()
	else:
		show_title()
	if test != "":
		var at: Node = load("res://scripts/autotest.gd").new()
		add_child(at)
		var ei := 0
		for a in args:
			if a.begins_with("--ep="):
				ei = int(a.substr(5))
		if args.has("--termstest"):
			at.terms_test(test)
		elif args.has("--invtest"):
			at.inv_test(test)
		elif args.has("--introtest"):
			at.intro_test(test)
		elif args.has("--looktest"):
			at.look_test(test)
		elif args.has("--updatetest"):
			at.update_test(test)
		elif args.has("--reachtest"):
			at.reach_test(ei)
		elif args.has("--clicktest"):
			at.click_test(test)
		elif args.has("--cleantest"):
			at.clean_test(test, ei)
		elif args.has("--settingstest"):
			at.settings_test(test)
		elif args.has("--uvwait"):
			at.uv_wait_test(ei)
		elif args.has("--uvtouchtest"):
			at.uv_touch_test(test, ei)
		elif args.has("--featuretest"):
			at.feature_test(test)
		elif args.has("--touchtest"):
			at.touch_test(test, ei)
		elif args.has("--pausetest"):
			at.pause_test(test, ei)
		elif args.has("--inputtest"):
			at.input_test(test, ei)
		else:
			at.run(test, ei, not args.has("--quick"))


func _load_data() -> void:
	var f := FileAccess.open("res://data/episodes.json", FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	EPISODES = d.EPISODES
	FINAL_TEXT = d.FINAL_TEXT
	var uf := FileAccess.open("res://data/updates.json", FileAccess.READ)
	if uf:
		var u = JSON.parse_string(uf.get_as_text())
		if u is Array:
			UPDATES = u
	var tf := FileAccess.open("res://data/terms.json", FileAccess.READ)
	if tf:
		var t = JSON.parse_string(tf.get_as_text())
		if t is Dictionary:
			TERMS = t


func _load_save() -> void:
	save = {"done": {}}
	var tmp := save_path + ".tmp"
	if not FileAccess.file_exists(save_path) and FileAccess.file_exists(tmp):
		DirAccess.rename_absolute(tmp, save_path)
	var d = _read_json(save_path)
	if d == null and FileAccess.file_exists(save_path):
		# 망가진 기록은 지우지 않고 따로 남기고, 바로 전에 저장한 기록으로 되살린다
		DirAccess.copy_absolute(save_path, save_path.get_basename() + ".broken.json")
		d = _read_json(_bak_path())
	if d is Dictionary:
		save = d
	save.done = _clean_done(save.get("done", {}))
	settings = _clean_settings(save.get("settings", {}))
	for k in ["seen_notes", "terms_ok"]:
		if save.has(k) and not (save[k] is String):
			save.erase(k)


func _bak_path() -> String:
	return save_path.get_basename() + ".bak.json"


static func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_length() > 1048576:
		return null
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else null


func write_save() -> void:
	save.settings = settings
	# 새 파일에 다 쓴 다음 바꿔 끼운다: 쓰는 도중에 꺼져도 앞 기록이 남는다
	var tmp := save_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(save))
	f.close()
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, _bak_path())
	DirAccess.rename_absolute(tmp, save_path)


static func _num(v, def: float) -> float:
	return float(v) if (v is float or v is int) else def


## 기록 파일 · 백업 코드의 설정: 아는 항목만, 알맞은 형식 · 범위로
static func _clean_settings(s) -> Dictionary:
	var out: Dictionary = DEFAULT_SETTINGS.duplicate()
	if not (s is Dictionary):
		return out
	for k in DEFAULT_SETTINGS:
		if not s.has(k):
			continue
		var v = s[k]
		match typeof(DEFAULT_SETTINGS[k]):
			TYPE_BOOL:
				if v is bool:
					out[k] = v
			TYPE_FLOAT, TYPE_INT:
				if v is float or v is int:
					var lim: Array = SETTING_RANGE.get(k, [-1000000.0, 1000000.0])
					out[k] = clamp(float(v), lim[0], lim[1])
			TYPE_STRING:
				if v is String and v in SETTING_CHOICES.get(k, []):
					out[k] = v
	return out


## 끝낸 장 기록: 있는 장 이름 · 등급 · 점수만 남긴다
func _clean_done(d) -> Dictionary:
	var out := {}
	if not (d is Dictionary):
		return out
	for E in EPISODES:
		var r = d.get(E.id)
		if not (r is Dictionary):
			continue
		var g := str(r.get("grade", "C"))
		var score := int(clamp(_num(r.get("score"), 0.0), 0.0, 100.0))
		out[E.id] = {"grade": g if g in ["S", "A", "B", "C"] else "C", "score": score, "choice": "burn" if str(r.get("choice", "")) == "burn" else "deliver", "best": int(clamp(_num(r.get("best"), score), 0.0, 100.0))}
	return out


func _apply_settings() -> void:
	Sfx.set_master(float(settings.volume))
	Sfx.set_bus("Effects", float(settings.sfx))
	Sfx.set_bus("Ambience", float(settings.amb))
	_apply_scale()
	if not touch:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_MAXIMIZED)


## 화질: 3D 화면을 그리는 해상도
func _apply_scale() -> void:
	get_viewport().scaling_3d_scale = {"low": 0.7, "mid": 0.85}.get(settings.get("quality", "high"), 1.0)


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


# ───────────────────────────── 시작 인트로
var _intro_tw: Tween


## 켤 때 한 번: YOOL 제작 → 마지막 방 표지와 글 → 타이틀. 누르거나 키를 치면 바로 넘어간다
func play_intro() -> void:
	stage = "intro"
	_set_world(null)
	var root := _new_screen()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("0b0a09")
	Ui.full(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var center := func(l: Label) -> Label:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l
	# 1) 만든 사람
	var studio := Ui.vbox(16)
	Ui.full(studio)
	studio.alignment = BoxContainer.ALIGNMENT_CENTER
	studio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wm := FontVariation.new()
	wm.base_font = Ui.serif_b
	wm.spacing_glyph = 24
	studio.add_child(center.call(Ui.label("YOOL", 72, Color("efe9df"), wm)))
	var bar := ColorRect.new()
	bar.color = Color(1, 1, 1, 0.25)
	bar.custom_minimum_size = Vector2(56, 1)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	studio.add_child(bar)
	studio.add_child(center.call(Ui.label("제작", 17, Color("a39b8e"), Ui.spaced)))
	studio.modulate.a = 0.0
	root.add_child(studio)
	# 2) 게임 표지
	var cover := Ui.vbox(8)
	Ui.full(cover)
	cover.alignment = BoxContainer.ALIGNMENT_CENTER
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := Ui.DoorMark.new()
	mark.custom_minimum_size = Vector2(150, 196)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mark.glow = 0.0
	mark.modulate.a = 0.0
	cover.add_child(mark)
	cover.add_child(Ui.gap(22))
	var t1: Label = center.call(Ui.label("마지막 방", 80, Color("efe9df"), Ui.serif_b))
	var t2: Label = center.call(Ui.label("특수청소부의 기록", 20, Color("a39b8e"), Ui.serif))
	var t3: Label = center.call(Ui.label("누군가 마지막으로 머문 방을 치운다.\n남겨진 물건이 그 사람의 이야기를 대신 들려준다.", 17, Color(1, 1, 1, 0.55), Ui.serif))
	t3.add_theme_constant_override("line_spacing", 6)
	for l in [t1, t2, t3]:
		l.modulate.a = 0.0
	cover.add_child(t1)
	cover.add_child(t2)
	cover.add_child(Ui.gap(30))
	cover.add_child(t3)
	root.add_child(cover)
	var skip := Ui.label("화면을 누르면 넘어간다" if touch else "아무 키나 누르면 넘어간다", 13, Color(1, 1, 1, 0.28), Ui.sans)
	Ui.pin(skip, 1, 1, -30, -26, -1, -1)
	root.add_child(skip)
	root.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_intro_end())
	var tw := create_tween()
	_intro_tw = tw
	tw.tween_interval(0.5)
	tw.tween_property(studio, "modulate:a", 1.0, 0.9)
	tw.tween_interval(1.3)
	tw.tween_property(studio, "modulate:a", 0.0, 0.7)
	tw.tween_interval(0.4)
	tw.tween_property(mark, "modulate:a", 1.0, 0.9)
	tw.tween_callback(func(): Sfx.play("flick", 0.45))
	tw.tween_property(mark, "glow", 1.0, 0.5)
	tw.tween_property(t1, "modulate:a", 1.0, 0.9)
	tw.parallel().tween_property(t2, "modulate:a", 1.0, 1.3)
	tw.tween_interval(0.4)
	tw.tween_property(t3, "modulate:a", 1.0, 1.0)
	tw.tween_interval(2.4)
	tw.tween_callback(_intro_end)


func _intro_end() -> void:
	if stage != "intro":
		return
	stage = "intro_end"
	if _intro_tw and _intro_tw.is_valid():
		_intro_tw.kill()
	fade(show_title)


## 작업 표시줄 · 창 아이콘: 게임 안에 들어 있는 그림으로 직접 정한다
func _set_window_icon() -> void:
	if OS.has_feature("web") or OS.has_feature("mobile"):
		return
	var tex = load("res://assets/tex/icon.png")
	if not (tex is Texture2D):
		return
	var img: Image = tex.get_image()
	if img == null:
		return
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(64, 64, Image.INTERPOLATE_LANCZOS)
	DisplayServer.set_icon(img)


# ───────────────────────────── 타이틀
func _unlocked(i: int) -> bool:
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--all"):
		return true
	# 앞 장을 마쳤거나, 이 장을 한 번이라도 끝냈으면 열린다
	return i == 0 or save.done.has(EPISODES[i - 1].id) or save.done.has(EPISODES[i].id)


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
	var menu := [["설정", open_settings], ["조작법", open_help], ["업데이트 노트", open_updates], ["기록 지우기", _reset_save], ["만든 사람들", func(): fade(show_credits)]]
	if not OS.has_feature("web"):
		menu.append(["끝내기", func(): get_tree().quit()])
	for m in menu:
		var b := Ui.button(m[0], 20, m[1], Ui.serif, Color("b9b1a4"))
		b.custom_minimum_size = Vector2(160, 0)
		if m[0] == "업데이트 노트" and save.get("seen_notes", "") != VERSION:
			var r := Ui.hbox(10)
			b.custom_minimum_size = Vector2(0, 0)
			r.add_child(b)
			var nw := Ui.label("NEW", 13, Color("d9614f"), Ui.sans_b)
			nw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			r.add_child(nw)
			col.add_child(r)
		else:
			col.add_child(b)
	root.add_child(col)
	var cw := Ui.label("죽음, 고독사, 약물 오남용 같은 무거운 이야기를 다룹니다. 힘들 때는 언제든 쉬어 가세요.", 14, Color(1, 1, 1, 0.38), Ui.sans)
	Ui.pin(cw, 0, 1, 96, -34, 1, -1)
	root.add_child(cw)
	var ver := Ui.label(("v%s" % VERSION) if touch else ("v%s      F11  전체 화면" % VERSION), 13, Color(1, 1, 1, 0.3), Ui.sans)
	Ui.pin(ver, 1, 1, -30, -34, -1, -1)
	root.add_child(ver)
	if _needs_terms():
		open_terms(func(): show_title())
		return
	if not update_checked and not testing and settings.get("autoupdate", true):
		update_checked = true
		check_update(false)


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


const BLUR_SHADER := "shader_type canvas_item;\nuniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;\nuniform float lod = 3.2;\nuniform float dim = 0.26;\nvoid fragment() {\n\tvec3 c = textureLod(screen_tex, SCREEN_UV, lod).rgb;\n\tfloat g = dot(c, vec3(0.299, 0.587, 0.114));\n\tc = mix(vec3(g), c, 0.5) * dim;\n\tCOLOR = vec4(c, 1.0);\n}"


## 멈춤 화면에서는 방 HUD · 자막 · 쪽지를 숨긴다
func _room_overlays(show: bool) -> void:
	if world and stage == "room" and world.get("hud"):
		world.hud.visible = show
	say_panel.visible = show
	note_panel.visible = show
	toast_box.visible = show


func _keycap(text: String) -> Control:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.06)
	s.border_color = Color(1, 1, 1, 0.3)
	s.set_border_width_all(1)
	s.border_width_bottom = 2
	s.set_corner_radius_all(4)
	s.content_margin_left = 9
	s.content_margin_right = 9
	s.content_margin_top = 3
	s.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", s)
	p.add_child(Ui.label(text, 14, Color("efe9df"), Ui.sans_b))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## 왼쪽에 표식이 붙는 메뉴 항목 (타이틀과 같은 방식)
func _menu_item(text: String, size: int, cb: Callable, primary: bool) -> Control:
	var row := Ui.hbox(0)
	var b := Ui.button(text, size, cb, Ui.serif_b if primary else Ui.serif, Color("efe9df") if primary else Color("b9b1a4"))
	var mark := Ui.label("—", size, Ui.ACCENT, Ui.serif)
	mark.modulate.a = 0.0
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.anchor_top = 0
	mark.anchor_bottom = 1
	mark.offset_left = -size * 1.6
	mark.offset_right = -8
	b.add_child(mark)
	b.mouse_entered.connect(func(): mark.modulate.a = 1.0)
	b.mouse_exited.connect(func(): mark.modulate.a = 0.0)
	row.add_child(b)
	return row


func show_pause(first := false) -> void:
	paused = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.stop_loops()
	if world and world.has_method("release"):
		world.release()
	_room_overlays(false)
	Ui.clear(pause_root)
	var bg := ColorRect.new()
	Ui.full(bg)
	var sh := Shader.new()
	sh.code = BLUR_SHADER
	var sm := ShaderMaterial.new()
	sm.shader = sh
	bg.material = sm
	pause_root.add_child(bg)
	# 왼쪽: 제목 · 진행 · 메뉴
	var left := Ui.vbox(6)
	Ui.pin(left, 0, 0.5, 130, 0, 1, 0)
	left.add_child(Ui.label("%d장 · %s" % [int(ep.no), ep.place], 15, Ui.ACCENT, Ui.spaced))
	left.add_child(Ui.label("현장 진입" if first else "잠시 멈춤", 58, Color("efe9df"), Ui.serif_b))
	if first:
		left.add_child(Ui.label("방독 마스크를 쓰고, 문을 연다.", 19, Color("a39b8e"), Ui.serif))
		left.add_child(Ui.gap(18))
		var goal := Ui.label("얼룩에 소독약을 뿌리고 문질러 닦아 낸다.\n물건마다 유족에게 남길지, 버릴지 정한다.\n다 끝나면 현관으로 나간다.", 17, Color("cfc9bf"), Ui.sans, true)
		goal.custom_minimum_size = Vector2(520, 0)
		goal.add_theme_constant_override("line_spacing", 6)
		left.add_child(goal)
	elif world and world.has_method("_counts"):
		var c: Dictionary = world._counts()
		left.add_child(Ui.label("오염 제거 %d / %d     유품 분류 %d / %d     단서 %d" % [c.sdone, c.stotal, c.sorted, c.total, S.clues.size()], 17, Color("a39b8e"), Ui.sans))
	left.add_child(Ui.gap(40))
	left.add_child(_menu_item("작업 시작" if first else "계속하기", 32, hide_pause, true))
	left.add_child(Ui.gap(4))
	if not first:
		left.add_child(_menu_item("보관함", 22, open_inventory, false))
		left.add_child(_menu_item("설정", 22, open_settings, false))
	left.add_child(_menu_item("장 선택으로", 22, quit_to_title, false))
	pause_root.add_child(left)
	# 오른쪽: 조작 안내 카드
	var card := Ui.panel(Ui.dark_box(0.5, 30, 0.1))
	Ui.pin(card, 1, 0.5, -130, 0, -1, 0)
	var cv := Ui.vbox(13)
	cv.add_child(Ui.label("조작", 15, Ui.ACCENT, Ui.spaced))
	cv.add_child(Ui.gap(2))
	var rows := [[["W", "A", "S", "D"], "이동"], [["마우스"], "둘러보기"], [["1", "2", "3"], "손 · 소독 분무기 · 스크러버"], [["왼쪽 클릭 유지"], "도구 사용 · 스크러버는 누른 채 문지르기"], [["E"], "집어 보기 · 조사 · 보관함에 넣기"], [["Q"], "폐기"], [["X", "오른쪽 클릭"], "내려놓기"], [["F"], "손전등"], [["I", "Tab"], "보관함 열기"], [["C"] if OS.has_feature("web") else ["Ctrl"], "누르고 있는 동안 숙이기" if settings.get("crouch_hold", true) else "누를 때마다 숙이기 · 일어서기"]]
	if touch:
		rows = [[["왼쪽 화면 끌기"], "이동"], [["오른쪽 화면 끌기"], "둘러보기"], [["손", "분무기", "스크러버"], "도구 바꾸기"], [["집기 · 뿌리기"], "누르고 있으면 도구 사용"], [["보관", "폐기"], "들고 있는 물건 분류"], [["내려놓기"], "제자리에 두기"], [["손전등"], "손전등 켜고 끄기"], [["보관함"], "넣은 물건 보기 · 꺼내기"], [["숙이기"], "숙이기 · 일어서기"]]
	for row in rows:
		var r := Ui.hbox(16)
		var caps := Ui.hbox(4)
		caps.custom_minimum_size = Vector2(196, 0)
		for k in row[0]:
			caps.add_child(_keycap(k))
		r.add_child(caps)
		var l := Ui.label(row[1], 16, Color("d8d2c8"), Ui.sans)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(l)
		cv.add_child(r)
	card.add_child(cv)
	pause_root.add_child(card)
	if not touch:
		var hint := Ui.label("Esc   " + ("작업 시작" if first else "계속하기"), 14, Color(1, 1, 1, 0.38), Ui.sans)
		Ui.pin(hint, 0, 1, 130, -44, 1, -1)
		pause_root.add_child(hint)
	pause_root.visible = true


func hide_pause() -> void:
	pause_root.visible = false
	_room_overlays(true)
	_unpause()
	if stage == "room":
		capture_mouse()
		if first_entry:
			first_entry = false
			for l in ep.intro:
				say(l, 3.8)
			if int(ep.no) == 1 and touch:
				say("왼쪽 화면을 끌어 걷고, 오른쪽 화면을 끌어 둘러본다.", 4.6)
				say("분무기로 얼룩에 소독약을 뿌리고, 스크러버로 문질러 닦는다.", 5.2)
				say("물건은 집기 버튼으로 들고, 보관할지 버릴지 정한다.", 4.6)
			elif int(ep.no) == 1:
				say("[2] 소독 분무기로 얼룩에 소독약을 뿌리고, [3] 스크러버로 문질러 닦는다.", 5.2)
				say("물건은 [E]로 집어 보관할지 버릴지 정한다. 손전등은 [F].", 4.6)


func capture_mouse() -> void:
	if not touch:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _notification(what: int) -> void:
	# 안드로이드 뒤로 가기 = Esc
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_ESCAPE
		ev.keycode = KEY_ESCAPE
		ev.pressed = true
		Input.parse_input_event(ev)
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if settings.get("bg_mute", false) and not touch:
			AudioServer.set_bus_mute(0, true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		AudioServer.set_bus_mute(0, Sfx.volume <= 0.001)


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
	if all_done and not save.get("seen_final5", false):
		save.seen_final5 = true
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
	var b := Ui.button("만든 사람들  ▸", 22, func(): fade(show_credits), Ui.serif_b)
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
	say_panel.visible = true
	note_panel.visible = true
	toast_box.visible = true


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
		if stage == "intro" and event.physical_keycode != KEY_F11:
			_intro_end()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_F11:
			settings.fullscreen = not settings.fullscreen
			_apply_settings()
			write_save()
			get_viewport().set_input_as_handled()
			return
		if modal_open:
			# 글자 칸에 쓰는 중이면 키는 그 칸으로 보낸다 (Esc만 빼고)
			if get_viewport().gui_get_focus_owner() is LineEdit and event.physical_keycode != KEY_ESCAPE:
				return
			if event.physical_keycode == KEY_ESCAPE:
				if not modal_locked:
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
			elif stage == "credits":
				fade(show_title)
				get_viewport().set_input_as_handled()


# ───────────────────────────── 만든 사람들
func show_credits() -> void:
	stage = "credits"
	_set_world(null)
	var root := _new_screen()
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	Ui.full(bg)
	root.add_child(bg)
	var v := Ui.vbox(10)
	v.custom_minimum_size = Vector2(760, 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var add_line := func(text: String, size: int, color: Color, font: Font, gap_before: int):
		if gap_before > 0:
			v.add_child(Ui.gap(gap_before))
		var l := Ui.label(text, size, color, font, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(760, 0)
		v.add_child(l)
	var head := Color("c9a463")
	var body := Color("e6e1d8")
	var dim := Color("8f897f")
	add_line.call("마지막 방", 64, Color("efe9df"), Ui.serif_b, 0)
	add_line.call("특수청소부의 기록", 20, dim, Ui.serif, 0)
	v.add_child(Ui.gap(90))
	for role in ["제작", "기획", "시나리오", "디자인", "프로그래밍", "사운드", "QA"]:
		var r := Ui.hbox(36)
		r.alignment = BoxContainer.ALIGNMENT_CENTER
		var rl := Ui.label(role, 18, head, Ui.spaced)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rl.custom_minimum_size = Vector2(240, 0)
		rl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(rl)
		var nl := Ui.label("은율", 28, body, Ui.serif_b)
		nl.custom_minimum_size = Vector2(240, 0)
		r.add_child(nl)
		v.add_child(r)
	add_line.call("이야기", 16, head, Ui.spaced, 70)
	for E in EPISODES:
		add_line.call("%d장  %s — %s" % [int(E.no), E.title, E.place], 20, body, Ui.serif, 0)
	add_line.call("글꼴", 16, head, Ui.spaced, 70)
	add_line.call("나눔고딕 · 나눔명조 · 나눔손글씨 펜", 20, body, Ui.serif, 0)
	add_line.call("NAVER · SIL Open Font License 1.1", 15, dim, Ui.sans, 0)
	add_line.call("엔진", 16, head, Ui.spaced, 60)
	add_line.call("Godot Engine · MIT License", 20, body, Ui.serif, 0)
	add_line.call("이 게임에 나오는 인물과 사건은 모두 지어낸 이야기이며, 실제 인물이나 단체와 관계가 없습니다.", 16, dim, Ui.sans, 90)
	add_line.call("마음이 힘들 때는 혼자 견디지 마세요.", 16, dim, Ui.sans, 30)
	add_line.call("자살예방상담 109  ·  청소년상담 1388  ·  정신건강상담 1577-0199", 16, dim, Ui.sans, 0)
	add_line.call("플레이해 주셔서 고맙습니다.", 26, body, Ui.serif_b, 120)
	root.add_child(v)
	var vh := get_viewport().get_visible_rect().size
	v.position = Vector2((vh.x - 760.0) / 2.0, vh.y + 20.0)
	await get_tree().process_frame
	var total: float = v.size.y + vh.y + 40.0
	var tw := create_tween()
	tw.tween_property(v, "position:y", vh.y / 2.0 - v.size.y + 40.0, total / 55.0)
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		if stage == "credits":
			fade(show_title))
	var skip := Ui.button("건너뛰기  Esc", 16, func(): fade(show_title), Ui.sans, Color(1, 1, 1, 0.45))
	Ui.pin(skip, 1, 1, -30, -26, -1, -1)
	root.add_child(skip)


# ───────────────────────────── 보관함
var inv_sel := ""


## 유품 보관함: 꼬리표를 고르면 오른쪽에 자세히 적히고, 꺼내면 처음 자리로 돌아간다
func open_inventory(quiet := false) -> void:
	if stage != "room" or world == null or not world.has_method("kept_items") or world.exiting:
		return
	if not quiet:
		Sfx.play("paper", 0.5)
	var kept: Array = world.kept_items()
	var bag: Array = world.trashed_items()
	var c: Dictionary = world._counts()
	var all := kept + bag
	if not all.any(func(x): return x.def.id == inv_sel):
		inv_sel = all[0].def.id if all.size() > 0 else ""
	var p := Ui.panel(Ui.paper_box(false, 40))
	var v := Ui.vbox(10)
	# 머리: 상자 이름표와 숫자 세 칸
	var head := Ui.hbox(22)
	var hv := Ui.vbox(0)
	hv.add_child(Ui.label("유품 보관함", 14, Ui.INK_DIM, Ui.spaced))
	hv.add_child(Ui.label("%d장 · %s" % [int(ep.no), ep.place], 28, Ui.INK, Ui.serif_b))
	head.add_child(Ui.expand(hv))
	for s in [["보관", kept.size()], ["폐기 봉투", bag.size()], ["남은 물건", c.total - c.sorted]]:
		var sv := Ui.vbox(0)
		sv.custom_minimum_size = Vector2(88, 0)
		sv.size_flags_vertical = Control.SIZE_SHRINK_END
		var nl := Ui.label(str(s[1]), 34, Ui.INK, Ui.serif_b)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sv.add_child(nl)
		var ll := Ui.label(s[0], 13, Ui.INK_DIM, Ui.spaced)
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sv.add_child(ll)
		head.add_child(sv)
	v.add_child(head)
	v.add_child(Ui.rule(0.6, 2))
	var body := Ui.hbox(26)
	# 왼쪽: 꼬리표 (보관함 · 폐기 봉투)
	var left := Ui.vbox(10)
	var tags := {}
	var detail := Ui.vbox(10)
	detail.custom_minimum_size = Vector2(300, 0)
	var pick := func(it) -> void:
		inv_sel = it.def.id
		for k in tags:
			tags[k].set_on(k == inv_sel)
		_inv_detail(detail, it)
	for sec in [["보관함 — 유족에게 전할 물건", kept, false], ["폐기 봉투 — 버린 물건", bag, true]]:
		left.add_child(Ui.label(sec[0], 16, Ui.INK, Ui.sans_b))
		var list: Array = sec[1]
		if list.is_empty():
			var e := Ui.Dashed.new()
			e.custom_minimum_size = Vector2(612, 0)
			var msg := "버린 물건이 없다."
			if not sec[2]:
				msg = "아직 넣은 물건이 없다. 물건을 집어 들고 [보관]을 고르면 여기 담긴다." if touch else "아직 넣은 물건이 없다. 물건을 E로 집어 들고 보관함에 넣으면 여기 담긴다."
			var el := Ui.label(msg, 15, Ui.INK_DIM, Ui.serif, true)
			el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			e.add_child(el)
			left.add_child(e)
		else:
			var grid := GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 12)
			grid.add_theme_constant_override("v_separation", 12)
			for it in list:
				var tb := Ui.TagButton.new(it.def.name, sec[2])
				tb.set_on(it.def.id == inv_sel)
				var item = it
				tb.pressed.connect(func():
					Sfx.play("paper", 0.25)
					pick.call(item))
				tags[it.def.id] = tb
				grid.add_child(tb)
			left.add_child(grid)
		left.add_child(Ui.gap(6))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(630, min(get_viewport().get_visible_rect().size.y * 0.55, 470.0))
	sc.add_child(left)
	body.add_child(sc)
	body.add_child(Ui.vrule(0.2))
	body.add_child(detail)
	v.add_child(body)
	var sel = null
	for it in all:
		if it.def.id == inv_sel:
			sel = it
	_inv_detail(detail, sel)
	v.add_child(Ui.rule(0.15))
	var foot := Ui.hbox(24)
	var fl := Ui.label("꺼낸 물건은 처음 있던 자리로 돌아간다. 다시 집어서 분류하면 된다.", 14, Ui.INK_DIM, Ui.sans)
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(Ui.expand(fl))
	if not touch:
		var kh := Ui.label("I · Tab  닫기", 13, Ui.INK_DIM, Ui.sans)
		kh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		foot.add_child(kh)
	foot.add_child(Ui.ink_button("닫기", 21, func(): close_modal()))
	v.add_child(foot)
	p.add_child(v)
	open_modal(p)
	modal_key_cb = func(ev: InputEventKey):
		if ev.physical_keycode == KEY_I or ev.physical_keycode == KEY_TAB:
			close_modal()


## 고른 꼬리표의 자세한 내용과 꺼내기
func _inv_detail(box: VBoxContainer, it) -> void:
	Ui.clear(box)
	box.add_child(Ui.label("고른 물건", 14, Ui.INK_DIM, Ui.spaced))
	if it == null:
		var e := Ui.label("꼬리표를 고르면 여기에 적힌다.", 16, Ui.INK_DIM, Ui.serif, true)
		e.custom_minimum_size = Vector2(300, 0)
		box.add_child(e)
		return
	var nl := Ui.label(it.def.name, 26, Ui.INK, Ui.serif_b, true)
	nl.custom_minimum_size = Vector2(300, 0)
	box.add_child(nl)
	var dl := Ui.label(it.def.get("desc", ""), 17, Ui.INK, Ui.serif, true)
	dl.custom_minimum_size = Vector2(300, 0)
	box.add_child(dl)
	box.add_child(Ui.rule(0.15))
	box.add_child(Ui.label("지금 폐기 봉투에 있다" if S.sorted.get(it.def.id, "") == "trash" else "지금 보관함에 있다", 14, Ui.INK_DIM, Ui.sans))
	var b := Ui.form_button("꺼내서 제자리에 두기", 16, func():
		world.take_out(it)
		Sfx.play("pick", 0.6)
		toast("%s — 원래 자리에 돌려놓았다" % it.def.name)
		open_inventory(true))
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(b)


# ───────────────────────────── 업데이트 노트
func open_updates(back: Callable = Callable()) -> void:
	var first_view: bool = save.get("seen_notes", "") != VERSION
	save.seen_notes = VERSION
	write_save()
	Sfx.play("paper", 0.5)
	var p := Ui.panel(Ui.paper_box(false, 44))
	var v := Ui.vbox(10)
	v.add_child(Ui.label("업데이트 노트", 14, Ui.INK_DIM, Ui.spaced))
	v.add_child(Ui.label("마지막 방  v%s" % VERSION, 28, Ui.INK, Ui.serif_b))
	var line := ColorRect.new()
	line.color = Color(Ui.INK, 0.35)
	line.custom_minimum_size = Vector2(0, 2)
	v.add_child(line)
	var list := Ui.vbox(4)
	for i in UPDATES.size():
		var u: Dictionary = UPDATES[i]
		var h := Ui.hbox(14)
		h.add_child(Ui.label(u.v, 24, Ui.INK, Ui.serif_b))
		var dt := Ui.label(u.get("date", ""), 15, Ui.INK_DIM, Ui.sans)
		dt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(dt)
		if i == 0:
			var now := Ui.label("새로 나옴" if first_view else "지금 버전", 14, Ui.RED, Ui.sans_b)
			now.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(now)
		list.add_child(h)
		if u.has("title"):
			list.add_child(Ui.label(u.title, 18, Ui.INK, Ui.serif))
		for item in u.get("items", []):
			var r := Ui.hbox(10)
			var dot := Ui.label("·", 17, Ui.INK_DIM, Ui.sans_b)
			dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			r.add_child(dot)
			var t := Ui.label(item, 16, Ui.INK, Ui.sans, true)
			t.custom_minimum_size = Vector2(580, 0)
			r.add_child(t)
			list.add_child(r)
		list.add_child(Ui.gap(18))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(640, min(get_viewport().get_visible_rect().size.y * 0.58, 520.0))
	sc.add_child(list)
	v.add_child(sc)
	v.add_child(_buttons_row([["닫기", func():
		if stage == "title":
			show_title()
		close_modal()]]))
	p.add_child(v)
	open_modal(p, back)


# ───────────────────────────── 이용 안내 · 약관
## 설치 프로그램이 없는 Android · Mac · 웹은 처음 켤 때(약관이 바뀌면 다시) 동의를 받는다
func _needs_terms() -> bool:
	if testing or TERMS.is_empty():
		return false
	if not (OS.has_feature("web") or OS.has_feature("android") or OS.has_feature("macos")):
		return false
	return str(save.get("terms_ok", "")) != str(TERMS.get("version", ""))


func open_terms(agree_cb: Callable = Callable(), back: Callable = Callable()) -> void:
	if TERMS.is_empty():
		return
	var p := Ui.panel(Ui.paper_box(false, 40))
	var v := Ui.vbox(8)
	v.add_child(Ui.label(TERMS.get("subtitle", "이용 안내"), 14, Ui.INK_DIM, Ui.spaced))
	v.add_child(Ui.label(TERMS.get("title", ""), 24, Ui.INK, Ui.serif_b))
	var line := ColorRect.new()
	line.color = Color(Ui.INK, 0.35)
	line.custom_minimum_size = Vector2(0, 2)
	v.add_child(line)
	var body := Ui.vbox(4)
	for o in TERMS.get("owner", []):
		body.add_child(Ui.label(o, 15, Ui.INK, Ui.sans_b))
	body.add_child(Ui.gap(4))
	var intro := Ui.label(TERMS.get("intro", "").replace("[동의함]", "[동의하고 시작]") if agree_cb.is_valid() else TERMS.get("intro", ""), 15, Ui.INK, Ui.sans, true)
	intro.custom_minimum_size = Vector2(600, 0)
	body.add_child(intro)
	var secs: Array = TERMS.get("sections", [])
	for i in secs.size():
		body.add_child(Ui.gap(8))
		body.add_child(Ui.label("%d. %s" % [i + 1, secs[i].h], 17, Ui.INK, Ui.serif_b))
		for it in secs[i].get("items", []):
			var r := Ui.hbox(8)
			var dot := Ui.label("·", 15, Ui.INK_DIM, Ui.sans_b)
			dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			r.add_child(dot)
			var t := Ui.label(it, 14, Ui.INK, Ui.sans, true)
			t.custom_minimum_size = Vector2(580, 0)
			r.add_child(t)
			body.add_child(r)
	body.add_child(Ui.gap(8))
	body.add_child(Ui.label("적용일: %s" % TERMS.get("version", ""), 13, Ui.INK_DIM, Ui.sans))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(630, min(get_viewport().get_visible_rect().size.y * 0.6, 540.0))
	sc.add_child(body)
	v.add_child(sc)
	if agree_cb.is_valid():
		v.add_child(_buttons_row([["동의하지 않음", func():
			if OS.has_feature("web"):
				toast("동의해야 게임을 할 수 있습니다.")
			else:
				get_tree().quit()], ["동의하고 시작", func():
			save.terms_ok = str(TERMS.get("version", ""))
			write_save()
			close_modal()
			agree_cb.call(), 22]]))
	else:
		v.add_child(_buttons_row([["닫기", func(): close_modal()]]))
	p.add_child(v)
	open_modal(p, back)
	# 처음 켤 때의 동의 화면은 Esc · 뒤로 가기로 닫히지 않는다
	modal_locked = agree_cb.is_valid()


# ───────────────────────────── 모달
func open_modal(content: Control, on_close: Callable = Callable()) -> void:
	for c in modal_center.get_children():
		c.queue_free()
	modal_center.add_child(content)
	modal_root.visible = true
	modal_open = true
	modal_close_cb = on_close
	modal_key_cb = Callable()
	modal_locked = false
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
		capture_mouse()
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


func open_help(back: Callable = Callable()) -> void:
	var p := Ui.panel(Ui.paper_box(false, 40))
	var v := Ui.vbox(10)
	v.add_child(Ui.label("작업 안내서", 14, Ui.INK_DIM, Ui.spaced))
	v.add_child(Ui.label("조작법", 30, Ui.INK, Ui.serif_b))
	v.add_child(Ui.rule(0.6, 2))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 34)
	grid.add_theme_constant_override("v_separation", 7)
	var crouch_txt := "누르고 있는 동안 숙이기 (낮은 곳 얼룩 · 물건)" if settings.get("crouch_hold", true) else "누를 때마다 숙이기 · 일어서기 (낮은 곳 얼룩 · 물건)"
	var keys := [["1단계 · 현장 정리", ""], ["W A S D / 마우스", "이동 / 둘러보기"], ["1 · 2 · 3, 휠", "손 · 소독 분무기 · 스크러버"], ["왼쪽 버튼 누르고 있기", "도구 사용. 소독약을 먼저 뿌려야 잘 닦인다"], ["E / Q / X", "집어 보기 · 보관 / 폐기 / 내려놓기"], ["E (서랍 · 문)", "열기 · 닫기"], ["F", "손전등"], ["I / Tab", "보관함 열기 · 넣거나 버린 물건 다시 꺼내기"], ["C" if OS.has_feature("web") else "Ctrl", crouch_txt], ["", ""], ["2단계 · 유품 조사", ""], ["끌기 / 휠", "돌려 보기 / 확대"], ["클릭", "수상한 곳 조사 · 뚜껑 열고 닫기"], ["U / H / R", "UV 라이트 / 단서 위치 / 정면"], ["", ""], ["3단계 · 사건 재구성", ""], ["쪽지 · 보기 선택", "답과 근거 단서(최대 2장)를 고른다"], ["", ""], ["Esc / F11", "멈춤 / 전체 화면"]]
	if touch:
		keys = [["1단계 · 현장 정리", ""], ["왼쪽 / 오른쪽 화면 끌기", "이동 / 둘러보기"], ["손 · 분무기 · 스크러버", "도구 바꾸기"], ["집기 · 뿌리기 · 문지르기", "누르고 있으면 도구 사용. 소독약을 먼저 뿌려야 잘 닦인다"], ["보관 / 폐기 / 내려놓기", "들고 있는 물건 분류"], ["집기 (서랍 · 문)", "열기 · 닫기"], ["손전등 · 멈춤", "오른쪽 · 왼쪽 위 버튼"], ["보관함", "넣거나 버린 물건 보기 · 다시 꺼내기 (왼쪽 위)"], ["숙이기", "눌러서 숙이기 · 일어서기 (왼쪽)"], ["", ""], ["2단계 · 유품 조사", ""], ["끌기 / 두 손가락", "돌려 보기 / 확대"], ["누르기", "수상한 곳 조사 · 뚜껑 열고 닫기"], ["UV · 단서 위치 · 정면", "화면 아래 버튼"], ["", ""], ["3단계 · 사건 재구성", ""], ["쪽지 · 보기 선택", "답과 근거 단서(최대 2장)를 고른다"]]
	for kv in keys:
		var head: bool = kv[1] == "" and kv[0] != ""
		grid.add_child(Ui.label(kv[0], 18 if head else 16, Ui.INK, Ui.serif_b if head else Ui.sans_b))
		grid.add_child(Ui.label(kv[1], 16, Ui.INK_DIM, Ui.sans))
	v.add_child(grid)
	v.add_child(Ui.gap(4))
	v.add_child(_buttons_row([["닫기", func(): close_modal()]]))
	p.add_child(v)
	open_modal(p, back)


# ───────────────────────────── 설정 (현장 장비 점검표)
const SETTINGS_TABS := ["화면", "소리", "조작", "기록", "정보"]
## 쪽마다 아래 비고 칸에 손글씨로 적는 한마디
const SETTINGS_TIPS := [
	"화면이 끊기면 화질을 낮추고, 어지러우면 흔들림을 끄거나 시야를 넓힌다.",
	"주변 소리를 줄이면 숨소리와 발소리가 또렷하게 들린다.",
	"숙이기를 '한 번씩'으로 두면 Ctrl을 계속 누르고 있지 않아도 된다.",
	"백업 코드는 메모장이나 메일에 붙여 두면 기기를 바꿔도 이어서 할 수 있다.",
	"문제가 생기면 메일로 알려 주세요. 버전과 기기를 같이 적어 주면 빨리 고칠 수 있다."]
const ONOFF := [["켬", true], ["끔", false]]
var settings_tab := 0
var _set_n := 0


## 클립보드에 끼운 점검표: 위에 쪽 색인, 가운데 번호 매긴 항목 표, 아래 손글씨 비고
func open_settings(tab := -1) -> void:
	if tab >= 0:
		settings_tab = tab
	_set_n = 0
	var paper := Ui.ClipPaper.new()
	var v := Ui.vbox(6)
	# 머리: 양식 이름 · 제목 | 양식 번호 · 점검일
	var head := Ui.hbox(0)
	var hv := Ui.vbox(0)
	hv.add_child(Ui.label("현장 장비 점검표", 14, Ui.INK_DIM, Ui.spaced))
	hv.add_child(Ui.label("설정", 34, Ui.INK, Ui.serif_b))
	head.add_child(Ui.expand(hv))
	var meta := Ui.vbox(0)
	meta.size_flags_vertical = Control.SIZE_SHRINK_END
	var form := Ui.label("양식 LR-%s" % VERSION, 13, Ui.INK_DIM, Ui.sans)
	form.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.add_child(form)
	var dt := Time.get_date_dict_from_system()
	var dr := Ui.hbox(8)
	dr.alignment = BoxContainer.ALIGNMENT_END
	var dl := Ui.label("점검일", 13, Ui.INK_DIM, Ui.sans)
	dl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dr.add_child(dl)
	dr.add_child(Ui.label("%d. %d. %d." % [dt.year, dt.month, dt.day], 26, Ui.BLUE_INK, Ui.hand))
	meta.add_child(dr)
	head.add_child(meta)
	v.add_child(head)
	v.add_child(Ui.rule(0.6, 2))
	# 쪽 색인 (가로)
	var tabs := Ui.hbox(6)
	for i in SETTINGS_TABS.size():
		var tb := Ui.InkTab.new("%d  %s" % [i + 1, SETTINGS_TABS[i]])
		tb.custom_minimum_size = Vector2(112, 50)
		tb.set_on(i == settings_tab)
		var idx := i
		tb.pressed.connect(func(): _settings_go(idx))
		tabs.add_child(tb)
	v.add_child(tabs)
	# 표 머리
	var th := Ui.hbox(12)
	var th_no := Ui.label("번호", 12, Ui.INK_DIM, Ui.spaced)
	th_no.custom_minimum_size = Vector2(40, 0)
	th.add_child(th_no)
	th.add_child(Ui.expand(Ui.label("점검 항목", 12, Ui.INK_DIM, Ui.spaced)))
	th.add_child(Ui.label("상태", 12, Ui.INK_DIM, Ui.spaced))
	v.add_child(th)
	v.add_child(Ui.rule(0.5, 1))
	# 항목 (쪽마다 여섯 줄 자리를 잡아 두어 쪽을 넘겨도 종이 크기가 같다)
	var body := Ui.vbox(0)
	body.custom_minimum_size = Vector2(820, 6 * 61)
	match settings_tab:
		0: _settings_view(body)
		1: _settings_sound(body)
		2: _settings_control(body)
		3: _settings_record(body)
		_: _settings_info(body)
	# 남은 칸은 빈 줄로 (종이 양식처럼)
	for i in max(0, 6 - _set_n):
		var blank := Control.new()
		blank.custom_minimum_size = Vector2(0, 59)
		blank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(blank)
		body.add_child(Ui.DotRule.new())
	v.add_child(body)
	# 비고
	var tip := Ui.Lined.new()
	tip.custom_minimum_size = Vector2(820, 92)
	var tv := Ui.vbox(0)
	tv.add_child(Ui.label("비고", 12, Ui.INK_DIM, Ui.spaced))
	var text: String = SETTINGS_TIPS[settings_tab]
	if settings_tab == 2 and touch:
		text = "버튼이 손가락에 비해 작으면 버튼 크기를 '크게'로 바꾼다."
	elif settings_tab == 2 and OS.has_feature("web"):
		text = text.replace("Ctrl", "C")
	var tt := Ui.label(text, 25, Ui.BLUE_INK, Ui.hand, true)
	tt.custom_minimum_size = Vector2(800, 0)
	tv.add_child(tt)
	tip.add_child(tv)
	v.add_child(tip)
	# 아래: 기본값 · 키 안내 · 닫기
	var foot := Ui.hbox(28)
	foot.add_child(Ui.button("기본값으로 되돌리기", 16, _settings_reset, Ui.sans, Ui.INK_DIM, Ui.RED))
	foot.add_child(Ui.expand(Control.new()))
	if not touch:
		var kh := Ui.label("1 ~ 5  쪽 넘기기     Esc  닫기", 13, Ui.INK_DIM, Ui.sans)
		kh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		foot.add_child(kh)
	foot.add_child(Ui.ink_button("닫기", 22, func():
		write_save()
		close_modal()))
	v.add_child(foot)
	paper.add_child(v)
	var board := Ui.panel(Ui.board_box())
	board.add_child(paper)
	open_modal(board)
	modal_key_cb = func(ev: InputEventKey):
		var k: int = ev.physical_keycode
		if k >= KEY_1 and k <= KEY_5:
			_settings_go(k - KEY_1)
		elif k == KEY_TAB:
			_settings_go((settings_tab + 1) % SETTINGS_TABS.size())


func _settings_go(i: int) -> void:
	if i == settings_tab:
		return
	settings_tab = i
	Sfx.play("paper", 0.3)
	open_settings()


func _settings_view(body: VBoxContainer) -> void:
	var pct := func(x: float) -> String: return "%d%%" % roundi(x * 100.0)
	if not touch:
		_set_choice(body, "전체 화면", "F11로도 바꿀 수 있다", "fullscreen", ONOFF, func(_x): _apply_settings())
	_set_ruler(body, "밝기", "방이 너무 어두우면 올린다", "bright", 0.6, 1.6, 0.1, pct, func(_x): apply_view())
	_set_ruler(body, "시야", "한눈에 보이는 넓이. 기본 72°", "fov", 60.0, 90.0, 2.0, func(x: float) -> String: return "%d°" % roundi(x), func(_x): apply_view())
	_set_choice(body, "화질", "화면이 끊기면 낮춘다 (그림자 · 안개 · 해상도)", "quality", [["낮음", "low"], ["보통", "mid"], ["높음", "high"]], func(_x): apply_view())
	_set_choice(body, "걷기 흔들림", "걸을 때 화면이 위아래로 흔들린다", "bob", ONOFF)
	_set_choice(body, "깜빡임 줄이기", "깜빡이는 전등 · 손전등을 고르게 켠다", "calm", ONOFF)


func _settings_sound(body: VBoxContainer) -> void:
	var pct := func(x: float) -> String: return "%d%%" % roundi(x * 100.0)
	_set_ruler(body, "전체 소리", "", "volume", 0.0, 1.0, 0.05, pct, func(x): Sfx.set_master(x))
	_set_ruler(body, "효과음", "발소리 · 분무기 · 종이 소리", "sfx", 0.0, 1.0, 0.05, pct, func(x): Sfx.set_bus("Effects", x))
	_set_ruler(body, "주변 소리", "방 안의 웅웅거림 · 파리 소리", "amb", 0.0, 1.0, 0.05, pct, func(x): Sfx.set_bus("Ambience", x))
	_set_choice(body, "숨소리", "방독 마스크 너머로 들리는 숨소리", "breath", ONOFF)
	if not touch and not OS.has_feature("web"):
		_set_choice(body, "다른 창을 볼 때", "게임 창에서 벗어나 있으면 소리를 끈다", "bg_mute", [["소리 끄기", true], ["그대로", false]])


func _settings_control(body: VBoxContainer) -> void:
	_set_ruler(body, "둘러보기 감도" if touch else "마우스 감도", "", "sens", 0.3, 2.5, 0.1, func(x: float) -> String: return "%.1f배" % x, func(x):
		if world and stage == "room":
			world.sens = 0.0022 * x)
	_set_choice(body, "상하 반전", "위아래로 둘러보는 방향을 뒤집는다", "invert", ONOFF)
	if touch:
		_set_choice(body, "버튼 크기", "현장 화면의 터치 버튼", "pad", [["작게", 0.85], ["보통", 1.0], ["크게", 1.2]])
	else:
		_set_choice(body, "숙이기 (%s)" % ("C" if OS.has_feature("web") else "Ctrl"), "누르고 있는 동안만 숙이거나, 누를 때마다 바꾼다", "crouch_hold", [["누르고 있기", true], ["한 번씩", false]], func(_x):
			if world and stage == "room":
				world.crouch_toggle = false)
	_set_action(body, "조작법", "키와 버튼을 한 장에 모아 본다", "조작법 보기", func(): open_help(func(): open_settings()))


func _settings_record(body: VBoxContainer) -> void:
	var n := 0
	for E in EPISODES:
		if save.done.has(E.id):
			n += 1
	_set_info(body, "끝낸 장", "기록은 %s에만 저장된다" % ("이 브라우저" if OS.has_feature("web") else "이 기기"), "%d / %d" % [n, EPISODES.size()])
	_set_action(body, "백업 코드 만들기", "끝낸 장 · 등급 · 설정을 코드로 옮겨 둔다", "코드 만들기", _backup_show)
	var b := _set_action(body, "백업 코드로 되살리기", "보관해 둔 코드를 붙여 넣어 기록을 되살린다" if stage == "title" else "타이틀 화면의 설정에서 할 수 있다", "코드 넣기", _backup_paste)
	b.disabled = stage != "title"
	if not (OS.has_feature("web") or OS.has_feature("android") or OS.has_feature("ios")):
		_set_action(body, "저장 폴더", "save.json을 복사해 두면 직접 백업할 수 있다", "폴더 열기", func(): OS.shell_open(OS.get_user_data_dir()))


func _settings_info(body: VBoxContainer) -> void:
	var r := _set_row(body, "지금 버전", "마지막 방 v%s" % VERSION)
	var ub := Ui.form_button("새 버전 확인", 16, func(): check_update(true))
	ub.custom_minimum_size.x = 132
	ub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(ub)
	_set_choice(body, "새 버전 자동 확인", "게임을 켤 때 새 버전이 있는지 확인한다", "autoupdate", ONOFF)
	_set_action(body, "업데이트 노트", "버전마다 바뀐 점", "읽어 보기", func(): open_updates(func(): open_settings()))
	_set_action(body, "이용 안내 및 약관", "적용일 %s" % TERMS.get("version", ""), "읽어 보기", func(): open_terms(Callable(), func(): open_settings()))
	var rc := _set_row(body, "문의", CONTACT)
	var mb := Ui.form_button("메일 쓰기", 16, func(): OS.shell_open("mailto:" + CONTACT))
	mb.custom_minimum_size.x = 132
	mb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rc.add_child(mb)


func _settings_reset() -> void:
	var keep_fs: bool = settings.fullscreen
	settings = DEFAULT_SETTINGS.duplicate()
	settings.fullscreen = keep_fs
	_apply_settings()
	apply_view()
	if world and stage == "room":
		world.sens = 0.0022 * float(settings.sens)
		world.crouch_toggle = false
	write_save()
	open_settings()


## 표 한 줄: 번호 | 항목 이름 · 설명 | (오른쪽 끝에 맞춘) 고르는 칸
func _set_row(box: VBoxContainer, title: String, desc: String) -> HBoxContainer:
	_set_n += 1
	var r := Ui.hbox(12)
	r.custom_minimum_size = Vector2(0, 59)
	var no := Ui.label("%02d" % _set_n, 16, Ui.INK_DIM, Ui.serif)
	no.custom_minimum_size = Vector2(40, 0)
	no.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(no)
	var tv := Ui.vbox(1)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.add_child(Ui.label(title, 18, Ui.INK, Ui.serif_b))
	if desc != "":
		tv.add_child(Ui.label(desc, 13, Ui.INK_DIM, Ui.sans, true))
	r.add_child(tv)
	box.add_child(r)
	box.add_child(Ui.DotRule.new())
	return r


static func _same(a, b) -> bool:
	if (a is float or a is int) and (b is float or b is int):
		return is_equal_approx(float(a), float(b))
	return typeof(a) == typeof(b) and a == b


## 보기 중 하나에 동그라미
func _set_choice(box: VBoxContainer, title: String, desc: String, key: String, opts: Array, cb: Callable = Callable()) -> void:
	var r := _set_row(box, title, desc)
	var g := Ui.hbox(4)
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var btns := []
	for o in opts:
		var b := Ui.InkChoice.new(o[0])
		b.set_on(_same(settings.get(key), o[1]))
		btns.append(b)
		g.add_child(b)
	for i in opts.size():
		var idx := i
		var val = opts[i][1]
		btns[i].pressed.connect(func():
			if _same(settings.get(key), val):
				return
			Sfx.play("ui", 0.5)
			settings[key] = val
			for j in btns.size():
				btns[j].set_on(j == idx)
			if cb.is_valid():
				cb.call(val)
			write_save())
	r.add_child(g)


## 눈금자: 끌거나 −/+로 조절, 값은 펜으로 적는다
func _set_ruler(box: VBoxContainer, title: String, desc: String, key: String, lo: float, hi: float, step: float, fmt: Callable, cb: Callable = Callable()) -> void:
	var r := _set_row(box, title, desc)
	var ru := Ui.InkRuler.new(lo, hi, step, float(settings.get(key, DEFAULT_SETTINGS[key])))
	ru.custom_minimum_size = Vector2(200, 46)
	var val := Ui.label(fmt.call(ru.value), 28, Ui.BLUE_INK, Ui.hand)
	val.custom_minimum_size = Vector2(76, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ru.changed.connect(func(x: float):
		settings[key] = x
		val.text = fmt.call(x)
		if cb.is_valid():
			cb.call(x))
	ru.released.connect(func(): write_save())
	var minus := Ui.form_button("−", 18, func():
		ru.set_value(ru.value - step)
		write_save())
	minus.custom_minimum_size = Vector2(44, 44)
	var plus := Ui.form_button("+", 18, func():
		ru.set_value(ru.value + step)
		write_save())
	plus.custom_minimum_size = Vector2(44, 44)
	for c in [minus, ru, plus, val]:
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(c)


func _set_action(box: VBoxContainer, title: String, desc: String, label: String, cb: Callable) -> Button:
	var r := _set_row(box, title, desc)
	var b := Ui.form_button(label, 16, cb)
	b.custom_minimum_size.x = 132
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(b)
	return b


func _set_info(box: VBoxContainer, title: String, desc: String, value: String) -> void:
	var r := _set_row(box, title, desc)
	var l := Ui.label(value, 30, Ui.BLUE_INK, Ui.hand)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(l)


# ───────────────────────────── 기록 백업 코드
const BACKUP_TAG := "LASTROOM1"


func _backup_code() -> String:
	var body := Marshalls.utf8_to_base64(JSON.stringify({"v": 1, "done": save.get("done", {}), "settings": settings}))
	return "%s:%s:%s" % [BACKUP_TAG, body, body.sha256_text().substr(0, 8)]


## 코드 → {"done", "settings"}. 틀린 코드면 빈 사전
func _backup_read(code: String) -> Dictionary:
	var c := code.strip_edges().replace("\n", "").replace("\r", "").replace(" ", "")
	if c.length() > 20000:
		return {}
	var parts := c.split(":")
	if parts.size() != 3 or parts[0] != BACKUP_TAG or parts[1].sha256_text().substr(0, 8) != parts[2]:
		return {}
	var d = JSON.parse_string(Marshalls.base64_to_utf8(parts[1]))
	if not (d is Dictionary) or not (d.get("done") is Dictionary):
		return {}
	return {"done": _clean_done(d.done), "settings": _clean_settings(d.get("settings", {}))}


func _code_field(text: String, editable: bool) -> LineEdit:
	var le := LineEdit.new()
	le.text = text
	le.editable = editable
	le.select_all_on_focus = true
	le.max_length = 20000
	le.custom_minimum_size = Vector2(600, 46)
	le.add_theme_font_override("font", Ui.sans)
	le.add_theme_font_size_override("font_size", 15)
	for k in ["font_color", "font_uneditable_color", "caret_color"]:
		le.add_theme_color_override(k, Ui.INK)
	le.add_theme_color_override("font_placeholder_color", Color(Ui.INK, 0.4))
	le.add_theme_color_override("selection_color", Color(Ui.RED, 0.3))
	for st in ["normal", "focus", "read_only"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.35)
		sb.border_color = Color(Ui.INK, 0.6 if st == "focus" else 0.35)
		sb.set_border_width_all(1)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		le.add_theme_stylebox_override(st, sb)
	return le


func _backup_sheet(title: String, text: String) -> Array:
	var p := Ui.panel(Ui.paper_box(false, 40))
	var v := Ui.vbox(10)
	v.add_child(Ui.label("기록 백업", 14, Ui.INK_DIM, Ui.spaced))
	v.add_child(Ui.label(title, 28, Ui.INK, Ui.serif_b))
	v.add_child(Ui.rule(0.6, 2))
	var t := Ui.label(text, 16, Ui.INK, Ui.serif, true)
	t.custom_minimum_size = Vector2(600, 0)
	v.add_child(t)
	p.add_child(v)
	return [p, v]


func _backup_show() -> void:
	var code := _backup_code()
	DisplayServer.clipboard_set(code)
	var pv := _backup_sheet("백업 코드", "코드를 복사했다. 메모장 · 메일 같은 곳에 붙여 넣어 보관해 두세요. 기기를 바꾸거나 기록이 지워졌을 때, 타이틀 화면의 설정 → 기록에서 되살릴 수 있다.")
	var v: VBoxContainer = pv[1]
	v.add_child(_code_field(code, false))
	var note := Ui.label("복사가 안 됐다면 칸을 눌러 전부 고른 뒤 복사한다. 코드에는 끝낸 장 · 등급 · 설정만 들어 있다.", 14, Ui.INK_DIM, Ui.sans, true)
	note.custom_minimum_size = Vector2(600, 0)
	v.add_child(note)
	v.add_child(_buttons_row([["다시 복사", func():
		DisplayServer.clipboard_set(code)
		note.text = "다시 복사했다."], ["닫기", func(): close_modal(), 21]]))
	open_modal(pv[0], func(): open_settings())


func _backup_paste() -> void:
	var pv := _backup_sheet("백업 코드로 되살리기", "보관해 둔 코드를 아래 칸에 붙여 넣는다. 지금 기록(끝낸 장 · 등급 · 설정)은 코드의 기록으로 바뀐다.")
	var v: VBoxContainer = pv[1]
	var le := _code_field("", true)
	le.placeholder_text = BACKUP_TAG + ": 로 시작하는 코드"
	v.add_child(le)
	var msg := Ui.label("", 15, Ui.RED, Ui.sans, true)
	msg.custom_minimum_size = Vector2(600, 0)
	v.add_child(msg)
	v.add_child(_buttons_row([["붙여 넣기", func(): le.text = DisplayServer.clipboard_get().strip_edges().left(20000)], ["그만둔다", func(): close_modal()], ["되살리기", func():
		var d := _backup_read(le.text)
		if d.is_empty():
			msg.text = "코드가 맞지 않는다. 빠진 글자 없이 전부 붙여 넣었는지 확인해 주세요."
			Sfx.play("error", 0.5)
			return
		confirm("기록을 바꿀까?", "지금 기록이 코드의 기록(끝낸 장 %d개)으로 바뀐다." % d.done.size(), "바꾼다", func(): _backup_apply(d)), 21]]))
	open_modal(pv[0], func(): open_settings())
	if not touch:
		le.grab_focus.call_deferred()


func _backup_apply(d: Dictionary) -> void:
	save.done = d.done
	settings = d.settings
	write_save()
	_apply_settings()
	apply_view()
	show_title()
	toast("기록을 되살렸다 — 끝낸 장 %d개" % d.done.size())


## 밝기 · 시야 · 화질을 지금 보이는 3D 화면에 적용
func apply_view() -> void:
	_apply_scale()
	if world == null:
		return
	var we = world.get("world_env")
	if we == null:
		we = world.get("env")
	if we is WorldEnvironment and we.environment:
		we.environment.adjustment_enabled = true
		we.environment.adjustment_brightness = float(settings.get("bright", 1.0))
		apply_quality_env(we.environment)
	var shadows: bool = settings.get("quality", "high") != "low"
	if stage == "room" and world.get("cam") is Camera3D:
		world.cam.fov = float(settings.get("fov", 72.0))
		world.flash.shadow_enabled = shadows
	elif stage == "inspect" and world.get("L") is Dictionary and world.L.has("key"):
		world.L.key.shadow_enabled = shadows


## 화질: 낮음은 그림자 · 빛 번짐 · 공기 안개를 끄고, 보통은 공기 안개 · 구석 그늘만 끈다
func apply_quality_env(e: Environment) -> void:
	var q: String = settings.get("quality", "high")
	e.ssao_enabled = q == "high"
	e.glow_enabled = q != "low"
	if e.has_meta("vfog"):
		e.volumetric_fog_enabled = q == "high"


# ───────────────────────────── 새 버전 확인 · 자동 업데이트
const UPDATE_URL := "https://eunyool10.github.io/LastRoom/version.json"
const PAGE_URL := "https://eunyool10.github.io/LastRoom/"
## 새 버전 파일은 이 게임의 GitHub 릴리스에서만 받는다
const RELEASE_URL := "https://github.com/EunYool10/LastRoom/releases/download/"
var update_checked := false
var update_info := {}
var _upd_http: HTTPRequest
var _upd_dl: HTTPRequest


static func _ver_num(v: String) -> int:
	var p := v.split("-")[0].split(".")
	var n := 0
	for i in 3:
		n = n * 1000 + (int(p[i]) if i < p.size() else 0)
	return n


static func _ver_ok(v) -> bool:
	return v is String and RegEx.create_from_string("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$").search(v) != null


## 새 버전 정보에 적힌 주소가 이 게임의 릴리스 파일일 때만 그대로 쓴다
func _release_url(u) -> String:
	var s := str(u)
	var ok := s.begins_with(RELEASE_URL) or (testing and s.begins_with("http://127.0.0.1:"))
	if not ok or s.length() > 300 or s.contains("..") or s.contains("?") or s.contains("#") or s.contains(" "):
		return ""
	return s


## 게임 밖 페이지 열기 (점검 중에는 열지 않고 적기만 한다)
func _open_url(u: String) -> void:
	if testing:
		print("OPEN_URL ", u)
		return
	OS.shell_open(u)


## 지난번에 받은 설치 파일은 다음 실행 때 지운다
func _clean_update_dir() -> void:
	var dir := OS.get_user_data_dir().path_join("update")
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))


func check_update(manual := false) -> void:
	if _upd_http and is_instance_valid(_upd_http):
		return
	_upd_http = HTTPRequest.new()
	_upd_http.timeout = 12.0
	_upd_http.body_size_limit = 65536
	add_child(_upd_http)
	_upd_http.request_completed.connect(func(result: int, code: int, _h, body: PackedByteArray):
		_upd_http.queue_free()
		_upd_http = null
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			if manual:
				toast("새 버전을 확인하지 못했다. 인터넷 연결을 확인해 주세요.")
			return
		var d = JSON.parse_string(body.get_string_from_utf8())
		if not (d is Dictionary) or not _ver_ok(d.get("version")):
			if manual:
				toast("새 버전 정보를 읽지 못했다.")
			return
		update_info = d
		if _ver_num(d.version) > _ver_num(VERSION):
			_show_update(d)
		elif manual:
			toast("지금이 최신 버전이다 (v%s)" % VERSION))
	var err := _upd_http.request(UPDATE_URL + "?t=%d" % Time.get_unix_time_from_system())
	if err != OK:
		_upd_http.queue_free()
		_upd_http = null
		if manual:
			toast("새 버전을 확인하지 못했다.")


func _platform_key() -> String:
	if OS.has_feature("web"):
		return "web"
	if OS.has_feature("android"):
		return "android"
	if OS.has_feature("macos"):
		return "mac"
	if OS.has_feature("windows"):
		return "windows"
	return "page"


func _show_update(d: Dictionary) -> void:
	var key := _platform_key()
	var p := Ui.panel(Ui.paper_box(false, 40))
	var v := Ui.vbox(10)
	v.add_child(Ui.label("새 버전", 14, Ui.INK_DIM, Ui.spaced))
	var h := Ui.hbox(14)
	h.add_child(Ui.label("마지막 방  v%s" % d.version, 28, Ui.INK, Ui.serif_b))
	var now := Ui.label("지금 v%s" % VERSION, 15, Ui.INK_DIM, Ui.sans)
	now.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(now)
	v.add_child(h)
	v.add_child(Ui.rule(0.3))
	var notes = d.get("notes", [])
	if not (notes is Array):
		notes = []
	for item in notes.slice(0, 8):
		var t := Ui.label("·  " + str(item).left(160), 16, Ui.INK, Ui.sans, true)
		t.custom_minimum_size = Vector2(560, 0)
		v.add_child(t)
	var how := {
		"windows": "새 설치 파일을 받아 원본과 같은지 확인한 다음, 지금 설치된 게임 위에 설치하고 다시 켠다. 기록은 그대로 남는다.",
		"android": "새 APK를 받는다. 받은 파일을 열어 [업데이트]를 누르면 지금 앱 위에 설치되고, 기록은 그대로 남는다.",
		"mac": "내려받기 페이지에서 새 앱을 받아 응용 프로그램 폴더의 앱과 바꾼다. 기록은 그대로 남는다.",
		"web": "새 버전으로 다시 불러온다. 기록은 그대로 남는다.",
		"page": "내려받기 페이지에서 새 버전을 받는다."}
	v.add_child(Ui.gap(4))
	var hl := Ui.label(how[key] + (" 업데이트하면 새 버전의 이용 안내에 동의한 것으로 봅니다(설정 → 정보 → 이용 안내)." if key == "windows" else ""), 15, Ui.INK_DIM, Ui.sans, true)
	hl.custom_minimum_size = Vector2(560, 0)
	v.add_child(hl)
	var label: String = {"windows": "지금 업데이트", "android": "새 APK 받기", "mac": "내려받기 페이지 열기", "web": "새로 불러오기", "page": "내려받기 페이지 열기"}[key]
	v.add_child(_buttons_row([["나중에", func(): close_modal()], [label, func(): _do_update(d, key), 22]]))
	p.add_child(v)
	open_modal(p)


func _do_update(d: Dictionary, key: String) -> void:
	match key:
		"windows":
			_download_installer(d)
		"android":
			var u := _release_url(d.get("android", ""))
			_open_url(u if u.ends_with(".apk") else PAGE_URL)
			close_modal()
		"web":
			JavaScriptBridge.eval("(async()=>{try{const rs=await navigator.serviceWorker.getRegistrations();await Promise.all(rs.map(r=>r.unregister()));const ks=await caches.keys();await Promise.all(ks.map(k=>caches.delete(k)));}catch(e){}location.reload();})()")
		_:
			_open_url(PAGE_URL)
			close_modal()


func _download_installer(d: Dictionary) -> void:
	var url := _release_url(d.get("windows", ""))
	var sums = d.get("sha256", {})
	var want := str(sums.get("windows", "")).to_lower() if sums is Dictionary else ""
	# 주소가 이 게임의 릴리스가 아니거나 확인값(SHA-256)이 없으면 받지 않고 내려받기 페이지를 연다
	if not url.ends_with(".exe") or RegEx.create_from_string("^[0-9a-f]{64}$").search(want) == null:
		_open_url(PAGE_URL)
		close_modal()
		return
	var dir := OS.get_user_data_dir().path_join("update")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join("LastRoom-Setup-%s.exe" % d.version)
	var p := Ui.panel(Ui.paper_box(false, 40))
	var v := Ui.vbox(12)
	v.add_child(Ui.label("새 버전 받는 중", 24, Ui.INK, Ui.serif_b))
	var st := Ui.label("연결하는 중…", 16, Ui.INK_DIM, Ui.sans, true)
	st.custom_minimum_size = Vector2(460, 0)
	v.add_child(st)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(460, 10)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(Ui.INK, 0.15)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Ui.INK
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	v.add_child(bar)
	v.add_child(_buttons_row([["그만두기", func(): close_modal()]]))
	p.add_child(v)
	# 닫으면(그만두기 · Esc) 받던 것도 멈춘다
	open_modal(p, func():
		if _upd_dl and is_instance_valid(_upd_dl):
			_upd_dl.cancel_request()
			_upd_dl.queue_free()
			_upd_dl = null)
	_upd_dl = HTTPRequest.new()
	_upd_dl.download_file = path
	_upd_dl.max_redirects = 10
	_upd_dl.use_threads = true
	_upd_dl.download_chunk_size = 1048576
	_upd_dl.body_size_limit = 400 * 1048576
	add_child(_upd_dl)
	var dl := _upd_dl
	var tick := Timer.new()
	tick.wait_time = 0.25
	tick.autostart = true
	dl.add_child(tick)
	tick.timeout.connect(func():
		var total := dl.get_body_size()
		var got := dl.get_downloaded_bytes()
		if total > 0:
			bar.value = 100.0 * got / total
			st.text = "%.1f / %.1f MB" % [got / 1048576.0, total / 1048576.0]
		elif got > 0:
			st.text = "%.1f MB" % (got / 1048576.0))
	dl.request_completed.connect(func(result: int, code: int, _h, _b):
		dl.queue_free()
		_upd_dl = null
		if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not FileAccess.file_exists(path):
			st.text = "받지 못했다. 잠시 뒤 다시 해 보거나 내려받기 페이지에서 받아 주세요."
			return
		# 받은 파일이 원본과 같은지 확인값으로 확인한 다음에만 실행한다
		if FileAccess.get_sha256(path).to_lower() != want:
			DirAccess.remove_absolute(path)
			st.text = "받은 파일이 원본과 달라 실행하지 않고 지웠다. 내려받기 페이지에서 받아 주세요."
			Sfx.play("error", 0.6)
			if testing:
				print("UPDATE_BADHASH ", path)
			return
		st.text = "원본과 같은 파일인지 확인했다. 설치를 시작한다. 잠시 뒤 게임이 다시 켜진다."
		bar.value = 100.0
		write_save()
		await get_tree().create_timer(0.8).timeout
		if testing:
			print("UPDATE_RUN ", path, " size=", FileAccess.get_file_as_bytes(path).size())
			return
		OS.create_process(path, ["/S", "/RUN"])
		get_tree().quit())
	if dl.request(url) != OK:
		st.text = "받지 못했다. 내려받기 페이지에서 받아 주세요."


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
	if P.get("pin") != null and not S.phone_unlocked:
		open_combo(str(P.pin), func():
			S.phone_unlocked = true
			Sfx.play("unlock", 0.8)
			get_tree().create_timer(0.2).timeout.connect(func(): _show_phone(0)), "비밀번호 4자리", "잠금 화면에 네 자리 숫자를 넣는다.")
		return
	if P.get("pattern") != null and not S.phone_unlocked:
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
	var lap: bool = P.skin == "laptop"
	sb.set_corner_radius_all(18 if flip else (8 if lap else 34))
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 18
	sb.content_margin_bottom = 16
	outer.add_theme_stylebox_override("panel", sb)
	outer.custom_minimum_size = Vector2(620, min(460.0, get_viewport().get_visible_rect().size.y * 0.7)) if lap else Vector2(360, min(640.0, get_viewport().get_visible_rect().size.y * 0.8))
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
func open_combo(code: String, ok: Callable, title := "숫자 자물쇠", hint := "네 자리 숫자. 키보드로도 넣을 수 있다.") -> void:
	if touch:
		hint = hint.replace(" 키보드로도 넣을 수 있다.", " ▲ ▼를 눌러 맞춘다.")
	var vals := [0, 0, 0, 0]
	var cursor := [0]
	var p := Ui.panel(Ui.dark_box(0.98, 34, 0.1))
	var v := Ui.vbox(14)
	var t := Ui.label(title, 17, Ui.ACCENT, Ui.sans_b)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var wheels := Ui.hbox(14)
	wheels.alignment = BoxContainer.ALIGNMENT_CENTER
	var digits := []
	var msg := Ui.label(hint, 15, Ui.DIM, Ui.sans, true)
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
