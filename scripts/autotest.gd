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


func _press(root: Node, contains: String) -> bool:
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
