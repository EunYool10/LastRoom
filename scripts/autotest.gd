extends Node
## 개발용 자동 점검: 실행 인자 --autotest 가 있을 때만 동작 (스크린샷 저장)

var out := ""
var n := 0


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join("%02d_%s.png" % [n, name]))
	n += 1


func _press(root, contains: String) -> bool:
	if not is_instance_valid(root):
		return false
	for b in root.find_children("*", "Button", true, false):
		if b.visible and not b.disabled and contains in b.text:
			b.pressed.emit()
			return true
	return false


func run(o: String, ei: int, full: bool) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(1.2)
	if ei == 0:
		await _shot("title")
	var E: Dictionary = Game.EPISODES[ei]
	Game.show_brief(E)
	await _wait(0.4)
	if ei == 0:
		await _shot("brief")
	Game.enter_room()
	await _wait(1.6)
	if ei == 0:
		await _shot("pause")
	for i in range(40):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	Game.hide_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.8)
	var room = Game.world
	print("AUTOTEST room preview=", room.preview, " stage=", Game.stage)
	var views := [[0.0, -0.5], [0.95, -0.38], [-0.95, -0.35], [PI, -0.3]]
	for i in views.size():
		room.yaw = views[i][0]
		room.pitch = views[i][1]
		await _wait(0.5)
		await _shot("view%d" % i)
	# 얼룩: 뿌리고 문지르기
	var st = room.stains[0]
	var sp := Vector3(st.def.pos[0], 0, st.def.pos[2])
	room.player.position = sp + Vector3(0, 0, 0.75)
	await _wait(0.3)
	var dz: float = room.player.position.z - sp.z
	room.yaw = 0.0
	room.pitch = -atan2(room.eye - float(st.def.pos[1]), max(0.2, dz))
	room.select_tool(2)
	room.using = true
	await _wait(2.2)
	await _shot("spray")
	room.using = false
	print("AUTOTEST player=", room.player.position, " yaw=", room.yaw, " pitch=", room.pitch)
	if room.aim:
		print("AUTOTEST aim=", room.aim.type, " pos=", room.aim.pos, " dist=", room.aim.dist)
	print("AUTOTEST spray progress=", st.progress)
	room.select_tool(3)
	room.using = true
	for k in range(260):
		room.scrub_motion += 18.0
		await get_tree().physics_frame
	room.using = false
	await _wait(0.4)
	print("AUTOTEST scrub: progress=", st.progress, " done=", st.done)
	await _shot("scrub")
	# 분류 카드
	for it in room.items:
		if it.state == "idle" and not it.hidden and it.def.kind == "trash":
			room.open_card(it)
			break
	await _wait(0.6)
	await _shot("card")
	room.card_action("trash")
	# 조사 지점 (숨은 물건 공개)
	for en in room.envs:
		if en.def.has("reveal"):
			room.use_env(en)
	await _wait(1.0)
	await _shot("env")
	for it in room.items:
		if it.state != "gone":
			room.sort_item(it, it.def.kind != "trash")
	for s2 in room.stains:
		s2.done = true
		s2.progress = 1.0
	room.complete = true
	room.try_exit()
	await _wait(2.4)
	await _shot("inspect")
	var ins = Game.world
	ins.toggle_uv()
	await _wait(0.4)
	await _shot("uv")
	ins.toggle_uv()
	if full:
		var first := true
		for id in E.docs:
			Game.open_doc(id)
			await _wait(0.5)
			if first or E.docs[id].style == "letter":
				await _shot("doc_" + id)
			first = false
			Game.close_modal()
		if E.phone.pattern != null:
			Game.open_phone()
			await _wait(0.4)
			await _shot("pattern")
			Game.close_modal()
		Game.S.phone_unlocked = true
		Game.open_phone()
		await _wait(0.4)
		await _shot("phone")
		Game.close_modal()
		if E.phone.apps[0].type == "threads":
			Game._show_thread(0, 0)
		await _wait(0.5)
		await _shot("chat")
		Game.close_modal()
	for d in E.items:
		if d.get("extra", false) and not Game.S.kept.has(d.id):
			Game.S.kept.append(d.id)
	ins.refresh()
	var shown := 0
	for d in E.items:
		if Game.S.kept.has(d.id) and d.kind == "clue" and shown < 4:
			ins.select(d.id)
			await _wait(0.5)
			await _shot("item_" + d.id)
			shown += 1
	# UV 무늬가 있는 물건: 무늬 쪽으로 돌리고 UV를 켜서 찍는다
	for d in E.items:
		if not Game.S.kept.has(d.id) or not ins.models.has(d.id):
			continue
		var uvs: Array = ins.models[d.id].res.get("uv", [])
		if uvs.is_empty():
			continue
		ins.select(d.id)
		await _wait(0.4)
		if uvs[0].position.y < 0.0:
			ins.pivot.rotate_x(PI)
		ins._set_uv(true)
		await _wait(0.4)
		await _shot("uvitem_" + d.id)
		ins._set_uv(false)
	if not full:
		get_tree().quit()
		return
	for k in E.clues:
		if not Game.S.clues.has(k):
			Game.S.clues.append(k)
	Game.go_board()
	await _wait(5.0)
	await _shot("board")
	var b = Game.board
	for qi in range(E.questions.size()):
		var Q: Dictionary = E.questions[qi]
		b._pick_opt(1 if int(Q.answer) == 0 else 0)
		b._submit()
		var c := 0
		for x in Q.evidence:
			if Game.S.clues.has(x) and c < 2:
				b._toggle_ev(x)
				c += 1
		b._pick_opt(int(Q.answer))
		b._submit()
		await _wait(0.4)
		if qi == 0:
			await _shot("answered")
		b._submit()
		await _wait(0.3)
	for i in range(8):
		if not _press(b, "▸"):
			break
		await _wait(0.25)
	await _wait(0.6)
	await _shot("letter")
	_press(b, "태워")
	await _wait(1.6)
	await _shot("burning")
	for i in range(60):
		await _wait(0.2)
		var found := false
		for bb in b.find_children("*", "Button", true, false):
			if "계속" in bb.text:
				found = true
		if found:
			break
	for i in range(6):
		print("AUTOTEST press ", _press(b, "▸"), " stage=", Game.stage)
		await _wait(0.4)
	await _wait(2.2)
	await _shot("result")
	print("AUTOTEST done stage=", Game.stage)
	get_tree().quit()


# ───────────── 실제 입력 흉내: 상호작용 반복 점검
func _key(k: int) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().physics_frame
	var r := InputEventKey.new()
	r.keycode = k
	r.physical_keycode = k
	r.pressed = false
	Input.parse_input_event(r)
	await get_tree().process_frame


func _face(room, target: Vector3, dist := 0.95) -> void:
	var c := Vector3(0, 0, 0)
	var dir := (Vector3(c.x, 0, c.z) - Vector3(target.x, 0, target.z))
	if dir.length() < 0.05:
		dir = Vector3(0, 0, 1)
	dir = dir.normalized()
	room.player.position = Vector3(target.x, 0, target.z) + dir * dist
	for i in range(3):
		await get_tree().physics_frame
	var p: Vector3 = room.player.position
	var to := target - Vector3(p.x, room.eye, p.z)
	room.yaw = atan2(-to.x, -to.z)
	room.pitch = atan2(to.y, Vector2(to.x, to.z).length())
	for i in range(3):
		await get_tree().physics_frame


func input_test(o: String, ei: int) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(1.0)
	Game.show_brief(Game.EPISODES[ei])
	await _wait(0.3)
	Game.enter_room()
	for i in range(60):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	Game.hide_pause()
	await _wait(0.5)
	var room = Game.world
	var tried := 0
	for it in room.items:
		if tried >= 6 or it.hidden or it.state != "idle":
			continue
		tried += 1
		var tp: Vector3 = it.root.global_position + Vector3(0, 0.03, 0)
		await _face(room, tp)
		var aim_s: String = ("%s:%s" % [room.aim.type, room.aim.obj.def.id if room.aim.type == "item" else ""]) if room.aim else "none"
		await _key(KEY_E)
		var opened: bool = room.card != null
		await _key(KEY_Q if it.def.kind == "trash" else KEY_E)
		await _wait(0.5)
		print("INPUT item=%s aim=%s card_opened=%s final_state=%s paused=%s" % [it.def.id, aim_s, opened, it.state, Game.paused])
	for en in room.envs:
		await _face(room, Vector3(en.def.pos[0], en.def.pos[1], en.def.pos[2]), 1.0)
		var a: String = room.aim.type if room.aim else "none"
		var before: bool = en.used
		await _key(KEY_E)
		await _wait(0.3)
		print("INPUT env=%s aim=%s used_before=%s used_after=%s" % [en.def.id, a, before, en.used])
	# 손 도구로 왼쪽 클릭
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await _wait(0.2)
	print("INPUT mouse_mode=", Input.mouse_mode)
	room.select_tool(1)
	var left := 0
	for it in room.items:
		if left >= 3 or it.hidden or it.state != "idle":
			continue
		left += 1
		await _face(room, it.root.global_position + Vector3(0, 0.03, 0))
		await _click(MOUSE_BUTTON_LEFT, Vector2(640, 360))
		var opened: bool = room.card != null
		await _click(MOUSE_BUTTON_LEFT, Vector2(640, 360))
		await _wait(0.4)
		print("INPUT lmb item=%s card_opened=%s after_second_click_card=%s state=%s" % [it.def.id, opened, room.card != null, it.state])
		if room.card != null:
			await _key(KEY_X)
			await _wait(0.4)
	# 조사 단계 클릭
	for it in room.items:
		if it.state != "gone":
			room.sort_item(it, it.def.kind != "trash")
	for s2 in room.stains:
		s2.done = true
	room.complete = true
	room.try_exit()
	await _wait(2.4)
	var ins = Game.world
	for d in Game.EPISODES[ei].items:
		if not Game.S.kept.has(d.id) or not d.has("spots"):
			continue
		ins.select(d.id)
		await _wait(0.5)
		for sp in ins.cur.m.spots:
			if sp.def.get("uv", false):
				continue
			var rot := 0
			var sp_pos: Vector3 = sp.body.global_position
			var nw: Vector3 = (sp.body.global_transform.basis * Vector3.UP).normalized()
			if nw.dot((ins.cam.global_position - sp_pos).normalized()) < 0.15:
				ins._rotate(Vector2(PI, 0))
				await _wait(0.3)
				rot = 1
				sp_pos = sp.body.global_position
			var vp: Vector2 = ins.cam.unproject_position(sp_pos)
			var sc: Vector2 = vp * (Vector2(get_window().size) / get_viewport().get_visible_rect().size)
			var before: int = Game.S.spots.size()
			await _click(MOUSE_BUTTON_LEFT, sc)
			await _wait(0.5)
			var m: bool = Game.modal_open
			if m:
				await _key(KEY_ESCAPE)
				await _wait(0.3)
			print("INPUT inspect item=%s spot=%s rotated=%s screen=%s spots %d->%d modal=%s" % [d.id, sp.name, rot, sc, before, Game.S.spots.size(), m])
			ins.reset_view()
			await _wait(0.3)
	await _shot("input_end")
	get_tree().quit()


func _click(btn: int, pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = btn
	e.position = pos
	e.global_position = pos
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().physics_frame
	var r := InputEventMouseButton.new()
	r.button_index = btn
	r.position = pos
	r.global_position = pos
	r.pressed = false
	Input.parse_input_event(r)
	await get_tree().process_frame


func pause_test(o: String, ei: int) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(1.0)
	Game.show_brief(Game.EPISODES[ei])
	await _wait(0.3)
	Game.enter_room()
	for i in range(80):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	await _wait(0.8)
	await _shot("pause_first")
	Game.hide_pause()
	await _wait(1.5)
	Game.world.yaw = 0.9
	Game.world.pitch = -0.25
	await _wait(0.6)
	Game.show_pause(false)
	await _wait(0.8)
	await _shot("pause")
	Game.hide_pause()
	await _wait(0.6)
	await _shot("after_resume")
	get_tree().quit()


# ───────────── 터치 조작 점검 (--touch --touchtest)
func _wp(p: Vector2) -> Vector2:
	var vr := get_viewport().get_visible_rect().size
	return p * Vector2(DisplayServer.window_get_size()) / vr


func _touch(idx: int, p: Vector2, on: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = _wp(p)
	e.pressed = on
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().physics_frame


func _tdrag(idx: int, a: Vector2, b: Vector2, steps: int) -> void:
	for i in steps:
		var e := InputEventScreenDrag.new()
		e.index = idx
		e.position = _wp(a.lerp(b, float(i + 1) / steps))
		e.relative = _wp(b - a) / steps
		Input.parse_input_event(e)
		await get_tree().physics_frame


func _btn(room, id: String) -> Vector2:
	room.touchpad._layout()
	for b in room.touchpad.btns:
		if b.id == id:
			return b.c
	return Vector2(-1, -1)


func _tap(room, id: String, hold := 0.0) -> void:
	var c := _btn(room, id)
	await _touch(3, c, true)
	if hold > 0.0:
		await _wait(hold)
	await _touch(3, c, false)


func touch_test(o: String, ei: int) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(1.0)
	Game.show_brief(Game.EPISODES[ei])
	await _wait(0.3)
	Game.enter_room()
	for i in range(80):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	await _wait(0.6)
	await _shot("touch_pause_first")
	Game.hide_pause()
	await _wait(1.0)
	var room = Game.world
	var vr := get_viewport().get_visible_rect().size
	print("TOUCH touch=", Game.touch, " pad=", room.touchpad != null, " vr=", vr, " win=", DisplayServer.window_get_size())
	await _shot("touch_hud")
	var p0: Vector3 = room.player.position
	var sb := Vector2(170, vr.y - 175)
	await _touch(0, sb, true)
	await _tdrag(0, sb, sb + Vector2(0, -90), 10)
	await _wait(0.6)
	await _touch(0, sb + Vector2(0, -90), false)
	print("TOUCH move dist=%.2f tmove_after=%s" % [room.player.position.distance_to(p0), room.tmove])
	var y0: float = room.yaw
	var lp := Vector2(vr.x * 0.6, vr.y * 0.4)
	await _touch(1, lp, true)
	await _tdrag(1, lp, lp + Vector2(220, 0), 10)
	await _touch(1, lp + Vector2(220, 0), false)
	print("TOUCH look dyaw=%.2f" % (room.yaw - y0))
	await _tap(room, "t2")
	var t2: int = room.tool
	await _tap(room, "t1")
	print("TOUCH tool after t2=%d after t1=%d" % [t2, room.tool])
	var done := 0
	for it in room.items:
		if done >= 2 or it.hidden or it.state != "idle" or it.def.kind == "clue":
			continue
		done += 1
		await _face(room, it.root.global_position + Vector3(0, 0.03, 0))
		await _tap(room, "use")
		await _wait(0.3)
		var opened: bool = room.card != null
		if done == 1:
			await _shot("touch_card")
		await _tap(room, "keep" if it.def.kind != "trash" else "trash")
		await _wait(0.5)
		print("TOUCH item=%s card=%s state=%s" % [it.def.id, opened, it.state])
	var st = room.stains[0]
	var sp := Vector3(st.def.pos[0], 0, st.def.pos[2])
	await _face(room, sp + Vector3(0, 0.02, 0), 1.0)
	var pr0: float = st.progress
	await _tap(room, "t2")
	await _tap(room, "use", 1.6)
	await _tap(room, "t3")
	await _tap(room, "use", 3.0)
	print("TOUCH stain progress %.2f -> %.2f aim=%s" % [pr0, st.progress, room.aim.type if room.aim else "none"])
	await _tap(room, "pause")
	await _wait(0.6)
	print("TOUCH pause visible=", Game.pause_root.visible)
	await _shot("touch_pause")
	get_tree().quit()


# ───────────── 보관함 · 업데이트 노트 · 크레딧 점검 (--featuretest)
func feature_test(o: String) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	Game.save.erase("seen_notes")
	Game.show_title()
	await _wait(1.2)
	await _shot("title_new")
	Game.open_updates()
	await _wait(0.5)
	await _shot("updates")
	print("FEAT seen_notes=", Game.save.get("seen_notes", ""), " updates=", Game.UPDATES.size())
	Game.close_modal()
	Game.show_title()
	await _wait(0.6)
	await _shot("title_seen")
	Game.show_credits()
	await _wait(11.0)
	await _shot("credits")
	Game.show_brief(Game.EPISODES[0])
	await _wait(0.3)
	Game.enter_room()
	for i in range(80):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	Game.hide_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.6)
	var room = Game.world
	var tr = null
	var kp = null
	for it in room.items:
		if it.hidden:
			continue
		if tr == null and it.def.kind == "trash":
			tr = it
		elif kp == null and it.def.kind == "keep":
			kp = it
	room.sort_item(tr, true)
	room.sort_item(kp, true)
	await _wait(0.6)
	print("FEAT kept=", room.kept_items().size(), " err=", Game.S.err.kept_trash, " sorted=", Game.S.sorted.size())
	await _key(KEY_I)
	await _wait(0.4)
	print("FEAT inventory open=", Game.modal_open)
	await _shot("inventory")
	room.take_out(tr)
	Game.open_inventory()
	await _wait(0.3)
	await _shot("inventory_after")
	print("FEAT after take_out kept=", room.kept_items().size(), " err=", Game.S.err.kept_trash, " state=", tr.state, " visible=", tr.root.visible, " scale=", tr.root.scale, " shape_off=", tr.shape.disabled)
	await _key(KEY_I)
	await _wait(0.3)
	print("FEAT inventory closed=", not Game.modal_open, " paused=", Game.paused)
	room.yaw = 0.0
	await _wait(0.4)
	get_tree().quit()


# ───────────── 터치로 조사 단계 버튼 누르기 (--touch --uvtouchtest)
func uv_touch_test(o: String, ei: int) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(1.0)
	Game.show_brief(Game.EPISODES[ei])
	await _wait(0.3)
	Game.enter_room()
	for i in range(80):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	Game.hide_pause()
	await _wait(0.5)
	var room = Game.world
	for it in room.items:
		if it.state != "gone":
			room.sort_item(it, it.def.kind != "trash")
	for s2 in room.stains:
		s2.done = true
		s2.progress = 1.0
	room.complete = true
	room.try_exit()
	await _wait(2.4)
	var ins = Game.world
	var c: Vector2 = ins.U.uvb.get_global_rect().get_center()
	print("UVT before=", ins.uv, " btn=", c)
	await _touch(0, c, true)
	await _wait(0.1)
	await _touch(0, c, false)
	await _wait(0.3)
	print("UVT after one tap=", ins.uv)
	await _shot("uv_tap")
	await _touch(0, c, true)
	await _wait(0.1)
	await _touch(0, c, false)
	await _wait(0.3)
	print("UVT after two taps=", ins.uv)
	get_tree().quit()


# ───────────── 웹에서 실제 브라우저 터치를 기다리며 UV 상태 기록 (--uvwait)
func uv_wait_test(ei: int) -> void:
	await _wait(1.0)
	Game.show_brief(Game.EPISODES[ei])
	await _wait(0.3)
	Game.enter_room()
	for i in range(80):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	Game.hide_pause()
	await _wait(0.5)
	var room = Game.world
	for it in room.items:
		if it.state != "gone":
			room.sort_item(it, it.def.kind != "trash")
	for s2 in room.stains:
		s2.done = true
		s2.progress = 1.0
	room.complete = true
	room.try_exit()
	await _wait(2.4)
	var ins = Game.world
	var vr := get_viewport().get_visible_rect().size
	var c: Vector2 = ins.U.uvb.get_global_rect().get_center() * Vector2(DisplayServer.window_get_size()) / vr
	print("UVW ready css=", c.x, ",", c.y, " touch=", Game.touch)
	var last: bool = ins.uv
	var flips := 0
	for i in range(600):
		await get_tree().process_frame
		if ins.uv != last:
			last = ins.uv
			flips += 1
			print("UVW flip ", flips, " uv=", last, " frame=", i)
	print("UVW done flips=", flips, " uv=", ins.uv)


# ───────────── 설정 화면 · 새 버전 알림 점검 (--settingstest)
func _btns(text: String) -> Array:
	var out_b := []
	for b in Game.modal_root.find_children("*", "Button", true, false):
		if b.visible and b.text == text:
			out_b.append(b)
	return out_b


func settings_test(o: String) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(1.0)
	Game.open_settings()
	await _wait(0.4)
	await _shot("settings")
	var offs := _btns("끄기")
	var bob_off: Button = offs[1] if not Game.touch else offs[0]
	bob_off.pressed.emit()
	_btns("+")[0].pressed.emit()
	await _wait(0.3)
	print("SET bob=", Game.settings.bob, " bright=", Game.settings.bright)
	await _shot("settings_changed")
	for b in Game.modal_root.find_children("*", "Button", true, false):
		if b.text == "기본값으로":
			b.pressed.emit()
			break
	await _wait(0.3)
	print("SET after reset bob=", Game.settings.bob, " bright=", Game.settings.bright)
	Game.close_modal()
	var d := {"version": "9.9.9", "notes": ["시험용 알림"], "windows": "http://127.0.0.1:8767/LastRoom-Setup-1.2.0.exe", "page": "https://eunyool10.github.io/LastRoom/"}
	Game._show_update(d)
	await _wait(0.4)
	await _shot("update_notice")
	if not Game.touch:
		Game._do_update(d, "windows")
		for i in range(120):
			await _wait(0.25)
			if not is_instance_valid(Game._upd_dl):
				break
		await _wait(1.6)
		await _shot("update_done")
	get_tree().quit()


# ───────────── 얼룩 판정 · 숙이기 점검 (--cleantest)
func _look_at_point(room, p: Vector3) -> void:
	var c: Vector3 = room.cam.global_position
	var to := p - c
	room.yaw = atan2(-to.x, -to.z)
	room.pitch = atan2(to.y, Vector2(to.x, to.z).length())
	await get_tree().physics_frame
	await get_tree().physics_frame


func clean_test(o: String, ei: int) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(1.0)
	Game.show_brief(Game.EPISODES[ei])
	await _wait(0.3)
	Game.enter_room()
	for i in range(80):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	Game.hide_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.6)
	var room = Game.world
	# 숙이기
	var y0: float = room.head.position.y
	var e := InputEventKey.new()
	e.physical_keycode = KEY_CTRL
	e.keycode = KEY_CTRL
	e.pressed = true
	Input.parse_input_event(e)
	await _wait(0.6)
	var y1: float = room.head.position.y
	await _shot("crouch")
	var r := InputEventKey.new()
	r.physical_keycode = KEY_CTRL
	r.keycode = KEY_CTRL
	r.pressed = false
	Input.parse_input_event(r)
	await _wait(0.6)
	print("CLEAN crouch eye %.2f -> %.2f -> %.2f" % [y0, y1, room.head.position.y])
	for st in room.stains:
		var center: Vector3 = st.node.global_position
		await _face(room, center, 1.0)
		await _wait(0.1)
		# 가장자리 바로 바깥
		var edge: Vector3 = st.node.to_global(Vector3(st.w * 0.5 + 0.05, 0, 0))
		await _look_at_point(room, edge)
		var edge_ok: bool = room.stain_aim != null and room.stain_aim.obj == st
		# 얼룩 위에 물건을 올려 두고 가운데를 겨누기
		var blocker = null
		for it in room.items:
			if it.state == "idle" and not it.hidden:
				blocker = it
				break
		var keep_pos: Vector3 = blocker.root.global_position
		blocker.root.global_position = center + st.node.global_transform.basis.y * 0.02
		await _look_at_point(room, center)
		await _wait(0.05)
		var blocked_type: String = room.aim.type if room.aim else "none"
		var through_ok: bool = room.stain_aim != null and room.stain_aim.obj == st
		blocker.root.global_position = keep_pos
		# 뿌리고 문지르기: 얼룩 전체를 훑는다
		var t0 := Time.get_ticks_msec()
		var pts := []
		var nx := int(ceil(st.w / 0.14))
		var nz := int(ceil(st.h / 0.14))
		for j in nz + 1:
			for i in nx + 1:
				pts.append(st.node.to_global(Vector3(-st.w * 0.5 + st.w * i / nx, 0, -st.h * 0.5 + st.h * j / nz)))
		room.select_tool(2, true)
		room.set_use(true)
		for p in pts:
			await _look_at_point(room, p)
			await _wait(0.06)
		room.set_use(false)
		room.select_tool(3, true)
		var passes := 0
		while not st.done and passes < 4:
			passes += 1
			room.set_use(true)
			for p in pts:
				await _look_at_point(room, p)
				for f in range(8):
					room.scrub_motion += 25.0
					await get_tree().physics_frame
				if st.done:
					break
			room.set_use(false)
		print("CLEAN %s %s edge=%s item_on_top=%s(%s) done=%s progress=%.2f passes=%d secs=%.1f" % [st.def.id, st.def.surf, edge_ok, through_ok, blocked_type, st.done, st.progress, passes, (Time.get_ticks_msec() - t0) / 1000.0])
	get_tree().quit()


# ───────────── 이용 안내 화면 (--termstest)
func terms_test(o: String) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(1.0)
	Game.open_terms(func(): print("TERMS agreed"))
	await _wait(0.4)
	await _shot("terms_agree")
	for b in Game.modal_root.find_children("*", "Button", true, false):
		if b.text == "동의하고 시작":
			b.pressed.emit()
	await _wait(0.3)
	print("TERMS saved=", Game.save.get("terms_ok", ""), " modal=", Game.modal_open)
	Game.save.erase("terms_ok")
	Game.write_save()
	Game.open_settings()
	await _wait(0.3)
	for sc in Game.modal_root.find_children("*", "ScrollContainer", true, false):
		sc.scroll_vertical = 10000
	await _wait(0.3)
	await _shot("settings_bottom")
	get_tree().quit()
