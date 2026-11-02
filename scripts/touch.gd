extends Control
## 휴대폰 · 태블릿 화면 조작 — 왼쪽은 이동 스틱, 오른쪽은 둘러보기, 아래 오른쪽은 도구 버튼

const STICK_R := 92.0

var room: Node
var stick_id := -1
var stick_base := Vector2.ZERO
var stick_pos := Vector2.ZERO
var look_id := -1
var held := {}
var btns: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.full(self)


func _layout() -> void:
	var s := get_viewport_rect().size
	var k := float(Game.settings.get("pad", 1.0))
	btns.clear()
	if room.card != null:
		_add("keep", "보관", Vector2(s.x - 140 * k, s.y - 130 * k), 72 * k, true)
		_add("trash", "폐기", Vector2(s.x - 305 * k, s.y - 100 * k), 54 * k, false)
		_add("cancel", "내려놓기", Vector2(s.x - 445 * k, s.y - 100 * k), 54 * k, false)
	else:
		var u := Vector2(s.x - 150 * k, s.y - 150 * k)
		_add("use", ["집기", "뿌리기", "문지르기"][room.tool - 1], u, 80 * k, true)
		var names := ["손", "분무기", "스크러버"]
		var offs := [Vector2(-205, 45), Vector2(-165, -120), Vector2(-25, -205)]
		for i in 3:
			_add("t%d" % (i + 1), names[i], u + offs[i] * k, 46 * k, i + 1 == room.tool)
	if room.card == null:
		_add("flash", "손전등" if room.flash_on else "손전등 꺼짐", Vector2(s.x - 74 * k, s.y * 0.42), 42 * k, false)
	_add("pause", "멈춤", Vector2(74 * k, 168), 38 * k, false)
	_add("box", "보관함", Vector2(74 * k, 168 + 94 * k), 38 * k, false)
	_add("crouch", "일어서기" if room.crouch_toggle else "숙이기", Vector2(74 * k, 168 + 188 * k), 38 * k, room.crouch_toggle)


func _add(id: String, label: String, c: Vector2, r: float, strong: bool) -> void:
	btns.append({"id": id, "label": label, "c": c, "r": r, "strong": strong})


func _hit(p: Vector2) -> String:
	for b in btns:
		if p.distance_to(b.c) <= b.r + 10.0:
			return b.id
	return ""


func _blocked() -> bool:
	return not is_visible_in_tree() or Game.paused or Game.modal_open or room.exiting


func reset() -> void:
	for i in held:
		_release(held[i])
	held.clear()
	stick_id = -1
	look_id = -1
	room.tmove = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if _blocked():
		if not held.is_empty() or stick_id != -1 or look_id != -1:
			reset()
		return
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			_layout()
			var b := _hit(p)
			if b != "":
				held[event.index] = b
				_press(b)
			elif p.x < size.x * 0.42 and stick_id == -1:
				stick_id = event.index
				stick_base = p
				stick_pos = p
			elif look_id == -1:
				look_id = event.index
		else:
			if held.has(event.index):
				var id: String = held[event.index]
				held.erase(event.index)
				_release(id)
			if event.index == stick_id:
				stick_id = -1
				room.tmove = Vector2.ZERO
			if event.index == look_id:
				look_id = -1
		get_viewport().set_input_as_handled()
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == stick_id:
			stick_pos = event.position
			var v := (stick_pos - stick_base) / STICK_R
			if v.length() > 1.0:
				# 손가락이 멀리 가면 스틱 받침이 따라온다
				stick_base = stick_pos - v.normalized() * STICK_R
				v = v.normalized()
			room.tmove = v
		elif event.index == look_id:
			room.look(event.relative)
		get_viewport().set_input_as_handled()
		queue_redraw()


func _press(id: String) -> void:
	Sfx.play("ui", 0.25)
	match id:
		"use":
			room.set_use(true)
		"t1", "t2", "t3":
			room.select_tool(int(id.substr(1)))
		"flash":
			room.toggle_flash()
		"keep", "trash", "cancel":
			room.card_action(id)
		"pause":
			held.clear()
			Game.show_pause(false)
		"box":
			held.clear()
			Game.open_inventory()
		"crouch":
			room.crouch_toggle = not room.crouch_toggle


func _release(id: String) -> void:
	if id == "use":
		room.set_use(false)


func _process(_dt: float) -> void:
	_layout()
	queue_redraw()


func _draw() -> void:
	var font: Font = Ui.sans_b
	var pressed := held.values()
	for b in btns:
		var on: bool = pressed.has(b.id)
		var fill := Color(0.05, 0.05, 0.05, 0.42) if not on else Color(0.95, 0.9, 0.82, 0.22)
		draw_circle(b.c, b.r, fill)
		var ring := Color(Ui.ACCENT, 0.85) if b.strong else Color(1, 1, 1, 0.32)
		draw_arc(b.c, b.r, 0, TAU, 48, ring, 2.0, true)
		var fs := 19 if b.r >= 70 else 15
		var w := font.get_string_size(b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, b.c + Vector2(-w / 2.0, fs * 0.36), b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.86))
	var s := get_viewport_rect().size
	if stick_id == -1:
		var c := Vector2(170, s.y - 175)
		draw_arc(c, STICK_R, 0, TAU, 48, Color(1, 1, 1, 0.16), 2.0, true)
		var t := "이동"
		var w2 := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(font, c + Vector2(-w2 / 2.0, 5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.3))
	else:
		draw_circle(stick_base, STICK_R, Color(0, 0, 0, 0.25))
		draw_arc(stick_base, STICK_R, 0, TAU, 48, Color(1, 1, 1, 0.3), 2.0, true)
		draw_circle(stick_pos, 38, Color(0.95, 0.9, 0.82, 0.35))
