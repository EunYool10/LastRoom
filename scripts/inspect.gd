extends Node3D
## 2단계 — 작업실에서 유품을 돌려 보며 단서 찾기

const L_SPOT := 64

var ep: Dictionary
var S: Dictionary
var cam: Camera3D
var pivot: Node3D
var bench: MeshInstance3D
var env: WorldEnvironment
var L := {}
var models := {}
var cur = null
var uv := false
var drag = null
var vel := Vector2.ZERO
var zoom := 1.0
var dist := 1.0
var hover = null
var hint_t := 0.0
var uv_t := 0
var ui: CanvasLayer
var U := {}


func setup(e: Dictionary, state: Dictionary) -> void:
	ep = e
	S = state
	_build_world()
	_build_ui()
	refresh()
	var defs := _item_defs()
	var first = null
	for d in defs:
		if d.kind == "clue":
			first = d
			break
	if first == null and defs.size() > 0:
		first = defs[0]
	if first != null:
		select(first.id)
	_set_uv(false)


func _item_defs() -> Array:
	return ep.items.filter(func(d): return S.kept.has(d.id))


# ───────────────────────────── 작업실
func _build_world() -> void:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("0f0e0d")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("8a8070")
	e.ambient_light_energy = 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.ssao_enabled = true
	e.glow_enabled = true
	e.glow_intensity = 0.5
	e.glow_hdr_threshold = 1.5
	e.adjustment_enabled = true
	e.adjustment_saturation = 0.9
	e.adjustment_brightness = float(Game.settings.get("bright", 1.0))
	Game.apply_quality_env(e)
	env = WorldEnvironment.new()
	env.environment = e
	add_child(env)
	cam = Camera3D.new()
	cam.fov = 35.0
	cam.near = 0.005
	cam.far = 30.0
	add_child(cam)
	cam.current = true
	L.key = DirectionalLight3D.new()
	L.key.light_color = Color("fff1e0")
	L.key.light_energy = 1.25
	L.key.shadow_enabled = Game.settings.get("quality", "high") != "low"
	L.key.rotation = Vector3(deg_to_rad(-48), deg_to_rad(28), 0)
	add_child(L.key)
	L.fill = DirectionalLight3D.new()
	L.fill.light_color = Color("b8c8ff")
	L.fill.light_energy = 0.35
	L.fill.rotation = Vector3(deg_to_rad(-15), deg_to_rad(-60), 0)
	add_child(L.fill)
	L.rim = DirectionalLight3D.new()
	L.rim.light_energy = 0.55
	L.rim.rotation = Vector3(deg_to_rad(-25), deg_to_rad(180), 0)
	add_child(L.rim)
	L.uv = OmniLight3D.new()
	L.uv.light_color = Color("8a4dff")
	L.uv.light_energy = 0.0
	L.uv.omni_range = 8.0
	add_child(L.uv)
	var bm := Build.tmat("ui_bench", 0.7)
	bm.uv1_scale = Vector3(2, 2, 1)
	bench = Build.plane_up(self, 8.0, 8.0, bm)
	pivot = Node3D.new()
	add_child(pivot)


func _set_uv(on: bool) -> void:
	uv = on
	var e := env.environment
	if on:
		e.ambient_light_color = Color("5a2aa0")
		e.ambient_light_energy = 0.45
		L.key.light_color = Color("9a6bff")
		L.key.light_energy = 0.45
		L.fill.light_energy = 0.0
		L.rim.light_color = Color("5a2ad0")
		L.rim.light_energy = 0.35
		L.uv.light_energy = 1.2
	else:
		e.ambient_light_color = Color("8a8070")
		e.ambient_light_energy = 0.35
		L.key.light_color = Color("fff1e0")
		L.key.light_energy = 1.25
		L.fill.light_energy = 0.35
		L.rim.light_color = Color.WHITE
		L.rim.light_energy = 0.55
		L.uv.light_energy = 0.0
	for id in models:
		for u in models[id].res.get("uv", []):
			u.visible = on
	if U.has("uvb"):
		U.uvb.add_theme_color_override("font_color", Color("cdb8ff") if on else Ui.TEXT)
		if Game.touch:
			U.uvb.text = "UV 켜짐" if on else "UV 라이트"
			_tool_style(U.uvb, on)
		else:
			U.uvb.text = "U   UV 켜짐" if on else "U   UV 라이트"
	if U.has("uvnote"):
		U.uvnote.visible = on


func toggle_uv() -> void:
	if Time.get_ticks_msec() - uv_t < 300:
		return
	uv_t = Time.get_ticks_msec()
	_set_uv(not uv)
	Sfx.play("switch", 0.6)


# ───────────────────────────── 모델
func _model(d: Dictionary) -> Dictionary:
	if models.has(d.id):
		return models[d.id]
	var res := Build.item(d.model, d.get("p", {}))
	var holder := Node3D.new()
	var g: Node3D = res.g
	holder.add_child(g)
	var v: Vector3 = res.get("view", Vector3.ZERO)
	g.rotation = Vector3(deg_to_rad(v.x), deg_to_rad(v.y), deg_to_rad(v.z))
	pivot.add_child(holder)
	var a := _aabb(holder)
	g.position -= a.get_center()
	var mdim: float = max(a.size.x, max(a.size.y, a.size.z))
	var spots := []
	var defs: Dictionary = d.get("spots", {})
	var anchors: Dictionary = res.get("anchors", {})
	for name in defs:
		if not anchors.has(name):
			continue
		var an: Dictionary = anchors[name]
		var n: Vector3 = an.n.normalized()
		var body := StaticBody3D.new()
		body.collision_layer = L_SPOT
		body.collision_mask = 0
		var cs := CollisionShape3D.new()
		var cy := CylinderShape3D.new()
		cy.radius = an.r
		cy.height = 0.003
		cs.shape = cy
		body.add_child(cs)
		g.add_child(body)
		body.position = an.p + n * 0.002
		if n.dot(Vector3.UP) < -0.999:
			body.basis = Basis(Vector3.RIGHT, PI)
		elif n.dot(Vector3.UP) < 0.999:
			body.basis = Basis(Quaternion(Vector3.UP, n))
		var rm := TorusMesh.new()
		rm.inner_radius = an.r * 0.72
		rm.outer_radius = an.r
		rm.rings = 32
		rm.ring_segments = 4
		var rmat := StandardMaterial3D.new()
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.albedo_color = Color(1.0, 0.82, 0.48, 0.0)
		var ring := MeshInstance3D.new()
		ring.mesh = rm
		ring.material_override = rmat
		ring.scale = Vector3(1, 0.05, 1)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(ring)
		var sp := {"name": name, "def": defs[name], "item": d, "ring": rmat, "body": body, "n": n, "cs": cs}
		body.set_meta("spot", sp)
		spots.append(sp)
	for u in res.get("uv", []):
		u.visible = uv
	var m := {"res": res, "holder": holder, "spots": spots, "dim": mdim, "half": a.size.y / 2.0}
	if res.has("lid"):
		m.lid0 = res.lid.rotation.x
	if res.has("drawer"):
		m.drawer0 = res.drawer.position.z
	models[d.id] = m
	if S.opened.get(d.id, false) == true:
		_apply_opened(m, true)
	holder.visible = false
	return m


func _spots_on(m: Dictionary, on: bool) -> void:
	for sp in m.spots:
		sp.cs.disabled = not on


func _aabb(root: Node3D) -> AABB:
	var inv := root.global_transform.affine_inverse()
	var out := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.has_meta("uv_only"):
			continue
		var a: AABB = (inv * mi.global_transform) * mi.get_aabb()
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out


func _apply_opened(m: Dictionary, instant: bool) -> void:
	var res: Dictionary = m.res
	var dur := 0.01 if instant else 0.8
	if res.has("lid"):
		create_tween().tween_property(res.lid, "rotation:x", -1.9, dur).set_trans(Tween.TRANS_CUBIC)
	if res.has("drawer"):
		var dr: Node3D = res.drawer
		create_tween().tween_property(dr, "position:z", 0.1, dur).set_trans(Tween.TRANS_CUBIC)
		var fl := dr.find_child("fbLetter", true, false)
		if fl:
			fl.visible = true
	if res.has("unwrap"):
		res.unwrap.hide.visible = false
		res.unwrap.show.visible = true
	if res.has("screen_mat"):
		var lit: Texture2D = Build.tex(res.lit_tex)
		res.screen_mat.albedo_texture = lit
		res.screen_mat.emission_texture = lit


func select(id: String) -> void:
	var d = null
	for x in ep.items:
		if x.id == id:
			d = x
	if d == null:
		return
	if cur != null:
		cur.m.holder.visible = false
		_spots_on(cur.m, false)
	var m := _model(d)
	m.holder.visible = true
	_spots_on(m, true)
	cur = {"def": d, "m": m}
	pivot.basis = Basis()
	vel = Vector2.ZERO
	zoom = 1.0
	dist = m.dim / (2.0 * tan(deg_to_rad(cam.fov) / 2.0)) * 1.7
	bench.position.y = -m.half - 0.003
	U.name.text = d.name
	U.desc.text = d.get("desc", "")
	var main = _main_spot()
	U.read.visible = main != null
	if main != null:
		U.read.text = "펼쳐 읽기" if main.def.has("read") else "화면 켜기"
	_refresh_list()
	Sfx.play("ui", 0.4)


# ───────────────────────────── 단서
func _spot_clues(sd: Dictionary) -> Array:
	if sd.has("clue"):
		return [sd.clue]
	if sd.has("read") and ep.docs.has(sd.read) and ep.docs[sd.read].has("clue"):
		return [ep.docs[sd.read].clue]
	if sd.get("action", "") == "unwrap" and ep.has("unwrap") and ep.unwrap.has("clue"):
		return [ep.unwrap.clue]
	if sd.get("action", "") == "phone":
		var out := []
		for a in ep.phone.apps:
			if a.has("clue"):
				out.append(a.clue)
			for th in a.get("threads", []):
				if th.has("clue"):
					out.append(th.clue)
			for en in a.get("entries", []):
				if en is Dictionary and en.has("clue"):
					out.append(en.clue)
		return out
	return []


func _item_clues(d: Dictionary) -> Array:
	var out := []
	var sp: Dictionary = d.get("spots", {})
	for k in sp:
		for c in _spot_clues(sp[k]):
			if not ep.clues[c].get("hint", false):
				out.append(c)
	return out


func missing() -> int:
	var n := 0
	for k in ep.clues:
		if not ep.clues[k].get("hint", false) and not S.clues.has(k):
			n += 1
	return n


func has_letter() -> bool:
	return S.kept.has(ep.letter.item)


func refresh() -> void:
	_refresh_list()
	_refresh_notes()


func _refresh_list() -> void:
	if not U.has("list"):
		return
	Ui.clear(U.list)
	for d in _item_defs():
		var cl := _item_clues(d)
		var found := 0
		for c in cl:
			if S.clues.has(c):
				found += 1
		var tag := "마지막 물건" if d.get("final", false) else ("단서" if d.kind == "clue" else "유품")
		var prog := "—"
		if cl.size() > 0:
			prog = "조사 끝" if found == cl.size() else "단서 %d / %d" % [found, cl.size()]
		var on: bool = cur != null and cur.def.id == d.id
		var b := Button.new()
		b.text = "%s\n%s   ·   %s" % [d.name, tag, prog]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var nb := Ui.paper_box(on, 12)
		var hb := Ui.paper_box(true, 12)
		b.add_theme_stylebox_override("normal", nb)
		b.add_theme_stylebox_override("hover", hb)
		b.add_theme_stylebox_override("pressed", hb)
		b.add_theme_font_override("font", Ui.serif_b if on else Ui.serif)
		b.add_theme_font_size_override("font_size", 16)
		var col := Ui.RED if d.get("final", false) else Ui.INK
		b.add_theme_color_override("font_color", col)
		b.add_theme_color_override("font_hover_color", col)
		b.add_theme_color_override("font_pressed_color", col)
		var id: String = d.id
		b.pressed.connect(func(): select(id))
		U.list.add_child(b)
	var total := 0
	var got := 0
	for k in ep.clues:
		if not ep.clues[k].get("hint", false):
			total += 1
			if S.clues.has(k):
				got += 1
	U.count.text = "찾은 단서  %d / %d" % [got, total]


func _refresh_notes() -> void:
	if not U.has("notes"):
		return
	Ui.clear(U.notes)
	if S.clues.is_empty():
		U.notes.add_child(Ui.label("아직 적은 것이 없다.", 22, Ui.INK_DIM, Ui.hand))
		return
	for id in S.clues:
		var c: Dictionary = ep.clues[id]
		var hint: bool = c.get("hint", false)
		var t := Ui.label(("· " if hint else "") + c.t, 17, Ui.BLUE_INK if hint else Ui.INK, Ui.serif_b, true)
		var dd := Ui.label(c.d, 15, Ui.INK_DIM if hint else Color("4a4238"), Ui.serif, true)
		U.notes.add_child(t)
		U.notes.add_child(dd)
		U.notes.add_child(Ui.gap(6))
	await get_tree().process_frame
	if is_instance_valid(U.scroll):
		U.scroll.scroll_vertical = int(U.scroll.get_v_scroll_bar().max_value)


func _activate(sp: Dictionary) -> void:
	var sd: Dictionary = sp.def
	var item: Dictionary = sp.item
	if sd.get("uv", false) and not uv:
		Game.note(item.name, sd.get("plain", "눈으로는 아무것도 보이지 않는다."))
		Sfx.play("click", 0.6)
		return
	S.spots[item.id + ":" + sp.name] = true
	if sd.has("clue"):
		var c: Dictionary = ep.clues[sd.clue]
		Game.add_clue(sd.clue)
		Game.note(c.t, c.d)
	elif sd.has("read"):
		Game.open_doc(sd.read)
	elif sd.get("action", "") == "phone":
		if ep.phone.get("charge", false) and S.opened.get(item.id, false) != true:
			if S.opened.get(item.id, false) is String:
				Game.note(item.name, "충전 중이다. 화면이 켜지기를 기다린다.")
				return
			S.opened[item.id] = "charging"
			Game.note(item.name, "배터리가 0%다. 작업실 충전기에 꽂아 두었다.")
			Sfx.play("click", 0.6)
			var cm: Dictionary = cur.m
			get_tree().create_timer(3.5).timeout.connect(func():
				S.opened[item.id] = true
				_apply_opened(cm, true)
				Sfx.play("unlock", 0.6)
				Game.note(item.name, "화면이 켜졌다. 잠금은 걸려 있지 않다."))
			return
		Game.open_phone()
	elif sd.get("action", "") == "combo":
		if S.opened.has(item.id):
			_toggle_open(cur.m, item)
			return
		var m: Dictionary = cur.m
		Game.open_combo(str(ep.combo.code), func():
			S.opened[item.id] = true
			_apply_opened(m, false)
			Sfx.play("unlock", 0.8)
			for rid in ep.combo.reveal:
				if not S.kept.has(rid):
					S.kept.append(rid)
			get_tree().create_timer(0.7).timeout.connect(func():
				Game.note(item.name, ep.combo.msg)
				refresh()))
		return
	elif sd.get("action", "") == "unwrap":
		if S.opened.has(item.id):
			Game.note(item.name, "포장은 이미 풀었다.")
			return
		S.opened[item.id] = true
		_apply_opened(cur.m, false)
		Sfx.play("paper", 0.8)
		for rid in ep.unwrap.reveal:
			if not S.kept.has(rid):
				S.kept.append(rid)
		if ep.unwrap.has("clue"):
			Game.add_clue(ep.unwrap.clue)
		get_tree().create_timer(0.6).timeout.connect(func():
			Game.note(item.name, ep.unwrap.msg)
			refresh())
		return
	elif sd.get("action", "") == "false":
		if S.opened.has(item.id):
			_toggle_open(cur.m, item)
			return
		S.opened[item.id] = true
		_apply_opened(cur.m, false)
		Sfx.play("drawer", 0.8)
		for rid in ep.falseBottom.reveal:
			if not S.kept.has(rid):
				S.kept.append(rid)
		get_tree().create_timer(0.6).timeout.connect(func():
			Game.note(item.name, ep.falseBottom.msg)
			refresh())
		return
	elif sd.has("text"):
		Game.note(item.name, sd.text)
		Sfx.play("click", 0.6)
	refresh()


## 지금 물건에서 읽을 곳(글) 또는 켤 화면(휴대폰 · 노트북)
func _main_spot():
	if cur == null:
		return null
	for sp in cur.m.spots:
		if sp.def.has("read"):
			return sp
	for sp in cur.m.spots:
		if sp.def.get("action", "") == "phone":
			return sp
	return null


## 한 번 연 뚜껑 · 이중 바닥은 다시 닫고 열 수 있다
func _toggle_open(m: Dictionary, item: Dictionary) -> void:
	var res: Dictionary = m.res
	m.closed = not m.get("closed", false)
	var open: bool = not m.closed
	if res.has("lid"):
		create_tween().tween_property(res.lid, "rotation:x", -1.9 if open else float(m.get("lid0", 0.0)), 0.6).set_trans(Tween.TRANS_CUBIC)
		Sfx.play("click", 0.6)
		Game.note(item.name, "뚜껑을 열었다. 안은 붉은 천으로 덧대어져 있다." if open else "뚜껑을 닫았다.")
	elif res.has("drawer"):
		create_tween().tween_property(res.drawer, "position:z", 0.1 if open else float(m.get("drawer0", 0.0)), 0.6).set_trans(Tween.TRANS_CUBIC)
		Sfx.play("drawer", 0.6)
		Game.note(item.name, "이중 바닥을 열었다." if open else "이중 바닥을 닫았다.")


# ───────────────────────────── 입력
func _pick_near(mpos: Vector2):
	var sp = _pick(mpos)
	if sp != null:
		return sp
	for r in [16.0, 30.0]:
		for k in 8:
			var a := TAU * k / 8.0
			sp = _pick(mpos + Vector2(cos(a), sin(a)) * r)
			if sp != null:
				return sp
	return null


func _pick(mpos: Vector2):
	if cur == null:
		return null
	var from := cam.project_ray_origin(mpos)
	var dir := cam.project_ray_normal(mpos)
	var ex: Array[RID] = []
	for i in range(4):
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 30.0, L_SPOT)
		q.exclude = ex
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty():
			return null
		var sp: Dictionary = hit.collider.get_meta("spot")
		var nw: Vector3 = (sp.body.global_transform.basis * Vector3.UP).normalized()
		if nw.dot(-dir) > 0.12 and sp.item.id == cur.def.id:
			if sp.def.get("uv", false) and not uv and not sp.def.has("plain"):
				return null
			return sp
		ex.append(hit.rid)
	return null


var touches := {}


func _input(event: InputEvent) -> void:
	# 두 손가락으로 벌리고 오므려 확대 · 축소
	if not Game.touch or Game.modal_open:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
		else:
			touches.erase(event.index)
		if touches.size() >= 2:
			drag = null
	elif event is InputEventScreenDrag and touches.has(event.index):
		if touches.size() >= 2:
			var ks := touches.keys()
			var d0: float = touches[ks[0]].distance_to(touches[ks[1]])
			touches[event.index] = event.position
			var d1: float = touches[ks[0]].distance_to(touches[ks[1]])
			if d0 > 10.0:
				zoom = clamp(zoom * d1 / d0, 0.6, 2.8)
			drag = null
		else:
			touches[event.index] = event.position


func _unhandled_input(event: InputEvent) -> void:
	if Game.modal_open:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag = {"moved": 0.0, "t": Time.get_ticks_msec()}
			else:
				# 누르는 사이 손이 조금 떨려도 '누르기'로 본다 (짧게 누르면 더 너그럽게)
				var quick: bool = drag != null and Time.get_ticks_msec() - int(drag.t) < 300
				var limit := 28.0 if Game.touch else (34.0 if quick else 22.0)
				if drag != null and drag.moved < limit:
					var sp = _pick_near(event.position)
					if sp != null:
						_activate(sp)
					vel = Vector2.ZERO
				drag = null
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(zoom * 1.1, 0.6, 2.8)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom / 1.1, 0.6, 2.8)
	elif event is InputEventMouseMotion:
		if drag != null:
			var r: Vector2 = event.relative
			drag.moved += abs(r.x) + abs(r.y)
			# 조금 움직인 것(손 떨림)으로는 돌리지 않는다: 누르려던 곳이 비껴가지 않게
			if drag.moved > 10.0:
				_rotate(r * 0.009)
				vel = r * 0.009
		else:
			hover = _pick(event.position)
			U.tip.visible = hover != null
			if hover != null:
				U.tip.position = event.position + Vector2(16, -30)
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover != null else Input.CURSOR_ARROW)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_U: toggle_uv()
			KEY_H: hint()
			KEY_R: reset_view()


func _rotate(r: Vector2) -> void:
	pivot.global_rotate(Vector3.UP, r.x)
	pivot.global_rotate(Vector3.RIGHT, r.y)


func hint() -> void:
	hint_t = 2.6
	Sfx.play("ui", 0.5)


func reset_view() -> void:
	pivot.basis = Basis()
	vel = Vector2.ZERO
	zoom = 1.0


func _process(dt: float) -> void:
	S.t2 += dt
	if drag == null and vel.length() > 0.0005:
		_rotate(vel)
		vel *= 0.9
	var dd := dist / zoom
	cam.position = cam.position.lerp(Vector3(0, dd * 0.14, dd), min(1.0, dt * 8.0))
	cam.look_at(Vector3.ZERO)
	L.uv.position = cam.position
	hint_t = max(0.0, hint_t - dt)
	if cur != null:
		for sp in cur.m.spots:
			var done: bool = S.spots.has(sp.item.id + ":" + sp.name)
			var show: bool = hint_t > 0.0 and not done and (not sp.def.get("uv", false) or uv or sp.def.has("plain"))
			var a := 0.0
			if show:
				a = 0.5 + 0.4 * sin(hint_t * 9.0)
			elif hover != null and hover.body == sp.body:
				a = 0.35
			sp.ring.albedo_color.a = a


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


# ───────────────────────────── 화면
func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 8
	add_child(ui)
	var root := Control.new()
	Ui.full(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Ui.theme
	ui.add_child(root)
	var shade := ColorRect.new()
	Ui.full(shade)
	shade.color = Color(0, 0, 0, 0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	var tl := Ui.vbox(2)
	Ui.pin(tl, 0, 0, 30, 22)
	tl.add_child(Ui.shadow(Ui.label("2단계  유품 조사", 13, Ui.ACCENT, Ui.spaced)))
	tl.add_child(Ui.shadow(Ui.label("%d장 · %s" % [int(ep.no), ep.title], 23, Ui.TEXT, Ui.serif_b)))
	root.add_child(tl)
	var tr := Ui.hbox(28)
	Ui.pin(tr, 1, 0, -30, 26, -1, 1)
	var cnt := Ui.shadow(Ui.label("", 16, Ui.DIM, Ui.sans))
	tr.add_child(cnt)
	tr.add_child(Ui.button("나가기", 18, func(): Game.quit_to_title(), Ui.sans))
	var nx := Ui.button("사건 재구성으로  ▸", 20, func(): Game.go_board(), Ui.serif_b, Ui.ACCENT, Color("f1d6a8"))
	tr.add_child(nx)
	root.add_child(tr)
	U.count = cnt
	# 보관함
	var lp := Ui.panel(Ui.dark_box(0.0, 0, 0.0))
	lp.anchor_top = 0
	lp.anchor_bottom = 1
	lp.offset_left = 26
	lp.offset_top = 96
	lp.offset_right = 286
	lp.offset_bottom = -26
	var lv := Ui.vbox(10)
	lv.add_child(Ui.shadow(Ui.label("보관함", 15, Ui.ACCENT, Ui.spaced)))
	var ls := ScrollContainer.new()
	ls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := Ui.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls.add_child(list)
	lv.add_child(ls)
	lp.add_child(lv)
	root.add_child(lp)
	U.list = list
	# 사건 노트
	var rp := Ui.panel(Ui.paper_box(false, 24))
	rp.anchor_left = 1
	rp.anchor_right = 1
	rp.anchor_top = 0
	rp.anchor_bottom = 1
	rp.offset_left = -346
	rp.offset_right = -26
	rp.offset_top = 96
	rp.offset_bottom = -26
	var rv := Ui.vbox(8)
	rv.add_child(Ui.label("사건 노트", 34, Ui.BLUE_INK, Ui.hand))
	var rs := ScrollContainer.new()
	rs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var notes := Ui.vbox(3)
	notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(notes)
	rv.add_child(rs)
	rp.add_child(rv)
	root.add_child(rp)
	U.notes = notes
	U.scroll = rs
	# 물건 이름
	var head := Ui.vbox(6)
	head.custom_minimum_size = Vector2(560, 0)
	Ui.pin(head, 0.5, 0, 0, 92, 0, 1)
	var nm := Ui.shadow(Ui.label("", 30, Ui.TEXT, Ui.serif_b), 3)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ds := Ui.shadow(Ui.label("", 16, Color("bdb6aa"), Ui.sans, true))
	ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(nm)
	head.add_child(ds)
	# 읽을 수 있는 물건(다이어리 · 편지 · 쪽지)은 버튼으로도 바로 펼친다
	var rd := Ui.button("펼쳐 읽기", 18, func():
		var sp = _main_spot()
		if sp != null:
			_activate(sp), Ui.sans_b)
	_tool_style(rd, false)
	rd.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rd.visible = false
	head.add_child(rd)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(head)
	U.name = nm
	U.desc = ds
	U.read = rd
	# 도구
	var tb := Ui.hbox(18 if Game.touch else 30)
	Ui.pin(tb, 0.5, 1, 0, -70 if Game.touch else -58, 0, -1)
	var uvb: Button
	if Game.touch:
		uvb = Ui.button("UV 라이트", 22, toggle_uv, Ui.sans_b)
		tb.add_child(uvb)
		tb.add_child(Ui.button("단서 위치", 22, hint, Ui.sans_b))
		tb.add_child(Ui.button("정면으로", 22, reset_view, Ui.sans_b))
		for b in tb.get_children():
			_tool_style(b, false)
	else:
		uvb = Ui.button("U   UV 라이트", 18, toggle_uv, Ui.sans_b)
		tb.add_child(uvb)
		tb.add_child(Ui.button("H   단서 위치", 18, hint, Ui.sans_b))
		tb.add_child(Ui.button("R   정면으로", 18, reset_view, Ui.sans_b))
	root.add_child(tb)
	U.uvb = uvb
	var uvnote := Ui.shadow(Ui.label("UV 라이트 켜짐 — 보랏빛으로 드러난 흔적을 " + ("눌러" if Game.touch else "클릭해") + " 조사한다", 16, Color("cdb8ff"), Ui.sans_b), 3)
	Ui.pin(uvnote, 0.5, 0, 0, 178, 0, 1)
	uvnote.visible = false
	root.add_child(uvnote)
	U.uvnote = uvnote
	var help := Ui.shadow(Ui.label("끌어서 돌려 보기   ·   두 손가락으로 확대   ·   수상한 곳을 누르기" if Game.touch else "끌어서 돌려 보기   ·   휠로 확대   ·   수상한 곳을 클릭", 14, Color(1, 1, 1, 0.42), Ui.sans))
	Ui.pin(help, 0.5, 1, 0, -26, 0, -1)
	root.add_child(help)
	var tip := Ui.label("조사하기", 14, Ui.INK, Ui.sans_b)
	var tipp := Ui.panel(Ui.paper_box(false, 6))
	tipp.add_child(tip)
	tipp.visible = false
	tipp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tipp)
	U.tip = tipp


func _tool_style(b: Button, on: bool) -> void:
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.36, 0.2, 0.62, 0.55) if on else Color(0, 0, 0, 0.5)
		sb.border_color = Color("cdb8ff") if on else Color(1, 1, 1, 0.28)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 26
		sb.content_margin_right = 26
		sb.content_margin_top = 14
		sb.content_margin_bottom = 12
		b.add_theme_stylebox_override(st, sb)
	b.flat = false
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(170, 62)
