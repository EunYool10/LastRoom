class_name Build
extends RefCounted
## 3D 모델 공용 도구: 재질 · 둥근 상자 · 회전체 · 관 · 글자 · 부품 합치기.
## 가구는 furn.gd, 유품은 relic.gd, 손과 도구는 viewmodel.gd

const DEG := PI / 180.0
const PBR_TILE := {"wood": 1.5, "woodh": 1.5, "fabric": 18.0, "knit": 11.0, "fleece": 4.0, "leather": 9.0, "plastic": 14.0, "brushed": 5.0, "paint": 2.5, "rust": 2.5, "card": 5.0, "paper": 5.0}
const PBR_BUMP := {"wood": 0.16, "woodh": 0.16, "fabric": 0.7, "knit": 0.75, "fleece": 0.7, "leather": 0.45, "plastic": 0.12, "brushed": 0.3, "paint": 0.35, "rust": 0.55, "card": 0.5, "paper": 0.3}
## 버튼 · 건반에 새길 글자 (assets/tex/pbr/glyphs.png 한 칸 64px, 16칸씩)
const GLYPHS := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ+-*#.:/%()°▲▼◀▶●■=,<>?!&~'[];전원온도난방수예약외출강중정지회타이머풍량바람세기열림닫잠금문선택확인취소메뉴음채널입력등급냉장동에너효율초일시한자영아들ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔㅁㄴㅇㄹㅎㅗㅓㅏㅣㅋㅌㅊㅍㅠㅜㅡ"
const PBR_NORMAL := {"fabric": true, "knit": true, "fleece": true, "leather": true, "rust": true}
const GLYPH_COLS := 16
const GLYPH_ROWS := 12
static var _mats := {}
static var _tex := {}
static var _meshes := {}
## 0이면 (품질 낮음) 작은 부품을 단순하게
static var detail := 1


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


## 실제 표면 결이 있는 재질: 나뭇결 · 직물 · 뜨개 · 가죽 · 플라스틱 · 헤어라인 금속 · 도장 · 녹 · 골판지 · 종이.
## UV가 필요 없도록 물체 좌표로 세 방향에서 입힌다
static func pbr(kind: String, hex: int, rough := 0.8, metal := 0.0, extra := {}, tile := 1.0) -> StandardMaterial3D:
	var key := "pbr|%s|%x|%s|%s|%s|%s|%d" % [kind, hex, rough, metal, str(extra), tile, detail]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	var c := (col(hex) * 1.1).clamp(Color(0, 0, 0, 1), Color(1, 1, 1, 1))
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.albedo_texture = tex("pbr/%s_a" % kind)
	if detail > 0:
		m.roughness_texture = tex("pbr/%s_r" % kind)
	# 법선 지도는 결이 눈에 띄는 재질만 (세 방향으로 읽어 비싸다)
	if detail > 0 and PBR_NORMAL.has(kind):
		m.normal_enabled = true
		m.normal_texture = tex("pbr/%s_n" % kind)
		m.normal_scale = float(PBR_BUMP[kind])
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 6.0
	m.uv1_scale = Vector3.ONE * float(PBR_TILE[kind]) * tile
	_apply(m, extra)
	_mats[key] = m
	return m


static func wood(hex: int, rough := 0.55, across := false) -> StandardMaterial3D:
	return pbr("woodh" if across else "wood", hex, rough)


static func plastic(hex: int, rough := 0.5) -> StandardMaterial3D:
	return pbr("plastic", hex, rough)


static func cloth_m(hex: int, rough := 1.0) -> StandardMaterial3D:
	return pbr("fabric", hex, rough)


static func knit_m(hex: int) -> StandardMaterial3D:
	return pbr("knit", hex, 1.0)


static func leather(hex: int, rough := 0.55) -> StandardMaterial3D:
	return pbr("leather", hex, rough)


static func painted(hex: int, rough := 0.42) -> StandardMaterial3D:
	return pbr("paint", hex, rough)


static func steel(hex := 0xb9bdc0, rough := 0.34) -> StandardMaterial3D:
	return pbr("brushed", hex, rough, 0.6)


## 작은 물건용: 결이 곱다
static func steel_fine(hex := 0xb9bdc0, rough := 0.34) -> StandardMaterial3D:
	return pbr("brushed", hex, rough, 0.6, {}, 7.0)


static func chrome(hex := 0xd4d7da, rough := 0.16) -> StandardMaterial3D:
	return mat(hex, rough, 0.72)


static func brass(hex := 0xc9a75a, rough := 0.3) -> StandardMaterial3D:
	return mat(hex, rough, 0.68)


static func rubber(hex := 0x161617) -> StandardMaterial3D:
	return mat(hex, 0.92)


static func glass(hex := 0xdfe8ee, a := 0.22, rough := 0.06) -> StandardMaterial3D:
	return mat(hex, rough, 0.0, {"alpha": a, "metallic_specular": 0.8})


static func tmat(name: String, rough := 0.8, extra := {}) -> StandardMaterial3D:
	var key := "t|%s|%s|%s" % [name, rough, str(extra)]
	if _mats.has(key) and not extra.has("emit_tex"):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(name)
	m.roughness = rough
	_apply(m, extra)
	_mats[key] = m
	return m


static func node(parent: Node, pos := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	if parent:
		parent.add_child(n)
	return n


## 움직이거나 코드에서 찾는 부품 (합치지 않는다)
static func pivot(parent: Node, nm: String, pos := Vector3.ZERO) -> Node3D:
	var n := node(parent, pos)
	n.name = nm
	return n


static func mi(parent: Node, mesh: Mesh, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = m
	n.position = pos
	parent.add_child(n)
	return n


## 충돌 판정에서 빠지는 작은 장식
static func ghost(n: MeshInstance3D) -> MeshInstance3D:
	n.set_meta("ghost", true)
	return n


static func box(parent: Node, size: Vector3, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var key := "b|%s" % size
	if not _meshes.has(key):
		_meshes[key] = _box_mesh(size)
	return mi(parent, _meshes[key], m, pos)


static func cyl(parent: Node, rt: float, rb: float, h: float, m: Material, pos := Vector3.ZERO, seg := 24) -> MeshInstance3D:
	var key := "c|%.5f|%.5f|%.5f|%d" % [rt, rb, h, seg]
	if not _meshes.has(key):
		_meshes[key] = _cyl_mesh(rt, rb, h, seg)
	return mi(parent, _meshes[key], m, pos)


## 앞(+Z)을 향해 누운 원통 (버튼 · 노브 · 렌즈)
static func cylz(parent: Node, r: float, h: float, m: Material, pos := Vector3.ZERO, seg := 16) -> MeshInstance3D:
	var n := cyl(parent, r, r, h, m, pos, seg)
	n.rotation.x = PI / 2.0
	return n


static func sph(parent: Node, r: float, m: Material, pos := Vector3.ZERO, seg := 16) -> MeshInstance3D:
	var key := "s|%.5f|%d" % [r, seg]
	if not _meshes.has(key):
		_meshes[key] = _sph_mesh(r, seg, maxi(4, seg / 2))
	return mi(parent, _meshes[key], m, pos)


## XY 평면에 놓인 고리 (앞면 +Z)
static func ring(parent: Node, r: float, tube_r: float, m: Material, pos := Vector3.ZERO, rings := 40, segs := 10) -> MeshInstance3D:
	var key := "r|%.5f|%.5f|%d|%d" % [r, tube_r, rings, segs]
	if not _meshes.has(key):
		_meshes[key] = _torus_mesh(r, tube_r, rings, segs)
	var n := mi(parent, _meshes[key], m, pos)
	n.rotation.x = PI / 2.0
	return n


## a에서 b까지 잇는 가는 원통 (다리 · 버팀대 · 전선)
static func rod(parent: Node, a: Vector3, b: Vector3, r: float, m: Material, seg := 8) -> MeshInstance3D:
	var n := cyl(parent, r, r, a.distance_to(b), m, (a + b) / 2.0, seg)
	var y := (b - a).normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	n.basis = Basis(x, y, x.cross(y))
	return n


## 모서리가 둥글게 깎인 상자 (면 + 모서리 띠만: 삼각형 108개). 빛이 모서리에 맺혀 상자 티가 나지 않는다
static func rbox(parent: Node, size: Vector3, r: float, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	if detail == 0 or r <= 0.0:
		return box(parent, size, m, pos)
	return mi(parent, _rbox_mesh(size, r, 0.0), m, pos)


## 키캡: 위가 살짝 좁고 모서리가 둥글다. 원점은 바닥 가운데
static func keycap(parent: Node, w: float, d: float, h: float, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	return mi(parent, _rbox_mesh(Vector3(w, h, d), minf(w, d) * 0.14, 0.14), m, pos + Vector3(0, h / 2.0, 0))


static func _rbox_mesh(size: Vector3, r: float, taper: float) -> ArrayMesh:
	var key := "rb|%s|%.5f|%.3f" % [size, r, taper]
	if _meshes.has(key):
		return _meshes[key]
	var h := size / 2.0
	r = minf(r, minf(h.x, minf(h.y, h.z)) * 0.95)
	var inner := h - Vector3.ONE * r
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var UV := PackedVector2Array()
	var I := PackedInt32Array()
	var faces := [[Vector3.RIGHT, Vector3.FORWARD, Vector3.UP], [Vector3.LEFT, Vector3.BACK, Vector3.UP], [Vector3.UP, Vector3.RIGHT, Vector3.FORWARD], [Vector3.DOWN, Vector3.RIGHT, Vector3.BACK], [Vector3.BACK, Vector3.RIGHT, Vector3.UP], [Vector3.FORWARD, Vector3.LEFT, Vector3.UP]]
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var hu: float = absf(h.dot(u))
		var hv: float = absf(h.dot(v))
		var hn: float = absf(h.dot(n))
		var us := [-hu, -hu + r, hu - r, hu]
		var vs := [-hv, -hv + r, hv - r, hv]
		var base := V.size()
		for j in 4:
			for i in 4:
				var p: Vector3 = u * float(us[i]) + v * float(vs[j]) + n * hn
				var c := p.clamp(-inner, inner)
				var d := p - c
				var nrm := n
				if d.length() > 0.0000001:
					nrm = d.normalized()
					p = c + nrm * r
				if taper > 0.0:
					var k: float = 1.0 - taper * clampf((p.y + h.y) / size.y, 0.0, 1.0)
					p.x *= k
					p.z *= k
				V.append(p)
				N.append(nrm)
				UV.append(Vector2(float(us[i]) / (2.0 * hu) + 0.5, 0.5 - float(vs[j]) / (2.0 * hv)))
		for j in 3:
			for i in 3:
				var a := base + j * 4 + i
				var b := a + 1
				var d := a + 4
				var c := d + 1
				I.append_array([a, d, c, a, c, b])
	var am := _commit(V, N, UV, I)
	_meshes[key] = am
	return am


static func _box_mesh(size: Vector3) -> ArrayMesh:
	var h := size / 2.0
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var UV := PackedVector2Array()
	var I := PackedInt32Array()
	for f in [[Vector3.RIGHT, Vector3.FORWARD, Vector3.UP], [Vector3.LEFT, Vector3.BACK, Vector3.UP], [Vector3.UP, Vector3.RIGHT, Vector3.FORWARD], [Vector3.DOWN, Vector3.RIGHT, Vector3.BACK], [Vector3.BACK, Vector3.RIGHT, Vector3.UP], [Vector3.FORWARD, Vector3.LEFT, Vector3.UP]]:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var c := n * absf(h.dot(n))
		var a := u * absf(h.dot(u))
		var b := v * absf(h.dot(v))
		var base := V.size()
		V.append_array([c - a - b, c + a - b, c + a + b, c - a + b])
		N.append_array([n, n, n, n])
		UV.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		I.append_array([base, base + 3, base + 2, base, base + 2, base + 1])
	return _commit(V, N, UV, I)


static func _cyl_mesh(rt: float, rb: float, h: float, seg: int) -> ArrayMesh:
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var UV := PackedVector2Array()
	var I := PackedInt32Array()
	var hy := h / 2.0
	var slope := (rb - rt) / maxf(h, 0.00001)
	for s in seg + 1:
		var a := TAU * s / seg
		var sa := sin(a)
		var ca := cos(a)
		var nrm := Vector3(sa, slope, ca).normalized()
		V.append(Vector3(rb * sa, -hy, rb * ca))
		N.append(nrm)
		UV.append(Vector2(float(s) / seg, 1.0))
		V.append(Vector3(rt * sa, hy, rt * ca))
		N.append(nrm)
		UV.append(Vector2(float(s) / seg, 0.0))
	for s in seg:
		var a := s * 2
		I.append_array([a, a + 1, a + 3, a, a + 3, a + 2])
	for cap in [[hy, rt, 1.0], [-hy, rb, -1.0]]:
		var r: float = cap[1]
		if r <= 0.0:
			continue
		var y: float = cap[0]
		var sg: float = cap[2]
		var base := V.size()
		V.append(Vector3(0, y, 0))
		N.append(Vector3(0, sg, 0))
		UV.append(Vector2(0.5, 0.5))
		for s in seg + 1:
			var a := TAU * s / seg
			V.append(Vector3(r * sin(a), y, r * cos(a)))
			N.append(Vector3(0, sg, 0))
			UV.append(Vector2(sin(a) * 0.5 + 0.5, cos(a) * 0.5 + 0.5))
		for s in seg:
			if sg > 0.0:
				I.append_array([base, base + 2 + s, base + 1 + s])
			else:
				I.append_array([base, base + 1 + s, base + 2 + s])
	return _commit(V, N, UV, I)


static func _sph_mesh(r: float, seg: int, rings: int) -> ArrayMesh:
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var UV := PackedVector2Array()
	var I := PackedInt32Array()
	for j in rings + 1:
		var ph := PI * j / rings
		for s in seg + 1:
			var a := TAU * s / seg
			var d := Vector3(sin(ph) * sin(a), cos(ph), sin(ph) * cos(a))
			V.append(d * r)
			N.append(d)
			UV.append(Vector2(float(s) / seg, float(j) / rings))
	for j in rings:
		for s in seg:
			var tl := j * (seg + 1) + s
			var tr := tl + 1
			var bl := tl + seg + 1
			var br := bl + 1
			I.append_array([tl, tr, br, tl, br, bl])
	return _commit(V, N, UV, I)


static func _torus_mesh(r: float, tube_r: float, rings: int, segs: int) -> ArrayMesh:
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var UV := PackedVector2Array()
	var I := PackedInt32Array()
	for i in rings + 1:
		var th := TAU * i / rings
		var out_d := Vector3(sin(th), 0, cos(th))
		for j in segs + 1:
			var ph := TAU * j / segs
			var d := out_d * cos(ph) + Vector3.UP * sin(ph)
			V.append(out_d * r + d * tube_r)
			N.append(d)
			UV.append(Vector2(float(i) / rings, float(j) / segs))
	for i in rings:
		for j in segs:
			var a := i * (segs + 1) + j
			var d := a + 1
			var b := a + segs + 1
			var c := b + 1
			I.append_array([a, d, c, a, c, b])
	return _commit(V, N, UV, I)


static func _commit(V: PackedVector3Array, N: PackedVector3Array, UV: PackedVector2Array, I: PackedInt32Array) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = V
	arr[Mesh.ARRAY_NORMAL] = N
	arr[Mesh.ARRAY_TEX_UV] = UV
	arr[Mesh.ARRAY_INDEX] = I
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	am.set_meta("a", arr)
	return am


## 합칠 때 쓰는 정점 배열 (한 메시당 한 번만 읽는다)
static func _arrays_of(mesh: Mesh) -> Array:
	if mesh.has_meta("a"):
		return mesh.get_meta("a")
	var arr := mesh.surface_get_arrays(0)
	mesh.set_meta("a", arr)
	return arr


## 회전체: 단면 (반지름, 높이)를 아래에서 위로 잇는다. 꺾임이 crease도 넘으면 날을 세운다
static func lathe(parent: Node, prof: Array, m: Material, pos := Vector3.ZERO, seg := 24, crease := 42.0) -> MeshInstance3D:
	if detail == 0:
		seg = maxi(8, seg / 2)
	var key := "la|%s|%d|%.1f" % [str(prof), seg, crease]
	if not _meshes.has(key):
		_meshes[key] = _lathe_mesh(prof, seg, crease)
	return mi(parent, _meshes[key], m, pos)


static func _lathe_mesh(prof: Array, seg: int, crease: float) -> ArrayMesh:
	var cnt := prof.size()
	var sn := []
	for i in cnt - 1:
		var a: Vector2 = prof[i]
		var b: Vector2 = prof[i + 1]
		var t := (b - a).normalized()
		sn.append(Vector2(t.y, -t.x))
	var lim := cos(deg_to_rad(crease))
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var UV := PackedVector2Array()
	var I := PackedInt32Array()
	var total := 0.0
	for i in cnt - 1:
		total += (prof[i + 1] as Vector2).distance_to(prof[i])
	var run := 0.0
	for i in cnt - 1:
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		var cur: Vector2 = sn[i]
		var n0: Vector2 = cur
		var n1: Vector2 = cur
		if i > 0 and (sn[i - 1] as Vector2).dot(cur) > lim:
			n0 = ((sn[i - 1] as Vector2) + cur).normalized()
		if i < cnt - 2 and (sn[i + 1] as Vector2).dot(cur) > lim:
			n1 = ((sn[i + 1] as Vector2) + cur).normalized()
		var base := V.size()
		var v0 := run / maxf(total, 0.00001)
		run += p1.distance_to(p0)
		var v1 := run / maxf(total, 0.00001)
		for s in seg + 1:
			var a := TAU * s / seg
			var sa := sin(a)
			var ca := cos(a)
			V.append(Vector3(p0.x * sa, p0.y, p0.x * ca))
			N.append(Vector3(n0.x * sa, n0.y, n0.x * ca).normalized())
			UV.append(Vector2(float(s) / seg, 1.0 - v0))
			V.append(Vector3(p1.x * sa, p1.y, p1.x * ca))
			N.append(Vector3(n1.x * sa, n1.y, n1.x * ca).normalized())
			UV.append(Vector2(float(s) / seg, 1.0 - v1))
		for s in seg:
			var a := base + s * 2
			var d := a + 1
			var b := a + 2
			var c := a + 3
			I.append_array([a, d, c, a, c, b])
	return _commit(V, N, UV, I)


## 곡선을 따라가는 관 (전선 · 손잡이 · 옷걸이 · 수도꼭지). 기본은 충돌 없음
static func tube(parent: Node, pts: Array, r: float, m: Material, seg := 6, smooth := true, sub := 5, pos := Vector3.ZERO, radii := []) -> MeshInstance3D:
	var sub_n := (sub if detail > 0 else 2) if smooth and pts.size() > 2 else 1
	var path: Array = _spline(pts, sub_n) if sub_n > 1 else pts
	var cnt := path.size()
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var UV := PackedVector2Array()
	var I := PackedInt32Array()
	var t0: Vector3 = ((path[1] as Vector3) - (path[0] as Vector3)).normalized()
	var up := Vector3.UP if absf(t0.y) < 0.9 else Vector3.RIGHT
	var nrm := t0.cross(up).normalized()
	var frames := []
	for i in cnt:
		var a: Vector3 = path[maxi(0, i - 1)]
		var b: Vector3 = path[mini(cnt - 1, i + 1)]
		var t := (b - a).normalized()
		nrm = (nrm - t * nrm.dot(t)).normalized()
		frames.append([path[i], nrm, t.cross(nrm).normalized(), t])
	for i in cnt:
		var f: Array = frames[i]
		var ri := _radius_at(radii, r, float(i) / sub_n)
		for s in seg + 1:
			var a := TAU * s / seg
			var dir: Vector3 = (f[1] as Vector3) * cos(a) + (f[2] as Vector3) * sin(a)
			V.append((f[0] as Vector3) + dir * ri)
			N.append(dir)
			UV.append(Vector2(float(s) / seg, float(i) / maxi(1, cnt - 1)))
	for i in cnt - 1:
		for s in seg:
			var a := i * (seg + 1) + s
			var b := a + 1
			var d := a + seg + 1
			var c := d + 1
			I.append_array([a, d, c, a, c, b])
	for e in [0, cnt - 1]:
		var f: Array = frames[e]
		var ax: Vector3 = (f[3] as Vector3) * (-1.0 if e == 0 else 1.0)
		var re := _radius_at(radii, r, float(e) / sub_n)
		var base := V.size()
		V.append(f[0])
		N.append(ax)
		UV.append(Vector2(0.5, 0.5))
		for s in seg + 1:
			var a := TAU * s / seg
			V.append((f[0] as Vector3) + ((f[1] as Vector3) * cos(a) + (f[2] as Vector3) * sin(a)) * re)
			N.append(ax)
			UV.append(Vector2(0.5, 0.5))
		for s in seg:
			if e == 0:
				I.append_array([base, base + 1 + s, base + 2 + s])
			else:
				I.append_array([base, base + 2 + s, base + 1 + s])
	return ghost(mi(parent, _commit(V, N, UV, I), m, pos))


## 단면을 이어 붙인 매끈한 몸체 (분무기 머리 · 손잡이 · 솔 몸통 · 손바닥).
## sections: [[중심 Vector3, X쪽 반폭, 그에 수직인 반폭, 모남 (2 타원 ~ 6 네모)], ...]. 중심선은 YZ 평면에서 굽는다
static func loft(parent: Node, sections: Array, m: Material, pos := Vector3.ZERO, seg := 24, sub := 5) -> MeshInstance3D:
	if detail == 0:
		seg = maxi(10, seg / 2)
		sub = maxi(2, sub / 2)
	var rows := []
	var n := sections.size()
	for i in n - 1:
		var s0: Array = sections[maxi(0, i - 1)]
		var s1: Array = sections[i]
		var s2: Array = sections[i + 1]
		var s3: Array = sections[mini(n - 1, i + 2)]
		for k in sub:
			var w := float(k) / sub
			rows.append([(s1[0] as Vector3).cubic_interpolate(s2[0], s0[0], s3[0], w), cubic_interpolate(float(s1[1]), float(s2[1]), float(s0[1]), float(s3[1]), w), cubic_interpolate(float(s1[2]), float(s2[2]), float(s0[2]), float(s3[2]), w), lerpf(float(s1[3]), float(s2[3]), w)])
	rows.append(sections[n - 1])
	var cnt := rows.size()
	var V := PackedVector3Array()
	var UV := PackedVector2Array()
	var I := PackedInt32Array()
	var tangents := []
	for i in cnt:
		var t: Vector3 = ((rows[mini(cnt - 1, i + 1)][0] as Vector3) - (rows[maxi(0, i - 1)][0] as Vector3)).normalized()
		tangents.append(t)
		var hv := t.cross(Vector3.RIGHT).normalized()
		var c: Vector3 = rows[i][0]
		var a := maxf(float(rows[i][1]), 0.00005)
		var bh := maxf(float(rows[i][2]), 0.00005)
		var ex: float = 2.0 / maxf(float(rows[i][3]), 1.0)
		for j in seg:
			var th := TAU * j / seg
			var cs := cos(th)
			var sn := sin(th)
			V.append(c + Vector3.RIGHT * a * signf(cs) * pow(absf(cs), ex) + hv * bh * signf(sn) * pow(absf(sn), ex))
			UV.append(Vector2(float(j) / seg, float(i) / maxi(1, cnt - 1)))
	var N := PackedVector3Array()
	N.resize(V.size())
	for i in cnt:
		for j in seg:
			var around: Vector3 = V[i * seg + (j + 1) % seg] - V[i * seg + (j + seg - 1) % seg]
			var along: Vector3 = V[mini(cnt - 1, i + 1) * seg + j] - V[maxi(0, i - 1) * seg + j]
			N[i * seg + j] = around.cross(along).normalized()
	for i in cnt - 1:
		for j in seg:
			var j2 := (j + 1) % seg
			var a := i * seg + j
			var bq := i * seg + j2
			var d := (i + 1) * seg + j
			var c := (i + 1) * seg + j2
			I.append_array([a, d, c, a, c, bq])
	# 양 끝 마개
	for e in [0, cnt - 1]:
		var ax: Vector3 = (tangents[e] as Vector3) * (-1.0 if e == 0 else 1.0)
		var base := V.size()
		V.append(rows[e][0])
		N.append(ax)
		UV.append(Vector2(0.5, 0.5))
		for j in seg:
			V.append(V[e * seg + j])
			N.append(ax)
			UV.append(Vector2(0.5, 0.5))
		for j in seg:
			var j2 := (j + 1) % seg
			if e == 0:
				I.append_array([base, base + 1 + j, base + 1 + j2])
			else:
				I.append_array([base, base + 1 + j2, base + 1 + j])
	return ghost(mi(parent, _commit(V, N, UV, I), m, pos))


static func _radius_at(radii: Array, r: float, k: float) -> float:
	if radii.is_empty():
		return r
	var i0: int = clampi(int(k), 0, radii.size() - 1)
	var i1: int = clampi(i0 + 1, 0, radii.size() - 1)
	return lerpf(float(radii[i0]), float(radii[i1]), k - float(i0))


static func _spline(pts: Array, sub: int) -> Array:
	var out := []
	var n := pts.size()
	for i in n - 1:
		var p0: Vector3 = pts[maxi(0, i - 1)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(n - 1, i + 2)]
		for s in sub:
			out.append(p1.cubic_interpolate(p2, p0, p3, float(s) / sub))
	out.append(pts[n - 1])
	return out


## 네 귀가 둥근 판 (휴대폰 몸통 · 버튼 · 플레이트). 앞면 +Y, 원점은 두께 가운데, 윗면 UV는 PlaneMesh와 같다
static func plate(parent: Node, w: float, d: float, t: float, rc: float, m: Material, pos := Vector3.ZERO, bevel := 0.0, cs := 5) -> MeshInstance3D:
	if detail == 0:
		cs = 2
	var key := "pl|%.5f|%.5f|%.5f|%.5f|%.5f|%d" % [w, d, t, rc, bevel, cs]
	if _meshes.has(key):
		return mi(parent, _meshes[key], m, pos)
	var b := bevel if bevel > 0.0 else minf(t * 0.2, 0.002)
	var outer := _outline(w, d, rc, 0.0, cs)
	var top := _outline(w, d, rc, b, cs)
	var cnt := outer.size()
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var UV := PackedVector2Array()
	var I := PackedInt32Array()
	var hy := t / 2.0
	# 위 · 아래 면 (부채꼴)
	for side in [1.0, -1.0]:
		var base := V.size()
		V.append(Vector3(0, hy * side, 0))
		N.append(Vector3(0, side, 0))
		UV.append(Vector2(0.5, 0.5))
		for i in cnt:
			var p: Vector2 = top[i]
			V.append(Vector3(p.x, hy * side, p.y))
			N.append(Vector3(0, side, 0))
			UV.append(Vector2(p.x / w + 0.5, p.y / d + 0.5))
		for i in cnt:
			var i2 := (i + 1) % cnt
			if side > 0.0:
				I.append_array([base, base + 1 + i2, base + 1 + i])
			else:
				I.append_array([base, base + 1 + i, base + 1 + i2])
	# 옆면과 깎은 모서리 (네 줄)
	var rows := [[top, hy, 0.75], [outer, hy - b, 0.32], [outer, -hy + b, -0.32], [top, -hy, -0.75]]
	var base := V.size()
	for r in rows:
		var ring_p: Array = r[0]
		for i in cnt:
			var p: Vector2 = ring_p[i]
			var o: Vector2 = outer[i]
			var prev: Vector2 = outer[(i + cnt - 1) % cnt]
			var nxt: Vector2 = outer[(i + 1) % cnt]
			var tg := (nxt - prev).normalized()
			var dir := Vector2(tg.y, -tg.x)
			if dir.dot(o) < 0.0:
				dir = -dir
			var k: float = r[2]
			V.append(Vector3(p.x, float(r[1]), p.y))
			N.append(Vector3(dir.x * (1.0 - absf(k)), k, dir.y * (1.0 - absf(k))).normalized())
			UV.append(Vector2(p.x / w + 0.5, p.y / d + 0.5))
	for j in 3:
		for i in cnt:
			var i2 := (i + 1) % cnt
			var a := base + j * cnt + i
			var c := base + j * cnt + i2
			var e := base + (j + 1) * cnt + i
			var f := base + (j + 1) * cnt + i2
			I.append_array([a, c, f, a, f, e])
	var am := _commit(V, N, UV, I)
	_meshes[key] = am
	return mi(parent, am, m, pos)


static func _outline(w: float, d: float, rc: float, inset: float, cs: int) -> Array:
	var hw := w / 2.0 - inset
	var hd := d / 2.0 - inset
	var r := maxf(rc - inset, 0.0001)
	var o := []
	for q in [[hw - r, hd - r, 0.0], [hw - r, -hd + r, 90.0], [-hw + r, -hd + r, 180.0], [-hw + r, hd - r, 270.0]]:
		for s in cs + 1:
			var a := deg_to_rad(float(q[2]) + 90.0 * s / cs)
			o.append(Vector2(float(q[0]) + sin(a) * r, float(q[1]) + cos(a) * r))
	return o


## 방 벽 · 바닥 판: 텍스처 UV는 그대로, 두 번째 UV는 미터 단위 (표면 결용). facing "wall"이면 +Z, "up"이면 +Y
static func sheet(parent: Node, w: float, h: float, facing: String, m: Material, pos := Vector3.ZERO, tile := 1.0) -> MeshInstance3D:
	var hw := w / 2.0
	var hh := h / 2.0
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var UV := PackedVector2Array()
	var UV2 := PackedVector2Array()
	var nrm := Vector3.BACK if facing == "wall" else Vector3.UP
	for c in [[-1.0, 1.0, 0.0, 0.0], [1.0, 1.0, 1.0, 0.0], [1.0, -1.0, 1.0, 1.0], [-1.0, -1.0, 0.0, 1.0]]:
		var x: float = float(c[0]) * hw
		var y: float = float(c[1]) * hh
		V.append(Vector3(x, y, 0.0) if facing == "wall" else Vector3(x, 0.0, -y))
		N.append(nrm)
		UV.append(Vector2(float(c[2]), float(c[3])))
		UV2.append(Vector2(x, y) * tile)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = V
	arr[Mesh.ARRAY_NORMAL] = N
	arr[Mesh.ARRAY_TEX_UV] = UV
	arr[Mesh.ARRAY_TEX_UV2] = UV2
	var T := PackedFloat32Array()
	for i in 4:
		T.append_array([1.0, 0.0, 0.0, 1.0])
	arr[Mesh.ARRAY_TANGENT] = T
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var n := MeshInstance3D.new()
	n.mesh = am
	n.material_override = m
	n.position = pos
	parent.add_child(n)
	return n


## 앞(+Z)을 보는 plate
static func platez(parent: Node, w: float, h: float, t: float, rc: float, m: Material, pos := Vector3.ZERO, bevel := 0.0) -> MeshInstance3D:
	var n := plate(parent, w, h, t, rc, m, pos, bevel)
	n.rotation.x = PI / 2.0
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
	var key := "q|%.5f|%.5f" % [w, h]
	if not _meshes.has(key):
		var hw := w / 2.0
		var hh := h / 2.0
		_meshes[key] = _commit(PackedVector3Array([Vector3(-hw, hh, 0), Vector3(hw, hh, 0), Vector3(hw, -hh, 0), Vector3(-hw, -hh, 0)]), PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK]), PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]), PackedInt32Array([0, 1, 2, 0, 2, 3]))
	return ghost(mi(parent, _meshes[key], m, pos))


## +Y를 향한 판 (텍스처 위쪽이 -Z)
static func plane_up(parent: Node, w: float, d: float, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var key := "p|%.5f|%.5f" % [w, d]
	if not _meshes.has(key):
		var hw := w / 2.0
		var hd := d / 2.0
		_meshes[key] = _commit(PackedVector3Array([Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd), Vector3(hw, 0, hd), Vector3(-hw, 0, hd)]), PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP]), PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]), PackedInt32Array([0, 1, 2, 0, 2, 3]))
	return ghost(mi(parent, _meshes[key], m, pos))


## -Y를 향한 판 (위아래로 뒤집으면 바로 읽힘)
static func plane_down(parent: Node, w: float, d: float, m: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var n := plane_up(parent, w, d, m, pos)
	n.rotation.x = PI
	return n


## 원통 둘레 라벨 (u=0.25 지점이 +Z 정면, u=0.75가 뒷면)
static func band(parent: Node, r: float, h: float, m: Material, y: float, seg := 36) -> MeshInstance3D:
	var key := "ba|%.5f|%.5f|%d" % [r, h, seg]
	if not _meshes.has(key):
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
		_meshes[key] = st.commit()
	return ghost(mi(parent, _meshes[key], m, Vector3(0, y, 0)))


## 인쇄된 글자 · 숫자: "up"이면 +Y로 (글자 위쪽이 -Z), "front"면 +Z로. pos는 글줄의 가운데
static func text(parent: Node, s: String, h: float, m: Material, pos := Vector3.ZERO, facing := "front") -> MeshInstance3D:
	var key := "tx|%s|%.5f|%s" % [s, h, facing]
	if not _meshes.has(key):
		var V := PackedVector3Array()
		var N := PackedVector3Array()
		var UV := PackedVector2Array()
		var I := PackedInt32Array()
		var adv := 0.0
		for ch in s:
			adv += _adv(ch)
		var x := -adv * h / 2.0
		var nrm := Vector3.UP if facing == "up" else Vector3.BACK
		for ch in s:
			var a := _adv(ch) * h
			var idx := GLYPHS.find(ch)
			if idx >= 0:
				var cu := 1.0 / GLYPH_COLS
				var cv := 1.0 / GLYPH_ROWS
				var u0 := (idx % GLYPH_COLS) * cu
				var v0 := int(idx / GLYPH_COLS) * cv
				var cx := x + a / 2.0
				var base := V.size()
				for c in [[-1, 1, 0, 0], [1, 1, 1, 0], [1, -1, 1, 1], [-1, -1, 0, 1]]:
					var px: float = cx + float(c[0]) * h / 2.0
					var py: float = float(c[1]) * h / 2.0
					V.append(Vector3(px, 0, -py) if facing == "up" else Vector3(px, py, 0))
					N.append(nrm)
					UV.append(Vector2(u0 + float(c[2]) * cu, v0 + float(c[3]) * cv))
				I.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
			x += a
		_meshes[key] = _commit(V, N, UV, I) if not V.is_empty() else null
	return ghost(mi(parent, _meshes[key], m, pos))


static func _adv(ch: String) -> float:
	return 1.02 if ch.unicode_at(0) > 0x2E80 else 0.62


## 글자 재질: lit이면 스스로 빛나는 표시창 글자
static func ink(hex := 0xf0f0ee, lit := false) -> StandardMaterial3D:
	var key := "ink|%x|%s" % [hex, lit]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex("pbr/glyphs")
	m.albedo_color = col(hex)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.6
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if lit:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
	return m


static func hash3(v: Vector3) -> float:
	var s := sin(v.x * 127.1 + v.y * 311.7 + v.z * 74.7) * 43758.5453
	return s - floor(s)


static func deformed(prim: PrimitiveMesh, f: Callable, flat_n := false) -> ArrayMesh:
	var arr := prim.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] = f.call(verts[i])
	arr[Mesh.ARRAY_VERTEX] = verts
	var st := SurfaceTool.new()
	st.create_from_arrays(arr)
	if flat_n:
		st.deindex()
	st.generate_normals()
	var out := st.commit_to_arrays()
	var res := ArrayMesh.new()
	res.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	res.set_meta("a", out)
	return res


## 같은 색을 k만큼 어둡게 (음수면 밝게)
static func shade(c: int, k: float) -> int:
	var cc := col(c)
	cc = cc.darkened(k) if k >= 0.0 else cc.lightened(-k)
	return cc.to_rgba32() >> 8


# ───────────────────────────── 부품 합치기
## 만든 모델의 부품을 재질별 메시 하나로 합쳐 그리기 횟수를 줄인다.
## 움직이는 부품 (이름을 붙인 노드, res에 담긴 노드, uv_only)은 각자 따로 합친다.
## 충돌 상자는 합치기 전에 재서 meta "solids"에 남긴다 (room._solidify가 쓴다)
static func finish(res: Dictionary) -> Dictionary:
	var keep := {}
	for k in res:
		_mark_keep(res[k], keep)
	var root: Node3D = res.g
	_bake_unit(root, keep)
	return res


static func _mark_keep(v, keep: Dictionary) -> void:
	if v is Node:
		keep[v] = true
	elif v is Dictionary:
		for k in v:
			_mark_keep(v[k], keep)
	elif v is Array:
		for x in v:
			_mark_keep(x, keep)


static func _is_keep(n: Node, keep: Dictionary) -> bool:
	return keep.has(n) or n.has_meta("uv_only") or not String(n.name).begins_with("@")


static func _bake_unit(unit: Node3D, keep: Dictionary) -> void:
	var parts := []
	var solids := []
	var units := []
	_collect(unit, Transform3D.IDENTITY, keep, parts, solids, units)
	if not solids.is_empty():
		unit.set_meta("solids", solids)
	var groups := {}
	for p in parts:
		var mt: Material = p[1]
		if not groups.has(mt):
			groups[mt] = []
		groups[mt].append(p)
	var solid_am := ArrayMesh.new()
	var clear_am := ArrayMesh.new()
	for mt in groups:
		var am: ArrayMesh = clear_am if (mt as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED else solid_am
		_append_group(am, groups[mt], mt)
	for pair in [[solid_am, false], [clear_am, true]]:
		if (pair[0] as ArrayMesh).get_surface_count() > 0:
			var n := MeshInstance3D.new()
			n.mesh = pair[0]
			n.name = "baked_clear" if pair[1] else "baked"
			if pair[1]:
				n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			unit.add_child(n)
	for p in parts:
		(p[0] as Node).set_meta("baked", true)
	_prune(unit, keep)
	for u in units:
		_bake_unit(u, keep)


static func _collect(n: Node, xf: Transform3D, keep: Dictionary, parts: Array, solids: Array, units: Array) -> void:
	for c in n.get_children():
		if not (c is Node3D):
			continue
		if _is_keep(c, keep):
			units.append(c)
			continue
		var cxf: Transform3D = xf * (c as Node3D).transform
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null and (c as MeshInstance3D).visible:
			var mesh_i := c as MeshInstance3D
			parts.append([mesh_i, mesh_i.material_override, cxf])
			if not c.has_meta("ghost"):
				var a := mesh_i.get_aabb()
				if a.size.length() >= 0.09:
					var sc := cxf.basis.get_scale()
					var b := cxf.basis.orthonormalized()
					solids.append([Transform3D(b, cxf * a.get_center()), (a.size * sc).abs().max(Vector3(0.01, 0.01, 0.01))])
		_collect(c, cxf, keep, parts, solids, units)


static func _append_group(am: ArrayMesh, parts: Array, mt: Material) -> void:
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var UV := PackedVector2Array()
	var I := PackedInt32Array()
	for p in parts:
		var mesh: Mesh = (p[0] as MeshInstance3D).mesh
		var xf: Transform3D = p[2]
		var arr := _arrays_of(mesh)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var offset := V.size()
		V.append_array(xf * v)
		var nb: Basis = xf.basis.inverse().transposed()
		var src_n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var nn: PackedVector3Array = Transform3D(nb, Vector3.ZERO) * src_n
		if not xf.basis.get_scale().is_equal_approx(Vector3.ONE):
			for i in nn.size():
				nn[i] = nn[i].normalized()
		N.append_array(nn)
		var uv = arr[Mesh.ARRAY_TEX_UV]
		if uv == null or (uv as PackedVector2Array).size() != v.size():
			var blank := PackedVector2Array()
			blank.resize(v.size())
			UV.append_array(blank)
		else:
			UV.append_array(uv)
		var idx = arr[Mesh.ARRAY_INDEX]
		if idx == null or (idx as PackedInt32Array).is_empty():
			for i in v.size():
				I.append(offset + i)
		else:
			var src_i: PackedInt32Array = idx
			var base := I.size()
			I.resize(base + src_i.size())
			for i in src_i.size():
				I[base + i] = src_i[i] + offset
	var arrs := []
	arrs.resize(Mesh.ARRAY_MAX)
	arrs[Mesh.ARRAY_VERTEX] = V
	arrs[Mesh.ARRAY_NORMAL] = N
	arrs[Mesh.ARRAY_TEX_UV] = UV
	arrs[Mesh.ARRAY_INDEX] = I
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrs)
	am.surface_set_material(am.get_surface_count() - 1, mt)


## 합쳐진 원본 노드를 지운다. 안에 남길 노드가 있으면 그 경로의 빈 노드는 둔다
static func _prune(n: Node, keep: Dictionary) -> void:
	for c in n.get_children():
		if _is_keep(c, keep) or String(c.name).begins_with("baked"):
			continue
		_prune(c, keep)
		if c.get_child_count() == 0 and (c.has_meta("baked") or not (c is MeshInstance3D)):
			c.free()


# ───────────────────────────── 만들기
static func furniture(t: String, p: Dictionary) -> Dictionary:
	return finish(Furn.make(t, p))


static func item(model: String, p: Dictionary) -> Dictionary:
	return finish(Relic.make(model, p))


static func uv_decal(res: Dictionary, w: float, d: float, texname: String, pos: Vector3, down: bool) -> void:
	var m := tmat(texname, 1.0, {"add": true})
	var n := plane_down(res.g, w, d, m, pos) if down else plane_up(res.g, w, d, m, pos)
	n.visible = false
	n.set_meta("uv_only", true)
	if not res.has("uv"):
		res["uv"] = []
	res["uv"].append(n)
