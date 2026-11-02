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
	if not full:
		get_tree().quit()
		return
	for k in E.clues:
		if not Game.S.clues.has(k):
			Game.S.clues.append(k)
	Game.go_board()
	await _wait(2.4)
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
