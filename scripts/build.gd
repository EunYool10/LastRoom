class_name Build
extends RefCounted
## 가구 · 유품 3D 모델 (기본 도형 + 구운 텍스처)

const DEG := PI / 180.0
static var _mats := {}
static var _tex := {}


static func col(hex: int) -> Color:
	return Color.hex((hex << 8) | 0xff)


static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load("res://assets/tex/%s.png" % name)
	return _tex[name]


static func _apply(m: StandardMaterial3D, extra: Dictionary) -> void:
	for k in extra:
		match k:
			"alpha":
				m.albedo_color.a = extra[k]
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			"emit":
				m.emission_enabled = true
				m.emission = col(extra[k])
			"emit_e":
				m.emission_energy_multiplier = extra[k]
			"emit_tex":
				m.emission_enabled = true
				m.emission = Color.WHITE
				m.emission_texture = m.albedo_texture
			"unshaded":
				m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			"add":
				m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
				m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			"cull_off":
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
			"alpha_tex":
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_:
				m.set(k, extra[k])


static func mat(hex: int, rough := 0.8, metal := 0.0, extra := {}) -> StandardMaterial3D:
	var key := "%x|%s|%s|%s" % [hex, rough, metal, str(extra)]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col(hex)
	m.roughness = rough
	m.metallic = metal
	_apply(m, extra)
	_mats[key] = m
	return m


static func tmat(name: String, rough := 0.8, extra := {}) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(name)
	m.roughness = rough
	_apply(m, extra)
	return m


static func node(parent: Node, pos := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	if parent:
		parent.add_child(n)
	return n


static func mi(parent: Node, mesh: Mesh, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = m
	n.position = pos
	parent.add_child(n)
	return n


static func box(parent: Node, size: Vector3, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return mi(parent, bm, m, pos)


static func cyl(parent: Node, rt: float, rb: float, h: float, m: Material, pos := Vector3.ZERO, seg := 24) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return mi(parent, c, m, pos)


static func sph(parent: Node, r: float, m: Material, pos := Vector3.ZERO, seg := 16) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = max(4, seg / 2)
	return mi(parent, s, m, pos)


## XY 평면에 놓인 고리 (앞면 +Z)
static func ring(parent: Node, r: float, tube: float, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = r - tube
	t.outer_radius = r + tube
	t.rings = 40
	t.ring_segments = 10
	var n := mi(parent, t, m, pos)
	n.rotation.x = PI / 2.0
	return n


## a에서 b까지 잇는 가는 원통 (다리 · 버팀대 · 전선)
static func rod(parent: Node, a: Vector3, b: Vector3, r: float, m: Material, seg := 8) -> MeshInstance3D:
	var n := cyl(parent, r, r, a.distance_to(b), m, (a + b) / 2.0, seg)
	var y := (b - a).normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	n.basis = Basis(x, y, x.cross(y))
	return n


## 모서리가 둥근 상자: 잘게 나눈 상자의 점을 가장자리 쪽으로 몰고, 안쪽 상자 둘레로 둥글게 민다
static func soft_box(parent: Node, size: Vector3, rad: float, m: Material, pos := Vector3.ZERO, sub := Vector3i(12, 4, 16)) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	bm.subdivide_width = sub.x
	bm.subdivide_height = sub.y
	bm.subdivide_depth = sub.z
	var h := size / 2.0
	var inner := (h - Vector3.ONE * rad).max(Vector3.ZERO)
	var mesh := deformed(bm, func(v):
		var q := Vector3(signf(v.x) * pow(absf(v.x) / h.x, 0.3) * h.x, signf(v.y) * pow(absf(v.y) / h.y, 0.3) * h.y, signf(v.z) * pow(absf(v.z) / h.z, 0.3) * h.z)
		var c := q.clamp(-inner, inner)
		var dv := q - c
		return c + dv.normalized() * rad if dv.length() > 0.00001 else q)
	return mi(parent, mesh, m, pos)


## +Z를 향한 사각 판
static func quad(parent: Node, w: float, h: float, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	return mi(parent, q, m, pos)


## +Y를 향한 판 (텍스처 위쪽이 -Z)
static func plane_up(parent: Node, w: float, d: float, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var p := PlaneMesh.new()
	p.size = Vector2(w, d)
	return mi(parent, p, m, pos)


## -Y를 향한 판 (위아래로 뒤집으면 바로 읽힘)
static func plane_down(parent: Node, w: float, d: float, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var n := plane_up(parent, w, d, m, pos)
	n.rotation.x = PI
	return n


## 원통 둘레 라벨 (u=0.25 지점이 +Z 정면, u=0.75가 뒷면)
static func band(parent: Node, r: float, h: float, m: Material, y: float, seg := 36) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(seg):
		var u0 := float(i) / seg
		var u1 := float(i + 1) / seg
		var a0 := (u0 - 0.25) * TAU
		var a1 := (u1 - 0.25) * TAU
		var n0 := Vector3(sin(a0), 0, cos(a0))
		var n1 := Vector3(sin(a1), 0, cos(a1))
		var tl := n0 * r + Vector3(0, h / 2, 0)
		var tr := n1 * r + Vector3(0, h / 2, 0)
		var br := n1 * r - Vector3(0, h / 2, 0)
		var bl := n0 * r - Vector3(0, h / 2, 0)
		for v in [[tl, n0, Vector2(u0, 0)], [tr, n1, Vector2(u1, 0)], [br, n1, Vector2(u1, 1)], [tl, n0, Vector2(u0, 0)], [br, n1, Vector2(u1, 1)], [bl, n0, Vector2(u0, 1)]]:
			st.set_normal(v[1])
			st.set_uv(v[2])
			st.add_vertex(v[0])
	return mi(parent, st.commit(), m, Vector3(0, y, 0))


static func hash3(v: Vector3) -> float:
	var s := sin(v.x * 127.1 + v.y * 311.7 + v.z * 74.7) * 43758.5453
	return s - floor(s)


static func deformed(prim: PrimitiveMesh, f: Callable, flat := false) -> ArrayMesh:
	var arr := prim.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] = f.call(verts[i])
	arr[Mesh.ARRAY_VERTEX] = verts
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var st := SurfaceTool.new()
	st.create_from(am, 0)
	if flat:
		st.deindex()
	st.generate_normals()
	return st.commit()


## 얇은 판 (앞/뒤 텍스처) — 앞면 +Y, 원점은 바닥 중앙
static func flat(parent: Node, w: float, d: float, t: float, front: String, back: String, side := 0xe8e2d4) -> Dictionary:
	var g := node(parent)
	box(g, Vector3(w, t, d), mat(side, 0.9), Vector3(0, t / 2, 0))
	plane_up(g, w, d, tmat(front, 0.85), Vector3(0, t + 0.0004, 0))
	if back != "":
		plane_down(g, w, d, tmat(back, 0.85), Vector3(0, -0.0004, 0))
	var r: float = min(w, d) * 0.4
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"front": {"p": Vector3(0, t, 0), "n": Vector3.UP, "r": r},
		"back": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": r}}}


static func uv_decal(res: Dictionary, w: float, d: float, texname: String, pos: Vector3, down: bool) -> void:
	var m := tmat(texname, 1.0, {"add": true})
	var n := plane_down(res.g, w, d, m, pos) if down else plane_up(res.g, w, d, m, pos)
	n.visible = false
	n.set_meta("uv_only", true)
	if not res.has("uv"):
		res["uv"] = []
	res["uv"].append(n)


# ───────────────────────────── 가구
static func furniture(t: String, p: Dictionary) -> Dictionary:
	match t:
		"bed": return _bed(p)
		"desk": return _desk(p)
		"chair": return _chair(p)
		"fridge": return _fridge(p)
		"wardrobe": return _wardrobe(p)
		"lowTable": return _low_table()
		"stove": return _stove()
		"tvCabinet": return _tv()
		"futons": return _futons()
		"mat": return _emat(p)
		"sink": return _sink(p)
		"kitchen": return _kitchen(p)
		"boiler": return _boiler()
		"window": return _window(p)
		"fluoro": return _fluoro()
		"bulb": return _bulb()
		"ringLight": return _ring_light()
		"vanity": return _vanity(p)
		"rack": return _rack(p)
		"ledSign": return _led()
		"bigMirror": return _big_mirror()
		"nightstand": return _nightstand(p)
		"pinkChair": return _pink_chair()
		"wallShelf": return _wall_shelf(p)
		"rail": return _rail(p)
		"plug": return _plug()
		"doorlock": return _doorlock()
		"boilerRoom": return _boiler_room()
		"suitcase": return _suitcase()
		"pcDesk": return _pc_desk(p)
		"gamingChair": return _gaming_chair()
		"bookshelf": return _bookshelf(p)
		"aircon": return _aircon()
		"fan": return _fan()
		"trays": return _trays()
	push_warning("unknown furniture " + t)
	return {"g": node(null)}


static func _bed(p: Dictionary) -> Dictionary:
	if p.get("style", "") == "premium":
		return _bed_premium(p)
	var g := node(null)
	var w: float = p.get("w", 0.9)
	var d: float = p.get("d", 1.9)
	var fm := mat(int(p.get("frame", 0x5a4434)), 0.7)
	box(g, Vector3(w, 0.25, d), fm, Vector3(0, 0.125, 0))
	box(g, Vector3(w - 0.04, 0.18, d - 0.04), mat(int(p.get("sheet", 0xd9d3c7)), 1.0), Vector3(0, 0.34, 0))
	var bl := BoxMesh.new()
	bl.size = Vector3(w - 0.02, 0.07, d * 0.66)
	bl.subdivide_width = 6
	bl.subdivide_depth = 8
	var bmesh := deformed(bl, func(v): return Vector3(v.x, v.y + (hash3(Vector3(v.x * 6, 1, v.z * 6)) - 0.5) * 0.05 + (0.01 if v.y > 0 else 0.0), v.z))
	var bn := mi(g, bmesh, tmat(p.get("blanket_tex", "blanket_e1"), 1.0), Vector3(0, 0.465, d * 0.15))
	bn.rotation.y = 0.03
	box(g, Vector3(w * 0.62, 0.1, 0.34), mat(int(p.get("pillow", 0xe8e2d6)), 1.0), Vector3(0, 0.48, -d / 2 + 0.25))
	box(g, Vector3(w, 0.55, 0.05), fm, Vector3(0, 0.52, -d / 2 + 0.025))
	return {"g": g, "foot": Vector2(w, d)}


## 3장 침대 (p.style == "premium"): 천을 씌운 받침 · 모서리가 둥근 매트리스 · 양옆과 발치로 처지는 이불 ·
## 이불 위로 접어 올린 시트 · 베개 둘과 기대 세운 쿠션 · 세로 줄 머리판 · 발치에 걸친 담요.
## 높이는 다른 침대와 같다 (매트리스 윗면 0.43, 이불 윗면 약 0.5 — 그 위에 놓인 물건들 때문)
static func _bed_premium(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.3)
	var d: float = p.get("d", 2.0)
	var fabric := mat(int(p.get("frame", 0xf1ebe5)), 1.0)
	var velvet := mat(int(p.get("head", 0xc9b5ab)), 1.0, 0.0, {"rim_enabled": true, "rim": 0.35, "rim_tint": 0.6})
	var sheet := mat(int(p.get("sheet", 0xffffff)), 1.0)
	box(g, Vector3(w - 0.12, 0.06, d - 0.12), mat(0x15120f, 0.9), Vector3(0, 0.03, 0))
	soft_box(g, Vector3(w, 0.17, d), 0.03, fabric, Vector3(0, 0.145, 0), Vector3i(20, 4, 28))
	soft_box(g, Vector3(w - 0.03, 0.2, d - 0.03), 0.045, sheet, Vector3(0, 0.33, 0), Vector3i(24, 6, 32))
	# 이불 · 접어 올린 시트 · 담요는 모두 매트리스 모서리 위 같은 곳(높이 0.38)을 중심으로 돌아 내려간다
	var e := w / 2.0 - 0.06
	var soft: bool = p.get("pattern", "") == "fluffy"
	_cloth(g, tmat(p.get("blanket_tex", "blanket_e1"), 1.0), e, 0.465, 0.07, -0.36, d / 2.0 - 0.06, 0.26, true, 0.016 if soft else 0.012, 1.0)
	_cloth(g, sheet, e, 0.532, 0.03, -0.36, -0.15, 0.3, false, 0.004, 2.0)
	var tm := mat(int(p.get("throw", 0xb59aa4)), 1.0, 0.0, {"rim_enabled": true, "rim": 0.3, "rim_tint": 0.5})
	_cloth(g, tm, e, 0.53, 0.022, 0.52, 0.88, 0.3, false, 0.004, 3.0)
	# 베개 둘: 바닥은 평평하고 위가 부풀었다. 머리판 쪽으로 살짝 기대 있다
	var pmesh := _puff(Vector3(0.58, 0.14, 0.38), true)
	var pm := mat(int(p.get("pillow", 0xffffff)), 0.9)
	var pz := -d / 2.0 + 0.25
	for sx in [-1, 1]:
		var pn := mi(g, pmesh, pm, Vector3(sx * 0.305, 0.5, pz))
		pn.rotation = Vector3(0.08, sx * 0.035, 0)
	# 베개 앞에 기대 세운 네모 쿠션
	var cu := mi(g, _puff(Vector3(0.36, 0.13, 0.36), false), mat(int(p.get("cushion", 0xc79aa8)), 1.0, 0.0, {"rim_enabled": true, "rim": 0.35, "rim_tint": 0.6}), Vector3(-0.08, 0.6, -0.5))
	cu.rotation = Vector3(PI / 2.0 - 0.35, 0.06, 0)
	# 머리판: 받침판 앞에 세로로 누빈 줄 (창대 아래 0.8까지)
	var hw := w + 0.06
	soft_box(g, Vector3(hw, 0.7, 0.05), 0.015, velvet, Vector3(0, 0.43, -d / 2.0 + 0.005), Vector3i(8, 6, 2))
	var n := int(round(hw / 0.1))
	var step := hw / n
	var cap := CapsuleMesh.new()
	cap.radius = step / 2.0
	cap.height = 0.5
	cap.radial_segments = 14
	cap.rings = 6
	for i in n:
		var c := mi(g, cap, velvet, Vector3(-hw / 2.0 + step * (i + 0.5), 0.55, -d / 2.0 + 0.035))
		c.scale = Vector3(1, 1, 0.6)
	return {"g": g, "foot": Vector2(w, d)}


## 천 위의 한 점: 가운데서 s만큼, 두께 방향으로 t만큼. e까지는 평평하고, 그 뒤로는 (e, -r)을 중심으로
## 반지름 r만큼 돌아 곧게 내려간다. (가로, 세로)를 돌려준다
static func _bend(s: float, t: float, e: float, r: float) -> Vector2:
	var a := absf(s)
	if a <= e:
		return Vector2(s, t)
	var sg := signf(s)
	var u := a - e
	var arc := r * PI / 2.0
	if u <= arc:
		var th := u / r
		return Vector2(sg * (e + (r + t) * sin(th)), -r + (r + t) * cos(th))
	return Vector2(sg * (e + r + t), -r - (u - arc))


## 침대 위에 덮은 천 한 장 (y: 가운데 면 높이, th: 두께, z0~z1: 평평한 구간).
## 양옆은 e에서 꺾여 bottom 높이까지 처지고, foot이면 z1에서 발치로도 처진다. 꺾이는 중심은 높이 0.38
static func _cloth(g: Node3D, m: Material, e: float, y: float, th: float, z0: float, z1: float, bottom: float, foot: bool, wrinkle: float, sd: float) -> MeshInstance3D:
	var cy := 0.38
	var r := y - cy
	var um := r * PI / 2.0 + maxf(0.0, cy - bottom)
	var low := bottom - y - 0.04
	var bm := BoxMesh.new()
	bm.size = Vector3(2.0, th, 1.0)
	bm.subdivide_width = 40
	bm.subdivide_height = 1
	bm.subdivide_depth = 40 if foot else 12
	var mesh := deformed(bm, func(v):
		# 꺾이는 곳에 점이 많이 가도록: 상자의 절반은 평평한 곳, 나머지 절반은 처지는 곳
		var aq: float = absf(v.x)
		var s: float = signf(v.x) * (aq / 0.5 * e if aq <= 0.5 else e + (aq - 0.5) / 0.5 * um)
		var pz: float = v.z + 0.5
		var zb: float = z0 + pz * (z1 - z0)
		if foot:
			zb = z0 + pz / 0.7 * (z1 - z0) if pz <= 0.7 else z1 + (pz - 0.7) / 0.3 * um
		var t: float = v.y
		if wrinkle > 0.0:
			var k: float = (1.0 - smoothstep(e - 0.12, e, absf(s))) * (1.0 - smoothstep(z1 - 0.12, z1, zb) if foot else 1.0)
			t += ((hash3(Vector3(s * 6.0, sd, zb * 6.0)) - 0.5) * wrinkle + sin(zb * 9.0 + s * 3.0 + sd) * wrinkle * 0.3) * k
		var bx := _bend(s, t, e, r)
		var py := bx.y
		var pzz := zb
		if foot and zb > z1:
			var bz := _bend(zb, t, z1, r)
			pzz = bz.x
			py = maxf(bx.y + bz.y - t, low)
		return Vector3(bx.x, py, pzz))
	return mi(g, mesh, m, Vector3(0, y, 0))


## 부푼 베개 · 쿠션: 가운데가 두툼하고 박음선 쪽은 얇으며, 네 귀가 살짝 뾰족하다.
## 두께는 y 방향. flat이면 바닥은 평평하고 위만 부푼다
static func _puff(size: Vector3, flat_bottom: bool) -> ArrayMesh:
	var bm := BoxMesh.new()
	bm.size = size
	bm.subdivide_width = 12
	bm.subdivide_height = 1
	bm.subdivide_depth = 10
	var hx := size.x / 2.0
	var hy := size.y / 2.0
	var hz := size.z / 2.0
	return deformed(bm, func(v):
		var ux: float = absf(v.x) / hx
		var uz: float = absf(v.z) / hz
		var f: float = maxf(0.1, (1.0 - pow(ux, 2.4)) * (1.0 - pow(uz, 2.4)))
		var y: float = -hy + (v.y + hy) * f if flat_bottom else v.y * f
		return Vector3(v.x * (1.0 - 0.07 * (1.0 - uz * uz)), y, v.z * (1.0 - 0.07 * (1.0 - ux * ux))))


static func _desk(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.1)
	var d: float = p.get("d", 0.55)
	var h: float = p.get("h", 0.74)
	var m := mat(0x8a6f52, 0.6)
	var m2 := mat(0x6e5640, 0.7)
	box(g, Vector3(w, 0.03, d), m, Vector3(0, h - 0.015, 0))
	box(g, Vector3(0.03, h - 0.03, d), m2, Vector3(-w / 2 + 0.015, (h - 0.03) / 2, 0))
	box(g, Vector3(0.03, h - 0.03, d), m2, Vector3(w / 2 - 0.015, (h - 0.03) / 2, 0))
	box(g, Vector3(w - 0.06, h * 0.55, 0.02), m2, Vector3(0, h * 0.62, -d / 2 + 0.01))
	var dr := node(g, Vector3(w * 0.22, h - 0.1, 0))
	dr.name = "deskDrawer"
	box(dr, Vector3(0.42, 0.11, 0.02), m, Vector3(0, 0, d / 2 - 0.01))
	box(dr, Vector3(0.4, 0.015, d - 0.06), m2, Vector3(0, -0.045, 0))
	box(dr, Vector3(0.015, 0.09, d - 0.06), m2, Vector3(-0.195, 0, 0))
	box(dr, Vector3(0.015, 0.09, d - 0.06), m2, Vector3(0.195, 0, 0))
	box(dr, Vector3(0.09, 0.015, 0.015), mat(0xbab6ae, 0.3, 0.6), Vector3(0, 0, d / 2 + 0.008))
	box(g, Vector3(w - 0.06, 0.015, d - 0.02), m2, Vector3(0, h - 0.16, 0))
	if p.get("shelf", false):
		for y in [1.3, 1.62]:
			box(g, Vector3(w, 0.025, 0.24), m, Vector3(0, y, -d / 2 + 0.12))
			box(g, Vector3(0.02, 0.1, 0.2), m2, Vector3(-w / 2 + 0.05, y - 0.06, -d / 2 + 0.11))
			box(g, Vector3(0.02, 0.1, 0.2), m2, Vector3(w / 2 - 0.05, y - 0.06, -d / 2 + 0.11))
	return {"g": g, "foot": Vector2(w, d)}


static func _chair(p: Dictionary) -> Dictionary:
	var g := node(null)
	var m := mat(int(p.get("color", 0x2b2d31)), 0.6)
	var leg := mat(0x777777, 0.4, 0.6)
	box(g, Vector3(0.42, 0.05, 0.42), m, Vector3(0, 0.45, 0))
	box(g, Vector3(0.42, 0.38, 0.04), m, Vector3(0, 0.7, 0.19))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			cyl(g, 0.012, 0.012, 0.43, leg, Vector3(sx * 0.18, 0.215, sz * 0.18), 8)
	return {"g": g, "foot": Vector2(0.42, 0.42)}


static func _fridge(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w := 0.46
	var d := 0.46
	var h := 0.84
	box(g, Vector3(w, h, d), mat(0xdedcd6, 0.4), Vector3(0, h / 2, 0))
	box(g, Vector3(w * 0.96, 0.006, 0.005), mat(0x999999), Vector3(0, h * 0.7, d / 2 + 0.002))
	box(g, Vector3(0.02, 0.18, 0.02), mat(0xaaaaaa, 0.5, 0.5), Vector3(w / 2 - 0.05, h * 0.55, d / 2 + 0.012))
	return {"g": g, "foot": Vector2(w, d)}


static func _wardrobe(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.3)
	var d: float = p.get("d", 0.58)
	var h := 1.85
	var lac := mat(0x1a110e, 0.28)
	var inner := mat(0x2a1d16, 0.9)
	box(g, Vector3(w, 0.04, d), lac, Vector3(0, h - 0.02, 0))
	box(g, Vector3(w, 0.1, d), lac, Vector3(0, 0.05, 0))
	box(g, Vector3(0.03, h, d), lac, Vector3(-w / 2 + 0.015, h / 2, 0))
	box(g, Vector3(0.03, h, d), lac, Vector3(w / 2 - 0.015, h / 2, 0))
	box(g, Vector3(w, h, 0.02), inner, Vector3(0, h / 2, -d / 2 + 0.01))
	box(g, Vector3(w - 0.06, 0.025, d - 0.04), inner, Vector3(0, 0.72, 0))
	box(g, Vector3(w - 0.06, 0.025, d - 0.04), inner, Vector3(0, 1.25, 0))
	box(g, Vector3(w * 0.42, 0.22, d * 0.7), mat(0x9b4a5a, 1.0), Vector3(w * 0.2, 1.37, 0))
	box(g, Vector3(w * 0.42, 0.18, d * 0.7), mat(0x3f5f8a, 1.0), Vector3(w * 0.2, 1.57, 0))
	box(g, Vector3(w * 0.4, 0.3, d * 0.7), mat(0x3f5f8a, 1.0), Vector3(w * 0.22, 0.9, 0))
	var nm: String = p.get("name", "wardrobe")
	var face := tmat("najeon_ward", 0.25)
	var brass := mat(0xc9a75a, 0.3, 0.7)
	var dw := w / 2 - 0.03
	for side in [-1, 1]:
		var pv := node(g, Vector3(side * (w / 2 - 0.03), 0, d / 2))
		pv.name = nm + ("L" if side < 0 else "R")
		var c: float = -side * dw / 2
		box(pv, Vector3(dw, h - 0.16, 0.025), lac, Vector3(c, h / 2 + 0.03, 0.0125))
		quad(pv, dw - 0.01, h - 0.17, face, Vector3(c, h / 2 + 0.03, 0.0256))
		box(pv, Vector3(0.02, 0.14, 0.02), brass, Vector3(-side * (dw - 0.04), h / 2, 0.035))
	return {"g": g, "foot": Vector2(w, d)}


static func _low_table() -> Dictionary:
	var g := node(null)
	var m := mat(0x7a4f2c, 0.45)
	cyl(g, 0.33, 0.33, 0.03, m, Vector3(0, 0.285, 0), 32)
	for i in range(4):
		var a := i / 4.0 * TAU + 0.78
		box(g, Vector3(0.03, 0.27, 0.03), m, Vector3(cos(a) * 0.22, 0.135, sin(a) * 0.22))
	return {"g": g, "foot": Vector2(0.62, 0.62)}


## 연탄난로: 쇠 몸통 · 띠 · 다리 · 뚜껑 · 재받이, 연통은 위로 올라가 꺾여서 벽 속으로 들어간다
static func _stove() -> Dictionary:
	var g := node(null)
	var iron := mat(0x2e2b29, 0.55, 0.45)
	var band := mat(0x5a544d, 0.4, 0.6)
	var rust := mat(0x5b3a26, 0.85, 0.2)
	var pipe_m := mat(0x3b3936, 0.5, 0.5)
	cyl(g, 0.205, 0.215, 0.48, iron, Vector3(0, 0.3, 0), 32)
	cyl(g, 0.222, 0.222, 0.03, band, Vector3(0, 0.08, 0), 32)
	cyl(g, 0.219, 0.219, 0.025, band, Vector3(0, 0.51, 0), 32)
	for i in 3:
		var a := TAU * i / 3.0 + 0.5
		cyl(g, 0.018, 0.022, 0.06, iron, Vector3(cos(a) * 0.16, 0.03, sin(a) * 0.16), 8)
	cyl(g, 0.24, 0.24, 0.025, iron, Vector3(0, 0.55, 0), 32)
	cyl(g, 0.115, 0.12, 0.02, band, Vector3(0, 0.572, 0.03), 24)
	box(g, Vector3(0.08, 0.015, 0.018), mat(0x1c1a19, 0.6, 0.3), Vector3(0, 0.59, 0.03))
	box(g, Vector3(0.2, 0.08, 0.05), rust, Vector3(0, 0.15, 0.205))
	box(g, Vector3(0.07, 0.012, 0.02), band, Vector3(0, 0.15, 0.24))
	cyl(g, 0.045, 0.045, 1.2, pipe_m, Vector3(0, 1.16, -0.12), 16)
	sph(g, 0.047, pipe_m, Vector3(0, 1.76, -0.12), 16)
	var hp := cyl(g, 0.045, 0.045, 0.32, pipe_m, Vector3(0, 1.76, -0.28), 16)
	hp.rotation.x = PI / 2
	var collar := cyl(g, 0.075, 0.075, 0.01, band, Vector3(0, 1.76, -0.392), 24)
	collar.rotation.x = PI / 2
	return {"g": g, "foot": Vector2(0.48, 0.48)}


static func _tv() -> Dictionary:
	var g := node(null)
	var wood := mat(0x6b4a30, 0.5)
	box(g, Vector3(1.0, 0.45, 0.42), wood, Vector3(0, 0.225, 0))
	box(g, Vector3(0.46, 0.006, 0.005), mat(0x3a2818), Vector3(-0.24, 0.3, 0.212))
	box(g, Vector3(0.46, 0.006, 0.005), mat(0x3a2818), Vector3(0.24, 0.3, 0.212))
	box(g, Vector3(0.5, 0.4, 0.42), mat(0x2b2a29, 0.5), Vector3(-0.18, 0.65, -0.02))
	quad(g, 0.38, 0.3, tmat("tv_screen", 0.15), Vector3(-0.2, 0.66, 0.192))
	box(g, Vector3(0.04, 0.04, 0.02), mat(0x888888), Vector3(0.02, 0.55, 0.2))
	return {"g": g, "foot": Vector2(1.0, 0.42)}


static func _futons() -> Dictionary:
	var g := node(null)
	for i in range(4):
		box(g, Vector3(0.85 - i * 0.03, 0.13, 0.62), tmat("futon%d" % i, 1.0), Vector3((i % 2) * 0.02, 0.065 + i * 0.13, 0))
	return {"g": g, "foot": Vector2(0.85, 0.62)}


static func _emat(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 0.9)
	var d: float = p.get("d", 1.8)
	box(g, Vector3(w, 0.01, d), mat(0xcdb894, 1.0), Vector3(0, 0.005, 0))
	plane_up(g, w, d, tmat("emat", 1.0), Vector3(0, 0.0105, 0))
	return {"g": g}


## 싱크대: 문 두 짝, 오목한 개수대와 수도꼭지
static func _sink(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.0)
	var d := 0.5
	var h := 0.8
	var depth := 0.16
	var body := mat(0xd8ccb4, 0.65)
	var steel := mat(0xa3a9ac, 0.3, 0.7)
	box(g, Vector3(w - 0.04, 0.08, d - 0.08), mat(0x3a3430, 0.8), Vector3(0, 0.04, -0.02))
	_cabinet(g, w, d, 0.08, h, h + 0.03 - depth - 0.02, body)
	for sx in [-1, 1]:
		box(g, Vector3(w / 2 - 0.02, h - 0.2, 0.016), mat(0xe4dac5, 0.55), Vector3(sx * w / 4, 0.08 + (h - 0.2) / 2 + 0.02, d / 2 + 0.004))
		box(g, Vector3(0.012, 0.12, 0.02), steel, Vector3(sx * 0.04, 0.6, d / 2 + 0.018))
	_basin_top(g, w, d, h + 0.015, 0.03, steel, p.get("bx", -0.15), p.get("bw", 0.42), 0.3, depth)
	box(g, Vector3(w, 0.14, 0.012), mat(0xdfe3e0, 0.4), Vector3(0, h + 0.1, -d / 2 + 0.006))
	return {"g": g, "foot": Vector2(w, d)}


static func _kitchen(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.8)
	var d := 0.6
	var depth := 0.16
	var white := mat(0xf3f0ee, 0.35)
	_cabinet(g, w, d, 0.0, 0.88, 0.88 - depth - 0.02, white)
	box(g, Vector3(0.45, 0.01, 0.35), mat(0x1d1d1f, 0.2), Vector3(-w / 2 + 0.4, 0.915, 0))
	_basin_top(g, w, d, 0.895, 0.03, mat(0xd8d2cf, 0.3), p.get("bx", 0.1), 0.46, 0.36, depth)
	box(g, Vector3(w, 0.65, 0.34), white, Vector3(0, 1.75, -0.13))
	for i in range(4):
		box(g, Vector3(0.005, 0.8, 0.005), mat(0xcfcac6), Vector3(-w / 2 + (i + 1) * w / 5, 0.44, d / 2 + 0.002))
	return {"g": g, "foot": Vector2(w, d)}


## 수납장 몸통: 아래는 꽉 찬 상자, 위쪽은 개수대가 들어가도록 테두리만
static func _cabinet(g: Node3D, w: float, d: float, y0: float, y1: float, solid_top: float, m: Material) -> void:
	box(g, Vector3(w, solid_top - y0, d), m, Vector3(0, (y0 + solid_top) / 2, 0))
	var sh := y1 - solid_top
	var sy := solid_top + sh / 2
	box(g, Vector3(w, sh, 0.02), m, Vector3(0, sy, d / 2 - 0.01))
	box(g, Vector3(w, sh, 0.02), m, Vector3(0, sy, -d / 2 + 0.01))
	box(g, Vector3(0.02, sh, d), m, Vector3(-w / 2 + 0.01, sy, 0))
	box(g, Vector3(0.02, sh, d), m, Vector3(w / 2 - 0.01, sy, 0))


## 상판에 개수대 구멍을 내고(네 조각), 오목한 개수대 · 배수구 · 수도꼭지를 붙인다
static func _basin_top(g: Node3D, w: float, d: float, top_y: float, t: float, top_m: Material, bx: float, bw: float, bd: float, depth: float) -> void:
	var lw := (bx - bw / 2) + w / 2
	var rw := w / 2 - (bx + bw / 2)
	var fd := (d - bd) / 2
	box(g, Vector3(lw, t, d), top_m, Vector3(-w / 2 + lw / 2, top_y, 0))
	box(g, Vector3(rw, t, d), top_m, Vector3(w / 2 - rw / 2, top_y, 0))
	box(g, Vector3(bw, t, fd), top_m, Vector3(bx, top_y, d / 2 - fd / 2))
	box(g, Vector3(bw, t, fd), top_m, Vector3(bx, top_y, -d / 2 + fd / 2))
	var steel_d := mat(0x7f868a, 0.35, 0.7)
	var top := top_y + t / 2
	box(g, Vector3(bw, 0.01, bd), steel_d, Vector3(bx, top - depth, 0))
	box(g, Vector3(0.008, depth, bd), steel_d, Vector3(bx - bw / 2 + 0.004, top - depth / 2, 0))
	box(g, Vector3(0.008, depth, bd), steel_d, Vector3(bx + bw / 2 - 0.004, top - depth / 2, 0))
	box(g, Vector3(bw, depth, 0.008), steel_d, Vector3(bx, top - depth / 2, bd / 2 - 0.004))
	box(g, Vector3(bw, depth, 0.008), steel_d, Vector3(bx, top - depth / 2, -bd / 2 + 0.004))
	cyl(g, 0.03, 0.03, 0.004, mat(0x2a2a2a, 0.5, 0.5), Vector3(bx, top - depth + 0.007, 0), 16)
	var chrome := mat(0xbfc3c6, 0.25, 0.5)
	var fz := -d / 2 + fd / 2
	cyl(g, 0.024, 0.026, 0.03, chrome, Vector3(bx, top + 0.015, fz), 16)
	cyl(g, 0.013, 0.013, 0.2, chrome, Vector3(bx, top + 0.13, fz), 12)
	sph(g, 0.0135, chrome, Vector3(bx, top + 0.23, fz), 12)
	var spout := cyl(g, 0.011, 0.011, 0.16, chrome, Vector3(bx, top + 0.23, fz + 0.08), 12)
	spout.rotation.x = PI / 2
	cyl(g, 0.01, 0.012, 0.035, chrome, Vector3(bx, top + 0.213, fz + 0.16), 12)
	box(g, Vector3(0.014, 0.012, 0.075), chrome, Vector3(bx, top + 0.25, fz - 0.025))


static func _boiler() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.12, 0.16, 0.03), mat(0xefefea, 0.5), Vector3.ZERO)
	quad(g, 0.08, 0.045, tmat("boiler_disp", 0.5, {"unshaded": true}), Vector3(0, 0.03, 0.0155))
	var b := cyl(g, 0.012, 0.012, 0.01, mat(0xc7372f), Vector3(0, -0.04, 0.018), 12)
	b.rotation.x = PI / 2
	return {"g": g}


static func _window(p: Dictionary) -> Dictionary:
	if p.get("style", "") == "premium":
		return _window_premium(p)
	var g := node(null)
	var w: float = p.get("w", 0.7)
	var h: float = p.get("h", 0.5)
	var view: String = p.get("tex", "win_e1")
	var gm := tmat(view, 1.0, {"unshaded": true})
	gm.albedo_color = col(int(p.get("tint", 0x9aa4b0)))
	quad(g, w, h, gm, Vector3.ZERO)
	if p.has("overlay"):
		quad(g, w, h, tmat(p.overlay, 1.0, {"alpha_tex": true, "unshaded": true}), Vector3(0, 0, 0.03))
	var fm := mat(int(p.get("frame", 0xd8d6d0)), 0.5)
	box(g, Vector3(w + 0.06, 0.04, 0.05), fm, Vector3(0, h / 2 + 0.01, 0))
	box(g, Vector3(w + 0.06, 0.04, 0.05), fm, Vector3(0, -h / 2 - 0.01, 0))
	box(g, Vector3(0.04, h, 0.05), fm, Vector3(-w / 2 - 0.01, 0, 0))
	box(g, Vector3(0.04, h, 0.05), fm, Vector3(w / 2 + 0.01, 0, 0))
	box(g, Vector3(0.025, h, 0.03), fm, Vector3(0, 0, 0.005))
	if p.get("bars", false):
		for i in range(1, 6):
			cyl(g, 0.006, 0.006, h, mat(0x3a3a3a, 0.5, 0.6), Vector3(-w / 2 + i * w / 6, 0, 0.04), 6)
	if p.has("curtain"):
		var cm := mat(int(p["curtain"]), 1.0)
		var cb := BoxMesh.new()
		cb.size = Vector3(w * 0.35, h + 0.25, 0.02)
		cb.subdivide_width = 8
		var cmesh := deformed(cb, func(v): return Vector3(v.x, v.y, v.z + sin(v.x * 40.0) * 0.02))
		mi(g, cmesh, cm, Vector3(-w * 0.38, -0.05, 0.06))
		mi(g, cmesh, cm, Vector3(w * 0.38, -0.05, 0.06))
	return {"g": g}


## 3장 오피스텔 창 (p.style == "premium"): 벽 두께만큼 나온 창틀과 테두리 · 대리석 창대 ·
## 흰 미닫이 두 짝과 잠금쇠 · 유리에 비친 빛 · 천장 가까이 단 커튼 봉과 고리 ·
## 주름 깊은 겉커튼 두 폭과 반쯤 친 속커튼. 원점은 유리 가운데, 벽면은 z -0.01.
## p.rod_y · p.rod_x: 커튼 봉 높이와 양 끝 (오른쪽이 벽에 붙은 창은 봉을 짧게)
static func _window_premium(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.6)
	var h: float = p.get("h", 1.1)
	var gm := tmat(p.get("tex", "win_e3"), 1.0, {"unshaded": true})
	gm.albedo_color = col(int(p.get("tint", 0x9aa4b0)))
	quad(g, w, h, gm, Vector3.ZERO)
	var trim := mat(0xf4f2ee, 0.8)
	var dep := 0.12
	box(g, Vector3(w + 0.06, 0.03, dep), trim, Vector3(0, h / 2.0 + 0.015, dep / 2.0 - 0.01))
	for sx in [-1.0, 1.0]:
		box(g, Vector3(0.03, h + 0.03, dep), trim, Vector3(sx * (w / 2.0 + 0.015), 0.015, dep / 2.0 - 0.01))
		box(g, Vector3(0.065, h, 0.016), trim, Vector3(sx * (w / 2.0 + 0.0325), 0, dep - 0.002))
	box(g, Vector3(w + 0.13, 0.065, 0.016), trim, Vector3(0, h / 2.0 + 0.0325, dep - 0.002))
	box(g, Vector3(w + 0.22, 0.03, dep + 0.06), mat(0xebe8e3, 0.22), Vector3(0, -h / 2.0 - 0.015, (dep + 0.06) / 2.0 - 0.01))
	box(g, Vector3(w + 0.13, 0.06, 0.014), trim, Vector3(0, -h / 2.0 - 0.06, -0.003))
	# 흰 창틀과 미닫이 두 짝 (왼쪽은 안쪽 레일, 오른쪽은 바깥 레일, 가운데서 겹친다)
	var pvc := mat(int(p.get("frame", 0xffffff)), 0.35)
	box(g, Vector3(w, 0.05, 0.08), pvc, Vector3(0, h / 2.0 - 0.025, 0.03))
	box(g, Vector3(w, 0.05, 0.08), pvc, Vector3(0, -h / 2.0 + 0.025, 0.03))
	for sx in [-1.0, 1.0]:
		box(g, Vector3(0.05, h - 0.1, 0.08), pvc, Vector3(sx * (w / 2.0 - 0.025), 0, 0.03))
	var ow := w / 2.0 - 0.05
	var sh := h - 0.1
	var sheen := _glass_sheen()
	var grip := mat(0xe9e9e6, 0.4)
	for k in 2:
		var x0 := -ow if k == 0 else -0.03
		var x1 := 0.03 if k == 0 else ow
		var cx := (x0 + x1) / 2.0
		var sw := x1 - x0
		var z := 0.022 if k == 0 else 0.05
		box(g, Vector3(sw, 0.045, 0.028), pvc, Vector3(cx, sh / 2.0 - 0.0225, z))
		box(g, Vector3(sw, 0.045, 0.028), pvc, Vector3(cx, -sh / 2.0 + 0.0225, z))
		box(g, Vector3(0.045, sh - 0.09, 0.028), pvc, Vector3(x0 + 0.0225, 0, z))
		box(g, Vector3(0.045, sh - 0.09, 0.028), pvc, Vector3(x1 - 0.0225, 0, z))
		quad(g, sw - 0.09, sh - 0.09, sheen, Vector3(cx, 0, z))
		box(g, Vector3(0.012, 0.15, 0.012), grip, Vector3(x0 + 0.0225 if k == 0 else x1 - 0.0225, -0.04, z + 0.02))
	var metal := mat(0xc4c6c8, 0.35, 0.7)
	box(g, Vector3(0.024, 0.06, 0.01), metal, Vector3(-0.0075, 0, 0.069))
	var lv := box(g, Vector3(0.04, 0.01, 0.007), metal, Vector3(-0.0195, 0.014, 0.076))
	lv.rotation.z = 0.45
	if p.has("curtain"):
		var gold := mat(0xd8c08c, 0.3, 0.7)
		var ry: float = p.get("rod_y", h / 2.0 + 0.2)
		var rx: Array = p.get("rod_x", [-(w / 2.0 + 0.3), w / 2.0 + 0.3])
		var rx0: float = rx[0]
		var rx1: float = rx[1]
		var zr := 0.22
		var zs := 0.15
		rod(g, Vector3(rx0, ry, zr), Vector3(rx1, ry, zr), 0.011, gold, 12)
		rod(g, Vector3(rx0 + 0.06, ry - 0.012, zs), Vector3(rx1 - 0.04, ry - 0.012, zs), 0.006, gold, 8)
		sph(g, 0.021, gold, Vector3(rx0 - 0.012, ry, zr), 12)
		sph(g, 0.021, gold, Vector3(rx1 + 0.012, ry, zr), 12)
		for bx in [rx0 + 0.1, rx1 - 0.1]:
			var wp := cyl(g, 0.022, 0.022, 0.008, gold, Vector3(bx, ry, -0.006), 14)
			wp.rotation.x = PI / 2.0
			rod(g, Vector3(bx, ry, -0.01), Vector3(bx, ry, zr + 0.012), 0.008, gold, 8)
		# 겉커튼: 봉 고리에 걸려 창대 아래까지
		var cm := mat(int(p["curtain"]), 1.0, 0.0, {"rim_enabled": true, "rim": 0.25, "rim_tint": 0.5})
		var top := ry - 0.035
		var bot := -h / 2.0 - 0.08
		for span in [[rx0 + 0.04, -w / 2.0 + 0.12], [w / 2.0 - 0.2, rx1 - 0.03]]:
			var a: float = span[0]
			var cw: float = span[1] - a
			_drape(g, cm, cw, top - bot, 0.03, 0.075, Vector3(a + cw / 2.0, (top + bot) / 2.0, zr), false)
			var nr := maxi(2, int(round(cw / 0.05)))
			for i in nr + 1:
				var rr := ring(g, 0.019, 0.0035, gold, Vector3(a + cw * i / nr, ry, zr))
				rr.rotation.y = PI / 2.0
		# 속커튼: 반쯤 비치는 흰 천, 창대 바로 위까지
		var sm := mat(0xffffff, 1.0, 0.0, {"alpha": 0.42, "cull_off": true})
		var stop := ry - 0.03
		var sbot := -h / 2.0 + 0.006
		for span in [[rx0 + 0.08, -0.4], [0.4, rx1 - 0.06]]:
			var a: float = span[0]
			var cw: float = span[1] - a
			_drape(g, sm, cw, stop - sbot, 0.012, 0.055, Vector3(a + cw / 2.0, (stop + sbot) / 2.0, zs), true)
	return {"g": g}


## 커튼 한 폭: 위는 고리에 잡혀 주름이 얕고, 아래로 갈수록 깊어지며 살짝 퍼진다. thin이면 얇은 한 겹 판
static func _drape(g: Node3D, m: Material, cw: float, ch: float, amp: float, period: float, pos: Vector3, thin: bool) -> MeshInstance3D:
	var folds := maxf(2.0, round(cw / period))
	var f := func(v: Vector3) -> Vector3:
		var t: float = clampf(0.5 - v.y / ch, 0.0, 1.0)
		var a: float = amp * (0.45 + 0.55 * smoothstep(0.0, 0.3, t))
		var ph: float = (v.x / cw + 0.5) * folds * TAU
		return Vector3(v.x * (1.0 + 0.12 * t), v.y, v.z + sin(ph) * a)
	var prim: PrimitiveMesh
	if thin:
		var q := QuadMesh.new()
		q.size = Vector2(cw, ch)
		q.subdivide_width = int(folds) * 6
		q.subdivide_depth = 8
		prim = q
	else:
		var b := BoxMesh.new()
		b.size = Vector3(cw, ch, 0.012)
		b.subdivide_width = int(folds) * 6
		b.subdivide_height = 8
		prim = b
	return mi(g, deformed(prim, f), m, pos)


## 유리에 비친 빛: 비스듬한 옅은 띠 두 줄 (투명)
static func _glass_sheen() -> StandardMaterial3D:
	if _mats.has("glass_sheen"):
		return _mats["glass_sheen"]
	var c0 := Color(1, 1, 1, 0)
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.33, 0.37, 0.41, 0.55, 0.57, 0.59, 1.0])
	gr.colors = PackedColorArray([c0, c0, Color(1, 1, 1, 0.055), c0, c0, Color(1, 1, 1, 0.035), c0, c0])
	var gt := GradientTexture2D.new()
	gt.gradient = gr
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 1)
	var m := StandardMaterial3D.new()
	m.albedo_texture = gt
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats["glass_sheen"] = m
	return m


static func _fluoro() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.62, 0.04, 0.1), mat(0xdedbd3), Vector3(0, -0.02, 0))
	var tube := cyl(g, 0.014, 0.014, 0.58, mat(0xf4f6f2, 0.5, 0.0, {"emit": 0x9aa39a, "emit_e": 0.4}), Vector3(0, -0.05, 0), 10)
	tube.rotation.z = PI / 2
	return {"g": g}


static func _bulb() -> Dictionary:
	var g := node(null)
	cyl(g, 0.003, 0.003, 0.3, mat(0x222222), Vector3(0, -0.15, 0), 6)
	cyl(g, 0.018, 0.018, 0.04, mat(0x333333), Vector3(0, -0.31, 0), 10)
	sph(g, 0.035, mat(0xf0ead8, 0.3, 0.0, {"emit": 0x332a18}), Vector3(0, -0.36, 0))
	return {"g": g}


## 링 라이트: 벌어진 삼각대와 버팀대 · 고무발 · 두 단 기둥과 조임 손잡이 · 기울기 머리 ·
## 검은 테 안의 빛나는 확산판 (이름 "ring" — 끄고 켤 때 이 재질의 빛 세기를 바꾼다) ·
## 가운데 휴대폰 거치대 · 뒤쪽 조절기와 벽 콘센트까지 늘어진 전선. 앞(+Z)이 비추는 쪽
static func _ring_light() -> Dictionary:
	var g := node(null)
	var m := mat(0x1e1e22, 0.42, 0.6)
	var plastic := mat(0x26262a, 0.65)
	var rubber := mat(0x101011, 0.95)
	cyl(g, 0.021, 0.021, 0.07, m, Vector3(0, 0.57, 0), 14)
	cyl(g, 0.02, 0.02, 0.045, m, Vector3(0, 0.3, 0), 14)
	for i in range(3):
		var a := i / 3.0 * TAU
		var dir := Vector3(sin(a), 0, cos(a))
		var top := Vector3(0, 0.55, 0) + dir * 0.02
		var ft := dir * 0.31 + Vector3(0, 0.02, 0)
		rod(g, top, ft, 0.0085, m, 8)
		rod(g, Vector3(0, 0.3, 0) + dir * 0.018, top.lerp(ft, 0.5), 0.0055, m, 6)
		cyl(g, 0.013, 0.016, 0.02, rubber, Vector3(ft.x, 0.01, ft.z), 10)
	cyl(g, 0.0135, 0.0135, 0.78, m, Vector3(0, 0.67, 0), 12)
	cyl(g, 0.019, 0.019, 0.045, plastic, Vector3(0, 1.07, 0), 14)
	rod(g, Vector3(0, 1.07, 0), Vector3(0.048, 1.07, 0), 0.005, m, 6)
	sph(g, 0.013, plastic, Vector3(0.054, 1.07, 0), 10)
	cyl(g, 0.0105, 0.0105, 0.28, m, Vector3(0, 1.21, 0), 12)
	box(g, Vector3(0.052, 0.035, 0.04), plastic, Vector3(0, 1.345, 0))
	sph(g, 0.012, plastic, Vector3(0.034, 1.345, 0), 10)
	var housing := ring(g, 0.228, 0.03, plastic, Vector3(0, 1.6, 0))
	housing.scale = Vector3(1, 0.55, 1)
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color.WHITE
	rm.emission_enabled = true
	rm.emission = Color(1.0, 0.92, 0.94)
	rm.emission_energy_multiplier = 2.0
	var r := ring(g, 0.228, 0.021, rm, Vector3(0, 1.6, 0.012))
	r.scale = Vector3(1, 0.35, 1)
	r.name = "ring"
	# 휴대폰 거치대: 기울기 머리에서 고리 가운데로 올라온 막대 · 집게 · 휴대폰 (화면이 비추는 쪽)
	rod(g, Vector3(0, 1.36, 0), Vector3(0, 1.375, 0.035), 0.006, m, 6)
	rod(g, Vector3(0, 1.375, 0.035), Vector3(0, 1.585, 0.035), 0.0055, m, 6)
	box(g, Vector3(0.1, 0.022, 0.018), plastic, Vector3(0, 1.6, 0.04))
	for sx in [-1.0, 1.0]:
		box(g, Vector3(0.01, 0.03, 0.022), plastic, Vector3(sx * 0.045, 1.6, 0.048))
	box(g, Vector3(0.074, 0.156, 0.009), mat(0x9c7b85, 0.5), Vector3(0, 1.615, 0.053))
	quad(g, 0.068, 0.148, mat(0x0c0c10, 0.12, 0.2), Vector3(0, 1.615, 0.0576))
	box(g, Vector3(0.03, 0.03, 0.003), mat(0x1a1a1d, 0.3), Vector3(0.017, 1.672, 0.047))
	var lens := mat(0x050507, 0.1, 0.5)
	for v in [Vector3(0.011, 1.678, 0.0455), Vector3(0.011, 1.664, 0.0455), Vector3(0.024, 1.671, 0.0455)]:
		var ln := cyl(g, 0.0048, 0.0048, 0.002, lens, v, 10)
		ln.rotation.x = PI / 2.0
	# 뒤쪽 조절기와 전선: 기둥을 따라 내려가 바닥을 지나 벽 콘센트로
	var ca := 0.7
	var ctl := node(g, Vector3(0.228 * sin(ca), 1.6 - 0.228 * cos(ca), -0.027))
	ctl.rotation.z = ca
	box(ctl, Vector3(0.07, 0.03, 0.022), plastic, Vector3.ZERO)
	for i in 3:
		var bt := cyl(ctl, 0.0045, 0.0045, 0.004, mat(0x45454c, 0.5), Vector3(-0.02 + i * 0.02, 0, -0.012), 8)
		bt.rotation.x = PI / 2.0
	var cab := mat(0x141416, 0.6)
	var pts := [Vector3(0.18, 1.42, -0.03), Vector3(0.06, 1.33, -0.024), Vector3(0.012, 1.2, -0.017), Vector3(0.012, 0.33, -0.017),
		Vector3(0.04, 0.15, 0.0), Vector3(0.1, 0.02, 0.02), Vector3(0.16, 0.004, 0.032), Vector3(0.97, 0.004, 0.2), Vector3(0.97, 0.18, 0.2)]
	for i in pts.size() - 1:
		rod(g, pts[i], pts[i + 1], 0.0032, cab, 6)
	box(g, Vector3(0.008, 0.11, 0.075), mat(0xf2f0ec, 0.5), Vector3(0.996, 0.2, 0.2))
	box(g, Vector3(0.03, 0.042, 0.034), mat(0xe8e6e2, 0.5), Vector3(0.977, 0.2, 0.2))
	return {"g": g, "foot": Vector2(0.62, 0.62)}


static func _vanity(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.0)
	var d := 0.45
	var wm := mat(0xf6efe9, 0.4)
	box(g, Vector3(w, 0.03, d), wm, Vector3(0, 0.745, 0))
	box(g, Vector3(0.04, 0.73, d), wm, Vector3(-w / 2 + 0.02, 0.365, 0))
	box(g, Vector3(0.04, 0.73, d), wm, Vector3(w / 2 - 0.02, 0.365, 0))
	box(g, Vector3(w - 0.08, 0.14, d - 0.04), wm, Vector3(0, 0.66, 0))
	box(g, Vector3(0.76, 0.6, 0.02), wm, Vector3(0, 1.3, -d / 2 + 0.005))
	quad(g, 0.7, 0.55, tmat("mirror_vanity", 0.1, {"metallic": 0.3}), Vector3(0, 1.3, -d / 2 + 0.016))
	var bm := mat(0xfff2dc, 0.3, 0.0, {"emit": 0xffd9a0, "emit_e": 0.5})
	for i in range(4):
		sph(g, 0.022, bm, Vector3(-0.36, 1.08 + i * 0.15, -d / 2 + 0.04))
		sph(g, 0.022, bm, Vector3(0.36, 1.08 + i * 0.15, -d / 2 + 0.04))
	return {"g": g, "foot": Vector2(w, d)}


## 3장 옷 행거: 금빛 관 두 기둥과 위 봉 · 고무발 달린 받침대 · 아래 원목 선반과 신발 상자 ·
## 봉에 고리를 건 벨벳 옷걸이마다 다른 옷 (니트 · 셔츠 · 재킷 · 블라우스 · 트렌치코트 · 원피스)
static func _rack(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 0.9)
	var gold := mat(0xd8c08c, 0.3, 0.7)
	var top := 1.55
	for sx in [-1.0, 1.0]:
		var x: float = sx * w / 2.0
		cyl(g, 0.011, 0.011, top - 0.03, gold, Vector3(x, (top - 0.03) / 2.0 + 0.03, 0), 12)
		sph(g, 0.016, gold, Vector3(x, top, 0), 12)
		rod(g, Vector3(x, 0.03, -0.21), Vector3(x, 0.03, 0.21), 0.011, gold, 10)
		rod(g, Vector3(x, 0.155, -0.16), Vector3(x, 0.155, 0.16), 0.008, gold, 8)
		for sz in [-1.0, 1.0]:
			cyl(g, 0.016, 0.018, 0.02, mat(0x1c1c1e, 0.8), Vector3(x, 0.01, sz * 0.21), 12)
	rod(g, Vector3(-w / 2.0, top, 0), Vector3(w / 2.0, top, 0), 0.012, gold, 12)
	box(g, Vector3(w - 0.02, 0.022, 0.34), mat(0xc9a27a, 0.6), Vector3(0, 0.174, 0))
	# 신발 상자 둘 (뚜껑이 조금 크다)
	for b in [[-0.17, 0xf3cfd6, 0xe6b9c3, 0.05], [0.18, 0xf4f1ec, 0x2a2a2e, -0.07]]:
		var bn := node(g, Vector3(b[0], 0.185, 0))
		bn.rotation.y = b[3]
		box(bn, Vector3(0.3, 0.1, 0.19), mat(b[1], 0.7), Vector3(0, 0.05, 0))
		box(bn, Vector3(0.306, 0.026, 0.196), mat(b[2], 0.6), Vector3(0, 0.1, 0))
	var hang := mat(0xe0bcc4, 1.0, 0.0, {"rim_enabled": true, "rim": 0.3, "rim_tint": 0.5})
	var clothes := [["knit", 0xefe6d8], ["shirt", 0xb9cfe6], ["coat", 0x26262a], ["shirt", 0xf2c6d0], ["long", 0xd2b48c], ["dress", 0xf7f4ef], ["dress", 0xc9a0ad]]
	var n := clothes.size()
	for i in n:
		var gn := node(g, Vector3(-w / 2.0 + 0.07 + i * (w - 0.14) / (n - 1), top - 0.09, 0))
		gn.rotation.y = sin(i * 2.3) * 0.07
		var kind: String = clothes[i][0]
		_hanger(gn, gold, hang, GARMENTS[kind][0] * 0.42, true)
		_garment(gn, kind, clothes[i][1], i * 1.7)
	return {"g": g, "foot": Vector2(w, 0.45)}


## 옷 종류별 [폭, 길이, 두께, 소매 길이]
const GARMENTS := {
	"shirt": [0.42, 0.64, 0.04, 0.5],
	"dress": [0.36, 0.98, 0.045, 0.0],
	"coat": [0.48, 0.74, 0.075, 0.56],
	"long": [0.48, 1.0, 0.08, 0.58],
	"knit": [0.46, 0.58, 0.085, 0.5],
}


## 옷걸이: 봉에 건 고리 · 목 · 옷 어깨선을 따라 내려가는 두 팔. 원점은 옷 윗단 가운데, 봉 가운데는 y 0.09.
## rail_x면 봉이 옷의 두께(x) 방향으로, 아니면 옷의 폭(z) 방향으로 지나간다
static func _hanger(g: Node3D, hook: Material, body: Material, half: float, rail_x: bool) -> void:
	var rr := ring(g, 0.021, 0.0028, hook, Vector3(0, 0.09, 0))
	if rail_x:
		rr.rotation.y = PI / 2.0
	rod(g, Vector3(0, 0.069, 0), Vector3(0, 0.02, 0), 0.0028, hook, 6)
	sph(g, 0.009, body, Vector3(0, 0.02, 0), 10)
	for sz in [-1.0, 1.0]:
		rod(g, Vector3(0, 0.022, 0), Vector3(0, -0.058, sz * half), 0.0055, body, 8)


## 옷걸이에 걸린 옷 한 벌: 어깨는 옷걸이를 따라 처지고 목선이 살짝 파였다. 아래로 갈수록 주름이 늘고
## 종류마다 허리 · 밑단 폭이 다르다. 소매가 있으면 양 어깨에서 늘어진다. 원점은 윗단 가운데, 폭은 z, 두께는 x
static func _garment(g: Node3D, kind: String, c: int, sd: float) -> void:
	var s: Array = GARMENTS[kind]
	var W: float = s[0]
	var L: float = s[1]
	var T: float = s[2]
	var sl: float = s[3]
	var m := mat(c, 0.9)
	var bm := BoxMesh.new()
	bm.size = Vector3(T, L, W)
	bm.subdivide_width = 2
	bm.subdivide_height = 16
	bm.subdivide_depth = 12
	var mesh := deformed(bm, func(v):
		var u: float = v.z / (W / 2.0)
		var au: float = absf(u)
		var t: float = 0.5 - v.y / L
		var y: float = v.y - L / 2.0
		y += (-0.075 * pow(au, 1.3) - 0.028 * maxf(0.0, 1.0 - au * 4.0)) * (1.0 - smoothstep(0.0, 0.28, t))
		y += sin(u * 6.0 + sd) * 0.007 * t * t * t
		return Vector3(_gx(kind, sd, u, t, v.x), y, v.z * _garment_w(kind, t) + sin(t * 5.0 + sd) * 0.004))
	mi(g, mesh, m, Vector3.ZERO)
	# 앞면: 재킷 · 코트는 깃 사이 안감 · 앞섶 · 단추 (긴 코트는 허리띠), 셔츠는 깃 · 앞단 · 단추,
	# 니트는 목둘레와 밑단 고무단, 원피스는 허리 띠
	var fx := func(u: float, y: float) -> float: return _gx(kind, sd, u, clampf(-y / L, 0.0, 1.0), T / 2.0)
	match kind:
		"coat", "long":
			var dk := mat(_shade(c, 0.4), 0.9)
			_gpatch(g, kind, sd, -0.03, -0.3, 0.17, 0.0, dk)
			_gpatch(g, kind, sd, -0.3, -L + 0.012, 0.005, 0.005, dk)
			for i in 2:
				sph(g, 0.009, mat(0x1a1a1c, 0.4), Vector3(fx.call(0.08, -0.36 - i * 0.12) + 0.005, -0.36 - i * 0.12, 0.02), 8)
			if kind == "long":
				_gpatch(g, kind, sd, -0.42, -0.47, W * 0.9, W * 0.9, mat(_shade(c, 0.15), 0.9))
		"shirt":
			_gpatch(g, kind, sd, -0.004, -0.05, 0.16, 0.12, mat(_shade(c, -0.12), 0.9))
			_gpatch(g, kind, sd, -0.05, -L + 0.012, 0.022, 0.022, mat(_shade(c, 0.08), 0.9))
			var bt := mat(0xf2efe8, 0.4)
			for i in 5:
				sph(g, 0.0055, bt, Vector3(fx.call(0.0, -0.1 - i * 0.1) + 0.005, -0.1 - i * 0.1, 0), 6)
		"knit":
			var rib := mat(_shade(c, 0.12), 0.95)
			_gpatch(g, kind, sd, -L + 0.065, -L + 0.004, W * 0.86, W * 0.86, rib)
			_gpatch(g, kind, sd, -0.012, -0.045, 0.17, 0.15, rib)
		"dress":
			_gpatch(g, kind, sd, -0.29, -0.315, W * 0.74, W * 0.74, mat(_shade(c, 0.15), 0.9))
	if sl <= 0.0:
		return
	var sw := 0.11
	var sm := BoxMesh.new()
	sm.size = Vector3(T * 0.75, sl, sw)
	sm.subdivide_height = 8
	sm.subdivide_depth = 3
	var smesh := deformed(sm, func(v):
		var t: float = 0.5 - v.y / sl
		return Vector3(v.x * (0.5 + 0.5 * (1.0 - pow(absf(v.z) / (sw / 2.0), 4.0))), v.y - sl / 2.0, v.z * (1.0 - 0.22 * t)))
	for sz in [-1.0, 1.0]:
		var sv := mi(g, smesh, m, Vector3(T * 0.15, -0.07, sz * (W / 2.0 + 0.008)))
		sv.rotation.x = sz * 0.05


## 옷의 두께 방향 위치: 가장자리 · 어깨는 얇고, 아래로 갈수록 주름이 깊다 (x: 가운데 면에서의 거리, 앞면은 두께/2)
static func _gx(kind: String, sd: float, u: float, t: float, x: float) -> float:
	var au := absf(u)
	return x * (0.28 + 0.72 * (1.0 - pow(au, 4.0))) * (0.55 + 0.45 * smoothstep(0.0, 0.18, t)) + sin(u * PI * 2.5 + sd * 3.0) * (0.004 + 0.012 * t) * (2.2 if kind == "dress" else 1.0)


## 옷 앞면에 붙인 띠 · 삼각형 (깃 · 앞섶 · 허리띠 · 고무단): 높이 y0 → y1에서 폭 w0 → w1, 앞면 굴곡을 따른다
static func _gpatch(g: Node3D, kind: String, sd: float, y0: float, y1: float, w0: float, w1: float, m: Material) -> void:
	var s: Array = GARMENTS[kind]
	var W: float = s[0]
	var L: float = s[1]
	var T: float = s[2]
	var bm := BoxMesh.new()
	bm.size = Vector3(0.002, 1.0, 1.0)
	bm.subdivide_height = 6
	bm.subdivide_depth = 8
	mi(g, deformed(bm, func(v):
		var k: float = 0.5 - v.y
		var y: float = lerpf(y0, y1, k)
		var t: float = clampf(-y / L, 0.0, 1.0)
		var z: float = v.z * lerpf(w0, w1, k)
		var u: float = clampf(z / (W / 2.0 * _garment_w(kind, t)), -1.0, 1.0)
		return Vector3(_gx(kind, sd, u, t, T / 2.0) + 0.003 + v.x, y, z)), m, Vector3.ZERO)


## 같은 색을 k만큼 어둡게 (음수면 밝게)
static func _shade(c: int, k: float) -> int:
	var cc := col(c)
	cc = cc.darkened(k) if k >= 0.0 else cc.lightened(-k)
	return cc.to_rgba32() >> 8


## 옷 종류별 폭 비율 (t: 0 어깨 ~ 1 밑단)
static func _garment_w(kind: String, t: float) -> float:
	match kind:
		"dress":
			return lerpf(0.95, 0.76, smoothstep(0.0, 0.32, t)) + 0.62 * smoothstep(0.32, 1.0, t)
		"knit":
			return lerpf(1.0, 0.96, smoothstep(0.0, 0.8, t)) - 0.08 * smoothstep(0.86, 1.0, t)
		"shirt":
			return lerpf(1.0, 0.86, smoothstep(0.0, 0.6, t)) + 0.05 * smoothstep(0.6, 1.0, t)
	return lerpf(1.0, 0.94, smoothstep(0.0, 0.5, t)) + 0.1 * smoothstep(0.5, 1.0, t)


static func _led() -> Dictionary:
	var g := node(null)
	var m := tmat("led_sign", 1.0, {"add": true})
	m.albedo_color = Color(1.4, 1.2, 1.3)
	var q := quad(g, 1.0, 0.25, m, Vector3.ZERO)
	q.name = "led"
	return {"g": g}


static func _big_mirror() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.56, 1.62, 0.03), mat(0xf2ece6), Vector3(0, 0.82, 0))
	quad(g, 0.5, 1.55, tmat("mirror_big", 0.1, {"metallic": 0.3}), Vector3(0, 0.82, 0.0161))
	return {"g": g, "foot": Vector2(0.56, 0.1)}


static func _nightstand(p: Dictionary) -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.42, 0.5, 0.4), mat(0xf3eee8, 0.4), Vector3(0, 0.25, 0))
	box(g, Vector3(0.36, 0.004, 0.005), mat(0xcfc6bd), Vector3(0, 0.32, 0.201))
	return {"g": g, "foot": Vector2(0.42, 0.4)}


static func _pink_chair() -> Dictionary:
	var g := node(null)
	var m := mat(0xf0b9c8, 0.9)
	var gold := mat(0xd8c08c, 0.3, 0.7)
	cyl(g, 0.25, 0.25, 0.1, m, Vector3(0, 0.45, 0), 24)
	var back := box(g, Vector3(0.48, 0.4, 0.08), m, Vector3(0, 0.7, -0.2))
	back.rotation.x = -0.12
	cyl(g, 0.02, 0.02, 0.4, gold, Vector3(0, 0.2, 0), 8)
	cyl(g, 0.2, 0.2, 0.02, gold, Vector3(0, 0.01, 0), 20)
	return {"g": g, "foot": Vector2(0.5, 0.5)}


static func _wall_shelf(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 0.8)
	box(g, Vector3(w, 0.025, 0.2), mat(0xf3eee8), Vector3.ZERO)
	for pot in [[-0.31, 0x8dbf8d], [0.3, 0x7aa37a]]:
		cyl(g, 0.045, 0.035, 0.08, mat(0xffffff, 0.5), Vector3(pot[0], 0.053, 0), 14)
		sph(g, 0.06, mat(pot[1], 1.0), Vector3(pot[0], 0.12, 0), 10)
	return {"g": g}


## 1장 벽에 단 옷 봉: 양 끝 벽 받침 · 철사 옷걸이에 건 회색 맨투맨과 남색 재킷
static func _rail(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 0.9)
	var steel := mat(0xb5b5b5, 0.3, 0.7)
	rod(g, Vector3(0, 0, -w / 2.0), Vector3(0, 0, w / 2.0), 0.01, steel, 10)
	for sz in [-1.0, 1.0]:
		var z: float = sz * (w / 2.0 - 0.04)
		rod(g, Vector3(0, 0, z), Vector3(0.058, 0, z), 0.007, steel, 8)
		var wp := cyl(g, 0.02, 0.02, 0.006, steel, Vector3(0.057, 0, z), 12)
		wp.rotation.z = PI / 2.0
	var wire := mat(0x8a8a8a, 0.35, 0.7)
	var clothes := [["knit", 0x6b6f75], ["coat", 0x3a4458]]
	for i in clothes.size():
		var gn := node(g, Vector3(0, -0.09, -w / 2.0 + 0.22 + i * 0.46))
		gn.rotation.y = PI + (i - 0.5) * 0.08
		var kind: String = clothes[i][0]
		_hanger(gn, wire, wire, GARMENTS[kind][0] * 0.42, false)
		_garment(gn, kind, clothes[i][1], 1.3 + i)
	return {"g": g}


static func _plug() -> Dictionary:
	var g := node(null)
	var w := mat(0xf2f0ea, 0.5)
	box(g, Vector3(0.26, 0.035, 0.06), w, Vector3(0, 0.0175, 0))
	for i in range(4):
		cyl(g, 0.012, 0.012, 0.004, mat(0x999999), Vector3(-0.09 + i * 0.06, 0.036, 0), 10)
	cyl(g, 0.007, 0.007, 0.04, mat(0xff5533, 0.5, 0.0, {"emit": 0x551100}), Vector3(0.12, 0.036, 0), 8)
	box(g, Vector3(0.04, 0.03, 0.03), w, Vector3(-0.05, 0.015, 0.12))
	var cord := cyl(g, 0.004, 0.004, 0.45, mat(0x2a2a2a), Vector3(-0.05, 0.006, 0.34), 6)
	cord.rotation.x = PI / 2
	return {"g": g}


static func _doorlock() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.07, 0.16, 0.04), mat(0x1d1e22, 0.35, 0.4), Vector3.ZERO)
	quad(g, 0.05, 0.1, tmat("doorlock", 0.5, {"unshaded": true}), Vector3(0, 0.01, 0.0205))
	return {"g": g}


# ───────────────────────────── 유품
static func item(model: String, p: Dictionary) -> Dictionary:
	match model:
		"can": return _can(p)
		"cup": return _cup(p)
		"lunchbox": return _lunchbox()
		"bottle": return _bottle(p)
		"bag": return _bag(p)
		"paperBall": return _paper_ball(p)
		"parcel": return _parcel(p)
		"books": return _books()
		"suit": return _suit()
		"pill": return _pill(p)
		"pillTrio": return _pill_trio()
		"phone": return _phone(p)
		"flip": return _flip()
		"envelope": return flat(null, 0.22, 0.11, 0.004, "env_%s_f" % p.tex, "env_%s_b" % p.tex, 0xe4dbc6)
		"paper": return flat(null, p.get("w", 0.21), p.get("d", 0.297), 0.0015, p.tex, "paper_back", 0xece6d8)
		"postit": return flat(null, 0.076, 0.076, 0.001, p.get("tex", "postit") + "_f", p.get("tex", "postit") + "_b", 0xf2dc6e)
		"photo": return flat(null, 0.15, 0.1, 0.0015, "photo_office", "photo_office_back", 0xf4f1ea)
		"frame": return _frame(p)
		"calendar": return _calendar(p.get("tex", "calendar_e1"))
		"jbox": return _jbox()
		"bankbook": return flat(null, 0.09, 0.14, 0.006, "bank_cover", "", 0xe7e2d6)
		"letter": return flat(null, 0.15, 0.105, 0.003, p.tex + "_f", p.tex + "_b", 0xefe8d8)
		"swatch": return _swatch()
		"wwatch": return _wwatch()
		"diary": return _diary()
		"thermo": return _thermo()
		"scarf": return _scarf()
		"glasses": return _glasses()
		"camera": return _camera()
		"teddy": return _teddy()
		"mkbox": return _mkbox()
		"shake": return _shake(p)
		"salad": return _salad()
		"hotpack": return _noanchor(flat(null, 0.1, 0.13, 0.008, "hotpack", "", 0xefefea))
		"sidedish": return _sidedish(p)
		"ramen": return _noanchor(flat(null, 0.14, 0.18, 0.014, p.get("tex", "ramen_a"), "", 0xc23a2a))
		"newspaper": return _newspaper()
		"yogurt": return _yogurt()
		"candle": return _candle()
		"pouch": return _noanchor(flat(null, 0.09, 0.12, 0.003, "pouch", "", 0xf7f7f3))
		"cotton": return _cotton()
		"tub": return _tub(p)
		"ticket": return flat(null, 0.15, 0.065, 0.001, "ticket_f", "paper_back", 0xf2f0e6)
		"logbook": return flat(null, 0.15, 0.21, 0.012, p.get("tex", "log") + "_cover", p.get("tex", "log") + "_back", 0xf0ece0)
		"sketchbook": return flat(null, 0.21, 0.28, 0.015, "sketch_cover", "", 0xe8e2d4)
		"alarmBox": return _standing_box(0.12, 0.16, 0.05, "alarm_box", 0xf4f4f0)
		"socksBox": return _standing_box(0.13, 0.18, 0.04, "socks_box", 0xeaf2f6)
		"laptop": return _laptop()
		"giftbox": return _giftbox()
		"dress": return _dress()
		"figure": return _figure()
		"uniform": return _uniform()
		"pipingKit": return _piping_kit()
		"onigiri": return _onigiri()
		"breadbag": return _noanchor(flat(null, 0.2, 0.26, 0.04, "breadbag", "", 0xefe3c8))
		"snack": return _noanchor(flat(null, 0.16, 0.22, 0.03, "snack", "", 0xf2a33a))
	push_warning("unknown item " + model)
	return {"g": node(null)}


static func _noanchor(r: Dictionary) -> Dictionary:
	r.erase("anchors")
	return r


static func _can(p: Dictionary) -> Dictionary:
	var g := node(null)
	var r := 0.029
	var h := 0.135
	cyl(g, r * 0.99, r * 0.99, h, mat(0xb8b8b8, 0.35, 0.6), Vector3(0, h / 2, 0))
	band(g, r, h * 0.96, tmat(p.get("tex", "can_volt"), 0.4, {"metallic": 0.4}), h / 2)
	cyl(g, r * 0.86, r, 0.008, mat(0xb8b8b8, 0.3, 0.7), Vector3(0, h + 0.004, 0))
	if p.get("crushed", false):
		g.scale = Vector3(1.12, 0.62, 0.9)
	return {"g": g, "lie": r}


static func _cup(p: Dictionary) -> Dictionary:
	var g := node(null)
	cyl(g, 0.052, 0.04, 0.08, mat(0xf4efe6, 0.7), Vector3(0, 0.04, 0))
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0525
	cm.bottom_radius = 0.0405
	cm.height = 0.079
	cm.cap_top = false
	cm.cap_bottom = false
	cm.radial_segments = 32
	var lab := tmat(p.get("tex", "cup_red"), 0.7)
	mi(g, cm, lab, Vector3(0, 0.04, 0)).rotation.y = -PI / 2
	cyl(g, 0.049, 0.049, 0.002, mat(0x3a2a1a, 1.0), Vector3(0, 0.0795, 0))
	var lid := box(g, Vector3(0.09, 0.002, 0.08), mat(0xe9e2d2), Vector3(0.03, 0.084, 0.035))
	lid.rotation = Vector3(-0.7, 0, 0.15)
	return {"g": g, "lie": 0.046}


static func _lunchbox() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.2, 0.035, 0.15), mat(0x161616, 0.5), Vector3(0, 0.0175, 0))
	box(g, Vector3(0.06, 0.01, 0.05), mat(0x8a6a3a), Vector3(-0.05, 0.037, 0.02))
	box(g, Vector3(0.05, 0.01, 0.06), mat(0xd4c9a8), Vector3(0.05, 0.037, -0.02))
	box(g, Vector3(0.198, 0.014, 0.148), mat(0xd8e4e8, 0.1, 0.0, {"alpha": 0.3}), Vector3(0, 0.042, 0))
	return {"g": g}


static func _bottle(p: Dictionary) -> Dictionary:
	var g := node(null)
	var m := mat(int(p.get("color", 0xcfe6f2)), 0.1, 0.0, {"alpha": float(p.get("alpha", 0.45))})
	cyl(g, 0.032, 0.032, 0.17, m, Vector3(0, 0.085, 0))
	cyl(g, 0.012, 0.03, 0.04, m, Vector3(0, 0.19, 0))
	cyl(g, 0.014, 0.014, 0.018, mat(int(p.get("cap", 0x2a6fd6))), Vector3(0, 0.219, 0))
	cyl(g, 0.0325, 0.0325, 0.05, mat(int(p.get("label", 0x2d8ad6))), Vector3(0, 0.1, 0))
	return {"g": g, "lie": 0.032}


static func _bag(p: Dictionary) -> Dictionary:
	var g := node(null)
	var m := mat(int(p.get("color", 0x121315)), 0.32, 0.1)
	var s := SphereMesh.new()
	s.radius = 0.24
	s.height = 0.48
	s.radial_segments = 20
	s.rings = 12
	var bm := deformed(s, func(v):
		var k := 1.0 + (hash3(v * 9.0) - 0.5) * 0.2
		return Vector3(v.x * k, v.y * k * 0.82 + 0.2, v.z * k))
	mi(g, bm, m, Vector3.ZERO)
	var k := sph(g, 0.045, m, Vector3(0, 0.41, 0))
	k.scale = Vector3(1, 1.5, 1)
	return {"g": g}


static func _paper_ball(p: Dictionary) -> Dictionary:
	var g := node(null)
	var s := SphereMesh.new()
	s.radius = 0.036
	s.height = 0.072
	s.radial_segments = 9
	s.rings = 5
	var bm := deformed(s, func(v):
		var k := 0.72 + hash3(v * 40.0) * 0.55
		return v * k + Vector3(0, 0.03, 0), true)
	mi(g, bm, mat(int(p.get("color", 0xeeeae0)), 0.95), Vector3.ZERO)
	return {"g": g}


static func _parcel(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 0.34)
	var h: float = p.get("h", 0.2)
	var d: float = p.get("d", 0.26)
	var t := tmat(p.get("tex", "parcel_plain"), 0.9)
	t.uv1_triplanar = true
	t.uv1_scale = Vector3(2.6, 2.6, 2.6)
	box(g, Vector3(w, h, d), t, Vector3(0, h / 2, 0))
	return {"g": g}


static func _books() -> Dictionary:
	var g := node(null)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var y := 0.0
	for c in [0x2e4a7a, 0x7a2e2e, 0x3b6b4a, 0xc9a43a]:
		var h := 0.028 + rng.randf() * 0.02
		var w := 0.19 + rng.randf() * 0.04
		var d := 0.26 + rng.randf() * 0.03
		var b := box(g, Vector3(w, h, d), mat(c, 0.8), Vector3((rng.randf() - 0.5) * 0.02, y + h / 2, (rng.randf() - 0.5) * 0.02))
		box(b, Vector3(w - 0.01, h * 0.8, 0.004), mat(0xf2eee4, 1.0), Vector3(0.006, 0, d / 2 + 0.001))
		b.rotation.y = (rng.randf() - 0.5) * 0.3
		y += h
	return {"g": g}


static func _suit() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.42, 0.06, 0.55), mat(0x1f2638, 0.85), Vector3(0, 0.03, 0))
	box(g, Vector3(0.15, 0.012, 0.12), mat(0xf2f2f2), Vector3(0, 0.066, -0.2))
	box(g, Vector3(0.04, 0.012, 0.22), mat(0x7a1d2a), Vector3(0, 0.07, -0.08))
	box(g, Vector3(0.45, 0.085, 0.6), mat(0xffffff, 0.1, 0.0, {"alpha": 0.12}), Vector3(0, 0.043, 0))
	return {"g": g, "view": Vector3(70, 0, 0), "anchors": {"front": {"p": Vector3(0, 0.086, 0.1), "n": Vector3.UP, "r": 0.12}}}


static func _pill_body(g: Node3D, texname: String, glass: int, cap: int, alpha: float) -> void:
	var r := 0.022
	var h := 0.075
	cyl(g, r, r, h, mat(glass, 0.2, 0.0, {"alpha": alpha}), Vector3(0, h / 2, 0))
	band(g, r + 0.0008, h * 0.64, tmat(texname, 0.7), h * 0.5)
	cyl(g, r + 0.002, r + 0.002, 0.02, mat(cap, 0.5), Vector3(0, h + 0.01, 0))


static func _pill(p: Dictionary) -> Dictionary:
	var g := node(null)
	_pill_body(g, "pill_e1", 0xa8561c, 0xf4f4f4, 0.82)
	return {"g": g, "lie": 0.024, "view": Vector3.ZERO, "anchors": {
		"label": {"p": Vector3(0, 0.0375, 0.0235), "n": Vector3.BACK, "r": 0.015},
		"back": {"p": Vector3(0, 0.0375, -0.0235), "n": Vector3.FORWARD, "r": 0.015},
		"bottom": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.016}}}


static func _pill_trio() -> Dictionary:
	var g := node(null)
	var caps := [0x2c6fd1, 0xd14b2c, 0x2ca86b]
	for i in range(3):
		var s := node(g, Vector3(-0.056 + i * 0.056, 0, 0))
		s.rotation.y = (i - 1) * 0.25
		_pill_body(s, "pill_t%d" % i, 0xf0f0f0, caps[i], 0.85)
	return {"g": g, "view": Vector3.ZERO, "anchors": {
		"label": {"p": Vector3(0, 0.0375, 0.0238), "n": Vector3.BACK, "r": 0.016},
		"back": {"p": Vector3(0, 0.0375, -0.0238), "n": Vector3.FORWARD, "r": 0.02}}}


static func _phone(p: Dictionary) -> Dictionary:
	var g := node(null)
	var k: String = p.get("tex", "e1")
	var w := 0.072
	var d := 0.152
	var t := 0.009
	box(g, Vector3(w, t, d), mat(int(p.get("case", 0x22252b)), 0.4), Vector3(0, t / 2, 0))
	var sm := tmat("phone_%s_%s" % [k, "dead" if p.get("dead", false) else "screen"], 0.25, {"emit_tex": true, "emission_energy_multiplier": 0.25})
	plane_up(g, w * 0.96, d * 0.97, sm, Vector3(0, t + 0.0004, 0))
	plane_down(g, w * 0.99, d * 0.99, tmat("phone_%s_back" % k, 0.4), Vector3(0, -0.0004, 0))
	var res := {"g": g, "view": Vector3(90, 0, 0), "screen_mat": sm, "lit_tex": "phone_%s_screen" % k, "anchors": {
		"screen": {"p": Vector3(0, t, 0), "n": Vector3.UP, "r": 0.03},
		"back": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.03}}}
	if p.get("smudge", false):
		uv_decal(res, w * 0.94, d * 0.94, "phone_%s_uv" % k, Vector3(0, t + 0.0009, 0), false)
	return res


static func _flip() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.05, 0.02, 0.096), mat(0x8d9096, 0.35, 0.6), Vector3(0, 0.01, 0))
	box(g, Vector3(0.051, 0.003, 0.006), mat(0x444444), Vector3(0, 0.0195, -0.032))
	plane_up(g, 0.028, 0.02, tmat("flip_disp", 0.3, {"emit_tex": true, "emission_energy_multiplier": 0.5}), Vector3(0, 0.0204, 0.012))
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {"front": {"p": Vector3(0, 0.02, 0.01), "n": Vector3.UP, "r": 0.022}}}


static func _frame(p: Dictionary) -> Dictionary:
	var g := node(null)
	var W := 0.18
	var H := 0.23
	var T := 0.022
	var fm := mat(int(p.get("fcolor", 0x6b4a2e)), 0.55)
	box(g, Vector3(W, 0.02, T), fm, Vector3(0, 0.01, 0))
	box(g, Vector3(W, 0.02, T), fm, Vector3(0, H - 0.01, 0))
	box(g, Vector3(0.02, H, T), fm, Vector3(-W / 2 + 0.01, H / 2, 0))
	box(g, Vector3(0.02, H, T), fm, Vector3(W / 2 - 0.01, H / 2, 0))
	var ph := quad(g, H - 0.04, W - 0.04, tmat(p.photo, 0.3), Vector3(0, H / 2, 0.002))
	ph.rotation.z = PI / 2
	box(g, Vector3(W - 0.02, H - 0.02, 0.006), fm, Vector3(0, H / 2, -T / 2 + 0.003))
	var bq := quad(g, W - 0.025, H - 0.025, tmat(p.back, 0.9), Vector3(0, H / 2, -T / 2 - 0.0002))
	bq.rotation.y = PI
	var leg := box(g, Vector3(0.03, 0.14, 0.006), mat(0x9b8461), Vector3(0, 0.07, -T / 2 - 0.03))
	leg.rotation.x = -0.35
	return {"g": g, "view": Vector3.ZERO, "anchors": {
		"front": {"p": Vector3(0, H / 2, 0.004), "n": Vector3.BACK, "r": 0.05},
		"back": {"p": Vector3(0, H * 0.6, -T / 2 - 0.001), "n": Vector3.FORWARD, "r": 0.05}}}


static func _calendar(texname: String) -> Dictionary:
	var g := node(null)
	var W := 0.3
	var H := 0.44
	var T := 0.004
	box(g, Vector3(W, H, T), mat(0xeeeeee), Vector3(0, H / 2, 0))
	quad(g, W, H, tmat(texname, 0.9), Vector3(0, H / 2, T / 2 + 0.0004))
	box(g, Vector3(W, 0.015, 0.01), mat(0x888888, 0.4, 0.6), Vector3(0, H - 0.004, 0))
	return {"g": g, "view": Vector3.ZERO, "anchors": {"front": {"p": Vector3(0, H * 0.45, T / 2 + 0.001), "n": Vector3.BACK, "r": 0.08}}}


static func _jbox() -> Dictionary:
	var g := node(null)
	var W := 0.22
	var H := 0.09
	var D := 0.15
	var outer := tmat("najeon_box", 0.28)
	var inner := mat(0x6e1420, 1.0)
	var lac := mat(0x150e0c, 0.3)
	box(g, Vector3(W, H * 0.7, D), lac, Vector3(0, H * 0.35, 0))
	quad(g, W - 0.004, H * 0.7 - 0.004, outer, Vector3(0, H * 0.35, D / 2 + 0.0004))
	plane_up(g, W - 0.01, D - 0.01, inner, Vector3(0, H * 0.7 + 0.0004, 0))
	var pivot := node(g, Vector3(0, H * 0.7, -D / 2))
	pivot.name = "lid"
	box(pivot, Vector3(W, H * 0.3, D), lac, Vector3(0, H * 0.15, D / 2))
	plane_up(pivot, W - 0.004, D - 0.004, outer, Vector3(0, H * 0.3 + 0.0004, D / 2))
	plane_down(pivot, W - 0.01, D - 0.01, inner, Vector3(0, -0.0004, D / 2))
	var brass := mat(0xc9a14a, 0.3, 0.75)
	box(g, Vector3(0.075, 0.028, 0.006), mat(0x2a1a10), Vector3(0, H * 0.38, D / 2 + 0.003))
	for i in range(4):
		var c := cyl(g, 0.009, 0.009, 0.012, brass, Vector3(-0.027 + i * 0.018, H * 0.38, D / 2 + 0.006), 12)
		c.rotation.z = PI / 2
	var res := {"g": g, "view": Vector3(12, 0, 0), "lid": pivot, "anchors": {
		"dial": {"p": Vector3(0, H * 0.38, D / 2 + 0.016), "n": Vector3.BACK, "r": 0.03},
		"bottom": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.055}}}
	uv_decal(res, W * 0.9, D * 0.9, "jbox_uv", Vector3(0, -0.0009, 0), true)
	return res


static func _swatch() -> Dictionary:
	var g := node(null)
	var band_m := mat(0xf1b9c6, 0.8)
	box(g, Vector3(0.022, 0.004, 0.075), band_m, Vector3(0, 0.002, -0.058))
	box(g, Vector3(0.022, 0.004, 0.075), band_m, Vector3(0, 0.002, 0.058))
	box(g, Vector3(0.038, 0.011, 0.045), mat(0x1c1c1e, 0.3, 0.4), Vector3(0, 0.0055, 0))
	plane_up(g, 0.032, 0.038, tmat("swatch_screen", 0.15, {"emit_tex": true, "emission_energy_multiplier": 0.4}), Vector3(0, 0.0112, 0))
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"face": {"p": Vector3(0, 0.0113, 0), "n": Vector3.UP, "r": 0.018},
		"back": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.018}}}


static func _wwatch() -> Dictionary:
	var g := node(null)
	var strap := mat(0x4a2e1c, 0.8)
	box(g, Vector3(0.018, 0.003, 0.08), strap, Vector3(0, 0.0015, -0.06))
	box(g, Vector3(0.018, 0.003, 0.08), strap, Vector3(0, 0.0015, 0.06))
	cyl(g, 0.019, 0.019, 0.009, mat(0xc0c0c0, 0.25, 0.8), Vector3(0, 0.0045, 0), 28)
	plane_up(g, 0.034, 0.034, tmat("wwatch_face", 0.2, {"alpha_tex": true}), Vector3(0, 0.0092, 0))
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"face": {"p": Vector3(0, 0.0093, 0), "n": Vector3.UP, "r": 0.017},
		"back": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.017}}}


static func _diary() -> Dictionary:
	var res := flat(null, 0.15, 0.21, 0.022, "diary_cover", "diary_back", 0xf8f3ea)
	uv_decal(res, 0.14, 0.2, "diary_uv", Vector3(0, -0.0009, 0), true)
	return res


static func _thermo() -> Dictionary:
	var g := node(null)
	var W := 0.06
	var H := 0.22
	var T := 0.012
	box(g, Vector3(W, H, T), mat(0xc9a878), Vector3(0, H / 2, 0))
	quad(g, W, H, tmat("thermo", 0.8), Vector3(0, H / 2, T / 2 + 0.0004))
	return {"g": g, "view": Vector3.ZERO, "anchors": {"face": {"p": Vector3(0, H * 0.5, T / 2 + 0.001), "n": Vector3.BACK, "r": 0.028}}}


static func _scarf() -> Dictionary:
	var g := node(null)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.15, 0.012, 0.48)
	bm.subdivide_depth = 10
	var sm := deformed(bm, func(v): return Vector3(v.x, v.y + sin(v.z * 18.0) * 0.006, v.z))
	mi(g, sm, mat(0x9c2a2e, 1.0), Vector3(0, 0.008, 0))
	plane_up(g, 0.15, 0.48, tmat("scarf", 1.0), Vector3(0, 0.0145, 0))
	sph(g, 0.04, mat(0x9c2a2e, 1.0), Vector3(0.12, 0.04, -0.18))
	var wood := mat(0xc89a62, 0.5)
	var n1 := cyl(g, 0.002, 0.002, 0.3, wood, Vector3(-0.02, 0.02, -0.25), 6)
	n1.rotation = Vector3(PI / 2, 0, 0.5)
	var n2 := cyl(g, 0.002, 0.002, 0.3, wood, Vector3(0.02, 0.02, -0.25), 6)
	n2.rotation = Vector3(PI / 2, 0, -0.5)
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"end": {"p": Vector3(0, 0.016, 0.17), "n": Vector3.UP, "r": 0.05},
		"needle": {"p": Vector3(0, 0.02, -0.22), "n": Vector3.UP, "r": 0.05}}}


static func _glasses() -> Dictionary:
	var g := node(null)
	var m := mat(0x7a5a2a, 0.4, 0.5)
	var lens := mat(0xdfe8ee, 0.05, 0.0, {"alpha": 0.25})
	for sx in [-1, 1]:
		ring(g, 0.022, 0.0022, m, Vector3(sx * 0.027, 0.024, 0))
		var c := CylinderMesh.new()
		c.top_radius = 0.021
		c.bottom_radius = 0.021
		c.height = 0.001
		mi(g, c, lens, Vector3(sx * 0.027, 0.024, 0)).rotation.x = PI / 2
		box(g, Vector3(0.004, 0.003, 0.1), m, Vector3(sx * 0.05, 0.03, -0.05))
	box(g, Vector3(0.012, 0.003, 0.003), m, Vector3(0, 0.03, 0))
	return {"g": g, "view": Vector3.ZERO}


static func _camera() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.1, 0.06, 0.028), mat(0xbfc3c7, 0.35, 0.6), Vector3(0, 0.03, 0))
	var l := cyl(g, 0.018, 0.02, 0.02, mat(0x222222, 0.3, 0.5), Vector3(0.015, 0.03, 0.024))
	l.rotation.x = PI / 2
	var lg := cyl(g, 0.011, 0.011, 0.002, mat(0x223355, 0.05, 0.5), Vector3(0.015, 0.03, 0.035))
	lg.rotation.x = PI / 2
	box(g, Vector3(0.06, 0.04, 0.002), mat(0x111111, 0.2), Vector3(-0.008, 0.032, -0.015))
	return {"g": g, "view": Vector3.ZERO, "anchors": {"back": {"p": Vector3(-0.008, 0.032, -0.0165), "n": Vector3.FORWARD, "r": 0.025}}}


static func _teddy() -> Dictionary:
	var g := node(null)
	var m := mat(0xa87a52, 1.0)
	var dk := mat(0x1a1410, 0.4)
	var b := sph(g, 0.07, m, Vector3(0, 0.07, 0))
	b.scale = Vector3(1, 1.08, 0.9)
	sph(g, 0.052, m, Vector3(0, 0.17, 0))
	sph(g, 0.02, m, Vector3(-0.038, 0.21, 0))
	sph(g, 0.02, m, Vector3(0.038, 0.21, 0))
	sph(g, 0.022, mat(0xd8b48e, 1.0), Vector3(0, 0.16, 0.045))
	sph(g, 0.006, dk, Vector3(-0.018, 0.182, 0.045))
	sph(g, 0.006, dk, Vector3(0.018, 0.182, 0.045))
	sph(g, 0.007, dk, Vector3(0, 0.165, 0.065))
	for v in [Vector3(-0.07, 0.09, 0.02), Vector3(0.07, 0.09, 0.02)]:
		sph(g, 0.026, m, v)
	for v in [Vector3(-0.04, 0.02, 0.05), Vector3(0.04, 0.02, 0.05)]:
		sph(g, 0.03, m, v)
	return {"g": g, "view": Vector3.ZERO}


static func _mkbox() -> Dictionary:
	var g := node(null)
	var W := 0.24
	var H := 0.13
	var D := 0.15
	var pink := mat(0xf2b8c8, 0.35)
	var dk := mat(0xd897aa, 0.4)
	box(g, Vector3(W, H, D), pink, Vector3(0, H / 2 + 0.02, 0))
	box(g, Vector3(W, 0.02, D), dk, Vector3(0, 0.01, 0))
	var drawer := node(g)
	drawer.name = "fb"
	box(drawer, Vector3(W * 0.9, 0.016, D * 0.92), mat(0xe8a5b8, 0.5), Vector3(0, 0.01, 0))
	var lt := plane_up(drawer, 0.1, 0.07, tmat("mkbox_letter", 0.9), Vector3(0, 0.0185, 0))
	lt.name = "fbLetter"
	lt.visible = false
	var hm := TorusMesh.new()
	hm.inner_radius = 0.033
	hm.outer_radius = 0.047
	var hn := mi(g, hm, dk, Vector3(0, H + 0.02, 0))
	hn.rotation.x = PI / 2
	hn.scale = Vector3(1, 1, 0.5)
	box(g, Vector3(0.03, 0.02, 0.008), mat(0xd8c08c, 0.3, 0.7), Vector3(0, H * 0.8, D / 2 + 0.004))
	return {"g": g, "view": Vector3(12, 0, 0), "drawer": drawer, "anchors": {
		"top": {"p": Vector3(0, H + 0.021, 0.03), "n": Vector3.UP, "r": 0.05},
		"bottom": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.06},
		"front": {"p": Vector3(0, H * 0.6, D / 2 + 0.001), "n": Vector3.BACK, "r": 0.04}}}


static func _shake(p: Dictionary) -> Dictionary:
	var g := node(null)
	cyl(g, 0.034, 0.034, 0.16, mat(0xf6f4f0, 0.4), Vector3(0, 0.08, 0))
	cyl(g, 0.035, 0.035, 0.03, mat(int(p.get("cap", 0xf08aa8)), 0.4), Vector3(0, 0.175, 0))
	band(g, 0.0345, 0.06, tmat("shake_label", 0.7), 0.08)
	return {"g": g, "lie": 0.035}


static func _salad() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.16, 0.055, 0.16), mat(0xeaf2f0, 0.1, 0.0, {"alpha": 0.4}), Vector3(0, 0.0275, 0))
	var leaf := mat(0x6aa34d, 1.0)
	for i in range(6):
		var s := sph(g, 0.03, leaf, Vector3((i % 3 - 1) * 0.04, 0.025, (i / 3 - 0.5) * 0.05), 8)
		s.scale.y = 0.5
	sph(g, 0.015, mat(0xd8452e), Vector3(0.03, 0.035, 0.02), 8)
	return {"g": g}


static func _sidedish(p: Dictionary) -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.12, 0.045, 0.09), mat(0xf2f2ee, 0.1, 0.0, {"alpha": 0.5}), Vector3(0, 0.0225, 0))
	box(g, Vector3(0.11, 0.02, 0.08), mat(int(p.get("food", 0x5c6b4a)), 1.0), Vector3(0, 0.012, 0))
	for i in range(5):
		sph(g, 0.008, mat(0xcfd8c8, 1.0), Vector3((i - 2) * 0.02, 0.024, ((i * 7) % 3 - 1) * 0.02), 6)
	var lid := box(g, Vector3(0.125, 0.008, 0.095), mat(int(p.get("lid", 0xc7372f)), 0.5), Vector3(0.02, 0.004, 0.08))
	lid.rotation.y = 0.4
	return {"g": g}


static func _newspaper() -> Dictionary:
	var g := node(null)
	var t := tmat("newspaper", 0.95)
	for i in range(5):
		var s := node(g, Vector3((i % 2) * 0.01, 0.003 + i * 0.006, (i % 3) * 0.008))
		box(s, Vector3(0.3, 0.006, 0.42), mat(0xd2cec2, 1.0), Vector3.ZERO)
		plane_up(s, 0.3, 0.42, t, Vector3(0, 0.0031, 0))
		s.rotation.y = (i - 2) * 0.05
	return {"g": g}


static func _yogurt() -> Dictionary:
	var g := node(null)
	cyl(g, 0.017, 0.02, 0.062, mat(0xf2f0ea, 0.4), Vector3(0, 0.031, 0), 16)
	cyl(g, 0.0222, 0.0222, 0.025, mat(0xe86f8e, 0.6), Vector3(0, 0.03, 0), 16)
	cyl(g, 0.0135, 0.0135, 0.002, mat(0xd94a6a), Vector3(0, 0.063, 0), 16)
	return {"g": g, "lie": 0.02}


static func _candle() -> Dictionary:
	var g := node(null)
	cyl(g, 0.04, 0.04, 0.002, mat(0xf3eedc, 0.6), Vector3(0, 0.001, 0), 18)
	cyl(g, 0.018, 0.02, 0.035, mat(0xf3eedc, 0.6), Vector3(0, 0.0175, 0), 14)
	cyl(g, 0.0015, 0.0015, 0.01, mat(0x111111), Vector3(0, 0.04, 0), 4)
	return {"g": g}


static func _cotton() -> Dictionary:
	var g := node(null)
	var m := mat(0xffffff, 1.0)
	for i in range(6):
		var s := sph(g, 0.018, m, Vector3((i % 3 - 1) * 0.03, 0.006, (i / 3 - 0.5) * 0.03), 8)
		s.scale = Vector3(1.1, 0.35, 1)
	return {"g": g}


static func _tub(p: Dictionary) -> Dictionary:
	var g := node(null)
	cyl(g, 0.04, 0.04, 0.09, mat(0xffffff, 0.4), Vector3(0, 0.045, 0))
	cyl(g, 0.042, 0.042, 0.02, mat(int(p.get("cap", 0x7bc39a)), 0.4), Vector3(0, 0.1, 0))
	band(g, 0.0405, 0.06, tmat(p.get("tex", "tub_slim"), 0.7), 0.045)
	return {"g": g, "lie": 0.042}


# ───────────────────────────── 4·5장 가구
static func _boiler_room() -> Dictionary:
	var g := node(null)
	var w := 0.6
	var d := 0.45
	var h := 2.1
	var wm := mat(0xe8e4dc, 0.6)
	box(g, Vector3(0.03, h, d), wm, Vector3(-w / 2 + 0.015, h / 2, 0))
	box(g, Vector3(0.03, h, d), wm, Vector3(w / 2 - 0.015, h / 2, 0))
	box(g, Vector3(w, 0.04, d), wm, Vector3(0, h - 0.02, 0))
	box(g, Vector3(w, h, 0.02), mat(0xcfc9bd, 0.8), Vector3(0, h / 2, -d / 2 + 0.01))
	box(g, Vector3(0.36, 0.5, 0.26), mat(0xf2f2ee, 0.4), Vector3(0, 1.3, -0.07))
	box(g, Vector3(0.12, 0.05, 0.01), mat(0x1b2420), Vector3(0, 1.4, 0.065))
	var pm := mat(0xb7b7b2, 0.35, 0.6)
	cyl(g, 0.045, 0.045, 0.22, pm, Vector3(0, 1.66, -0.07), 16)
	cyl(g, 0.05, 0.05, 0.3, pm, Vector3(0.03, 1.96, -0.07), 16)
	box(g, Vector3(0.22, 0.3, 0.004), mat(0x161412, 1.0, 0.0, {"alpha": 0.8}), Vector3(0.01, 1.82, -d / 2 + 0.023))
	var door := node(g, Vector3(w / 2 - 0.015, 0, d / 2))
	door.rotation.y = deg_to_rad(70)
	box(door, Vector3(w - 0.03, h - 0.05, 0.025), wm, Vector3(-(w - 0.03) / 2, h / 2, 0))
	for i in range(10):
		box(door, Vector3(w - 0.12, 0.018, 0.03), mat(0xd6d0c4, 0.7), Vector3(-(w - 0.03) / 2, 0.35 + i * 0.1, 0.006))
	return {"g": g, "foot": Vector2(w, d)}


static func _suitcase() -> Dictionary:
	var g := node(null)
	var shell := mat(0x2f5a8a, 0.4)
	box(g, Vector3(0.45, 0.12, 0.65), shell, Vector3(0, 0.06, 0))
	box(g, Vector3(0.4, 0.05, 0.28), mat(0xd9c7a6, 1.0), Vector3(0, 0.125, -0.15))
	box(g, Vector3(0.38, 0.04, 0.25), mat(0x6b7a8a, 1.0), Vector3(0.01, 0.12, 0.16))
	box(g, Vector3(0.1, 0.03, 0.07), mat(0xf2c230, 0.6), Vector3(0.12, 0.152, 0.18))
	var lid := node(g, Vector3(0, 0.12, -0.325))
	lid.rotation.x = deg_to_rad(-100)
	box(lid, Vector3(0.45, 0.04, 0.65), shell, Vector3(0, 0.02, 0.325))
	box(g, Vector3(0.12, 0.02, 0.02), mat(0x222222), Vector3(0, 0.08, 0.335))
	return {"g": g, "foot": Vector2(0.45, 0.66)}


static func _pc_desk(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.6)
	var d := 0.6
	var h := 0.74
	box(g, Vector3(w, 0.03, d), mat(0x1e1f22, 0.4), Vector3(0, h - 0.015, 0))
	for sx in [-1, 1]:
		box(g, Vector3(0.05, h - 0.03, d - 0.05), mat(0x2a2b2e, 0.4, 0.4), Vector3(sx * (w / 2 - 0.04), (h - 0.03) / 2, 0))
	for i in range(2):
		var mx := -0.27 + i * 0.54
		box(g, Vector3(0.52, 0.32, 0.03), mat(0x111214, 0.3), Vector3(mx, h + 0.3, -d / 2 + 0.12))
		var scr := tmat("monitor_draw" if i == 0 else "monitor_chat", 0.3, {"emit_tex": true, "emission_energy_multiplier": 0.9})
		quad(g, 0.49, 0.29, scr, Vector3(mx, h + 0.3, -d / 2 + 0.136))
		box(g, Vector3(0.05, 0.14, 0.05), mat(0x222326, 0.4, 0.4), Vector3(mx, h + 0.08, -d / 2 + 0.1))
		box(g, Vector3(0.22, 0.015, 0.15), mat(0x222326, 0.4, 0.4), Vector3(mx, h + 0.008, -d / 2 + 0.1))
	box(g, Vector3(0.44, 0.02, 0.14), mat(0x2a2c30, 0.5), Vector3(0, h + 0.01, 0.06))
	box(g, Vector3(0.3, 0.012, 0.2), mat(0x18181a, 0.4), Vector3(0.48, h + 0.006, 0.08))
	box(g, Vector3(0.2, 0.42, 0.42), mat(0x141518, 0.35, 0.3), Vector3(-w / 2 + 0.16, 0.21, 0.0))
	return {"g": g, "foot": Vector2(w, d)}


static func _gaming_chair() -> Dictionary:
	var g := node(null)
	var m := mat(0x1d1f24, 0.6)
	box(g, Vector3(0.5, 0.08, 0.5), m, Vector3(0, 0.48, 0))
	var back := box(g, Vector3(0.5, 0.8, 0.08), m, Vector3(0, 0.92, 0.24))
	back.rotation.x = 0.12
	var stripe := box(g, Vector3(0.22, 0.62, 0.085), mat(0x7a2a3a, 0.6), Vector3(0, 0.95, 0.236))
	stripe.rotation.x = 0.12
	cyl(g, 0.03, 0.03, 0.4, mat(0x444444, 0.3, 0.6), Vector3(0, 0.24, 0), 10)
	for i in range(5):
		var a := i / 5.0 * TAU
		var leg := box(g, Vector3(0.3, 0.03, 0.04), mat(0x2a2a2a, 0.4, 0.4), Vector3(cos(a) * 0.15, 0.05, sin(a) * 0.15))
		leg.rotation.y = -a
		sph(g, 0.025, mat(0x111111, 0.5), Vector3(cos(a) * 0.3, 0.025, sin(a) * 0.3), 8)
	for sx in [-1, 1]:
		box(g, Vector3(0.06, 0.04, 0.3), m, Vector3(sx * 0.27, 0.68, 0.02))
		box(g, Vector3(0.03, 0.18, 0.03), m, Vector3(sx * 0.27, 0.58, 0.08))
	return {"g": g, "foot": Vector2(0.55, 0.55)}


static func _bookshelf(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.0)
	var d := 0.32
	var h := 1.8
	var wm := mat(0x3a3330, 0.6)
	box(g, Vector3(0.03, h, d), wm, Vector3(-w / 2 + 0.015, h / 2, 0))
	box(g, Vector3(0.03, h, d), wm, Vector3(w / 2 - 0.015, h / 2, 0))
	box(g, Vector3(w, h, 0.02), wm, Vector3(0, h / 2, -d / 2 + 0.01))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var cols := [0x8a3a3a, 0x3a5a8a, 0xd8c070, 0x4a7a5a, 0xe8e0d0, 0x6a4a7a, 0x2a2a2e, 0xc06040]
	for s in range(6):
		var y := 0.03 + s * 0.35
		box(g, Vector3(w - 0.03, 0.025, d - 0.02), wm, Vector3(0, y, 0))
		if s == 5:
			break
		var x := -w / 2 + 0.05
		while x < w / 2 - 0.08:
			var bw := 0.02 + rng.randf() * 0.03
			var bh := 0.18 + rng.randf() * 0.1
			if rng.randf() < 0.12:
				var fig := cyl(g, 0.03, 0.035, 0.12, mat(cols[rng.randi() % cols.size()], 0.5), Vector3(x + 0.03, y + 0.075, 0.02), 10)
				sph(g, 0.03, mat(0xe8c8a8, 0.6), fig.position + Vector3(0, 0.09, 0), 8)
				x += 0.09
				continue
			box(g, Vector3(bw, bh, d - 0.08), mat(cols[rng.randi() % cols.size()], 0.8), Vector3(x + bw / 2, y + 0.0125 + bh / 2, 0.01))
			x += bw + 0.004
	return {"g": g, "foot": Vector2(w, d)}


static func _aircon() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.8, 0.28, 0.2), mat(0xf4f4f2, 0.35), Vector3.ZERO)
	box(g, Vector3(0.72, 0.03, 0.02), mat(0xcfcfcb, 0.5), Vector3(0, -0.11, 0.1))
	sph(g, 0.008, mat(0x2a2a2a, 0.3, 0.0, {"emit": 0x3aff6a, "emit_e": 2.0}), Vector3(0.32, 0.06, 0.101), 6)
	return {"g": g}


static func _fan() -> Dictionary:
	var g := node(null)
	var m := mat(0xe8e8e4, 0.45)
	cyl(g, 0.16, 0.18, 0.04, m, Vector3(0, 0.02, 0), 20)
	cyl(g, 0.015, 0.015, 0.95, m, Vector3(0, 0.5, 0), 10)
	var head := node(g, Vector3(0, 1.0, 0.02))
	ring(head, 0.17, 0.01, m, Vector3(0, 0, 0.06))
	for i in range(3):
		var a := i * TAU / 3.0
		var bl := box(head, Vector3(0.05, 0.13, 0.008), mat(0xaecde0, 0.4, 0.0, {"alpha": 0.8}), Vector3(-sin(a) * 0.065, cos(a) * 0.065, 0.06))
		bl.rotation.z = a
	var hub := cyl(head, 0.05, 0.05, 0.09, m, Vector3(0, 0, -0.01), 12)
	hub.rotation.x = PI / 2
	return {"g": g, "foot": Vector2(0.3, 0.3)}


static func _trays() -> Dictionary:
	var g := node(null)
	for i in range(5):
		var t := box(g, Vector3(0.36, 0.02, 0.27), mat(0xc9d8c0 if i % 2 == 0 else 0xe6dcc6, 0.5), Vector3((i % 2) * 0.01, 0.01 + i * 0.022, (i % 3) * 0.008))
		t.rotation.y = (i - 2) * 0.04
	for v in [Vector3(-0.09, 0.13, -0.05), Vector3(0.08, 0.13, -0.05)]:
		cyl(g, 0.045, 0.035, 0.04, mat(0xf2f0ea, 0.3), v, 14)
	return {"g": g, "foot": Vector2(0.38, 0.3)}


# ───────────────────────────── 4·5장 유품
static func _standing_box(w: float, h: float, d: float, texname: String, side: int) -> Dictionary:
	var g := node(null)
	box(g, Vector3(w, h, d), mat(side, 0.6), Vector3(0, h / 2, 0))
	quad(g, w - 0.002, h - 0.002, tmat(texname, 0.6), Vector3(0, h / 2, d / 2 + 0.0005))
	return {"g": g, "view": Vector3.ZERO, "anchors": {
		"front": {"p": Vector3(0, h / 2, d / 2 + 0.001), "n": Vector3.BACK, "r": min(w, h) * 0.4},
		"back": {"p": Vector3(0, h / 2, -d / 2 - 0.001), "n": Vector3.FORWARD, "r": min(w, h) * 0.4}}}


static func _laptop() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.32, 0.018, 0.22), mat(0x3a3c42, 0.35, 0.3), Vector3(0, 0.009, 0))
	plane_up(g, 0.3, 0.2, tmat("laptop_keys", 0.6), Vector3(0, 0.0185, 0))
	var pivot := node(g, Vector3(0, 0.018, -0.11))
	pivot.rotation.x = deg_to_rad(-105)
	box(pivot, Vector3(0.32, 0.01, 0.22), mat(0x3a3c42, 0.35, 0.3), Vector3(0, 0.005, 0.11))
	plane_down(pivot, 0.3, 0.2, tmat("laptop_lock", 0.2, {"emit_tex": true, "emission_energy_multiplier": 0.35}), Vector3(0, -0.0005, 0.11))
	var n := Vector3(0, 0.2588, 0.9659)
	var c := Vector3(0, 0.124, -0.138)
	return {"g": g, "view": Vector3.ZERO, "anchors": {
		"screen": {"p": c, "n": n, "r": 0.08},
		"back": {"p": c - n * 0.011, "n": -n, "r": 0.08}}}


static func _giftbox() -> Dictionary:
	var g := node(null)
	var W := 0.32
	var H := 0.1
	var D := 0.24
	var wrap := node(g)
	var wm := tmat("gift_wrap", 0.7)
	wm.uv1_triplanar = true
	wm.uv1_scale = Vector3(3, 3, 3)
	box(wrap, Vector3(W, H, D), wm, Vector3(0, H / 2, 0))
	var rib := mat(0xb8323a, 0.5)
	box(wrap, Vector3(0.03, H + 0.004, D + 0.004), rib, Vector3(0, H / 2, 0))
	box(wrap, Vector3(W + 0.004, H + 0.004, 0.03), rib, Vector3(0, H / 2, 0))
	sph(wrap, 0.03, rib, Vector3(0, H + 0.01, 0), 10).scale = Vector3(1.6, 0.6, 1.0)
	var tag := plane_up(wrap, 0.1, 0.055, tmat("gift_tag", 0.9), Vector3(0.09, H + 0.002, 0.06))
	tag.rotation.y = 0.3
	var inner := node(g)
	box(inner, Vector3(W, 0.02, D), mat(0x6b4a2e, 0.55), Vector3(0, 0.01, 0))
	plane_up(inner, W - 0.03, D - 0.03, tmat("portrait_family", 0.4), Vector3(0, 0.0205, 0))
	inner.visible = false
	return {"g": g, "view": Vector3(35, 0, 0), "unwrap": {"hide": wrap, "show": inner}, "anchors": {
		"top": {"p": Vector3(0, H, 0), "n": Vector3.UP, "r": 0.07},
		"front": {"p": Vector3(0, H / 2, D / 2 + 0.001), "n": Vector3.BACK, "r": 0.04}}}


static func _dress() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.34, 0.03, 0.46), mat(0x2b3a5a, 0.9), Vector3(0, 0.015, 0))
	box(g, Vector3(0.14, 0.006, 0.05), mat(0xf2efe8, 0.8), Vector3(0, 0.033, -0.2))
	var tg := plane_up(g, 0.05, 0.075, tmat("price_tag", 0.9), Vector3(0.11, 0.0315, 0.12))
	tg.rotation.y = -0.4
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"tag": {"p": Vector3(0.11, 0.031, 0.12), "n": Vector3.UP, "r": 0.04},
		"front": {"p": Vector3(-0.06, 0.03, -0.05), "n": Vector3.UP, "r": 0.06}}}


static func _figure() -> Dictionary:
	var g := node(null)
	cyl(g, 0.035, 0.035, 0.01, mat(0x222222, 0.4), Vector3(0, 0.005, 0), 16)
	cyl(g, 0.016, 0.022, 0.07, mat(0x5a6fa8, 0.5), Vector3(0, 0.045, 0), 12)
	sph(g, 0.02, mat(0xf0d4bc, 0.6), Vector3(0, 0.095, 0), 12)
	var hair := sph(g, 0.021, mat(0x2a2030, 0.5), Vector3(0, 0.1, -0.004), 12)
	hair.scale = Vector3(1.05, 0.9, 1.05)
	return {"g": g, "view": Vector3.ZERO, "anchors": {"bottom": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.03}}}


static func _uniform() -> Dictionary:
	var g := node(null)
	box(g, Vector3(0.36, 0.05, 0.42), mat(0xf4f4f0, 0.9), Vector3(0, 0.025, 0))
	var net := sph(g, 0.08, mat(0xffffff, 1.0), Vector3(0.1, 0.065, 0.12), 12)
	net.scale = Vector3(1, 0.3, 1)
	plane_up(g, 0.08, 0.032, tmat("uniform_tag", 0.8), Vector3(-0.09, 0.0505, -0.1))
	return {"g": g, "view": Vector3(75, 0, 0), "anchors": {"front": {"p": Vector3(-0.09, 0.05, -0.1), "n": Vector3.UP, "r": 0.05}}}


static func _piping_kit() -> Dictionary:
	var g := node(null)
	var cone := cyl(g, 0.045, 0.004, 0.18, mat(0xe8e8e2, 0.4, 0.0, {"alpha": 0.85}), Vector3(0, 0.045, 0), 16)
	cone.rotation.z = PI / 2
	for i in range(4):
		cyl(g, 0.008, 0.004, 0.02, mat(0xc0c0c0, 0.25, 0.8), Vector3(-0.06 + i * 0.03, 0.01, 0.07), 10)
	return {"g": g, "view": Vector3(60, 0, 0), "anchors": {"top": {"p": Vector3(0, 0.09, 0), "n": Vector3.UP, "r": 0.05}}}


static func _onigiri() -> Dictionary:
	var g := node(null)
	var pm := PrismMesh.new()
	pm.size = Vector3(0.09, 0.08, 0.03)
	var n := mi(g, pm, mat(0xf4f4f0, 0.6), Vector3(0, 0.015, 0))
	n.rotation.x = -PI / 2
	box(g, Vector3(0.09, 0.031, 0.025), mat(0x1c1c1c, 0.6), Vector3(0, 0.0155, 0.028))
	return {"g": g}
