class_name Relic
extends Build
## 유품 · 생활 쓰레기 모델. 크기 · 기준점 · 조사 지점(anchors)은 inspect.gd와 배치에 맞춰 둔다

static func make(model: String, p: Dictionary) -> Dictionary:
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
		"envelope": return _envelope(p)
		"paper": return flat(null, p.get("w", 0.21), p.get("d", 0.297), 0.0015, p.tex, "paper_back", 0xece6d8, 0.006)
		"postit": return flat(null, 0.076, 0.076, 0.001, p.get("tex", "postit") + "_f", p.get("tex", "postit") + "_b", 0xf2dc6e, 0.004)
		"photo": return flat(null, 0.15, 0.1, 0.0015, "photo_office", "photo_office_back", 0xf4f1ea, 0.002)
		"frame": return _frame(p)
		"calendar": return _calendar(p.get("tex", "calendar_e1"))
		"jbox": return _jbox()
		"bankbook": return _bound(0.09, 0.14, 0.006, "bank_cover", "", 0xe7e2d6)
		"letter": return flat(null, 0.15, 0.105, 0.003, p.tex + "_f", p.tex + "_b", 0xefe8d8, 0.003)
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
		"hotpack": return _pack(0.1, 0.13, 0.008, "hotpack", 0xefefea)
		"sidedish": return _sidedish(p)
		"ramen": return _pack(0.14, 0.18, 0.014, p.get("tex", "ramen_a"), 0xc23a2a)
		"newspaper": return _newspaper()
		"yogurt": return _yogurt()
		"candle": return _candle()
		"pouch": return _pack(0.09, 0.12, 0.003, "pouch", 0xf7f7f3)
		"cotton": return _cotton()
		"tub": return _tub(p)
		"ticket": return flat(null, 0.15, 0.065, 0.001, "ticket_f", "paper_back", 0xf2f0e6, 0.002)
		"logbook": return _bound(0.15, 0.21, 0.012, p.get("tex", "log") + "_cover", p.get("tex", "log") + "_back", 0xf0ece0)
		"sketchbook": return _sketchbook()
		"alarmBox": return _standing_box(0.12, 0.16, 0.05, "alarm_box", 0xf4f4f0)
		"socksBox": return _standing_box(0.13, 0.18, 0.04, "socks_box", 0xeaf2f6)
		"laptop": return _laptop()
		"giftbox": return _giftbox()
		"dress": return _dress()
		"figure": return _figure()
		"uniform": return _uniform()
		"pipingKit": return _piping_kit()
		"onigiri": return _onigiri()
		"breadbag": return _pack(0.2, 0.26, 0.04, "breadbag", 0xefe3c8)
		"snack": return _pack(0.16, 0.22, 0.03, "snack", 0xf2a33a)
	push_warning("unknown item " + model)
	return {"g": node(null)}


static func _noanchor(r: Dictionary) -> Dictionary:
	r.erase("anchors")
	return r


# ───────────────────────────── 종이 · 포장
## 얇은 판 (앞/뒤 텍스처) — 앞면 +Y, 원점은 바닥 중앙. 종이는 귀가 살짝 들린다
static func flat(_parent: Node, w: float, d: float, t: float, front: String, back: String, side := 0xe8e2d4, curl := 0.0) -> Dictionary:
	var g := node(null)
	var fm := tmat(front, 0.85)
	if curl > 0.0 and detail > 0:
		var bend := func(x: float, z: float) -> float:
			var u := (x / (w / 2.0))
			var v := (z / (d / 2.0))
			return curl * (0.4 * u * u + 0.6 * pow((u + 1.0) * 0.5 * (v + 1.0) * 0.5, 4.0))
		var top := PlaneMesh.new()
		top.size = Vector2(w, d)
		top.subdivide_width = 10
		top.subdivide_depth = 12
		mi(g, deformed(top, func(v): return Vector3(v.x, t + 0.0003 + bend.call(v.x, v.z), v.z)), fm, Vector3.ZERO)
		if back != "":
			var bot := PlaneMesh.new()
			bot.size = Vector2(w, d)
			bot.subdivide_width = 10
			bot.subdivide_depth = 12
			var flipm := deformed(bot, func(v): return Vector3(v.x, -v.y + 0.0 - 0.0001 + bend.call(v.x, -v.z), -v.z))
			mi(g, flipm, tmat(back, 0.85), Vector3.ZERO)
	else:
		box(g, Vector3(w, t, d), pbr("paper", side, 0.9), Vector3(0, t / 2.0, 0))
		plane_up(g, w, d, fm, Vector3(0, t + 0.0004, 0))
		if back != "":
			plane_down(g, w, d, tmat(back, 0.85), Vector3(0, -0.0004, 0))
	var r: float = minf(w, d) * 0.4
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"front": {"p": Vector3(0, t, 0), "n": Vector3.UP, "r": r},
		"back": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": r}}}


## 봉투: 뒤 덮개 삼각형이 도드라진다
static func _envelope(p: Dictionary) -> Dictionary:
	var r := flat(null, 0.22, 0.11, 0.004, "env_%s_f" % p.tex, "env_%s_b" % p.tex, 0xe4dbc6, 0.003)
	var g: Node3D = r.g
	var pm := pbr("paper", 0xdcd2ba, 0.9)
	box(g, Vector3(0.216, 0.0035, 0.106), pm, Vector3(0, 0.002, 0))
	return r


## 묶인 책자: 표지 · 페이지 덩어리 · 책등
static func _bound(w: float, d: float, t: float, cover: String, back: String, side: int) -> Dictionary:
	var g := node(null)
	var pages := pbr("paper", 0xf1ecde, 1.0)
	box(g, Vector3(w - 0.004, t - 0.002, d - 0.004), pages, Vector3(0.0005, t / 2.0, 0))
	box(g, Vector3(0.006, t, d), pbr("paper", side, 0.8), Vector3(-w / 2.0 + 0.003, t / 2.0, 0))
	plate(g, w, d, 0.0008, 0.002, pbr("paper", side, 0.8), Vector3(0, t - 0.0004, 0))
	plate(g, w, d, 0.0008, 0.002, pbr("paper", side, 0.8), Vector3(0, 0.0004, 0))
	plane_up(g, w, d, tmat(cover, 0.78), Vector3(0, t + 0.0004, 0))
	if back != "":
		plane_down(g, w, d, tmat(back, 0.78), Vector3(0, -0.0004, 0))
	var r: float = minf(w, d) * 0.4
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"front": {"p": Vector3(0, t, 0), "n": Vector3.UP, "r": r},
		"back": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": r}}}


static func _sketchbook() -> Dictionary:
	var res := _bound(0.21, 0.28, 0.015, "sketch_cover", "", 0xe8e2d4)
	var g: Node3D = res.g
	var wire := chrome(0x9a9a9a, 0.32)
	for i in 26:
		var z := -0.13 + i * 0.0104
		ring(g, 0.0088, 0.0011, wire, Vector3(-0.1035, 0.0075, z), 14, 4).set_meta("ghost", true)
	return res


## 비닐 · 은박 포장: 가운데가 부풀고 위아래를 톱니로 눌러 붙였다
static func _pack(w: float, d: float, t: float, texname: String, side: int) -> Dictionary:
	var g := node(null)
	var hw := w / 2.0
	var hd := d / 2.0 - 0.012
	var bulge := func(x: float, z: float, sign_y: float) -> float:
		var u := absf(x) / hw
		var v := absf(z) / hd
		var f := pow(maxf(0.0, 1.0 - pow(u, 4.0)), 0.75) * pow(maxf(0.0, 1.0 - pow(v, 5.0)), 0.75)
		var wr := (hash3(Vector3(x * 20.0, sign_y, z * 20.0)) - 0.5) * 0.25 + sin(x * 70.0 + z * 40.0) * 0.1
		return t * f * (1.0 + wr * f)
	var pl := PlaneMesh.new()
	pl.size = Vector2(w, d - 0.024)
	pl.subdivide_width = 14
	pl.subdivide_depth = 18
	var foil := {"metallic_specular": 0.85}
	mi(g, deformed(pl, func(v): return Vector3(v.x, bulge.call(v.x, v.z, 1.0), v.z)), tmat(texname, 0.32, foil), Vector3(0, 0.0004, 0))
	var pl2 := PlaneMesh.new()
	pl2.size = Vector2(w, d - 0.024)
	pl2.subdivide_width = 10
	pl2.subdivide_depth = 12
	mi(g, deformed(pl2, func(v): return Vector3(v.x, -0.0002, -v.z)), mat(side, 0.35, 0.05), Vector3.ZERO).set_meta("ghost", true)
	# 눌러 붙인 끝단 (세로 주름 톱니)
	var crimp := mat(shade(side, -0.08), 0.32, 0.08)
	for sz in [-1.0, 1.0]:
		box(g, Vector3(w, 0.0012, 0.024), crimp, Vector3(0, 0.001, float(sz) * (d / 2.0 - 0.012)))
		if detail > 0:
			var n := int(w / 0.006)
			for i in n:
				box(g, Vector3(0.0016, 0.0014, 0.02), mat(shade(side, 0.16), 0.3, 0.1), Vector3(-w / 2.0 + (i + 0.5) * w / n, 0.0018, float(sz) * (d / 2.0 - 0.012))).set_meta("ghost", true)
	return {"g": g}


## 세운 상자: 앞면 인쇄 · 뚜껑 덮개 틈 · 옆면 접합선
static func _standing_box(w: float, h: float, d: float, texname: String, side: int) -> Dictionary:
	var g := node(null)
	rbox(g, Vector3(w, h, d), 0.0012, pbr("card", side, 0.6), Vector3(0, h / 2.0, 0))
	quad(g, w - 0.002, h - 0.002, tmat(texname, 0.55), Vector3(0, h / 2.0, d / 2.0 + 0.0005))
	box(g, Vector3(w + 0.0008, 0.0006, d + 0.0008), mat(shade(side, 0.25), 0.8), Vector3(0, h - 0.018, 0)).set_meta("ghost", true)
	box(g, Vector3(0.0006, h, 0.0012), mat(shade(side, 0.25), 0.8), Vector3(w / 2.0, h / 2.0, d / 2.0 - 0.0005)).set_meta("ghost", true)
	return {"g": g, "view": Vector3.ZERO, "anchors": {
		"front": {"p": Vector3(0, h / 2.0, d / 2.0 + 0.001), "n": Vector3.BACK, "r": minf(w, h) * 0.4},
		"back": {"p": Vector3(0, h / 2.0, -d / 2.0 - 0.001), "n": Vector3.FORWARD, "r": minf(w, h) * 0.4}}}


static func _parcel(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 0.34)
	var h: float = p.get("h", 0.2)
	var d: float = p.get("d", 0.26)
	var t: StandardMaterial3D = tmat(p.get("tex", "parcel_plain"), 0.9).duplicate()
	t.uv1_triplanar = true
	t.uv1_scale = Vector3(2.6, 2.6, 2.6)
	rbox(g, Vector3(w, h, d), 0.003, t, Vector3(0, h / 2.0, 0))
	# 덮개 맞닿은 선 · 투명 테이프 · 송장
	box(g, Vector3(w * 0.998, 0.0006, 0.0018), mat(0x4a3a24, 0.9), Vector3(0, h + 0.0003, 0)).set_meta("ghost", true)
	var tape := mat(0xcbb78e, 0.25, 0.0, {"alpha": 0.82})
	box(g, Vector3(w + 0.002, 0.0008, 0.048), tape, Vector3(0, h + 0.0006, 0)).set_meta("ghost", true)
	for sx in [-1.0, 1.0]:
		box(g, Vector3(0.0008, h * 0.45, 0.048), tape, Vector3(float(sx) * (w / 2.0 + 0.0005), h * 0.77, 0)).set_meta("ghost", true)
	var slip := node(g, Vector3(w * 0.14, h + 0.0012, d * 0.22))
	slip.rotation.y = 0.05
	box(slip, Vector3(0.11, 0.0006, 0.06), mat(0xf6f4ee, 0.85), Vector3.ZERO).set_meta("ghost", true)
	for i in 14:
		box(slip, Vector3(0.0018 + fmod(i * 0.37, 1.0) * 0.002, 0.0002, 0.018), mat(0x101010, 0.8), Vector3(-0.045 + i * 0.0048, 0.0005, -0.016)).set_meta("ghost", true)
	for i in 3:
		box(slip, Vector3(0.078 - i * 0.015, 0.0002, 0.0028), mat(0x444444, 0.8), Vector3(-0.012, 0.0005, 0.006 + i * 0.0075)).set_meta("ghost", true)
	return {"g": g}


# ───────────────────────────── 캔 · 컵 · 병
static func _can(p: Dictionary) -> Dictionary:
	var g := node(null)
	var r := 0.029
	var h := 0.135
	var alu := pbr("brushed", 0xc4c4c6, 0.32, 0.6, {}, 12.0)
	lathe(g, [Vector2(0.0, 0.006), Vector2(r * 0.72, 0.002), Vector2(r * 0.84, 0.0), Vector2(r * 0.96, 0.006), Vector2(r, 0.018), Vector2(r, h - 0.016), Vector2(r * 0.93, h - 0.006), Vector2(r * 0.86, h - 0.0005), Vector2(r * 0.86, h + 0.0015), Vector2(r * 0.8, h + 0.0015), Vector2(r * 0.79, h - 0.005), Vector2(0.0, h - 0.005)], alu, Vector3.ZERO, 30, 50.0)
	band(g, r + 0.00025, h * 0.8, tmat(p.get("tex", "can_volt"), 0.35, {"metallic": 0.5}), h / 2.0)
	# 따개: 구멍과 고리
	var top := h - 0.005
	cyl(g, 0.0035, 0.0035, 0.001, mat(0x505050, 0.5, 0.6), Vector3(0.0, top + 0.0003, 0.012), 8)
	plate(g, 0.0125, 0.019, 0.0016, 0.004, alu, Vector3(0, top + 0.0012, 0.004))
	cyl(g, 0.0028, 0.0028, 0.0016, mat(0x303030, 0.5, 0.6), Vector3(0, top + 0.0016, 0.0085), 8)
	if p.get("crushed", false):
		g.scale = Vector3(1.12, 0.62, 0.9)
	return {"g": g, "lie": r}


static func _cup(p: Dictionary) -> Dictionary:
	var g := node(null)
	var paper := pbr("paper", 0xf4efe6, 0.7)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.052, 0.08), Vector2(0.0535, 0.08), Vector2(0.0535, 0.084), Vector2(0.05, 0.084), Vector2(0.049, 0.08), Vector2(0.0425, 0.05), Vector2(0.0, 0.05)], paper, Vector3.ZERO, 34, 70.0)
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0525
	cm.bottom_radius = 0.0405
	cm.height = 0.079
	cm.cap_top = false
	cm.cap_bottom = false
	cm.radial_segments = 32
	mi(g, cm, tmat(p.get("tex", "cup_red"), 0.65), Vector3(0, 0.04, 0)).rotation.y = -PI / 2.0
	# 말라붙은 국물과 면발
	cyl(g, 0.0468, 0.0468, 0.002, mat(0x3a2a1a, 0.42), Vector3(0, 0.0675, 0), 28).set_meta("ghost", true)
	var noodle := mat(0xd8bf85, 0.8)
	for i in 7:
		var a := i * 0.9
		tube(g, [Vector3(cos(a) * 0.02, 0.0688, sin(a) * 0.02), Vector3(cos(a + 1.0) * 0.032, 0.0694, sin(a + 1.0) * 0.032), Vector3(cos(a + 2.2) * 0.018, 0.069, sin(a + 2.2) * 0.018), Vector3(cos(a + 3.2) * 0.03, 0.0694, sin(a + 3.2) * 0.03)], 0.0012, noodle, 4)
	# 반쯤 뜯어 젖힌 은박 뚜껑
	var ld := PlaneMesh.new()
	ld.size = Vector2(0.104, 0.104)
	ld.subdivide_width = 12
	ld.subdivide_depth = 12
	var r0 := 0.052
	var mesh := deformed(ld, func(v):
		var ux: float = v.x / r0
		var uz: float = v.z / r0
		var dx: float = ux * sqrt(maxf(0.0, 1.0 - uz * uz * 0.5)) * r0
		var dz: float = uz * sqrt(maxf(0.0, 1.0 - ux * ux * 0.5)) * r0
		# 뜯은 앞쪽 반을 뒤로 접어 넘겼다
		if dz <= 0.0:
			return Vector3(dx, 0.0, dz)
		var lift: float = deg_to_rad(20.0 + 22.0 * dz / r0)
		return Vector3(dx, sin(lift) * dz, -cos(lift) * dz))
	mi(g, mesh, mat(0xe0dccf, 0.4, 0.5, {"cull_off": true}), Vector3(0, 0.0848, 0)).set_meta("ghost", true)
	return {"g": g, "lie": 0.046}


static func _bottle(p: Dictionary) -> Dictionary:
	var g := node(null)
	var alpha: float = p.get("alpha", 0.45)
	var m := mat(int(p.get("color", 0xcfe6f2)), 0.08, 0.0, {"alpha": alpha, "metallic_specular": 0.7})
	var r := 0.032
	var prof := [Vector2(0.0, 0.0), Vector2(r * 0.72, 0.0), Vector2(r * 0.95, 0.008), Vector2(r, 0.018), Vector2(r, 0.05), Vector2(r * 0.93, 0.056), Vector2(r, 0.062), Vector2(r, 0.13), Vector2(r * 0.93, 0.136), Vector2(r, 0.142), Vector2(r, 0.158), Vector2(r * 0.8, 0.178), Vector2(0.018, 0.192), Vector2(0.0125, 0.202), Vector2(0.0125, 0.207)]
	lathe(g, prof, m, Vector3.ZERO, 26, 55.0)
	# 입구 고리와 뚜껑: 세로 톱니와 봉인 띠
	var cap_m := plastic(int(p.get("cap", 0x2a6fd6)), 0.45)
	lathe(g, [Vector2(0.0145, 0.206), Vector2(0.0145, 0.21), Vector2(0.0125, 0.21)], cap_m, Vector3.ZERO, 18)
	lathe(g, [Vector2(0.0, 0.212), Vector2(0.0148, 0.212), Vector2(0.015, 0.2265), Vector2(0.014, 0.2285), Vector2(0.0, 0.2285)], cap_m, Vector3.ZERO, 20, 55.0)
	if detail > 0:
		for i in 22:
			var a := i * TAU / 22.0
			box(g, Vector3(0.001, 0.012, 0.0011), cap_m, Vector3(sin(a) * 0.0152, 0.2195, cos(a) * 0.0152)).rotation.y = a
	cyl(g, r + 0.0006, r + 0.0006, 0.06, plastic(int(p.get("label", 0x2d8ad6)), 0.5), Vector3(0, 0.095, 0), 26).set_meta("ghost", true)
	return {"g": g, "lie": 0.032}


# ───────────────────────────── 쓰레기봉투 · 종이 뭉치
static func _bag(p: Dictionary) -> Dictionary:
	var g := node(null)
	var m := mat(int(p.get("color", 0x121315)), 0.28, 0.05, {"metallic_specular": 0.7})
	var s := SphereMesh.new()
	s.radius = 0.24
	s.height = 0.48
	s.radial_segments = 34
	s.rings = 22
	var bm := deformed(s, func(v):
		var a: float = atan2(v.x, v.z)
		var y01: float = (v.y + 0.24) / 0.48
		var fold: float = sin(a * 9.0 + y01 * 4.0) * 0.012 * y01 + (hash3(Vector3(snappedf(v.x, 0.05), snappedf(v.y, 0.05), snappedf(v.z, 0.05)) * 9.0) - 0.5) * 0.02
		var pinch: float = 1.0 - pow(y01, 3.2) * 0.72
		var lump: float = sin(a * 3.0 + y01 * 4.0 + 0.7) * 0.085 + sin(a * 5.0 - y01 * 7.0) * 0.05 + sin(y01 * 11.0 + a) * 0.03
		var crease: float = -pow(absf(sin(a * 7.0 + y01 * 3.0)), 18.0) * 0.055 * (1.0 - y01 * 0.4)
		var k: float = 1.0 + fold * 2.0 + lump * (1.0 - y01 * 0.7) + crease
		return Vector3(v.x * k * pinch, (v.y + 0.0) * 0.82 + 0.2 + maxf(0.0, y01 - 0.82) * 0.04, v.z * k * pinch))
	mi(g, bm, m, Vector3.ZERO)
	# 묶은 매듭과 위로 벌어진 자락
	var knot := sph(g, 0.03, m, Vector3(0, 0.405, 0), 14)
	knot.scale = Vector3(1.15, 0.8, 1.0)
	for i in 5:
		var a := i * TAU / 5.0 + 0.4
		var d := Vector3(cos(a), 0.6, sin(a)).normalized()
		var q := QuadMesh.new()
		q.size = Vector2(0.06, 0.11)
		q.subdivide_width = 4
		q.subdivide_depth = 5
		var fl := deformed(q, func(v): return Vector3(v.x * (1.0 + v.y * 2.5), v.y, sin(v.x * 40.0) * 0.008))
		var n := mi(g, fl, mat(int(p.get("color", 0x121315)), 0.28, 0.05, {"cull_off": true}), Vector3(0, 0.41, 0) + d * 0.05)
		n.basis = Basis.looking_at(d, Vector3.UP)
		n.set_meta("ghost", true)
	return {"g": g}


static func _paper_ball(p: Dictionary) -> Dictionary:
	var g := node(null)
	var s := SphereMesh.new()
	s.radius = 0.036
	s.height = 0.072
	s.radial_segments = 18
	s.rings = 10
	var bm := deformed(s, func(v):
		var k := 0.68 + hash3(Vector3(snappedf(v.x, 0.012), snappedf(v.y, 0.012), snappedf(v.z, 0.012)) * 40.0) * 0.6
		return v * k + Vector3(0, 0.03, 0), true)
	mi(g, bm, pbr("paper", int(p.get("color", 0xeeeae0)), 0.95), Vector3.ZERO)
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
		var b := node(g, Vector3((rng.randf() - 0.5) * 0.02, y + h / 2.0, (rng.randf() - 0.5) * 0.02))
		b.rotation.y = (rng.randf() - 0.5) * 0.3
		var cover := pbr("paper", c, 0.6)
		box(b, Vector3(w - 0.006, h * 0.84, d - 0.006), pbr("paper", 0xf2eee4, 1.0), Vector3(0.002, 0, 0))
		rbox(b, Vector3(w, 0.002, d), 0.0008, cover, Vector3(0, h / 2.0 - 0.001, 0))
		rbox(b, Vector3(w, 0.002, d), 0.0008, cover, Vector3(0, -h / 2.0 + 0.001, 0))
		rbox(b, Vector3(0.008, h, d), 0.003, cover, Vector3(-w / 2.0 + 0.003, 0, 0))
		box(b, Vector3(w * 0.7, 0.0004, 0.012), mat(shade(c, -0.5), 0.5), Vector3(0.0, h / 2.0 + 0.0002, d * 0.3)).set_meta("ghost", true)
		y += h
	return {"g": g}


static func _suit() -> Dictionary:
	var g := node(null)
	var navy := cloth_m(0x1f2638)
	var dk := cloth_m(0x161c2a)
	soft_box(g, Vector3(0.42, 0.06, 0.55), 0.018, navy, Vector3(0, 0.03, 0), Vector3i(10, 3, 12))
	# 깃 · 흰 셔츠 · 넥타이 · 단추 · 주머니
	box(g, Vector3(0.15, 0.01, 0.13), cloth_m(0xf2f2f2), Vector3(0, 0.062, -0.2))
	var knot := rbox(g, Vector3(0.03, 0.012, 0.024), 0.004, cloth_m(0x7a1d2a), Vector3(0, 0.071, -0.24))
	knot.rotation.y = 0.05
	box(g, Vector3(0.04, 0.008, 0.2), cloth_m(0x7a1d2a), Vector3(0, 0.069, -0.13))
	for sx in [-1.0, 1.0]:
		var lap := soft_box(g, Vector3(0.09, 0.014, 0.26), 0.005, dk, Vector3(float(sx) * 0.1, 0.068, -0.14), Vector3i(3, 1, 5))
		lap.rotation.y = -float(sx) * 0.28
		lap.set_meta("ghost", true)
	for i in 2:
		sph(g, 0.009, plastic(0x0e0e10, 0.4), Vector3(0.02, 0.07, 0.02 + i * 0.08), 10).scale = Vector3(1, 0.4, 1)
	box(g, Vector3(0.09, 0.0012, 0.03), dk, Vector3(-0.115, 0.0606, 0.08))
	# 세탁소 비닐과 옷걸이
	soft_box(g, Vector3(0.45, 0.085, 0.6), 0.03, mat(0xffffff, 0.1, 0.0, {"alpha": 0.1, "metallic_specular": 0.8}), Vector3(0, 0.043, 0), Vector3i(10, 3, 12))
	var wire := steel_fine(0x9a9a9a, 0.4)
	tube(g, [Vector3(-0.16, 0.082, -0.25), Vector3(0.0, 0.086, -0.3), Vector3(0.16, 0.082, -0.25)], 0.0018, wire, 4)
	tube(g, [Vector3(0, 0.086, -0.3), Vector3(0, 0.088, -0.34), Vector3(0.018, 0.088, -0.36), Vector3(0.03, 0.088, -0.34)], 0.0018, wire, 4)
	return {"g": g, "view": Vector3(70, 0, 0), "anchors": {"front": {"p": Vector3(0, 0.086, 0.1), "n": Vector3.UP, "r": 0.12}}}


# ───────────────────────────── 약 · 통
static func _pill_body(g: Node3D, texname: String, glass_c: int, cap: int, alpha: float) -> void:
	var r := 0.022
	var h := 0.075
	lathe(g, [Vector2(0.0, 0.0), Vector2(r - 0.003, 0.0), Vector2(r, 0.003), Vector2(r, h - 0.002), Vector2(r - 0.002, h), Vector2(0.0, h)], mat(glass_c, 0.15, 0.0, {"alpha": alpha, "metallic_specular": 0.7}), Vector3.ZERO, 22, 55.0)
	band(g, r + 0.0008, h * 0.64, tmat(texname, 0.65), h * 0.5)
	var cm := plastic(cap, 0.45)
	lathe(g, [Vector2(r + 0.0021, h), Vector2(r + 0.0021, h + 0.019), Vector2(r + 0.0008, h + 0.021), Vector2(0.0, h + 0.021)], cm, Vector3.ZERO, 26, 55.0)
	if detail > 0:
		for i in 30:
			var a := i * TAU / 30.0
			box(g, Vector3(0.0012, 0.016, 0.0013), cm, Vector3(sin(a) * (r + 0.0022), h + 0.0095, cos(a) * (r + 0.0022))).rotation.y = a


static func _pill(_p: Dictionary) -> Dictionary:
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


static func _tub(p: Dictionary) -> Dictionary:
	var g := node(null)
	var r := 0.04
	var body := plastic(0xffffff, 0.34)
	lathe(g, [Vector2(0.0, 0.0), Vector2(r - 0.003, 0.0), Vector2(r, 0.004), Vector2(r, 0.086), Vector2(r - 0.005, 0.09), Vector2(0.0, 0.09)], body, Vector3.ZERO, 26, 55.0)
	var cm := plastic(int(p.get("cap", 0x7bc39a)), 0.4)
	lathe(g, [Vector2(0.042, 0.09), Vector2(0.042, 0.108), Vector2(0.04, 0.11), Vector2(0.0, 0.11)], cm, Vector3.ZERO, 28, 55.0)
	if detail > 0:
		for i in 36:
			var a := i * TAU / 36.0
			box(g, Vector3(0.0016, 0.015, 0.0012), cm, Vector3(sin(a) * 0.0425, 0.0985, cos(a) * 0.0425)).rotation.y = a
	band(g, 0.0405, 0.06, tmat(p.get("tex", "tub_slim"), 0.6), 0.045)
	return {"g": g, "lie": 0.042}


static func _shake(p: Dictionary) -> Dictionary:
	var g := node(null)
	var body := plastic(0xf6f4f0, 0.32)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.034, 0.005), Vector2(0.034, 0.158), Vector2(0.031, 0.16), Vector2(0.0, 0.16)], body, Vector3.ZERO, 26, 55.0)
	var cm := plastic(int(p.get("cap", 0xf08aa8)), 0.36)
	lathe(g, [Vector2(0.036, 0.16), Vector2(0.036, 0.186), Vector2(0.03, 0.19), Vector2(0.0, 0.19)], cm, Vector3.ZERO, 28, 55.0)
	# 여닫는 주둥이 뚜껑
	rbox(g, Vector3(0.024, 0.008, 0.03), 0.003, cm, Vector3(0, 0.194, 0.012))
	rod(g, Vector3(-0.009, 0.195, -0.006), Vector3(0.009, 0.195, -0.006), 0.0028, cm, 6).set_meta("ghost", true)
	band(g, 0.0345, 0.06, tmat("shake_label", 0.6), 0.08)
	return {"g": g, "lie": 0.035}


static func _yogurt() -> Dictionary:
	var g := node(null)
	var body := plastic(0xf2f0ea, 0.3)
	# 잘록한 요구르트병
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.016, 0.0), Vector2(0.0205, 0.004), Vector2(0.021, 0.018), Vector2(0.015, 0.042), Vector2(0.0145, 0.05), Vector2(0.0165, 0.06), Vector2(0.0155, 0.0628), Vector2(0.0, 0.0628)], body, Vector3.ZERO, 24, 60.0)
	var pk := mat(0xe86f8e, 0.5)
	var lb := CylinderMesh.new()
	lb.top_radius = 0.0165
	lb.bottom_radius = 0.0208
	lb.height = 0.026
	lb.cap_top = false
	lb.cap_bottom = false
	lb.radial_segments = 24
	mi(g, lb, pk, Vector3(0, 0.03, 0)).set_meta("ghost", true)
	cyl(g, 0.0158, 0.0158, 0.0012, mat(0xd94a6a, 0.3, 0.75), Vector3(0, 0.0635, 0), 22).set_meta("ghost", true)
	return {"g": g, "lie": 0.02}


static func _candle() -> Dictionary:
	var g := node(null)
	var foil := steel_fine(0xd0d0d0, 0.28)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.04, 0.0025), Vector2(0.021, 0.004), Vector2(0.0205, 0.018), Vector2(0.0, 0.018)], foil, Vector3.ZERO, 26, 60.0)
	lathe(g, [Vector2(0.0, 0.002), Vector2(0.0193, 0.002), Vector2(0.0187, 0.033), Vector2(0.015, 0.035), Vector2(0.0, 0.034)], mat(0xf3eedc, 0.5), Vector3.ZERO, 22, 60.0)
	tube(g, [Vector3(0, 0.033, 0), Vector3(0.0008, 0.04, 0.0), Vector3(0.0022, 0.0445, 0.0002)], 0.0009, mat(0x111111, 0.9), 4)
	return {"g": g}


static func _cotton() -> Dictionary:
	var g := node(null)
	var m := pbr("fleece", 0xffffff, 1.0)
	for i in range(6):
		var s := sph(g, 0.018, m, Vector3((i % 3 - 1) * 0.03, 0.006, (i / 3 - 0.5) * 0.03), 12)
		s.scale = Vector3(1.1, 0.35, 1)
	return {"g": g}


# ───────────────────────────── 음식 용기
static func _lunchbox() -> Dictionary:
	var g := node(null)
	var tray := plastic(0x161616, 0.4)
	rbox(g, Vector3(0.2, 0.012, 0.15), 0.005, tray, Vector3(0, 0.006, 0))
	for sz in [-1.0, 1.0]:
		rbox(g, Vector3(0.2, 0.026, 0.006), 0.002, tray, Vector3(0, 0.024, float(sz) * 0.072))
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(0.006, 0.026, 0.15), 0.002, tray, Vector3(float(sx) * 0.097, 0.024, 0))
	# 칸막이와 굳은 음식
	box(g, Vector3(0.004, 0.02, 0.14), tray, Vector3(-0.02, 0.022, 0))
	box(g, Vector3(0.076, 0.02, 0.004), tray, Vector3(0.056, 0.022, -0.012))
	var rice := pbr("fleece", 0xd4c9a8, 1.0)
	soft_box(g, Vector3(0.075, 0.018, 0.13), 0.008, rice, Vector3(-0.06, 0.018, 0), Vector3i(5, 2, 6))
	box(g, Vector3(0.07, 0.012, 0.052), mat(0x8a6a3a, 0.7), Vector3(0.058, 0.016, 0.03))
	for i in 5:
		sph(g, 0.009, mat(0x5e3a18, 0.5), Vector3(0.03 + i * 0.015, 0.023, -0.042 + ((i * 7) % 3 - 1) * 0.012), 8).scale = Vector3(1.2, 0.5, 1)
	# 투명 뚜껑
	var lid_m := glass(0xd8e4e8, 0.24, 0.08)
	rbox(g, Vector3(0.202, 0.006, 0.152), 0.005, lid_m, Vector3(0, 0.043, 0)).set_meta("ghost", true)
	return {"g": g}


static func _salad() -> Dictionary:
	var g := node(null)
	var bowl := glass(0xeaf2f0, 0.3, 0.08)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.066, 0.0), Vector2(0.08, 0.052), Vector2(0.082, 0.055), Vector2(0.0, 0.055)], bowl, Vector3.ZERO, 28, 55.0)
	var leaf := pbr("leather", 0x6aa34d, 0.8)
	var dark := pbr("leather", 0x4a7f33, 0.8)
	for i in range(14):
		var a := i * 2.4
		var r := 0.012 + i * 0.0044
		var s := sph(g, 0.024, leaf if i % 2 == 0 else dark, Vector3(cos(a) * r, 0.02 + fmod(i * 0.37, 1.0) * 0.016, sin(a) * r), 8)
		s.scale = Vector3(1.0, 0.32, 0.8)
		s.rotation = Vector3(fmod(i * 0.7, 1.0), a, fmod(i * 1.3, 1.0) * 0.4)
		s.set_meta("ghost", true)
	for v in [Vector3(0.03, 0.04, 0.02), Vector3(-0.024, 0.042, -0.018)]:
		sph(g, 0.012, mat(0xd8452e, 0.45), v, 10).set_meta("ghost", true)
	return {"g": g}


static func _sidedish(p: Dictionary) -> Dictionary:
	var g := node(null)
	var tb := mat(0xf2f2ee, 0.08, 0.0, {"alpha": 0.5})
	rbox(g, Vector3(0.12, 0.045, 0.09), 0.012, tb, Vector3(0, 0.0225, 0))
	rbox(g, Vector3(0.112, 0.02, 0.082), 0.008, pbr("leather", int(p.get("food", 0x5c6b4a)), 0.7), Vector3(0, 0.012, 0))
	for i in range(5):
		sph(g, 0.008, mat(0xcfd8c8, 0.8), Vector3((i - 2) * 0.02, 0.024, ((i * 7) % 3 - 1) * 0.02), 8).set_meta("ghost", true)
	var lid := node(g, Vector3(0.02, 0.0, 0.08))
	lid.rotation.y = 0.4
	var lm := plastic(int(p.get("lid", 0xc7372f)), 0.42)
	rbox(lid, Vector3(0.125, 0.006, 0.095), 0.004, lm, Vector3(0, 0.004, 0))
	for sz in [-1.0, 1.0]:
		rbox(lid, Vector3(0.03, 0.003, 0.012), 0.001, lm, Vector3(0, 0.002, float(sz) * 0.052))
	return {"g": g}


static func _onigiri() -> Dictionary:
	var g := node(null)
	# 둥근 삼각형: 비닐 포장 + 김 띠
	var pm := PrismMesh.new()
	pm.size = Vector3(0.09, 0.08, 0.03)
	pm.subdivide_width = 4
	pm.subdivide_height = 4
	pm.subdivide_depth = 2
	var mesh := deformed(pm, func(v): return v * Vector3(1, 1, 1 - absf(v.x) * 2.0 * 0.4))
	var n := mi(g, mesh, pbr("fleece", 0xf4f4f0, 0.9), Vector3(0, 0.015, 0))
	n.rotation.x = -PI / 2.0
	var nori := mat(0x1c1c1c, 0.65)
	box(g, Vector3(0.09, 0.031, 0.025), nori, Vector3(0, 0.0155, 0.028))
	box(g, Vector3(0.094, 0.0005, 0.08), mat(0xe8e4dc, 0.3, 0.0, {"alpha": 0.32}), Vector3(0, 0.0315, 0.0)).set_meta("ghost", true)
	box(g, Vector3(0.008, 0.0009, 0.082), mat(0xd9402a, 0.4), Vector3(0, 0.032, 0.0)).set_meta("ghost", true)
	return {"g": g}


static func _newspaper() -> Dictionary:
	var g := node(null)
	var t := tmat("newspaper", 0.95)
	for i in range(5):
		var s := node(g, Vector3((i % 2) * 0.01, 0.003 + i * 0.006, (i % 3) * 0.008))
		box(s, Vector3(0.3, 0.006, 0.42), pbr("paper", 0xd2cec2, 1.0), Vector3.ZERO)
		var pl := PlaneMesh.new()
		pl.size = Vector2(0.3, 0.42)
		pl.subdivide_width = 8
		pl.subdivide_depth = 8
		mi(s, deformed(pl, func(v): return Vector3(v.x, 0.0031 + sin(v.x * 11.0 + i) * 0.0006, v.z)), t, Vector3.ZERO)
		s.rotation.y = (i - 2) * 0.05
		box(g, Vector3(0.3, 0.0005, 0.002), mat(0x9a968a, 0.9), Vector3((i % 2) * 0.01, 0.0065 + i * 0.006, (i % 3) * 0.008)).set_meta("ghost", true)
	return {"g": g}


# ───────────────────────────── 휴대폰 · 시계
static func _phone(p: Dictionary) -> Dictionary:
	var g := node(null)
	var k: String = p.get("tex", "e1")
	var w := 0.072
	var d := 0.152
	var t := 0.009
	var cs := plastic(int(p.get("case", 0x22252b)), 0.36)
	plate(g, w, d, t, 0.0075, cs, Vector3(0, t / 2.0, 0), 0.001)
	var sm := tmat("phone_%s_%s" % [k, "dead" if p.get("dead", false) else "screen"], 0.2, {"emit_tex": true, "emission_energy_multiplier": 0.25})
	plane_up(g, w * 0.96, d * 0.97, sm, Vector3(0, t + 0.0004, 0))
	plane_down(g, w * 0.99, d * 0.99, tmat("phone_%s_back" % k, 0.4), Vector3(0, -0.0004, 0))
	# 측면 버튼 · 스피커 · 충전 단자 · 전면 카메라
	var side := steel_fine(0x7a7f85, 0.26)
	for z in [-0.038, -0.02]:
		rbox(g, Vector3(0.0014, 0.0038, 0.015), 0.0006, side, Vector3(-w / 2.0 - 0.0004, t * 0.55, float(z)))
	rbox(g, Vector3(0.0014, 0.0038, 0.022), 0.0006, side, Vector3(w / 2.0 + 0.0004, t * 0.55, -0.028))
	box(g, Vector3(0.008, 0.0028, 0.0011), mat(0x0c0c0e, 0.7), Vector3(0, t * 0.45, d / 2.0 + 0.0002))
	for sx in [-1.0, 1.0]:
		for i in 4:
			cylz(g, 0.0006, 0.0011, mat(0x0c0c0e, 0.7), Vector3(float(sx) * (0.012 + i * 0.003), t * 0.45, d / 2.0 + 0.0002), 6)
	box(g, Vector3(0.014, 0.0003, 0.0014), mat(0x0a0a0c, 0.5), Vector3(0, t + 0.0007, -d * 0.47))
	cyl(g, 0.0014, 0.0014, 0.0003, mat(0x050507, 0.15), Vector3(0.012, t + 0.0007, -d * 0.47), 10)
	# 뒤 카메라 뭉치와 렌즈
	var bump := node(g, Vector3(-0.015, 0.0, -0.05))
	plate(bump, 0.03, 0.036, 0.002, 0.007, plastic(shade(int(p.get("case", 0x22252b)), 0.25), 0.3), Vector3(0, -0.0008, 0))
	var lens := mat(0x050507, 0.08, 0.5)
	for v in [Vector3(-0.007, -0.002, -0.009), Vector3(-0.007, -0.002, 0.009), Vector3(0.008, -0.002, 0.0)]:
		cyl(bump, 0.0052, 0.0052, 0.0008, chrome(0x6a6a70, 0.25), v, 16)
		cyl(bump, 0.0036, 0.0036, 0.0006, lens, v - Vector3(0, 0.0005, 0), 14)
	cyl(bump, 0.0022, 0.0022, 0.0004, mat(0xf6f0d0, 0.3), Vector3(0.008, -0.002, -0.011), 10)
	var res := {"g": g, "view": Vector3(90, 0, 0), "screen_mat": sm, "lit_tex": "phone_%s_screen" % k, "anchors": {
		"screen": {"p": Vector3(0, t, 0), "n": Vector3.UP, "r": 0.03},
		"back": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.03}}}
	if p.get("smudge", false):
		uv_decal(res, w * 0.94, d * 0.94, "phone_%s_uv" % k, Vector3(0, t + 0.0009, 0), false)
	return res


## 폴더폰 (펼친 모습): 아래는 숫자 건반 · 통화/종료 · 십자 버튼, 위는 화면 · 스피커. 단축번호 1번에 "아들" 스티커
static func _flip() -> Dictionary:
	var g := node(null)
	var body := steel_fine(0x8d9096, 0.3)
	var inner := plastic(0x2c2e32, 0.4)
	var t := 0.0105
	var w := 0.05
	# 아래 몸체
	plate(g, w, 0.096, t, 0.008, body, Vector3(0, t / 2.0, 0.052), 0.0012)
	plate(g, w - 0.003, 0.09, 0.0006, 0.006, inner, Vector3(0, t + 0.0002, 0.052)).set_meta("ghost", true)
	var key_m := plastic(0xc4c7cc, 0.34)
	var lbl := ink(0x18181c)
	var top := t + 0.0005
	# 메뉴 줄: 소프트키 둘 · 십자 · 통화 · 종료
	var sy := top + 0.0009
	for i in 2:
		rbox(g, Vector3(0.011, 0.0018, 0.006), 0.0008, key_m, Vector3(-0.0165 + i * 0.033, sy, 0.0145))
	rbox(g, Vector3(0.012, 0.0018, 0.006), 0.0008, plastic(0x2a9b4a, 0.36), Vector3(-0.0165, sy, 0.0225))
	rbox(g, Vector3(0.012, 0.0018, 0.006), 0.0008, plastic(0xc7372f, 0.36), Vector3(0.0165, sy, 0.0225))
	cyl(g, 0.0088, 0.0088, 0.0016, key_m, Vector3(0, sy, 0.0185), 20).set_meta("ghost", true)
	cyl(g, 0.0034, 0.0034, 0.002, plastic(0x6e7278, 0.3), Vector3(0, sy + 0.0002, 0.0185), 12).set_meta("ghost", true)
	for k in 4:
		var a2 := k * TAU / 4.0
		text(g, ["▲", "▶", "▼", "◀"][k], 0.0042, lbl, Vector3(sin(a2) * 0.0061, sy + 0.0009, 0.0185 - cos(a2) * 0.0061), "up")
	# 숫자 3 x 4
	var keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"]
	for i in keys.size():
		var kx := -0.0145 + (i % 3) * 0.0145
		var kz := 0.034 + int(i / 3) * 0.0138
		rbox(g, Vector3(0.0125, 0.0018, 0.0108), 0.001, key_m, Vector3(kx, sy, kz))
		text(g, keys[i], 0.0072, lbl, Vector3(kx, sy + 0.00095, kz - 0.0005), "up")
	box(g, Vector3(0.0118, 0.0004, 0.0048), mat(0xf0d24a, 0.85), Vector3(-0.0145, sy + 0.0011, 0.0376)).set_meta("ghost", true)
	text(g, "아들", 0.0046, ink(0x2a2a2a), Vector3(-0.0145, sy + 0.00135, 0.0376), "up")
	cyl(g, 0.0009, 0.0009, 0.0008, mat(0x0c0c0e, 0.7), Vector3(0, top + 0.0002, 0.0955), 8).set_meta("ghost", true)
	# 옆 버튼 · 바닥 단자
	for z in [0.03, 0.046]:
		rbox(g, Vector3(0.0012, 0.0036, 0.012), 0.0005, mat(0x565a60, 0.35), Vector3(-0.0255, 0.0052, float(z)))
	box(g, Vector3(0.016, 0.0034, 0.0009), mat(0x0c0c0e, 0.6), Vector3(0, 0.005, 0.1004))
	# 경첩
	var hg := cyl(g, 0.0052, 0.0052, 0.05, steel_fine(0x6e7276, 0.28), Vector3(0, t, 0.002), 14)
	hg.rotation.z = PI / 2.0
	for sx in [-1.0, 1.0]:
		var c := cyl(g, 0.0058, 0.0058, 0.003, chrome(0xb0b4b8, 0.24), Vector3(float(sx) * 0.0265, t, 0.002), 14)
		c.rotation.z = PI / 2.0
	# 위 몸체: 살짝 들려 있다. 화면 · 스피커 · 안테나
	var tilt := 0.3
	var up := node(g, Vector3(0, t, 0.0))
	up.rotation.x = tilt
	var ut := 0.0085
	plate(up, w, 0.09, ut, 0.008, body, Vector3(0, ut / 2.0 - 0.002, -0.048), 0.0012)
	plate(up, w - 0.003, 0.084, 0.0006, 0.006, inner, Vector3(0, ut - 0.0018, -0.048)).set_meta("ghost", true)
	plane_up(up, 0.04, 0.0286, tmat("flip_disp", 0.2, {"emit_tex": true, "emission_energy_multiplier": 0.5}), Vector3(0, ut - 0.0014, -0.05))
	box(up, Vector3(0.012, 0.0006, 0.0014), mat(0x0c0c0e, 0.7), Vector3(0, ut - 0.0015, -0.083)).set_meta("ghost", true)
	text(up, "ROOMI", 0.0048, ink(0x9a9ca0), Vector3(0, ut - 0.0014, -0.0265), "up")
	var ant := cyl(up, 0.003, 0.0034, 0.012, plastic(0x2a2a2e, 0.45), Vector3(0.019, 0.0025, -0.098), 10)
	ant.rotation.x = PI / 2.0
	var ca := cos(tilt)
	var sa := sin(tilt)
	var p := Vector3(0, ut - 0.0014, -0.05)
	var c_scr := Vector3(0, t + p.y * ca - p.z * sa, p.y * sa + p.z * ca)
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {"front": {"p": c_scr, "n": Vector3(0, ca, sa), "r": 0.022}}}


## 스마트워치: 둥근 사각 몸통 · 크라운 · 옆 버튼 · 줄 구멍 · 버클
static func _swatch() -> Dictionary:
	var g := node(null)
	var band_m := pbr("leather", 0xf1b9c6, 0.65, 0.0, {}, 2.5)
	var body := plastic(0x1c1c1e, 0.24)
	for sz in [-1.0, 1.0]:
		plate(g, 0.022, 0.075, 0.0034, 0.004, band_m, Vector3(0, 0.002, float(sz) * 0.058))
	for i in 7:
		cyl(g, 0.0012, 0.0012, 0.0006, mat(0x7a5a60, 0.6), Vector3(0, 0.0038, 0.046 + i * 0.008), 8).set_meta("ghost", true)
	var buck := steel_fine(0xbfbfbf, 0.25)
	ring(g, 0.0095, 0.0011, buck, Vector3(0, 0.003, -0.098), 18, 5).rotation = Vector3.ZERO
	rod(g, Vector3(0, 0.003, -0.098), Vector3(0, 0.003, -0.087), 0.0008, buck, 4).set_meta("ghost", true)
	plate(g, 0.038, 0.045, 0.011, 0.0095, body, Vector3(0, 0.0055, 0), 0.0012)
	plane_up(g, 0.032, 0.038, tmat("swatch_screen", 0.12, {"emit_tex": true, "emission_energy_multiplier": 0.4}), Vector3(0, 0.0112, 0))
	var cr := lathe(g, [Vector2(0.0, 0.0), Vector2(0.0035, 0.0), Vector2(0.0038, 0.0012), Vector2(0.0038, 0.0034), Vector2(0.003, 0.004), Vector2(0.0, 0.004)], steel_fine(0xa8acb0, 0.24), Vector3(0.019, 0.0055, -0.007), 16)
	cr.rotation.z = -PI / 2.0
	rbox(g, Vector3(0.0015, 0.0034, 0.011), 0.0006, plastic(0x34343a, 0.36), Vector3(0.0194, 0.0055, 0.008))
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"face": {"p": Vector3(0, 0.0113, 0), "n": Vector3.UP, "r": 0.018},
		"back": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.018}}}


## 손목시계: 러그 · 크라운 · 가죽끈과 바늘 버클
static func _wwatch() -> Dictionary:
	var g := node(null)
	var strap := pbr("leather", 0x4a2e1c, 0.55, 0.0, {}, 2.5)
	var cs := steel_fine(0xc0c0c0, 0.22)
	for sz in [-1.0, 1.0]:
		var st := plate(g, 0.018, 0.08, 0.0026, 0.003, strap, Vector3(0, 0.0014, float(sz) * 0.06))
		st.set_meta("ghost", true)
	for i in 6:
		cyl(g, 0.001, 0.001, 0.0004, mat(0x201008, 0.6), Vector3(0, 0.0028, 0.048 + i * 0.007), 6).set_meta("ghost", true)
	for i in 2:
		box(g, Vector3(0.019, 0.003, 0.004), strap, Vector3(0, 0.003, 0.026 + i * 0.008))
	ring(g, 0.0088, 0.0011, cs, Vector3(0, 0.002, -0.0985), 18, 5).rotation = Vector3.ZERO
	rod(g, Vector3(0, 0.003, -0.1), Vector3(0, 0.0032, -0.09), 0.0009, cs, 4).set_meta("ghost", true)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.017, 0.0), Vector2(0.0192, 0.0025), Vector2(0.0192, 0.0062), Vector2(0.0176, 0.0092), Vector2(0.0, 0.0092)], cs, Vector3.ZERO, 34, 55.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var lug := box(g, Vector3(0.003, 0.0035, 0.01), cs, Vector3(float(sx) * 0.0095, 0.0042, float(sz) * 0.0205))
			lug.rotation.x = float(sz) * 0.14
	var crn := lathe(g, [Vector2(0.0, 0.0), Vector2(0.0028, 0.0), Vector2(0.0034, 0.0008), Vector2(0.0034, 0.0032), Vector2(0.0, 0.0036)], cs, Vector3(0.019, 0.0048, 0), 12)
	crn.rotation.z = -PI / 2.0
	plane_up(g, 0.034, 0.034, tmat("wwatch_face", 0.14, {"alpha_tex": true}), Vector3(0, 0.0092, 0))
	lathe(g, [Vector2(0.0, 0.0097), Vector2(0.015, 0.0097), Vector2(0.0171, 0.0093)], glass(0xeaf0f4, 0.12, 0.04), Vector3.ZERO, 26, 80.0).set_meta("ghost", true)
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"face": {"p": Vector3(0, 0.0093, 0), "n": Vector3.UP, "r": 0.017},
		"back": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.017}}}


# ───────────────────────────── 액자 · 달력 · 나전함
static func _frame(p: Dictionary) -> Dictionary:
	var g := node(null)
	var W := 0.18
	var H := 0.23
	var T := 0.022
	var fm := wood(int(p.get("fcolor", 0x6b4a2e)), 0.42)
	var fa := wood(int(p.get("fcolor", 0x6b4a2e)), 0.42, true)
	rbox(g, Vector3(W, 0.02, T), 0.0035, fa, Vector3(0, 0.01, 0))
	rbox(g, Vector3(W, 0.02, T), 0.0035, fa, Vector3(0, H - 0.01, 0))
	rbox(g, Vector3(0.02, H, T), 0.0035, fm, Vector3(-W / 2.0 + 0.01, H / 2.0, 0))
	rbox(g, Vector3(0.02, H, T), 0.0035, fm, Vector3(W / 2.0 - 0.01, H / 2.0, 0))
	var ph := quad(g, H - 0.04, W - 0.04, tmat(p.photo, 0.3), Vector3(0, H / 2.0, 0.002))
	ph.rotation.z = PI / 2.0
	quad(g, W - 0.04, H - 0.04, _glass_sheen(), Vector3(0, H / 2.0, 0.0028))
	box(g, Vector3(W - 0.02, H - 0.02, 0.006), mat(0x3a3028, 0.85), Vector3(0, H / 2.0, -T / 2.0 + 0.003))
	var bq := quad(g, W - 0.025, H - 0.025, tmat(p.back, 0.9), Vector3(0, H / 2.0, -T / 2.0 - 0.0002))
	bq.rotation.y = PI
	var cover := mat(0x9b8461, 0.85)
	var leg := rbox(g, Vector3(0.03, 0.14, 0.004), 0.001, cover, Vector3(0, 0.07, -T / 2.0 - 0.03))
	leg.rotation.x = -0.35
	# 뒤판 고정쇠 넷
	var clip := chrome(0x9a9a9a, 0.3)
	for v in [Vector3(-0.055, H / 2.0, 0), Vector3(0.055, H / 2.0, 0), Vector3(0, H - 0.03, 0), Vector3(0, 0.03, 0)]:
		box(g, Vector3(0.006 if absf(v.x) > 0.01 else 0.012, 0.012 if absf(v.x) > 0.01 else 0.006, 0.0014), clip, v + Vector3(0, 0, -T / 2.0 - 0.0014)).set_meta("ghost", true)
	return {"g": g, "view": Vector3.ZERO, "anchors": {
		"front": {"p": Vector3(0, H / 2.0, 0.004), "n": Vector3.BACK, "r": 0.05},
		"back": {"p": Vector3(0, H * 0.6, -T / 2.0 - 0.001), "n": Vector3.FORWARD, "r": 0.05}}}


static func _glass_sheen() -> StandardMaterial3D:
	return Furn._glass_sheen()


static func _calendar(texname: String) -> Dictionary:
	var g := node(null)
	var W := 0.3
	var H := 0.44
	var T := 0.004
	box(g, Vector3(W, H, T), pbr("paper", 0xeeeeee, 0.85), Vector3(0, H / 2.0, 0))
	quad(g, W, H, tmat(texname, 0.82), Vector3(0, H / 2.0, T / 2.0 + 0.0004))
	# 쌓인 장 · 스프링 철 · 벽걸이 고리
	box(g, Vector3(W - 0.002, 0.012, 0.002), pbr("paper", 0xf4f2ea, 0.9), Vector3(0, H - 0.01, T / 2.0 + 0.001))
	var wire := chrome(0x9a9a9c, 0.3)
	for i in 34:
		if i == 16 or i == 17:
			continue
		var x := -W / 2.0 + 0.012 + i * ((W - 0.024) / 33.0)
		var rr := ring(g, 0.0042, 0.0007, wire, Vector3(x, H - 0.002, 0.0), 12, 4)
		rr.rotation = Vector3(PI / 2.0, PI / 2.0, 0.0)
		rr.set_meta("ghost", true)
	tube(g, [Vector3(-0.018, H, 0), Vector3(-0.012, H + 0.012, 0), Vector3(0, H + 0.022, 0), Vector3(0.012, H + 0.012, 0), Vector3(0.018, H, 0)], 0.0012, wire, 4)
	return {"g": g, "view": Vector3.ZERO, "anchors": {"front": {"p": Vector3(0, H * 0.45, T / 2.0 + 0.001), "n": Vector3.BACK, "r": 0.08}}}


## 나전함: 옻칠 몸통 · 뚜껑 · 놋쇠 경첩과 4자리 다이얼
static func _jbox() -> Dictionary:
	var g := node(null)
	var W := 0.22
	var H := 0.09
	var D := 0.15
	var outer := tmat("najeon_box", 0.2, {"metallic_specular": 0.65})
	var inner := cloth_m(0x6e1420)
	var lac := mat(0x150e0c, 0.2, 0.05)
	var bm := brass(0xc9a14a, 0.28)
	rbox(g, Vector3(W, H * 0.7, D), 0.003, lac, Vector3(0, H * 0.35, 0))
	quad(g, W - 0.008, H * 0.7 - 0.008, outer, Vector3(0, H * 0.35, D / 2.0 + 0.0004))
	plane_up(g, W - 0.01, D - 0.01, inner, Vector3(0, H * 0.7 + 0.0004, 0))
	box(g, Vector3(W - 0.012, 0.004, D - 0.012), mat(0x3a0a12, 0.9), Vector3(0, H * 0.7 - 0.001, 0))
	for sx in [-1.0, 1.0]:
		var c := cyl(g, 0.004, 0.004, 0.024, bm, Vector3(float(sx) * 0.055, H * 0.7, -D / 2.0 - 0.001), 10)
		c.rotation.z = PI / 2.0
		box(g, Vector3(0.028, 0.012, 0.0016), bm, Vector3(float(sx) * 0.055, H * 0.62, -D / 2.0 - 0.0008))
	var lid := pivot(g, "lid", Vector3(0, H * 0.7, -D / 2.0))
	rbox(lid, Vector3(W, H * 0.3, D), 0.004, lac, Vector3(0, H * 0.15, D / 2.0))
	plane_up(lid, W - 0.008, D - 0.008, outer, Vector3(0, H * 0.3 + 0.0004, D / 2.0))
	plane_down(lid, W - 0.01, D - 0.01, inner, Vector3(0, -0.0004, D / 2.0))
	box(g, Vector3(0.09, 0.03, 0.006), mat(0x2a1a10, 0.5), Vector3(0, H * 0.38, D / 2.0 + 0.003))
	# 다이얼: 바퀴 넷, 숫자, 돌리는 홈
	var lbl := ink(0x2a1a10)
	for i in range(4):
		var cx := -0.027 + i * 0.018
		var c := cyl(g, 0.0095, 0.0095, 0.013, bm, Vector3(cx, H * 0.38, D / 2.0 + 0.0065), 18)
		c.rotation.z = PI / 2.0
		if detail > 0:
			for k in 16:
				var a := k * TAU / 16.0
				var d := Vector3(0, sin(a), cos(a))
				var gv := box(g, Vector3(0.012, 0.0006, 0.0012), mat(0x7a6030, 0.45, 0.7), Vector3(cx, H * 0.38, D / 2.0 + 0.0065) + d * 0.0096)
				gv.rotation.x = -a
		text(g, str((i * 3 + 1) % 10), 0.0105, lbl, Vector3(cx, H * 0.38, D / 2.0 + 0.0167))
	var res := {"g": g, "view": Vector3(12, 0, 0), "lid": lid, "anchors": {
		"dial": {"p": Vector3(0, H * 0.38, D / 2.0 + 0.016), "n": Vector3.BACK, "r": 0.03},
		"bottom": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.055}}}
	uv_decal(res, W * 0.9, D * 0.9, "jbox_uv", Vector3(0, -0.0009, 0), true)
	return res


static func _diary() -> Dictionary:
	var res := _bound(0.15, 0.21, 0.022, "diary_cover", "diary_back", 0xf8f3ea)
	var g: Node3D = res.g
	# 고무줄 밴드와 책갈피 끈
	box(g, Vector3(0.008, 0.0232, 0.2098), mat(0x7a2a3a, 0.9), Vector3(0.05, 0.011, 0)).set_meta("ghost", true)
	tube(g, [Vector3(-0.02, 0.0, 0.105), Vector3(-0.022, -0.001, 0.13), Vector3(-0.017, -0.001, 0.15)], 0.0012, mat(0x9b3a4a, 0.9), 4)
	uv_decal(res, 0.14, 0.2, "diary_uv", Vector3(0, -0.0009, 0), true)
	return res


static func _thermo() -> Dictionary:
	var g := node(null)
	var W := 0.06
	var H := 0.22
	var T := 0.012
	rbox(g, Vector3(W, H, T), 0.004, wood(0xc9a878, 0.5), Vector3(0, H / 2.0, 0))
	quad(g, W, H, tmat("thermo", 0.72), Vector3(0, H / 2.0, T / 2.0 + 0.0004))
	var gl := glass(0xeaf0f4, 0.3, 0.05)
	cyl(g, 0.0028, 0.0028, H - 0.05, gl, Vector3(0, H / 2.0 + 0.012, T / 2.0 + 0.003), 10).set_meta("ghost", true)
	cyl(g, 0.0013, 0.0013, 0.1, mat(0xc9302a, 0.3), Vector3(0, H * 0.34, T / 2.0 + 0.003), 8).set_meta("ghost", true)
	sph(g, 0.0052, mat(0xc9302a, 0.25), Vector3(0, 0.02, T / 2.0 + 0.003), 12).set_meta("ghost", true)
	cylz(g, 0.0035, 0.002, brass(0xb89a56, 0.3), Vector3(0, H - 0.012, T / 2.0), 10)
	return {"g": g, "view": Vector3.ZERO, "anchors": {"face": {"p": Vector3(0, H * 0.5, T / 2.0 + 0.001), "n": Vector3.BACK, "r": 0.028}}}


# ───────────────────────────── 천 · 안경 · 카메라
static func _scarf() -> Dictionary:
	var g := node(null)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.15, 0.012, 0.48)
	bm.subdivide_width = 8
	bm.subdivide_depth = 26
	var sm := deformed(bm, func(v): return Vector3(v.x + sin(v.z * 9.0) * 0.006, v.y + sin(v.z * 18.0) * 0.006 + sin(v.x * 30.0 + v.z * 7.0) * 0.0014, v.z))
	mi(g, sm, knit_m(0x9c2a2e), Vector3(0, 0.008, 0))
	plane_up(g, 0.15, 0.48, tmat("scarf", 1.0), Vector3(0, 0.0145, 0))
	var yarn := knit_m(0x9c2a2e)
	sph(g, 0.04, yarn, Vector3(0.12, 0.04, -0.18), 18)
	for i in 8:
		var a := i * 0.8
		var r := ring(g, 0.04, 0.0025, yarn, Vector3(0.12, 0.04, -0.18), 24, 5)
		r.rotation = Vector3(a, a * 0.6, a * 1.3)
		r.set_meta("ghost", true)
	tube(g, [Vector3(0.08, 0.01, -0.17), Vector3(0.03, 0.01, -0.13), Vector3(-0.02, 0.016, -0.2)], 0.0026, yarn, 5)
	var wood_n := wood(0xc89a62, 0.42)
	for sg in [-1.0, 1.0]:
		var n1 := cyl(g, 0.0024, 0.0024, 0.3, wood_n, Vector3(float(sg) * 0.02, 0.02, -0.25), 8)
		n1.rotation = Vector3(PI / 2.0, 0, float(sg) * 0.5)
		var k := sph(g, 0.005, wood_n, Vector3(float(sg) * 0.02, 0.02, -0.25) + Basis.from_euler(n1.rotation) * Vector3(0, 0.15, 0), 8)
		k.set_meta("ghost", true)
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"end": {"p": Vector3(0, 0.016, 0.17), "n": Vector3.UP, "r": 0.05},
		"needle": {"p": Vector3(0, 0.02, -0.22), "n": Vector3.UP, "r": 0.05}}}


static func _glasses() -> Dictionary:
	var g := node(null)
	var m := mat(0x7a5a2a, 0.32, 0.6)
	var lens := glass(0xdfe8ee, 0.2, 0.05)
	var y := 0.024
	for sx in [-1.0, 1.0]:
		ring(g, 0.0222, 0.0015, m, Vector3(float(sx) * 0.027, y, 0), 36, 6)
		cylz(g, 0.0212, 0.0008, lens, Vector3(float(sx) * 0.027, y, 0), 28)
		# 경첩 · 다리 · 귀걸이 곡선
		box(g, Vector3(0.006, 0.0036, 0.004), m, Vector3(float(sx) * 0.051, y + 0.004, -0.002))
		tube(g, [Vector3(float(sx) * 0.052, y + 0.004, -0.004), Vector3(float(sx) * 0.054, y + 0.004, -0.06), Vector3(float(sx) * 0.054, y + 0.003, -0.11), Vector3(float(sx) * 0.052, y - 0.012, -0.135)], 0.0013, m, 5)
		# 코받침
		var nose := sph(g, 0.0034, mat(0xe8e4dc, 0.3, 0.0, {"alpha": 0.7}), Vector3(float(sx) * 0.0085, y - 0.008, 0.002), 8)
		nose.scale = Vector3(0.5, 1.2, 1.0)
		nose.set_meta("ghost", true)
	tube(g, [Vector3(-0.0065, y + 0.008, 0), Vector3(0, y + 0.012, 0.0008), Vector3(0.0065, y + 0.008, 0)], 0.0012, m, 5)
	return {"g": g, "view": Vector3.ZERO}


## 소형 디지털카메라: 렌즈 단 · 플래시 · 셔터 · 전원 · 모드 다이얼 · 뒷면 화면과 십자 · 줄 고리
static func _camera() -> Dictionary:
	var g := node(null)
	var body := pbr("brushed", 0xbfc3c7, 0.3, 0.6, {}, 7.0)
	rbox(g, Vector3(0.1, 0.06, 0.028), 0.007, body, Vector3(0, 0.03, 0))
	var grip := leather(0x2a2a2c, 0.65)
	box(g, Vector3(0.012, 0.05, 0.002), grip, Vector3(-0.04, 0.03, 0.0145))
	# 렌즈: 단이 있는 경통 · 유리
	var lz := 0.014
	var lens_n := node(g, Vector3(0.015, 0.03, lz))
	lens_n.rotation.x = PI / 2.0
	var bar := pbr("brushed", 0x1e1e20, 0.3, 0.5, {}, 7.0)
	lathe(lens_n, [Vector2(0.0, 0.0), Vector2(0.024, 0.0), Vector2(0.024, 0.006), Vector2(0.021, 0.008), Vector2(0.02, 0.016), Vector2(0.017, 0.018), Vector2(0.0, 0.018)], bar, Vector3.ZERO, 30, 55.0)
	if detail > 0:
		for k in 36:
			var a := k * TAU / 36.0
			box(lens_n, Vector3(0.0009, 0.0052, 0.0009), mat(0x3e3e42, 0.4, 0.5), Vector3(sin(a) * 0.0242, 0.0032, cos(a) * 0.0242)).rotation.y = a
	ring(g, 0.0206, 0.0006, chrome(0xc4c8cc, 0.22), Vector3(0.015, 0.03, lz + 0.0092), 34, 4)
	var gl := cyl(g, 0.0125, 0.0125, 0.0014, mat(0x1a2a4a, 0.05, 0.5), Vector3(0.015, 0.03, lz + 0.0185), 24)
	gl.rotation.x = PI / 2.0
	ring(g, 0.0135, 0.0009, chrome(0xb0b4b8, 0.2), Vector3(0.015, 0.03, lz + 0.0186), 26, 4)
	text(g, "ROOMI", 0.0058, ink(0x303034), Vector3(-0.026, 0.05, 0.0145))
	# 플래시 · AF 보조등
	box(g, Vector3(0.014, 0.008, 0.0012), mat(0xf4f2e4, 0.2), Vector3(-0.032, 0.05, 0.0143)).position.x = 0.04
	sph(g, 0.0022, mat(0xc0301a, 0.3), Vector3(0.034, 0.043, 0.0142), 8)
	# 위: 셔터 · 줌 레버 · 전원 · 모드 다이얼
	var top := 0.06
	var sh := lathe(g, [Vector2(0.0, 0.0), Vector2(0.0075, 0.0), Vector2(0.0075, 0.002), Vector2(0.0062, 0.0035), Vector2(0.0, 0.0035)], chrome(0xc8ccd0, 0.22), Vector3(0.035, top, 0), 18)
	sh.set_meta("ghost", true)
	ring(g, 0.0088, 0.0011, bar, Vector3(0.035, top + 0.001, 0), 20, 4).rotation = Vector3.ZERO
	rbox(g, Vector3(0.008, 0.002, 0.003), 0.0006, plastic(0x2c2c30, 0.4), Vector3(0.0, top + 0.001, 0.003))
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.01, 0.0), Vector2(0.0102, 0.004), Vector2(0.0092, 0.0055), Vector2(0.0, 0.0055)], bar, Vector3(-0.022, top, 0.0), 24)
	if detail > 0:
		for k in 24:
			var a := k * TAU / 24.0
			box(g, Vector3(0.001, 0.0034, 0.0006), mat(0x444448, 0.35, 0.5), Vector3(-0.022 + sin(a) * 0.01, top + 0.0024, cos(a) * 0.01)).rotation.y = a
	text(g, "M", 0.0065, ink(0xeaeaea), Vector3(-0.022, top + 0.0058, 0), "up")
	# 뒤: 화면 · 십자 버튼 · 메뉴 버튼들 (앞이 +Z이므로 뒤는 -Z)
	var bk := node(g, Vector3(0, 0.0, -0.0145))
	bk.rotation.y = PI
	box(bk, Vector3(0.06, 0.04, 0.0016), mat(0x111111, 0.15), Vector3(0.008, 0.032, 0.0008))
	var btn := plastic(0x2a2a2e, 0.4)
	cylz(bk, 0.0095, 0.0014, btn, Vector3(-0.035, 0.026, 0.0008), 22)
	for i in 4:
		var a := i * TAU / 4.0
		rbox(bk, Vector3(0.0048, 0.0048, 0.0012), 0.0008, plastic(0x46464c, 0.35), Vector3(-0.035 + cos(a) * 0.0064, 0.026 + sin(a) * 0.0064, 0.0016))
	cylz(bk, 0.0026, 0.0014, plastic(0x56565c, 0.35), Vector3(-0.035, 0.026, 0.0019), 12)
	for i in 3:
		rbox(bk, Vector3(0.008, 0.005, 0.001), 0.0008, btn, Vector3(-0.0356 + i * 0.012 - 0.0, 0.05, 0.0008))
	text(bk, "메뉴", 0.0036, ink(0xd0d0d0), Vector3(-0.0236, 0.05, 0.0014))
	var eyelet := steel_fine(0x8e9296, 0.3)
	ring(g, 0.0028, 0.0007, eyelet, Vector3(-0.05, 0.05, 0), 10, 4)
	return {"g": g, "view": Vector3.ZERO, "anchors": {"back": {"p": Vector3(-0.008, 0.032, -0.0165), "n": Vector3.FORWARD, "r": 0.025}}}


## 곰 인형: 부드러운 털, 박음선, 코 · 입 자수, 귀 안쪽, 발바닥, 낡아 덧댄 천
static func _teddy() -> Dictionary:
	var g := node(null)
	var m := pbr("fleece", 0xa87a52, 1.0)
	var inner := pbr("fleece", 0xd8b48e, 1.0)
	var dk := mat(0x1a1410, 0.35)
	var seam := mat(0x7a5635, 1.0)
	var b := sph(g, 0.07, m, Vector3(0, 0.07, 0), 22)
	b.scale = Vector3(1, 1.08, 0.9)
	sph(g, 0.052, m, Vector3(0, 0.17, 0), 22)
	for sx in [-1.0, 1.0]:
		var ear := sph(g, 0.022, m, Vector3(float(sx) * 0.038, 0.21, 0), 14)
		ear.scale = Vector3(1, 1, 0.65)
		var e2 := sph(g, 0.014, inner, Vector3(float(sx) * 0.038, 0.208, 0.009), 12)
		e2.scale = Vector3(1, 1, 0.5)
		e2.set_meta("ghost", true)
		sph(g, 0.006, dk, Vector3(float(sx) * 0.018, 0.182, 0.045), 12).set_meta("ghost", true)
		sph(g, 0.0018, mat(0xffffff, 0.2), Vector3(float(sx) * 0.018 + 0.002, 0.1845, 0.05), 6).set_meta("ghost", true)
	sph(g, 0.024, inner, Vector3(0, 0.16, 0.042), 16)
	var nose := sph(g, 0.0085, dk, Vector3(0, 0.168, 0.064), 12)
	nose.scale = Vector3(1.2, 0.8, 0.7)
	rod(g, Vector3(0, 0.161, 0.066), Vector3(0, 0.15, 0.064), 0.0012, dk, 4).set_meta("ghost", true)
	for sx in [-1.0, 1.0]:
		tube(g, [Vector3(0, 0.15, 0.064), Vector3(float(sx) * 0.007, 0.146, 0.063), Vector3(float(sx) * 0.014, 0.148, 0.061)], 0.0011, dk, 4)
	for v in [Vector3(-0.07, 0.09, 0.02), Vector3(0.07, 0.09, 0.02)]:
		var arm := sph(g, 0.026, m, v, 14)
		arm.scale = Vector3(0.9, 1.3, 0.9)
	for sx in [-1.0, 1.0]:
		var ft := sph(g, 0.03, m, Vector3(float(sx) * 0.04, 0.02, 0.05), 14)
		ft.scale = Vector3(1, 0.8, 1.15)
		var pad := sph(g, 0.018, inner, Vector3(float(sx) * 0.04, 0.02, 0.082), 12)
		pad.scale = Vector3(1, 1, 0.4)
		pad.set_meta("ghost", true)
	# 배 가운데 박음선, 덧댄 천 조각
	for i in 8:
		rod(g, Vector3(0, 0.02 + i * 0.012, 0.0628), Vector3(0, 0.026 + i * 0.012, 0.0628), 0.0009, seam, 3).set_meta("ghost", true)
	var ptch := soft_box(g, Vector3(0.03, 0.03, 0.004), 0.002, cloth_m(0x8a6f8a), Vector3(-0.022, 0.085, 0.061), Vector3i(2, 2, 1))
	ptch.rotation = Vector3(-0.1, -0.25, 0.1)
	ptch.set_meta("ghost", true)
	for k in 12:
		var a := k * TAU / 12.0
		var c := Vector3(cos(a) * 0.017, sin(a) * 0.017, 0) + Vector3(-0.022, 0.085, 0.0642)
		box(g, Vector3(0.002, 0.0006, 0.001), seam, c).rotation.z = a
	return {"g": g, "view": Vector3.ZERO}


## 화장품 함: 경첩 뚜껑선 · 잠금쇠 · 위 손잡이 · 비밀 바닥 (이름 fb)
static func _mkbox() -> Dictionary:
	var g := node(null)
	var W := 0.24
	var H := 0.13
	var D := 0.15
	var pink := painted(0xf2b8c8, 0.3)
	var dk := painted(0xd897aa, 0.36)
	var gold := brass(0xd8c08c, 0.26)
	rbox(g, Vector3(W, H, D), 0.012, pink, Vector3(0, H / 2.0 + 0.02, 0))
	rbox(g, Vector3(W, 0.02, D), 0.008, dk, Vector3(0, 0.01, 0))
	box(g, Vector3(W + 0.0006, 0.0014, D + 0.0006), mat(0xb97a8e, 0.6), Vector3(0, H * 0.72, 0)).set_meta("ghost", true)
	var drawer := pivot(g, "fb")
	box(drawer, Vector3(W * 0.9, 0.016, D * 0.92), mat(0xe8a5b8, 0.5), Vector3(0, 0.01, 0))
	var lt := plane_up(drawer, 0.1, 0.07, tmat("mkbox_letter", 0.9), Vector3(0, 0.0185, 0))
	lt.name = "fbLetter"
	lt.visible = false
	tube(g, [Vector3(-0.05, H + 0.02, 0), Vector3(-0.048, H + 0.052, 0), Vector3(0, H + 0.064, 0), Vector3(0.048, H + 0.052, 0), Vector3(0.05, H + 0.02, 0)], 0.0065, dk, 8, true, 6).set_meta("ghost", false)
	for sx in [-1.0, 1.0]:
		cyl(g, 0.011, 0.012, 0.004, gold, Vector3(float(sx) * 0.05, H + 0.022, 0), 12)
		box(g, Vector3(0.022, 0.016, 0.003), gold, Vector3(float(sx) * 0.07, H * 0.72, -D / 2.0 - 0.0016))
	box(g, Vector3(0.03, 0.02, 0.006), gold, Vector3(0, H * 0.8, D / 2.0 + 0.003))
	rbox(g, Vector3(0.016, 0.03, 0.005), 0.002, gold, Vector3(0, H * 0.64, D / 2.0 + 0.003))
	cylz(g, 0.0035, 0.002, mat(0x201810, 0.4), Vector3(0, H * 0.8, D / 2.0 + 0.0061), 10)
	return {"g": g, "view": Vector3(12, 0, 0), "drawer": drawer, "anchors": {
		"top": {"p": Vector3(0, H + 0.021, 0.03), "n": Vector3.UP, "r": 0.05},
		"bottom": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.06},
		"front": {"p": Vector3(0, H * 0.6, D / 2.0 + 0.001), "n": Vector3.BACK, "r": 0.04}}}


## 노트북: 키 하나하나 · 터치패드 · 경첩 · 베젤과 카메라 · 측면 단자
static func _laptop() -> Dictionary:
	var g := node(null)
	var shell := pbr("brushed", 0x3a3c42, 0.3, 0.55, {}, 7.0)
	var deck := pbr("brushed", 0x2e3036, 0.34, 0.45, {}, 7.0)
	plate(g, 0.32, 0.22, 0.018, 0.009, shell, Vector3(0, 0.009, 0), 0.0015)
	box(g, Vector3(0.302, 0.0008, 0.128), mat(0x0c0d0f, 0.6), Vector3(0, 0.0184, -0.038))
	Furn.keyboard(g, Vector3(0, 0.0178, -0.038), 0.29, 0.116, plastic(0x18191c, 0.38), ink(0xd8d8dc, false), deck, true)
	# 터치패드와 팜레스트, 전원 버튼
	plate(g, 0.1, 0.062, 0.0008, 0.004, plastic(0x26282e, 0.26), Vector3(0, 0.0184, 0.067)).set_meta("ghost", true)
	box(g, Vector3(0.1, 0.0003, 0.0009), mat(0x0d0d10, 0.5), Vector3(0, 0.0192, 0.087)).set_meta("ghost", true)
	cyl(g, 0.0042, 0.0042, 0.0012, plastic(0x18191c, 0.4), Vector3(0.14, 0.0186, -0.09), 12)
	sph(g, 0.0013, mat(0x224422, 0.3, 0.0, {"emit": 0x3aaa55}), Vector3(0.127, 0.0186, -0.09), 6)
	# 옆면 단자
	for sx in [-1.0, 1.0]:
		for i in 2:
			box(g, Vector3(0.0012, 0.0056, 0.0135), mat(0x0a0a0c, 0.6), Vector3(float(sx) * 0.1597, 0.0095, -0.05 + i * 0.024))
	cylz(g, 0.0028, 0.0014, mat(0x0a0a0c, 0.6), Vector3(0.1597, 0.0095, 0.022), 10).rotation = Vector3(0, 0, PI / 2.0)
	# 받침 고무발 · 경첩
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			cyl(g, 0.006, 0.0065, 0.0012, rubber(), Vector3(float(sx) * 0.135, 0.0003, float(sz) * 0.09), 10).set_meta("ghost", true)
		var hg := cyl(g, 0.0052, 0.0052, 0.05, shell, Vector3(float(sx) * 0.08, 0.018, -0.11), 12)
		hg.rotation.z = PI / 2.0
	var lid := node(g, Vector3(0, 0.018, -0.11))
	lid.rotation.x = deg_to_rad(-105)
	plate(lid, 0.32, 0.22, 0.01, 0.009, shell, Vector3(0, 0.005, 0.11), 0.0012)
	box(lid, Vector3(0.312, 0.0008, 0.212), mat(0x08080a, 0.34), Vector3(0, -0.0004, 0.11))
	plane_down(lid, 0.3, 0.2, tmat("laptop_lock", 0.16, {"emit_tex": true, "emission_energy_multiplier": 0.35}), Vector3(0, -0.0009, 0.11))
	cyl(lid, 0.0018, 0.0018, 0.0006, mat(0x03040a, 0.08), Vector3(0, -0.0009, 0.206), 10)
	text(lid, "ROOMI", 0.012, ink(0xa0a2a8), Vector3(0, 0.0106, 0.11), "up").rotation.y = PI
	var n := Vector3(0, 0.2588, 0.9659)
	var c := Vector3(0, 0.124, -0.138)
	return {"g": g, "view": Vector3.ZERO, "anchors": {
		"screen": {"p": c, "n": n, "r": 0.08},
		"back": {"p": c - n * 0.011, "n": -n, "r": 0.08}}}


## 선물 상자: 포장지 접힌 선 · 리본과 고리 매듭 · 꼬리표 / 안에 든 액자
static func _giftbox() -> Dictionary:
	var g := node(null)
	var W := 0.32
	var H := 0.1
	var D := 0.24
	var wrap := node(g)
	var wm: StandardMaterial3D = tmat("gift_wrap", 0.55).duplicate()
	wm.uv1_triplanar = true
	wm.uv1_scale = Vector3(3, 3, 3)
	rbox(wrap, Vector3(W, H, D), 0.003, wm, Vector3(0, H / 2.0, 0))
	var rib := pbr("fabric", 0xb8323a, 0.5, 0.0, {}, 2.0)
	box(wrap, Vector3(0.03, H + 0.004, D + 0.004), rib, Vector3(0, H / 2.0, 0))
	box(wrap, Vector3(W + 0.004, H + 0.004, 0.03), rib, Vector3(0, H / 2.0, 0))
	for a in [0.5, 2.3, 3.7, 5.4]:
		var d := Vector3(cos(float(a)), 0.28, sin(float(a))).normalized()
		var ln := soft_box(wrap, Vector3(0.075, 0.018, 0.03), 0.008, rib, Vector3(0, H + 0.012, 0) + d * 0.038, Vector3i(6, 2, 3))
		ln.basis = Basis.looking_at(Vector3(-d.z, 0, d.x), Vector3.UP)
		ln.set_meta("ghost", true)
	sph(wrap, 0.016, rib, Vector3(0, H + 0.014, 0), 12).scale = Vector3(1.1, 0.75, 1.0)
	var tag := plane_up(wrap, 0.1, 0.055, tmat("gift_tag", 0.9), Vector3(0.09, H + 0.002, 0.06))
	tag.rotation.y = 0.3
	var inner := node(g)
	rbox(inner, Vector3(W, 0.02, D), 0.004, wood(0x6b4a2e, 0.42), Vector3(0, 0.01, 0))
	plane_up(inner, W - 0.03, D - 0.03, tmat("portrait_family", 0.35), Vector3(0, 0.0205, 0))
	inner.visible = false
	return {"g": g, "view": Vector3(35, 0, 0), "unwrap": {"hide": wrap, "show": inner}, "anchors": {
		"top": {"p": Vector3(0, H, 0), "n": Vector3.UP, "r": 0.07},
		"front": {"p": Vector3(0, H / 2.0, D / 2.0 + 0.001), "n": Vector3.BACK, "r": 0.04}}}


static func _dress() -> Dictionary:
	var g := node(null)
	var navy := cloth_m(0x2b3a5a)
	soft_box(g, Vector3(0.34, 0.03, 0.46), 0.012, navy, Vector3(0, 0.015, 0), Vector3i(8, 2, 12))
	box(g, Vector3(0.14, 0.006, 0.05), cloth_m(0xf2efe8), Vector3(0, 0.033, -0.2))
	box(g, Vector3(0.34, 0.002, 0.012), cloth_m(0x1e2a44), Vector3(0, 0.0305, 0.08)).set_meta("ghost", true)
	for sx in [-1.0, 1.0]:
		box(g, Vector3(0.002, 0.0018, 0.44), mat(0x1e2a44, 0.9), Vector3(float(sx) * 0.09, 0.0305, 0.0)).set_meta("ghost", true)
	var tg := plane_up(g, 0.05, 0.075, tmat("price_tag", 0.9), Vector3(0.11, 0.0315, 0.12))
	tg.rotation.y = -0.4
	tube(g, [Vector3(0.09, 0.0318, 0.09), Vector3(0.05, 0.034, 0.05), Vector3(0.01, 0.033, 0.02)], 0.0008, mat(0xd8d4c8, 0.9), 3)
	return {"g": g, "view": Vector3(90, 0, 0), "anchors": {
		"tag": {"p": Vector3(0.11, 0.031, 0.12), "n": Vector3.UP, "r": 0.04},
		"front": {"p": Vector3(-0.06, 0.03, -0.05), "n": Vector3.UP, "r": 0.06}}}


## 그림쟁이의 피규어: 받침 · 다리 · 치마 · 팔 · 머리와 앞머리
static func _figure() -> Dictionary:
	var g := node(null)
	cyl(g, 0.035, 0.035, 0.008, plastic(0x222222, 0.3), Vector3(0, 0.004, 0), 22)
	var skin := plastic(0xf0d4bc, 0.45)
	var cloth := plastic(0x5a6fa8, 0.42)
	var hair := plastic(0x2a2030, 0.34)
	for sx in [-1.0, 1.0]:
		rod(g, Vector3(float(sx) * 0.008, 0.008, 0), Vector3(float(sx) * 0.0085, 0.05, 0), 0.0045, skin, 8)
		lathe(g, [Vector2(0.0, 0.0), Vector2(0.006, 0.0), Vector2(0.0065, 0.005), Vector2(0.005, 0.016), Vector2(0.0, 0.016)], cloth, Vector3(float(sx) * 0.008, 0.008, 0.001), 10)
	lathe(g, [Vector2(0.0, 0.042), Vector2(0.022, 0.042), Vector2(0.024, 0.044), Vector2(0.014, 0.066), Vector2(0.0, 0.066)], cloth, Vector3.ZERO, 16, 60.0)
	lathe(g, [Vector2(0.0, 0.066), Vector2(0.013, 0.066), Vector2(0.012, 0.09), Vector2(0.0066, 0.094), Vector2(0.0, 0.094)], plastic(0xf6f4f0, 0.42), Vector3.ZERO, 14, 60.0)
	for sx in [-1.0, 1.0]:
		rod(g, Vector3(float(sx) * 0.012, 0.089, 0), Vector3(float(sx) * 0.022, 0.067, 0.008), 0.0034, plastic(0xf6f4f0, 0.42), 6).set_meta("ghost", true)
		sph(g, 0.0034, skin, Vector3(float(sx) * 0.022, 0.065, 0.009), 6).set_meta("ghost", true)
	sph(g, 0.02, skin, Vector3(0, 0.112, 0), 16)
	var hb := sph(g, 0.022, hair, Vector3(0, 0.115, -0.003), 16)
	hb.scale = Vector3(1.06, 1.0, 1.05)
	for sx in [-1.0, 0.0, 1.0]:
		var f := sph(g, 0.009, hair, Vector3(float(sx) * 0.011, 0.122, 0.017), 8)
		f.scale = Vector3(1.0, 1.4, 0.6)
		f.set_meta("ghost", true)
	for sx in [-1.0, 1.0]:
		tube(g, [Vector3(float(sx) * 0.018, 0.112, -0.01), Vector3(float(sx) * 0.026, 0.085, -0.012), Vector3(float(sx) * 0.023, 0.06, -0.01)], 0.0052, hair, 6)
		var e := sph(g, 0.0034, mat(0x2a3a7a, 0.2), Vector3(float(sx) * 0.0078, 0.111, 0.0183), 8)
		e.scale = Vector3(0.8, 1.2, 0.3)
		e.set_meta("ghost", true)
	return {"g": g, "view": Vector3.ZERO, "anchors": {"bottom": {"p": Vector3.ZERO, "n": Vector3.DOWN, "r": 0.03}}}


static func _uniform() -> Dictionary:
	var g := node(null)
	var w := cloth_m(0xf4f4f0)
	soft_box(g, Vector3(0.36, 0.05, 0.42), 0.015, w, Vector3(0, 0.025, 0), Vector3i(8, 2, 10))
	box(g, Vector3(0.34, 0.0015, 0.0025), mat(0xbdbdb6, 0.9), Vector3(0, 0.0505, 0.05)).set_meta("ghost", true)
	for i in 4:
		sph(g, 0.0055, plastic(0x2a2a2e, 0.4), Vector3(0.06, 0.0515, -0.14 + i * 0.09), 8).scale = Vector3(1, 0.4, 1)
	for sx in [-1.0, 1.0]:
		var cl := soft_box(g, Vector3(0.075, 0.006, 0.05), 0.002, w, Vector3(float(sx) * 0.04, 0.053, -0.19), Vector3i(2, 1, 2))
		cl.rotation.y = -float(sx) * 0.4
		cl.set_meta("ghost", true)
	var net := sph(g, 0.08, pbr("fabric", 0xffffff, 1.0, 0.0, {}, 3.0), Vector3(0.1, 0.065, 0.12), 16)
	net.scale = Vector3(1, 0.3, 1)
	plane_up(g, 0.08, 0.032, tmat("uniform_tag", 0.8), Vector3(-0.09, 0.0505, -0.1))
	return {"g": g, "view": Vector3(75, 0, 0), "anchors": {"front": {"p": Vector3(-0.09, 0.05, -0.1), "n": Vector3.UP, "r": 0.05}}}


static func _piping_kit() -> Dictionary:
	var g := node(null)
	var cone := node(g, Vector3(0, 0.045, 0))
	cone.rotation.z = PI / 2.0
	lathe(cone, [Vector2(0.0045, -0.09), Vector2(0.045, 0.09), Vector2(0.0, 0.09)], mat(0xe8e8e2, 0.34, 0.0, {"alpha": 0.85}), Vector3.ZERO, 22, 80.0)
	var ck := steel_fine(0xc4c4c4, 0.26)
	# 깍지: 끝이 별 모양인 금속 꼭지 넷
	for i in range(4):
		var c := Vector3(-0.06 + i * 0.03, 0.0, 0.07)
		lathe(g, [Vector2(0.0, 0.0), Vector2(0.0095, 0.0), Vector2(0.0092, 0.003), Vector2(0.0045, 0.022), Vector2(0.0, 0.022)], ck, c, 16, 60.0)
		if detail > 0:
			for k in 6:
				var a := k * TAU / 6.0
				box(g, Vector3(0.0014, 0.012, 0.001), ck, c + Vector3(cos(a) * 0.0055, 0.016, sin(a) * 0.0055)).rotation.y = -a
	return {"g": g, "view": Vector3(60, 0, 0), "anchors": {"top": {"p": Vector3(0, 0.09, 0), "n": Vector3.UP, "r": 0.05}}}
