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


func _choice(text: String) -> Button:
	for b in Game.modal_root.find_children("*", "Button", true, false):
		if b.visible and b.text == text:
			return b
	return null


## 설정 다섯 쪽 · 기록 백업 코드 · 기록 파일 검사 (--settingstest)
func settings_test(o: String) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(1.0)
	for i in 5:
		Game.open_settings(i)
		await _wait(0.4)
		await _shot("settings_%d" % i)
	Game.open_settings(0)
	await _wait(0.2)
	_choice("낮음").pressed.emit()
	await _wait(0.2)
	print("SET quality=", Game.settings.quality, " scale=", get_viewport().scaling_3d_scale)
	await _shot("settings_quality_low")
	for r in Game.modal_root.find_children("*", "", true, false):
		if r is Ui.InkRuler and r.hi == 90.0:
			r.set_value(84.0)
	print("SET fov=", Game.settings.fov)
	Game._settings_reset()
	await _wait(0.2)
	print("SET after reset quality=", Game.settings.quality, " fov=", Game.settings.fov, " bright=", Game.settings.bright)
	# 백업 코드: 만들고 → 읽고 → 한 글자 바꾸면 거절
	Game.save.done = {"ep1": {"grade": "A", "score": 80, "choice": "deliver", "best": 80}, "ep4": {"grade": "S", "score": 95, "choice": "burn", "best": 95}}
	var code: String = Game._backup_code()
	var back: Dictionary = Game._backup_read(code)
	var bad: Dictionary = Game._backup_read(code.substr(0, 20) + ("A" if code[20] != "A" else "B") + code.substr(21))
	print("SET backup len=", code.length(), " ok=", back.get("done", {}).size() == 2, " tampered_rejected=", bad.is_empty())
	# 망가진 설정 값은 기본값으로
	var cs: Dictionary = Game._clean_settings({"sens": "fast", "volume": 7.0, "quality": "ultra", "bob": 1, "fov": 40})
	print("SET clean sens=", cs.sens, " volume=", cs.volume, " quality=", cs.quality, " bob=", cs.bob, " fov=", cs.fov)
	# 4장 열림: 3장 기록 없이 4장을 끝낸 기록
	Game.show_title()
	await _wait(0.3)
	print("SET unlocked ch3=", Game._unlocked(2), " ch4=", Game._unlocked(3), " ch5=", Game._unlocked(4))
	await _shot("title_unlock")
	Game.open_settings(3)
	await _wait(0.2)
	Game._backup_show()
	await _wait(0.3)
	await _shot("backup_code")
	Game.close_modal()
	await _wait(0.2)
	Game.open_help()
	await _wait(0.3)
	await _shot("help")
	Game.close_modal()
	var d := {"version": "9.9.9", "notes": ["시험용 알림"], "windows": "https://github.com/EunYool10/LastRoom/releases/download/v9.9.9/LastRoom-Setup-9.9.9.exe", "page": "https://eunyool10.github.io/LastRoom/"}
	Game._show_update(d)
	await _wait(0.4)
	await _shot("update_notice")
	get_tree().quit()


## 새 버전 받기: 확인값이 맞을 때만 실행 (--updatetest, 127.0.0.1:8767 에 시험 파일)
func update_test(o: String) -> void:
	out = o
	await _wait(0.8)
	var url := "http://127.0.0.1:8767/dummy.exe"
	var good := FileAccess.get_sha256(out.path_join("dummy.exe"))
	for case in [["good", good], ["bad", "0".repeat(64)]]:
		var d := {"version": "9.9.%d" % (1 if case[0] == "good" else 2), "windows": url, "sha256": {"windows": case[1]}}
		print("UPD case ", case[0])
		Game._download_installer(d)
		for i in range(80):
			await _wait(0.25)
			if not is_instance_valid(Game._upd_dl):
				break
		await _wait(1.2)
		Game.close_modal()
	print("UPD outside url:")
	Game._download_installer({"version": "9.9.3", "windows": "https://example.com/x.exe", "sha256": {"windows": good}})
	print("UPD no hash:")
	Game._download_installer({"version": "9.9.4", "windows": url})
	await _wait(0.3)
	get_tree().quit()


## 보관함 · 폐기 봉투 꺼내기 · 서랍 다시 닫기 (--invtest)
func inv_test(o: String) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(0.8)
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
	var keeps := []
	var trashes := []
	for it in room.items:
		if it.hidden:
			continue
		if it.def.kind == "trash" and trashes.size() < 3:
			trashes.append(it)
		elif it.def.kind == "keep" and keeps.size() < 3:
			keeps.append(it)
	room.sort_item(keeps[0], true)
	room.sort_item(trashes[0], true)
	room.sort_item(keeps[1], false)
	room.sort_item(trashes[1], false)
	room.sort_item(trashes[2], false)
	await _wait(0.6)
	print("INV kept=", room.kept_items().size(), " bag=", room.trashed_items().size(), " err=", Game.S.err)
	Game.open_inventory()
	await _wait(0.4)
	await _shot("inventory")
	Game.inv_sel = keeps[1].def.id
	Game.open_inventory(true)
	await _wait(0.3)
	await _shot("inventory_bag_selected")
	room.take_out(keeps[1])
	print("INV after bag take_out err=", Game.S.err, " state=", keeps[1].state, " visible=", keeps[1].root.visible)
	Game.close_modal()
	await _wait(0.3)
	Game.open_inventory()
	await _wait(0.2)
	Game.close_modal()
	# 서랍: 열기 → 닫기 → 다시 열기
	var dr = null
	for en in room.envs:
		if en.def.id == "drawer":
			dr = en
	var node: Node3D = room.find_child("deskDrawer", true, false)
	var z0: float = node.position.z
	room.use_env(dr)
	await _wait(1.0)
	var z1: float = node.position.z
	var letter = null
	for it in room.items:
		if it.def.id == dr.def.reveal:
			letter = it
	var shown1: bool = letter.root.visible
	room.use_env(dr)
	await _wait(1.0)
	var z2: float = node.position.z
	var shown2: bool = letter.root.visible
	room.use_env(dr)
	await _wait(1.0)
	print("INV drawer z %.2f -> open %.2f -> closed %.2f -> open %.2f; letter shown %s / closed %s / reopen %s; shape_on=%s" % [z0, z1, z2, node.position.z, shown1, shown2, letter.root.visible, not dr.shape.disabled])
	await _face(room, Vector3(dr.def.pos[0], dr.def.pos[1], dr.def.pos[2]), 1.0)
	await _wait(0.3)
	await _shot("drawer_open")
	get_tree().quit()


## 인트로 (--introtest)
func intro_test(o: String) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	for i in 6:
		await _wait(0.8)
		await _shot("intro_%d" % i)
	await _wait(2.6)
	await _shot("intro_cover_text")
	await _key(KEY_SPACE)
	await _wait(1.4)
	print("INTRO stage=", Game.stage)
	await _shot("intro_after")
	get_tree().quit()


## 3장 다이어리 · 2장 난로 살펴보기 (--looktest)
func look_test(o: String) -> void:
	out = o
	DirAccess.make_dir_recursive_absolute(out)
	await _wait(0.8)
	# 2장 연탄난로
	Game.show_brief(Game.EPISODES[1])
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
	await _face(room, Vector3(1.45, 0.4, -1.2), 1.3)
	await _wait(0.5)
	await _shot("ch2_stove")
	room.player.position = Vector3(0.2, 0, 0.6)
	room.yaw = atan2(-(1.45 - 0.2), -(-1.2 - 0.6))
	room.pitch = -0.25
	await _wait(0.5)
	await _shot("ch2_stove_far")
	# 3장 다이어리: 조사 단계에서 앞면 누르기
	Game.show_brief(Game.EPISODES[2])
	await _wait(0.3)
	Game.enter_room()
	for i in range(80):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	Game.hide_pause()
	await _wait(0.5)
	room = Game.world
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _face(room, Vector3(1.0, 0.85, 1.5), 1.2)
	await _wait(0.5)
	await _shot("ch3_kitchen")
	for it in room.items:
		if it.state != "gone":
			room.sort_item(it, it.def.kind != "trash")
	for s2 in room.stains:
		s2.done = true
		s2.progress = 1.0
	room.complete = true
	room.try_exit()
	await _wait(2.6)
	var ins = Game.world
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ins.select("diary")
	await _wait(1.0)
	await _shot("ch3_diary")
	print("LOOK read button visible=", ins.U.read.visible, " text=", ins.U.read.text)
	ins.U.read.pressed.emit()
	await _wait(0.4)
	print("LOOK read button modal=", Game.modal_open)
	await _shot("ch3_diary_read")
	Game.close_modal()
	await _wait(0.2)
	for sp in ins.cur.m.spots:
		var c: Vector3 = sp.body.global_position
		var sc: Vector2 = ins.cam.unproject_position(c)
		var picked = ins._pick(sc)
		print("LOOK diary spot ", sp.name, " screen=", sc, " pick=", picked.name if picked != null else "none", " facing=", ins.cam.global_position.direction_to(c).dot(-(sp.body.global_transform.basis * Vector3.UP).normalized()))
		if sp.name == "front":
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.position = _wp(sc)
			e.global_position = e.position
			e.pressed = true
			Input.parse_input_event(e)
			await get_tree().process_frame
			var r := InputEventMouseButton.new()
			r.button_index = MOUSE_BUTTON_LEFT
			r.position = _wp(sc)
			r.global_position = r.position
			r.pressed = false
			Input.parse_input_event(r)
			await _wait(0.5)
			print("LOOK diary click modal=", Game.modal_open)
			await _shot("ch3_diary_click")
			Game.close_modal()
			await _wait(0.2)
	# 메이크업 박스 이중 바닥: 열기 → 닫기 → 열기
	ins.select("mkbox")
	await _wait(0.6)
	for sp in ins.cur.m.spots:
		if sp.name == "bottom":
			ins._activate(sp)
			await _wait(1.0)
			var z1: float = ins.cur.m.res.drawer.position.z
			ins._activate(sp)
			await _wait(1.0)
			var z2: float = ins.cur.m.res.drawer.position.z
			ins._activate(sp)
			await _wait(1.0)
			print("LOOK false bottom z open %.2f closed %.2f reopen %.2f" % [z1, z2, ins.cur.m.res.drawer.position.z])
	# 4장 싱크대
	Game.show_brief(Game.EPISODES[3])
	await _wait(0.3)
	Game.enter_room()
	for i in range(80):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	Game.hide_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.5)
	await _face(Game.world, Vector3(0.85, 0.83, 1.55), 1.1)
	await _wait(0.5)
	await _shot("ch4_sink")
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
	Game.open_settings(4)
	await _wait(0.3)
	await _shot("settings_info")
	get_tree().quit()


## 물건마다 서서 · 숙여서 손이 닿는 자리에서 겨눌 수 있는지 (--reachtest, --ep=-1 이면 모든 장)
func reach_test(ei: int) -> void:
	await _wait(0.8)
	var eps: Array = [ei] if ei >= 0 else range(Game.EPISODES.size())
	for e in eps:
		Game.show_brief(Game.EPISODES[e])
		await _wait(0.2)
		Game.enter_room()
		for i in range(80):
			if Game.pause_root.visible:
				break
			await _wait(0.1)
		Game.hide_pause()
		await _wait(0.4)
		var room = Game.world
		for en in room.envs:
			if en.def.has("reveal"):
				room.use_env(en)
		await _wait(0.8)
		var space: PhysicsDirectSpaceState3D = room.get_world_3d().direct_space_state
		var cap := CapsuleShape3D.new()
		cap.radius = 0.27
		cap.height = 1.5
		var bodies := []
		for it in room.items:
			bodies.append(it.body.get_rid())
		var bad := []
		for it in room.items:
			if it.hidden or it.state != "idle":
				continue
			var c: Vector3 = it.shape.global_position
			var half: Vector3 = (it.shape.shape as BoxShape3D).size * 0.35
			var targets := [c]
			for sx in [-1, 1]:
				for sy in [-1, 1]:
					for sz in [-1, 1]:
						targets.append(it.shape.global_transform * Vector3(sx * half.x, sy * half.y, sz * half.z))
			var ex: Array[RID] = []
			for r in bodies:
				if r != it.body.get_rid():
					ex.append(r)
			var ok := false
			var x: float = -room.W / 2 + 0.28
			while x < room.W / 2 - 0.27 and not ok:
				var z: float = -room.D / 2 + 0.28
				while z < room.D / 2 - 0.27 and not ok:
					if Vector2(x - c.x, z - c.z).length() < 2.3:
						var qs := PhysicsShapeQueryParameters3D.new()
						qs.shape = cap
						qs.transform = Transform3D(Basis(), Vector3(x, 0.86, z))
						qs.collision_mask = 1
						if space.intersect_shape(qs, 1).is_empty():
							for eye in [room.eye, max(0.85, room.eye - 0.62)]:
								for tg in targets:
									var from := Vector3(x, eye, z)
									var to: Vector3 = from + (tg - from).normalized() * 3.2
									var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 2 | 4 | 16)
									q.exclude = ex
									var hit := space.intersect_ray(q)
									if not hit.is_empty() and hit.collider != it.body and not hit.collider.has_meta("ref"):
										var q2 := PhysicsRayQueryParameters3D.create(from, to, 2)
										q2.exclude = ex
										var h2 := space.intersect_ray(q2)
										if not h2.is_empty() and from.distance_to(h2.position) - from.distance_to(hit.position) < 0.08:
											hit = h2
									if not hit.is_empty() and hit.collider == it.body and from.distance_to(hit.position) < 2.4:
										ok = true
										break
								if ok:
									break
					z += 0.15
				x += 0.15
			if not ok:
				bad.append("%s %s (%.2f, %.2f, %.2f)" % [it.def.id, it.def.name, c.x, c.y, c.z])
		print("REACH ", Game.EPISODES[e].id, " items=", room.items.size(), " unreachable=", bad)
	get_tree().quit()


func _mouse(p: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = _wp(p)
	e.global_position = e.position
	e.pressed = pressed
	Input.parse_input_event(e)
	for i in 3:
		await get_tree().process_frame


func _mouse_move(p: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = _wp(p)
	e.global_position = e.position
	e.relative = rel
	Input.parse_input_event(e)
	for i in 2:
		await get_tree().process_frame


## 버튼 · 조사 · 집기가 씹히지 않는지 (--clicktest)
func click_test(o: String) -> void:
	out = o
	await _wait(1.0)
	# 1) 글자 버튼: 글자 오른쪽 12px 바깥을 눌러도 눌린다
	Game.open_settings(0)
	await _wait(0.4)
	var close_b: Button = null
	for b in Game.modal_root.find_children("*", "Button", true, false):
		if b.text == "닫기":
			close_b = b
	var r := close_b.get_global_rect()
	await _mouse(Vector2(r.end.x + 12, r.get_center().y), true)
	await _mouse(Vector2(r.end.x + 12, r.get_center().y), false)
	await _wait(0.4)
	print("CLICK text button 12px outside -> closed=", not Game.modal_open)
	# 2) 집기: 작은 물건에서 1.4° 비껴 겨눠도 잡힌다 (3장 포스트잇)
	Game.show_brief(Game.EPISODES[2])
	await _wait(0.3)
	Game.enter_room()
	for i in range(80):
		if Game.pause_root.visible:
			break
		await _wait(0.1)
	Game.hide_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.5)
	var room = Game.world
	var target = null
	for it in room.items:
		if it.def.id == "postit":
			target = it
	await _face(room, target.shape.global_position, 1.0)
	await _wait(0.2)
	room.player.rotation.y = room.yaw
	room.head.rotation.x = room.pitch
	room._raycast()
	var center_ok: bool = room.aim != null and room.aim.obj == target
	room.yaw += 0.025
	room.player.rotation.y = room.yaw
	room._raycast()
	var off_ok: bool = room.aim != null and room.aim.obj == target
	print("CLICK aim center=", center_ok, " offset 1.4deg=", off_ok)
	# 3) 조사: 누르는 사이 20px 움직여도 펼쳐진다 (다이어리 앞면)
	for it in room.items:
		if it.state != "gone":
			room.sort_item(it, it.def.kind != "trash")
	for s2 in room.stains:
		s2.done = true
		s2.progress = 1.0
	room.complete = true
	room.try_exit()
	await _wait(2.6)
	var ins = Game.world
	ins.select("diary")
	await _wait(1.0)
	var front = null
	for sp in ins.cur.m.spots:
		if sp.name == "front":
			front = sp
	var sc: Vector2 = ins.cam.unproject_position(front.body.global_position)
	# 사람이 짧게 누르는 것처럼: 누르기 → 두 번 움직임 → 떼기를 한 번에 보낸다
	for ev in [[sc, true, Vector2.ZERO], [sc + Vector2(8, 4), null, Vector2(8, 4)], [sc + Vector2(14, 8), null, Vector2(6, 4)], [sc + Vector2(14, 8), false, Vector2.ZERO]]:
		if ev[1] == null:
			var m := InputEventMouseMotion.new()
			m.position = _wp(ev[0])
			m.global_position = m.position
			m.relative = ev[2]
			Input.parse_input_event(m)
		else:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.position = _wp(ev[0])
			e.global_position = e.position
			e.pressed = ev[1]
			Input.parse_input_event(e)
	for i in 40:
		if Game.modal_open:
			break
		await _wait(0.05)
	print("CLICK inspect click with 22px jitter -> opened=", Game.modal_open, " spot_done=", Game.S.spots.has("diary:front"), " drag=", ins.drag, " pick_at_release=", ins._pick_near(sc + Vector2(14, 8)) != null)
	get_tree().quit()
