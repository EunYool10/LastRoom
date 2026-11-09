class_name Furn
extends Build
## 가구 · 설비 모델. 바깥 치수와 윗면 높이는 물건 배치(episodes.json)에 맞춰 그대로 둔다

static func make(t: String, p: Dictionary) -> Dictionary:
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


# ───────────────────────────── 공용 작은 부품
## 십자 나사 머리 (앞 +Z)
static func _screw(g: Node3D, pos: Vector3, m: Material, r := 0.004) -> void:
	cylz(g, r, 0.0015, m, pos, 10)
	if detail > 0:
		var dk := mat(0x18181a, 0.7)
		box(g, Vector3(r * 1.3, r * 0.3, 0.0006), dk, pos + Vector3(0, 0, 0.0009))
		box(g, Vector3(r * 0.3, r * 1.3, 0.0006), dk, pos + Vector3(0, 0, 0.0009))


## 막대 손잡이: 다리 두 개로 문짝에서 떠 있다 (앞 +Z, 길이는 x 방향)
static func _bar_handle(g: Node3D, c: Vector3, len_x: float, m: Material, vertical := false) -> void:
	var a := Vector3(0, len_x / 2.0, 0) if vertical else Vector3(len_x / 2.0, 0, 0)
	rod(g, c - a, c + a, 0.005, m, 10)
	var inset := a * 0.75
	for sg in [-1.0, 1.0]:
		var base: Vector3 = c + inset * float(sg)
		rod(g, base - Vector3(0, 0, 0.022), base, 0.004, m, 8)
		cylz(g, 0.008, 0.002, m, base - Vector3(0, 0, 0.022), 12)


## 경첩 (앞 +Z, 세로)
static func _hinge(g: Node3D, c: Vector3, m: Material, h := 0.07) -> void:
	box(g, Vector3(0.024, h, 0.002), m, c)
	cyl(g, 0.0035, 0.0035, h, m, c + Vector3(0, 0, 0.003), 8)
	for sy in [-1.0, 1.0]:
		_screw(g, c + Vector3(-0.006, float(sy) * h * 0.3, 0.0015), m, 0.0022)


## 천 위로 도드라진 박음선 · 파이핑: 사각형 둘레를 도는 얇은 끈
static func _piping(g: Node3D, w: float, d: float, y: float, m: Material, r := 0.006) -> void:
	for sz in [-1.0, 1.0]:
		rod(g, Vector3(-w / 2.0, y, float(sz) * d / 2.0), Vector3(w / 2.0, y, float(sz) * d / 2.0), r, m, 6).set_meta("ghost", true)
	for sx in [-1.0, 1.0]:
		rod(g, Vector3(float(sx) * w / 2.0, y, -d / 2.0), Vector3(float(sx) * w / 2.0, y, d / 2.0), r, m, 6).set_meta("ghost", true)


## 전원 줄 끝 플러그: 몸통과 둥근 핀 둘 (핀이 +X쪽)
static func _mains_plug(g: Node3D, c: Vector3, ry: float, body: Material) -> void:
	var n := node(g, c)
	n.rotation.y = ry
	rbox(n, Vector3(0.034, 0.03, 0.042), 0.008, body, Vector3.ZERO)
	var pin := chrome()
	for sz in [-1.0, 1.0]:
		var b := cyl(n, 0.0024, 0.0024, 0.019, pin, Vector3(0.026, 0.0, float(sz) * 0.0095), 8)
		b.rotation.z = PI / 2.0


# ───────────────────────────── 침대 · 천
static func _bed(p: Dictionary) -> Dictionary:
	if p.get("style", "") == "premium":
		return _bed_premium(p)
	var g := node(null)
	var w: float = p.get("w", 0.9)
	var d: float = p.get("d", 1.9)
	var fhex := int(p.get("frame", 0x5a4434))
	var fm := wood(fhex, 0.55)
	var fa := wood(fhex, 0.55, true)
	var dark := wood(shade(fhex, 0.25), 0.7)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			rbox(g, Vector3(0.065, 0.1, 0.065), 0.006, dark, Vector3(float(sx) * (w / 2.0 - 0.05), 0.05, float(sz) * (d / 2.0 - 0.09)))
		rbox(g, Vector3(0.03, 0.17, d - 0.05), 0.004, fm, Vector3(float(sx) * (w / 2.0 - 0.015), 0.165, 0.015))
	rbox(g, Vector3(w, 0.22, 0.03), 0.005, fa, Vector3(0, 0.15, d / 2.0 - 0.015))
	var n := 9
	for i in n:
		box(g, Vector3(w - 0.06, 0.012, 0.09), wood(0x9a7f5e, 0.8, true), Vector3(0, 0.242, -d / 2.0 + 0.13 + i * (d - 0.26) / (n - 1)))
	var sheet_m := cloth_m(int(p.get("sheet", 0xd9d3c7)))
	soft_box(g, Vector3(w - 0.04, 0.18, d - 0.04), 0.035, sheet_m, Vector3(0, 0.34, 0), Vector3i(16, 5, 22))
	_piping(g, w - 0.075, d - 0.075, 0.43, cloth_m(shade(int(p.get("sheet", 0xd9d3c7)), 0.12)), 0.004)
	_piping(g, w - 0.075, d - 0.075, 0.25, cloth_m(shade(int(p.get("sheet", 0xd9d3c7)), 0.12)), 0.004)
	_cloth(g, tmat(p.get("blanket_tex", "blanket_e1"), 1.0), w / 2.0 - 0.06, 0.46, 0.07, -d * 0.16, d / 2.0 - 0.06, 0.26, true, 0.018, 1.0)
	var pn := mi(g, _puff(Vector3(w * 0.62, 0.13, 0.36), true), cloth_m(int(p.get("pillow", 0xe8e2d6))), Vector3(0, 0.495, -d / 2.0 + 0.26))
	pn.rotation = Vector3(0.05, 0.08, 0.02)
	rbox(g, Vector3(w, 0.55, 0.05), 0.008, fa, Vector3(0, 0.52, -d / 2.0 + 0.025))
	rbox(g, Vector3(w + 0.024, 0.024, 0.066), 0.007, fa, Vector3(0, 0.806, -d / 2.0 + 0.025))
	return {"g": g, "foot": Vector2(w, d)}


# ───────────────────────────── 책상 · 의자
static func _desk(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.1)
	var d: float = p.get("d", 0.55)
	var h: float = p.get("h", 0.74)
	var top := wood(0x8a6f52, 0.48, true)
	var side := wood(0x7a6048, 0.6)
	rbox(g, Vector3(w, 0.03, d), 0.0035, top, Vector3(0, h - 0.015, 0))
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(0.03, h - 0.03, d - 0.012), 0.002, side, Vector3(float(sx) * (w / 2.0 - 0.015), (h - 0.03) / 2.0, 0))
		for sz in [-1.0, 1.0]:
			cyl(g, 0.011, 0.013, 0.006, rubber(), Vector3(float(sx) * (w / 2.0 - 0.015), 0.003, float(sz) * (d / 2.0 - 0.05)), 10)
	rbox(g, Vector3(w - 0.06, h * 0.55, 0.016), 0.0015, side, Vector3(0, h * 0.62, -d / 2.0 + 0.012))
	rbox(g, Vector3(w - 0.06, 0.015, d - 0.02), 0.0015, side, Vector3(0, h - 0.16, 0))
	rbox(g, Vector3(w - 0.06, 0.018, d - 0.09), 0.0015, side, Vector3(0, 0.16, -0.025))
	# 서랍: 앞판 · 네 벽 · 바닥 · 레일 · 막대 손잡이
	var dr := pivot(g, "deskDrawer", Vector3(w * 0.22, h - 0.1, 0))
	rbox(dr, Vector3(0.42, 0.11, 0.02), 0.002, top, Vector3(0, 0, d / 2.0 - 0.01))
	box(dr, Vector3(0.4, 0.008, d - 0.06), wood(0xb79a78, 0.8), Vector3(0, -0.045, 0))
	for sx in [-1.0, 1.0]:
		box(dr, Vector3(0.012, 0.09, d - 0.06), wood(0xa68a68, 0.8), Vector3(float(sx) * 0.195, 0, 0))
		box(g, Vector3(0.008, 0.016, d - 0.05), steel(0x8a8e92), Vector3(w * 0.22 + float(sx) * 0.205, h - 0.112, 0))
	box(dr, Vector3(0.39, 0.09, 0.012), wood(0xa68a68, 0.8), Vector3(0, 0, -d / 2.0 + 0.036))
	var hm := steel(0xc2c5c8, 0.28)
	_bar_handle(dr, Vector3(0, 0.002, d / 2.0 + 0.024), 0.1, hm)
	if p.get("shelf", false):
		var bracket := painted(0xd9d6d0, 0.45)
		for y in [1.3, 1.62]:
			rbox(g, Vector3(w, 0.025, 0.24), 0.003, top, Vector3(0, y, -d / 2.0 + 0.12))
			for sx in [-1.0, 1.0]:
				var bx: float = float(sx) * (w / 2.0 - 0.05)
				box(g, Vector3(0.022, 0.16, 0.004), bracket, Vector3(bx, float(y) - 0.09, -d / 2.0 + 0.003))
				box(g, Vector3(0.022, 0.004, 0.19), bracket, Vector3(bx, float(y) - 0.0145, -d / 2.0 + 0.1))
				rod(g, Vector3(bx, float(y) - 0.15, -d / 2.0 + 0.006), Vector3(bx, float(y) - 0.016, -d / 2.0 + 0.16), 0.003, bracket, 6)
				for yy in [-0.05, -0.14]:
					_screw(g, Vector3(bx, float(y) + float(yy), -d / 2.0 + 0.0052), steel(), 0.003)
	return {"g": g, "foot": Vector2(w, d)}


static func _chair(p: Dictionary) -> Dictionary:
	var g := node(null)
	var c := int(p.get("color", 0x2b2d31))
	var leg := steel(0xa0a4a8, 0.3)
	var pad := cloth_m(c)
	soft_box(g, Vector3(0.42, 0.05, 0.42), 0.022, pad, Vector3(0, 0.45, 0), Vector3i(10, 2, 10))
	rbox(g, Vector3(0.38, 0.016, 0.38), 0.004, plastic(0x1c1d20), Vector3(0, 0.42, 0))
	var bk := soft_box(g, Vector3(0.42, 0.34, 0.045), 0.02, pad, Vector3(0, 0.72, 0.19), Vector3i(10, 8, 2))
	bk.rotation.x = 0.08
	var sh := rbox(g, Vector3(0.38, 0.3, 0.012), 0.004, plastic(0x1c1d20), Vector3(0, 0.72, 0.219))
	sh.rotation.x = 0.08
	for sx in [-1.0, 1.0]:
		tube(g, [Vector3(float(sx) * 0.15, 0.415, 0.15), Vector3(float(sx) * 0.15, 0.415, 0.22), Vector3(float(sx) * 0.15, 0.5, 0.232), Vector3(float(sx) * 0.15, 0.6, 0.222)], 0.009, leg, 8)
		for sz in [-1.0, 1.0]:
			var fx: float = float(sx) * 0.18
			var fz: float = float(sz) * 0.18
			rod(g, Vector3(fx * 0.88, 0.415, fz * 0.88), Vector3(fx * 1.08, 0.012, fz * 1.08), 0.0115, leg, 10)
			cyl(g, 0.013, 0.015, 0.012, rubber(), Vector3(fx * 1.08, 0.006, fz * 1.08), 10)
		rod(g, Vector3(float(sx) * 0.178, 0.17, -0.178), Vector3(float(sx) * 0.178, 0.17, 0.178), 0.006, leg, 6).set_meta("ghost", true)
	return {"g": g, "foot": Vector2(0.42, 0.42)}


# ───────────────────────────── 냉장고 · 장
static func _fridge(_p: Dictionary) -> Dictionary:
	var g := node(null)
	var w := 0.46
	var d := 0.46
	var h := 0.84
	var shell := painted(0xdedcd6, 0.36)
	var trim := plastic(0x8d8f91, 0.5)
	# 몸통은 문보다 뒤에서 끝나고, 사이에 고무 패킹
	rbox(g, Vector3(w, h - 0.03, d - 0.05), 0.008, shell, Vector3(0, (h + 0.03) / 2.0, -0.025))
	box(g, Vector3(w - 0.03, h - 0.06, 0.012), mat(0x2b2b2c, 0.8), Vector3(0, (h + 0.03) / 2.0, d / 2.0 - 0.05))
	var split := h * 0.7
	var door := painted(0xe3e1db, 0.32)
	rbox(g, Vector3(w, split - 0.035, 0.04), 0.009, door, Vector3(0, (split + 0.033) / 2.0, d / 2.0 - 0.02))
	rbox(g, Vector3(w, h - split - 0.005, 0.04), 0.009, door, Vector3(0, split + (h - split) / 2.0 + 0.0025, d / 2.0 - 0.02))
	# 손잡이: 문 위쪽을 파 낸 홈과 세로 손잡이
	box(g, Vector3(w - 0.08, 0.008, 0.012), mat(0x3b3a38, 0.7), Vector3(0, split + 0.002, d / 2.0 + 0.001))
	rbox(g, Vector3(0.024, 0.2, 0.022), 0.007, trim, Vector3(w / 2.0 - 0.05, h * 0.5, d / 2.0 + 0.013))
	rbox(g, Vector3(0.024, 0.07, 0.022), 0.007, trim, Vector3(w / 2.0 - 0.05, split + 0.05, d / 2.0 + 0.013))
	# 경첩 덮개 · 다리 · 전선 · 뒷면 방열판
	for y in [h - 0.003, 0.028]:
		rbox(g, Vector3(0.05, 0.012, 0.05), 0.003, trim, Vector3(-w / 2.0 + 0.04, float(y), d / 2.0 - 0.015))
	for sx in [-1.0, 1.0]:
		cyl(g, 0.016, 0.019, 0.024, rubber(), Vector3(float(sx) * (w / 2.0 - 0.05), 0.012, d / 2.0 - 0.06), 12)
		cyl(g, 0.016, 0.016, 0.024, rubber(), Vector3(float(sx) * (w / 2.0 - 0.05), 0.012, -d / 2.0 + 0.06), 12)
	for i in 10:
		rod(g, Vector3(-w / 2.0 + 0.05 + i * 0.04, 0.1, -d / 2.0 - 0.004), Vector3(-w / 2.0 + 0.05 + i * 0.04, h - 0.06, -d / 2.0 - 0.004), 0.002, mat(0x2a2a2a, 0.6, 0.4), 4).set_meta("ghost", true)
	# 상표 · 에너지 표시 스티커
	text(g, "ROOMI", 0.016, ink(0x8c8e90), Vector3(-w / 2.0 + 0.08, h - 0.035, d / 2.0 + 0.0006))
	box(g, Vector3(0.07, 0.1, 0.0008), mat(0xf4f2ea, 0.8), Vector3(-w / 2.0 + 0.085, h * 0.42, d / 2.0 + 0.0005))
	text(g, "에너지", 0.012, ink(0x2a7a3a), Vector3(-w / 2.0 + 0.085, h * 0.42 + 0.03, d / 2.0 + 0.0012))
	text(g, "1등급", 0.018, ink(0x2a7a3a), Vector3(-w / 2.0 + 0.085, h * 0.42, d / 2.0 + 0.0012))
	tube(g, [Vector3(-0.15, 0.1, -d / 2.0 - 0.01), Vector3(-0.2, 0.05, -d / 2.0 - 0.05), Vector3(-0.22, 0.01, -d / 2.0 - 0.1)], 0.004, rubber(), 6)
	return {"g": g, "foot": Vector2(w, d)}


static func _wardrobe(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.3)
	var d: float = p.get("d", 0.58)
	var h := 1.85
	var lac := mat(0x1a110e, 0.22, 0.05)
	var inner := wood(0x3a2a20, 0.85)
	rbox(g, Vector3(w + 0.03, 0.04, d + 0.02), 0.01, lac, Vector3(0, h - 0.02, 0))
	rbox(g, Vector3(w + 0.012, 0.02, d + 0.01), 0.006, lac, Vector3(0, h - 0.05, 0))
	rbox(g, Vector3(w + 0.02, 0.09, d + 0.012), 0.008, lac, Vector3(0, 0.055, 0))
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(0.03, h, d), 0.004, lac, Vector3(float(sx) * (w / 2.0 - 0.015), h / 2.0, 0))
		for sz in [-1.0, 1.0]:
			var ft := lathe(g, [Vector2(0.0, 0.0), Vector2(0.022, 0.0), Vector2(0.03, 0.012), Vector2(0.03, 0.022), Vector2(0.02, 0.03), Vector2(0.0, 0.03)], lac, Vector3(float(sx) * (w / 2.0 - 0.06), 0.0, float(sz) * (d / 2.0 - 0.06)), 14)
			ft.scale.y = 0.4
	box(g, Vector3(w, h, 0.02), inner, Vector3(0, h / 2.0, -d / 2.0 + 0.01))
	box(g, Vector3(0.02, h - 0.16, d - 0.05), inner, Vector3(0.0, h / 2.0 + 0.03, -0.015))
	for y in [0.72, 1.25]:
		box(g, Vector3(w - 0.06, 0.022, d - 0.04), inner, Vector3(0, float(y), 0))
	# 오른쪽 칸에 개어 쌓은 이불
	for b in [[1.37, 0.22, 0x9b4a5a], [1.57, 0.18, 0x3f5f8a], [0.9, 0.3, 0x3f5f8a]]:
		var fold := soft_box(g, Vector3(w * 0.42, float(b[1]), d * 0.7), 0.05, cloth_m(int(b[2])), Vector3(w * 0.22, float(b[0]), 0), Vector3i(8, 6, 6))
		fold.rotation.y = 0.04
		box(g, Vector3(w * 0.4, 0.0015, d * 0.68), mat(shade(int(b[2]), 0.35), 1.0), Vector3(w * 0.22, float(b[0]), d * 0.01)).set_meta("ghost", true)
	var nm: String = p.get("name", "wardrobe")
	var face := tmat("najeon_ward", 0.2, {"metallic_specular": 0.65})
	var bm := brass()
	var dw := w / 2.0 - 0.03
	for side in [-1.0, 1.0]:
		var pv := pivot(g, nm + ("L" if side < 0.0 else "R"), Vector3(float(side) * (w / 2.0 - 0.03), 0, d / 2.0))
		var c: float = -float(side) * dw / 2.0
		rbox(pv, Vector3(dw, h - 0.16, 0.025), 0.003, lac, Vector3(c, h / 2.0 + 0.03, 0.0125))
		quad(pv, dw - 0.04, h - 0.2, face, Vector3(c, h / 2.0 + 0.03, 0.0256))
		# 문 테두리 (자개 면이 살짝 들어가 보인다)
		for sy in [-1.0, 1.0]:
			box(pv, Vector3(dw, 0.02, 0.006), lac, Vector3(c, h / 2.0 + 0.03 + float(sy) * (h - 0.18) / 2.0, 0.0268))
		for sx in [-1.0, 1.0]:
			box(pv, Vector3(0.02, h - 0.16, 0.006), lac, Vector3(c + float(sx) * (dw / 2.0 - 0.01), h / 2.0 + 0.03, 0.0268))
		# 놋쇠 경첩 셋, 돋을새김 손잡이 판과 고리
		for y in [0.34, h / 2.0 + 0.03, h - 0.3]:
			box(pv, Vector3(0.05, 0.07, 0.003), bm, Vector3(float(side) * -0.018, float(y), 0.0305))
			cyl(pv, 0.0045, 0.0045, 0.078, bm, Vector3(float(side) * 0.008, float(y), 0.032), 10)
		var hx: float = -float(side) * (dw - 0.045)
		var plt := lathe(pv, [Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.038, 0.003), Vector2(0.03, 0.005), Vector2(0.0, 0.005)], bm, Vector3(hx, h / 2.0, 0.0305), 20)
		plt.rotation.x = PI / 2.0
		rod(pv, Vector3(hx, h / 2.0 + 0.012, 0.031), Vector3(hx, h / 2.0 + 0.012, 0.044), 0.0038, bm, 8)
		ring(pv, 0.021, 0.0028, bm, Vector3(hx, h / 2.0 - 0.012, 0.043), 24, 8)
	return {"g": g, "foot": Vector2(w, d)}


static func _low_table() -> Dictionary:
	var g := node(null)
	var m := wood(0x7a4f2c, 0.32, true)
	var edge := wood(0x5a3a22, 0.4)
	lathe(g, [Vector2(0.0, 0.27), Vector2(0.318, 0.27), Vector2(0.33, 0.276), Vector2(0.33, 0.296), Vector2(0.322, 0.3), Vector2(0.0, 0.3)], m, Vector3.ZERO, 40, 60.0)
	var leg := wood(0x6a4426, 0.5)
	var hinge := steel(0x8c9094, 0.4)
	for i in 4:
		var a := i / 4.0 * TAU + 0.78
		var dir := Vector3(cos(a), 0, sin(a))
		var top := dir * 0.2 + Vector3(0, 0.27, 0)
		var ft := dir * 0.235 + Vector3(0, 0.0, 0)
		var lg := rbox(g, Vector3(0.03, 0.27, 0.03), 0.006, leg, (top + ft) / 2.0 - Vector3(0, 0.0, 0))
		lg.rotation = Vector3(-dir.z * 0.13, 0.0, dir.x * 0.13)
		var br := rbox(g, Vector3(0.042, 0.018, 0.042), 0.002, hinge, top - Vector3(0, 0.008, 0))
		br.rotation.y = -a
		cyl(g, 0.018, 0.02, 0.004, rubber(), ft + Vector3(0, 0.002, 0), 10)
	# 접이식 다리를 잇는 보강대
	for i in 2:
		var a := i / 2.0 * PI + 0.78
		var dir := Vector3(cos(a), 0, sin(a))
		rbox(g, Vector3(0.36, 0.012, 0.012), 0.002, edge, dir * 0.0 + Vector3(0, 0.235, 0)).rotation.y = -a
	return {"g": g, "foot": Vector2(0.62, 0.62)}


# ───────────────────────────── 2장 설비
static func _stove() -> Dictionary:
	var g := node(null)
	var iron := pbr("rust", 0x35312e, 0.62, 0.35)
	var band_m := steel(0x5f5951, 0.45)
	var rust_m := pbr("rust", 0x5b3a26, 0.85, 0.15)
	var pipe_m := pbr("rust", 0x3b3936, 0.55, 0.4)
	# 몸통: 아래가 살짝 넓고 띠로 조여 있다
	lathe(g, [Vector2(0.0, 0.06), Vector2(0.215, 0.06), Vector2(0.222, 0.066), Vector2(0.222, 0.096), Vector2(0.214, 0.102), Vector2(0.206, 0.3), Vector2(0.21, 0.31), Vector2(0.21, 0.33), Vector2(0.204, 0.335), Vector2(0.205, 0.495), Vector2(0.219, 0.5), Vector2(0.219, 0.522), Vector2(0.0, 0.53)], iron, Vector3.ZERO, 36, 50.0)
	cyl(g, 0.222, 0.222, 0.028, band_m, Vector3(0, 0.08, 0), 36)
	cyl(g, 0.219, 0.219, 0.022, band_m, Vector3(0, 0.51, 0), 36)
	for i in 3:
		var a := TAU * i / 3.0 + 0.5
		lathe(g, [Vector2(0.0, 0.0), Vector2(0.026, 0.0), Vector2(0.02, 0.012), Vector2(0.016, 0.06), Vector2(0.0, 0.06)], iron, Vector3(cos(a) * 0.16, 0.0, sin(a) * 0.16), 10)
	# 윗판과 뚜껑: 고리 손잡이 · 공기 조절 구멍
	cyl(g, 0.24, 0.24, 0.024, iron, Vector3(0, 0.55, 0), 40)
	lathe(g, [Vector2(0.0, 0.562), Vector2(0.118, 0.562), Vector2(0.12, 0.572), Vector2(0.108, 0.58), Vector2(0.0, 0.586)], band_m, Vector3(0, 0, 0.03), 28)
	var hd := tube(g, [Vector3(-0.045, 0.586, 0.03), Vector3(-0.03, 0.616, 0.03), Vector3(0.03, 0.616, 0.03), Vector3(0.045, 0.586, 0.03)], 0.006, mat(0x1c1a19, 0.6, 0.3), 8)
	hd.set_meta("ghost", true)
	# 재받이 문: 경첩 · 틀 · 돌려 여는 손잡이 · 공기구멍
	var ash_z := 0.206
	rbox(g, Vector3(0.21, 0.09, 0.022), 0.004, rust_m, Vector3(0, 0.155, ash_z))
	for sx in [-1.0, 1.0]:
		cyl(g, 0.006, 0.006, 0.03, band_m, Vector3(float(sx) * 0.085, 0.204, ash_z + 0.012), 8).rotation.z = PI / 2.0
	cylz(g, 0.012, 0.016, band_m, Vector3(0, 0.155, ash_z + 0.018), 12)
	rod(g, Vector3(-0.03, 0.155, ash_z + 0.03), Vector3(0.03, 0.155, ash_z + 0.03), 0.0045, mat(0x1c1a19, 0.6, 0.3), 8)
	for i in 5:
		box(g, Vector3(0.012, 0.022, 0.003), mat(0x0d0c0b, 0.8), Vector3(-0.05 + i * 0.025, 0.135, ash_z + 0.0115))
	# 연통: 마디 이음새 · 고정쇠 · 조절판 · 벽 칼라
	for i in 4:
		var y0: float = 0.56 + i * 0.3
		cyl(g, 0.045, 0.045, 0.3, pipe_m, Vector3(0, y0 + 0.15, -0.12), 18)
		lathe(g, [Vector2(0.0465, y0 - 0.018), Vector2(0.049, y0 - 0.012), Vector2(0.049, y0 + 0.012), Vector2(0.0465, y0 + 0.018)], band_m, Vector3(0, 0, -0.12), 18)
	cylz(g, 0.014, 0.01, band_m, Vector3(0, 0.86, -0.0752), 8)
	rod(g, Vector3(-0.025, 0.86, -0.07), Vector3(0.025, 0.86, -0.07), 0.003, mat(0x1c1a19, 0.6, 0.3), 6).set_meta("ghost", true)
	sph(g, 0.047, pipe_m, Vector3(0, 1.76, -0.12), 16)
	var hp := cyl(g, 0.045, 0.045, 0.32, pipe_m, Vector3(0, 1.76, -0.28), 16)
	hp.rotation.x = PI / 2.0
	var collar := cyl(g, 0.078, 0.078, 0.01, band_m, Vector3(0, 1.76, -0.392), 24)
	collar.rotation.x = PI / 2.0
	return {"g": g, "foot": Vector2(0.48, 0.48)}


## 브라운관 TV와 미닫이 장, 리모컨
static func _tv() -> Dictionary:
	var g := node(null)
	var wm := wood(0x6b4a30, 0.42, true)
	var dk := wood(0x4a3220, 0.55)
	rbox(g, Vector3(1.0, 0.03, 0.42), 0.006, wm, Vector3(0, 0.435, 0))
	rbox(g, Vector3(1.0, 0.025, 0.42), 0.004, wm, Vector3(0, 0.09, 0))
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(0.025, 0.36, 0.42), 0.003, dk, Vector3(float(sx) * 0.4875, 0.26, 0))
		for sz in [-1.0, 1.0]:
			rbox(g, Vector3(0.05, 0.08, 0.05), 0.008, dk, Vector3(float(sx) * 0.44, 0.04, float(sz) * 0.16))
	box(g, Vector3(0.96, 0.33, 0.012), dk, Vector3(0, 0.26, -0.2))
	box(g, Vector3(0.95, 0.012, 0.36), dk, Vector3(0, 0.26, -0.01))
	# 미닫이 문 두 짝: 레일에 겹치고 손가락 홈이 있다
	box(g, Vector3(0.95, 0.008, 0.03), steel(0x6a6a68), Vector3(0, 0.106, 0.195))
	box(g, Vector3(0.95, 0.008, 0.03), steel(0x6a6a68), Vector3(0, 0.415, 0.195))
	for i in 2:
		var x := -0.24 + i * 0.48
		var z := 0.188 + i * 0.016
		rbox(g, Vector3(0.49, 0.3, 0.012), 0.002, wm, Vector3(x, 0.26, z))
		cylz(g, 0.018, 0.003, mat(0x2a1a10, 0.7), Vector3(x + (0.2 if i == 0 else -0.2), 0.26, z + 0.006), 16)
	# 브라운관 TV: 앞 테 · 볼록한 화면 · 뒤로 좁아지는 몸통
	var case_m := plastic(0x2b2a29, 0.48)
	var case_d := plastic(0x1e1d1c, 0.55)
	var ty := 0.65
	rbox(g, Vector3(0.5, 0.4, 0.06), 0.014, case_m, Vector3(-0.18, ty, 0.158))
	var rear := rbox(g, Vector3(0.42, 0.33, 0.28), 0.03, case_d, Vector3(-0.18, ty - 0.01, -0.03))
	rear.scale.x = 1.0
	# 뒤판 통풍 슬롯
	for i in 12:
		box(g, Vector3(0.015, 0.002, 0.2), mat(0x060606, 0.8), Vector3(-0.3 + i * 0.022, ty + 0.1555, -0.04))
	var bezel := rbox(g, Vector3(0.408, 0.33, 0.006), 0.006, mat(0x0f0f10, 0.45), Vector3(-0.2, ty + 0.005, 0.189))
	bezel.set_meta("ghost", true)
	var q := QuadMesh.new()
	q.size = Vector2(0.38, 0.3)
	q.subdivide_width = 14
	q.subdivide_depth = 12
	var scr := deformed(q, func(v): return Vector3(v.x, v.y, 0.012 * (1.0 - pow(v.x / 0.19, 2.0)) * (1.0 - pow(v.y / 0.15, 2.0))))
	mi(g, scr, tmat("tv_screen", 0.32, {"metallic_specular": 0.7}), Vector3(-0.2, ty + 0.005, 0.1925))
	# 오른쪽 조작부: 스피커 구멍 · 전원 · 채널 · 음량 · 표시등 · 단자
	var px := 0.025
	for j in 9:
		for i in 6:
			cylz(g, 0.0016, 0.001, mat(0x070707, 0.9), Vector3(px - 0.022 + i * 0.009, ty + 0.14 - j * 0.009, 0.1885), 6)
	var bt := plastic(0x45433f, 0.4)
	var lbl := ink(0xc6c2b8)
	var rows := [["전원", 0.05, 0xb5332a], ["CH", 0.016, 0x45433f], ["CH", -0.006, 0x45433f], ["VOL", -0.03, 0x45433f], ["VOL", -0.052, 0x45433f]]
	for i in rows.size():
		var r: Array = rows[i]
		var ky: float = ty + float(r[1])
		rbox(g, Vector3(0.026, 0.016, 0.006), 0.0025, plastic(int(r[2]), 0.4) if i == 0 else bt, Vector3(px, ky, 0.1912))
		if i in [0, 1, 3]:
			text(g, str(r[0]), 0.0075, lbl, Vector3(px, ky + 0.0125, 0.1892))
	text(g, "▲", 0.008, lbl, Vector3(px, ty + 0.016, 0.1945))
	text(g, "▼", 0.008, lbl, Vector3(px, ty - 0.006, 0.1945))
	text(g, "+", 0.008, lbl, Vector3(px, ty - 0.03, 0.1945))
	text(g, "-", 0.008, lbl, Vector3(px, ty - 0.052, 0.1945))
	sph(g, 0.003, mat(0xff3322, 0.4, 0.0, {"emit": 0x992211, "emit_e": 1.2}), Vector3(px, ty + 0.078, 0.1894), 8)
	for i in 3:
		cylz(g, 0.0045, 0.006, mat(0xd6b24a if i == 0 else (0xeeeeee if i == 1 else 0xc7372f), 0.4), Vector3(px - 0.012 + i * 0.012, ty - 0.12, 0.1896), 10)
	text(g, "HANBIT", 0.0105, ink(0xb8b4aa), Vector3(-0.2, ty - 0.178, 0.1892))
	# 안테나
	var ch := chrome(0xc8ccd0, 0.22)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.026, 0.02), Vector2(0.012, 0.03), Vector2(0.0, 0.03)], case_d, Vector3(-0.18, ty + 0.165, -0.02), 14)
	for sx in [-1.0, 1.0]:
		var d0 := Vector3(float(sx) * 0.52, 1.0, -0.12).normalized()
		var base := Vector3(-0.18, ty + 0.19, -0.02)
		var r0: float = 0.0035
		for seg in 3:
			var a := base + d0 * (0.13 * seg)
			var b := base + d0 * (0.13 * (seg + 1))
			rod(g, a, b, r0 - seg * 0.0008, ch, 6).set_meta("ghost", true)
		sph(g, 0.004, ch, base + d0 * 0.39, 8)
	_remote(g, Vector3(0.43, 0.45, -0.09), 0.25)
	return {"g": g, "foot": Vector2(1.0, 0.42)}


## 리모컨: 버튼 하나하나와 "9번" 스티커
static func _remote(parent: Node3D, c: Vector3, ry: float) -> void:
	var r := node(parent, c)
	r.rotation.y = ry
	var w := 0.05
	var l := 0.165
	var body := plastic(0x26262a, 0.5)
	plate(r, w, l, 0.018, 0.012, body, Vector3(0, 0.009, 0), 0.0025)
	var top := 0.018
	var nb := plastic(0x8d8d90, 0.45)
	var lbl := ink(0x101012)
	# 전원 · 입력
	var pw := cyl(r, 0.0055, 0.0055, 0.003, plastic(0xc7372f, 0.4), Vector3(-0.012, top + 0.0012, -0.066), 12)
	pw.set_meta("ghost", true)
	rbox(r, Vector3(0.014, 0.003, 0.009), 0.001, nb, Vector3(0.012, top + 0.0012, -0.066))
	text(r, "입력", 0.0045, lbl, Vector3(0.012, top + 0.0031, -0.066), "up")
	# 숫자 3 x 4
	var keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"]
	for i in keys.size():
		var kx := -0.0135 + (i % 3) * 0.0135
		var kz := -0.046 + int(i / 3) * 0.0125
		rbox(r, Vector3(0.0105, 0.003, 0.0085), 0.0012, nb, Vector3(kx, top + 0.0012, kz))
		text(r, keys[i], 0.0058, lbl, Vector3(kx, top + 0.0031, kz), "up")
	# 음량 · 채널 시소 버튼과 십자 버튼
	var bz := 0.022
	for sx in [-1.0, 1.0]:
		rbox(r, Vector3(0.0095, 0.0035, 0.024), 0.002, nb, Vector3(float(sx) * 0.0145, top + 0.0014, bz + 0.01))
		text(r, "+", 0.0052, lbl, Vector3(float(sx) * 0.0145, top + 0.0034, bz + 0.002), "up")
		text(r, "-", 0.0052, lbl, Vector3(float(sx) * 0.0145, top + 0.0034, bz + 0.018), "up")
	cyl(r, 0.0065, 0.0065, 0.0028, plastic(0x4b4b50, 0.4), Vector3(0, top + 0.0012, bz + 0.01), 16)
	cyl(r, 0.0028, 0.0028, 0.0034, plastic(0xa0a0a4, 0.4), Vector3(0, top + 0.0014, bz + 0.01), 10)
	for k in 3:
		cyl(r, 0.0032, 0.0032, 0.0025, plastic(int([0xc7372f, 0x2a9b4a, 0x2a6fd1][k]), 0.4), Vector3(-0.011 + k * 0.011, top + 0.0011, 0.058), 10)
	# 9번 버튼 옆 스티커
	box(r, Vector3(0.02, 0.0004, 0.012), mat(0xf0d24a, 0.9), Vector3(0.0, top + 0.0002, 0.0734))
	text(r, "9", 0.0082, ink(0x2a2a2a), Vector3(0, top + 0.00048, 0.0734), "up")
	# 앞쪽 적외선 창
	cylz(r, 0.0048, 0.002, mat(0x2a0a0a, 0.15), Vector3(0, 0.0095, -l / 2.0), 10)


static func _futons() -> Dictionary:
	var g := node(null)
	for i in range(4):
		var w := 0.85 - i * 0.03
		var y := 0.065 + i * 0.13
		var n := soft_box(g, Vector3(w, 0.13, 0.62), 0.05, tmat("futon%d" % i, 1.0), Vector3((i % 2) * 0.02, y, 0), Vector3i(10, 4, 8))
		n.rotation.y = (i - 1.5) * 0.02
		# 개어 놓은 접힘선
		box(g, Vector3(w - 0.03, 0.0015, 0.6), mat(0x1a1612, 1.0), Vector3((i % 2) * 0.02, y, 0.0)).set_meta("ghost", true)
	return {"g": g, "foot": Vector2(0.85, 0.62)}


static func _emat(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 0.9)
	var d: float = p.get("d", 1.8)
	rbox(g, Vector3(w, 0.01, d), 0.0035, pbr("fabric", 0xcdb894, 1.0), Vector3(0, 0.005, 0))
	plane_up(g, w, d, tmat("emat", 1.0), Vector3(0, 0.0105, 0))
	_piping(g, w - 0.01, d - 0.01, 0.0095, cloth_m(0x9e7d4f), 0.0035)
	# 온도 조절기: 다이얼과 전원 스위치, 멀티탭 쪽으로 뽑혀 나온 줄
	var ct := node(g, Vector3(w / 2.0 - 0.14, 0.012, d / 2.0 + 0.06))
	var body := plastic(0xe8e4d8, 0.5)
	rbox(ct, Vector3(0.09, 0.03, 0.05), 0.008, body, Vector3(0, 0.015, 0))
	lathe(ct, [Vector2(0.0, 0.03), Vector2(0.018, 0.03), Vector2(0.017, 0.042), Vector2(0.0, 0.043)], plastic(0x8c3a2a, 0.45), Vector3(-0.022, 0.0, 0.0), 18)
	for i in 5:
		var a := -2.0 + i * 1.0
		box(ct, Vector3(0.0012, 0.0004, 0.005), mat(0x333333), Vector3(-0.022 + sin(a) * 0.024, 0.0303, cos(a) * 0.024 * -1.0))
	rbox(ct, Vector3(0.016, 0.006, 0.02), 0.0015, plastic(0x2c2c2c, 0.4), Vector3(0.024, 0.031, 0.0))
	sph(ct, 0.0028, mat(0x555555, 0.4), Vector3(0.024, 0.034, -0.014), 8)
	text(ct, "강", 0.008, ink(0x4a2a22), Vector3(-0.022, 0.0306, 0.021), "up")
	var cord := rubber(0x2a2a2a)
	tube(g, [Vector3(w / 2.0 - 0.14, 0.008, d / 2.0 + 0.03), Vector3(w / 2.0 - 0.14, 0.012, d / 2.0 + 0.01), Vector3(w / 2.0 - 0.14, 0.012, d / 2.0 - 0.02)], 0.0045, cord, 6)
	tube(g, [Vector3(w / 2.0 - 0.095, 0.008, d / 2.0 + 0.06), Vector3(w / 2.0 - 0.01, 0.005, d / 2.0 + 0.11), Vector3(0.12, 0.005, d / 2.0 + 0.17), Vector3(0.1, 0.005, d / 2.0 + 0.1), Vector3(0.14, 0.005, 1.0)], 0.0042, cord, 6)
	return {"g": g}


# ───────────────────────────── 싱크대 · 주방
static func _door_panel(g: Node3D, w: float, h: float, c: Vector3, m: Material, hm: Material, knob_side: float) -> void:
	rbox(g, Vector3(w, h, 0.018), 0.003, m, c)
	_bar_handle(g, c + Vector3(knob_side * (w / 2.0 - 0.04), h * 0.28, 0.034), 0.11, hm, true)


## 수납장 몸통: 아래는 꽉 찬 상자, 위쪽은 개수대가 들어가도록 테두리만
static func _cabinet(g: Node3D, w: float, d: float, y0: float, y1: float, solid_top: float, m: Material) -> void:
	box(g, Vector3(w, solid_top - y0, d), m, Vector3(0, (y0 + solid_top) / 2.0, 0))
	var sh := y1 - solid_top
	var sy := solid_top + sh / 2.0
	box(g, Vector3(w, sh, 0.02), m, Vector3(0, sy, d / 2.0 - 0.01))
	box(g, Vector3(w, sh, 0.02), m, Vector3(0, sy, -d / 2.0 + 0.01))
	box(g, Vector3(0.02, sh, d), m, Vector3(-w / 2.0 + 0.01, sy, 0))
	box(g, Vector3(0.02, sh, d), m, Vector3(w / 2.0 - 0.01, sy, 0))


## 상판에 개수대 구멍을 내고(네 조각), 눌러 찍은 개수대 · 배수구 거름망 · 넘침 구멍 · 수도꼭지와 레버
static func _basin_top(g: Node3D, w: float, d: float, top_y: float, t: float, top_m: Material, bx: float, bw: float, bd: float, depth: float) -> void:
	var lw := (bx - bw / 2.0) + w / 2.0
	var rw := w / 2.0 - (bx + bw / 2.0)
	var fd := (d - bd) / 2.0
	box(g, Vector3(lw, t, d), top_m, Vector3(-w / 2.0 + lw / 2.0, top_y, 0))
	box(g, Vector3(rw, t, d), top_m, Vector3(w / 2.0 - rw / 2.0, top_y, 0))
	box(g, Vector3(bw, t, fd), top_m, Vector3(bx, top_y, d / 2.0 - fd / 2.0))
	box(g, Vector3(bw, t, fd), top_m, Vector3(bx, top_y, -d / 2.0 + fd / 2.0))
	var bowl := steel(0x8f969a, 0.28)
	var top := top_y + t / 2.0
	box(g, Vector3(bw, 0.006, bd), bowl, Vector3(bx, top - depth, 0))
	for sx in [-1.0, 1.0]:
		box(g, Vector3(0.006, depth, bd), bowl, Vector3(bx + float(sx) * (bw / 2.0 - 0.003), top - depth / 2.0, 0))
	for sz in [-1.0, 1.0]:
		box(g, Vector3(bw, depth, 0.006), bowl, Vector3(bx, top - depth / 2.0, float(sz) * (bd / 2.0 - 0.003)))
	# 개수대 테두리 (상판 위로 말아 올린 입술)
	var rim := steel(0xc4c8cb, 0.22)
	for sz in [-1.0, 1.0]:
		rbox(g, Vector3(bw + 0.02, 0.003, 0.012), 0.001, rim, Vector3(bx, top + 0.001, float(sz) * (bd / 2.0 + 0.002)))
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(0.012, 0.003, bd + 0.02), 0.001, rim, Vector3(bx + float(sx) * (bw / 2.0 + 0.002), top + 0.001, 0))
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.034, 0.0), Vector2(0.036, 0.003), Vector2(0.03, 0.005), Vector2(0.0, 0.005)], chrome(0xb0b4b8, 0.3), Vector3(bx, top - depth + 0.003, 0), 20)
	for i in 8:
		var a := i * TAU / 8.0
		box(g, Vector3(0.012, 0.002, 0.0028), mat(0x151515, 0.8), Vector3(bx + cos(a) * 0.016, top - depth + 0.0085, sin(a) * 0.016)).rotation.y = -a
	cyl(g, 0.0055, 0.0055, 0.003, mat(0x101010, 0.8), Vector3(bx, top - depth + 0.0085, 0), 10)
	cylz(g, 0.009, 0.002, mat(0x202020, 0.7), Vector3(bx, top - 0.03, -bd / 2.0 + 0.0065), 12)
	# 수도꼭지: 받침 · 몸통 · 휜 토수구 · 거품기 · 레버
	var ch := chrome()
	var fz := -d / 2.0 + fd / 2.0
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.03, 0.004), Vector2(0.024, 0.01), Vector2(0.017, 0.022), Vector2(0.017, 0.07), Vector2(0.016, 0.076), Vector2(0.0, 0.076)], ch, Vector3(bx, top, fz), 22, 55.0)
	tube(g, [Vector3(bx, top + 0.07, fz), Vector3(bx, top + 0.19, fz + 0.004), Vector3(bx, top + 0.25, fz + 0.04), Vector3(bx, top + 0.235, fz + 0.115), Vector3(bx, top + 0.2, fz + 0.15)], 0.0105, ch, 12, true, 6)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.01, 0.0), Vector2(0.013, 0.003), Vector2(0.013, 0.02), Vector2(0.0108, 0.024), Vector2(0.0, 0.024)], ch, Vector3(bx, top + 0.178, fz + 0.15), 14)
	lathe(g, [Vector2(0.0, 0.08), Vector2(0.017, 0.08), Vector2(0.015, 0.1), Vector2(0.0, 0.106)], ch, Vector3(bx, top, fz), 16)
	var lv := rod(g, Vector3(bx, top + 0.106, fz), Vector3(bx, top + 0.124, fz - 0.082), 0.0052, ch, 10)
	lv.set_meta("ghost", true)
	sph(g, 0.0075, ch, Vector3(bx, top + 0.125, fz - 0.084), 10)


static func _sink(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.0)
	var d := 0.5
	var h := 0.8
	var depth := 0.16
	var body := painted(0xd8ccb4, 0.55)
	var door := painted(0xe4dac5, 0.42)
	box(g, Vector3(w - 0.04, 0.08, d - 0.08), rubber(0x2a2622), Vector3(0, 0.04, -0.02))
	_cabinet(g, w, d, 0.08, h, h + 0.03 - depth - 0.02, body)
	var hm := steel(0xc4c7ca, 0.26)
	for sx in [-1.0, 1.0]:
		_door_panel(g, w / 2.0 - 0.02, h - 0.2, Vector3(float(sx) * w / 4.0, 0.08 + (h - 0.2) / 2.0 + 0.02, d / 2.0 + 0.004), door, hm, -float(sx))
	_basin_top(g, w, d, h + 0.015, 0.03, steel(0xa8aeb1, 0.3), p.get("bx", -0.15), p.get("bw", 0.42), 0.3, depth)
	# 뒤 벽 타일
	var tile := painted(0xdfe3e0, 0.18)
	var grout := mat(0x8a8a84, 0.9)
	box(g, Vector3(w, 0.14, 0.008), grout, Vector3(0, h + 0.1, -d / 2.0 + 0.006))
	var n := maxi(3, int(w / 0.1))
	for i in n:
		rbox(g, Vector3(w / n - 0.004, 0.06, 0.006), 0.0015, tile, Vector3(-w / 2.0 + (i + 0.5) * w / n, h + 0.067, -d / 2.0 + 0.012))
		rbox(g, Vector3(w / n - 0.004, 0.06, 0.006), 0.0015, tile, Vector3(-w / 2.0 + (i + 0.5) * w / n, h + 0.132, -d / 2.0 + 0.012))
	return {"g": g, "foot": Vector2(w, d)}


static func _kitchen(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.8)
	var d := 0.6
	var depth := 0.16
	var white := painted(0xf3f0ee, 0.28)
	var hm := steel(0xcfd2d4, 0.24)
	box(g, Vector3(w - 0.04, 0.07, d - 0.06), rubber(0x2a2826), Vector3(0, 0.035, -0.02))
	_cabinet(g, w, d, 0.07, 0.88, 0.88 - depth - 0.02, white)
	# 아래 문 다섯 칸. 왼쪽 끝(-x) 쪽은 빌트인 냉장고 문
	var n := 5
	var dw := w / n
	for i in n:
		var cx := -w / 2.0 + (i + 0.5) * dw
		if i == 0:
			continue
		_door_panel(g, dw - 0.006, 0.76, Vector3(cx, 0.45, d / 2.0 + 0.003), white, hm, 1.0 if i % 2 == 0 else -1.0)
	var fx := -w / 2.0 + 0.5 * dw
	rbox(g, Vector3(dw - 0.006, 0.76, 0.024), 0.003, painted(0xf6f4f1, 0.24), Vector3(fx, 0.45, d / 2.0 + 0.005))
	for i in 7:
		box(g, Vector3(dw - 0.06, 0.005, 0.003), mat(0x90908e, 0.5), Vector3(fx, 0.12 + i * 0.012, d / 2.0 + 0.018))
	_bar_handle(g, Vector3(fx + dw / 2.0 - 0.04, 0.6, d / 2.0 + 0.04), 0.2, hm, true)
	text(g, "냉장", 0.014, ink(0x8a8a88), Vector3(fx, 0.78, d / 2.0 + 0.0175))
	# 상판: 앞쪽 왼편에 2구 가스레인지
	_basin_top(g, w, d, 0.895, 0.03, pbr("paint", 0xd8d2cf, 0.22), p.get("bx", 0.1), 0.46, 0.36, depth)
	var hob := node(g, Vector3(-w / 2.0 + 0.4, 0.91, 0))
	rbox(hob, Vector3(0.5, 0.012, 0.38), 0.004, steel(0x8c9094, 0.28), Vector3(0, 0.006, 0))
	var cast := pbr("rust", 0x1d1d1f, 0.7, 0.3)
	for sx in [-1.0, 1.0]:
		var bx := float(sx) * 0.115
		lathe(hob, [Vector2(0.0, 0.012), Vector2(0.05, 0.012), Vector2(0.05, 0.018), Vector2(0.041, 0.024), Vector2(0.0, 0.024)], mat(0x2a2a2c, 0.55, 0.6), Vector3(bx, 0.0, -0.03), 22)
		lathe(hob, [Vector2(0.0, 0.0), Vector2(0.02, 0.0), Vector2(0.018, 0.012), Vector2(0.0, 0.012)], brass(0xb89a56, 0.4), Vector3(bx, 0.024, -0.03), 14)
		for i in 4:
			var a := i * PI / 2.0 + PI / 4.0
			var dir := Vector3(cos(a), 0, sin(a))
			var pc := Vector3(bx, 0.044, -0.03) + dir * 0.082
			rod(hob, pc - dir * 0.05, pc + dir * 0.05, 0.006, cast, 6)
			rod(hob, pc + dir * 0.05, pc + dir * 0.05 - Vector3(0, 0.034, 0), 0.006, cast, 6).set_meta("ghost", true)
		# 불 조절 다이얼
		var kn := node(hob, Vector3(bx, 0.012, 0.145))
		lathe(kn, [Vector2(0.0, 0.0), Vector2(0.024, 0.0), Vector2(0.024, 0.008), Vector2(0.021, 0.018), Vector2(0.0, 0.019)], chrome(0xbcbfc2, 0.25), Vector3.ZERO, 22)
		rbox(kn, Vector3(0.008, 0.007, 0.034), 0.002, plastic(0x2a2a2c, 0.4), Vector3(0, 0.021, 0))
		for k in 3:
			var ta := -0.9 + k * 0.9
			box(hob, Vector3(0.002, 0.0006, 0.007), mat(0xd8d8d8, 0.5), Vector3(bx + sin(ta) * 0.033, 0.0125, 0.145 - cos(ta) * 0.033))
	text(hob, "약", 0.01, ink(0xcfcfcf), Vector3(-0.115 - 0.034, 0.013, 0.17), "up")
	text(hob, "강", 0.01, ink(0xcfcfcf), Vector3(-0.115 + 0.034, 0.013, 0.17), "up")
	# 위 장: 문 네 짝과 가스 후드
	var upw := white
	rbox(g, Vector3(w, 0.65, 0.3), 0.004, upw, Vector3(0, 1.75, -0.15))
	var un := 4
	var uw := w / un
	for i in un:
		var cx := -w / 2.0 + (i + 0.5) * uw
		rbox(g, Vector3(uw - 0.006, 0.63, 0.018), 0.003, painted(0xf7f4f1, 0.22), Vector3(cx, 1.75, 0.01))
		_bar_handle(g, Vector3(cx + (uw / 2.0 - 0.04) * (1.0 if i % 2 == 0 else -1.0), 1.5, 0.042), 0.1, hm, true)
	var hood := node(g, Vector3(-w / 2.0 + 0.4, 1.34, -0.1))
	rbox(hood, Vector3(0.52, 0.09, 0.36), 0.006, steel(0xbfc2c4, 0.3), Vector3.ZERO)
	for i in 9:
		box(hood, Vector3(0.012, 0.001, 0.26), mat(0x1a1a1c, 0.8), Vector3(-0.2 + i * 0.05, -0.0455, 0))
	for i in 3:
		rbox(hood, Vector3(0.026, 0.012, 0.004), 0.0015, plastic(0x2a2a2c, 0.4), Vector3(-0.06 + i * 0.06, -0.01, 0.181))
	sph(hood, 0.0025, mat(0x222222, 0.4, 0.0, {"emit": 0x113311}), Vector3(0.13, -0.01, 0.181), 8)
	return {"g": g, "foot": Vector2(w, d)}


## 보일러 조절기: 뚜껑 · LCD · 전원/난방/온수/예약/온도 버튼 하나하나
static func _boiler() -> Dictionary:
	var g := node(null)
	var body := plastic(0xefefea, 0.42)
	rbox(g, Vector3(0.124, 0.164, 0.012), 0.004, mat(0xd8d8d2, 0.6), Vector3(0, 0, -0.012))
	rbox(g, Vector3(0.12, 0.16, 0.022), 0.009, body, Vector3(0, 0, 0.0))
	var dz := 0.0112
	box(g, Vector3(0.09, 0.056, 0.0014), mat(0x1b2420, 0.3), Vector3(0, 0.038, dz))
	quad(g, 0.08, 0.045, tmat("boiler_disp", 0.5, {"unshaded": true}), Vector3(0, 0.038, dz + 0.0009))
	var btn := plastic(0xdedcd6, 0.4)
	var lbl := ink(0x3a3a3a)
	var names := ["난방", "온수", "예약", "외출"]
	for i in 4:
		var bx := -0.039 + i * 0.026
		rbox(g, Vector3(0.022, 0.015, 0.0035), 0.0024, btn, Vector3(bx, -0.012, dz + 0.0012))
		text(g, names[i], 0.0058, lbl, Vector3(bx, -0.012, dz + 0.0032))
	for i in 2:
		var bx := -0.02 + i * 0.04
		rbox(g, Vector3(0.03, 0.017, 0.0035), 0.0028, plastic(0xcfccc5, 0.4), Vector3(bx, -0.036, dz + 0.0012))
		text(g, "▼" if i == 0 else "▲", 0.0095, lbl, Vector3(bx, -0.036, dz + 0.0032))
	var red := cylz(g, 0.0105, 0.0035, plastic(0xc7372f, 0.35), Vector3(0, -0.062, dz + 0.0012), 18)
	red.set_meta("ghost", true)
	text(g, "전원", 0.0058, ink(0xf2f2ef), Vector3(0, -0.062, dz + 0.0032))
	sph(g, 0.002, mat(0x3a3a3a, 0.4), Vector3(0.05, -0.062, dz + 0.0005), 6)
	text(g, "ROOMI", 0.007, ink(0x9a9a96), Vector3(-0.038, 0.073, dz))
	for sy in [-1.0, 1.0]:
		_screw(g, Vector3(0.05, float(sy) * 0.071, dz - 0.0008), steel(0x9a9a9a), 0.0018)
	tube(g, [Vector3(0, 0.08, -0.016), Vector3(0.0, 0.12, -0.017), Vector3(0.003, 0.2, -0.018), Vector3(-0.002, 0.4, -0.018)], 0.002, mat(0xe8e4d8, 0.7), 5)
	return {"g": g}


# ───────────────────────────── 창문
static func _window(p: Dictionary) -> Dictionary:
	if p.get("style", "") == "premium":
		return _window_premium(p)
	var g := node(null)
	var w: float = p.get("w", 0.7)
	var h: float = p.get("h", 0.5)
	var view: String = p.get("tex", "win_e1")
	var gm: StandardMaterial3D = tmat(view, 1.0, {"unshaded": true}).duplicate()
	gm.albedo_color = col(int(p.get("tint", 0x9aa4b0)))
	quad(g, w, h, gm, Vector3.ZERO)
	if p.has("overlay"):
		quad(g, w, h, tmat(p.overlay, 1.0, {"alpha_tex": true, "unshaded": true}), Vector3(0, 0, 0.03))
	var fm := painted(int(p.get("frame", 0xd8d6d0)), 0.42)
	var dk := mat(shade(int(p.get("frame", 0xd8d6d0)), 0.45), 0.8)
	# 바깥 창틀
	rbox(g, Vector3(w + 0.06, 0.04, 0.06), 0.004, fm, Vector3(0, h / 2.0 + 0.01, 0.005))
	rbox(g, Vector3(w + 0.06, 0.04, 0.06), 0.004, fm, Vector3(0, -h / 2.0 - 0.01, 0.005))
	rbox(g, Vector3(0.04, h, 0.06), 0.004, fm, Vector3(-w / 2.0 - 0.01, 0, 0.005))
	rbox(g, Vector3(0.04, h, 0.06), 0.004, fm, Vector3(w / 2.0 + 0.01, 0, 0.005))
	rbox(g, Vector3(w + 0.1, 0.015, 0.1), 0.003, fm, Vector3(0, -h / 2.0 - 0.036, 0.025))
	# 미닫이 두 짝: 틀 · 가운데 겹침 · 잠금쇠 · 유리 반사
	var sheen := _glass_sheen()
	var pvc := painted(int(p.get("frame", 0xd8d6d0)), 0.36)
	var sw := w / 2.0 + 0.006
	for k in 2:
		var cx := -sw / 2.0 + 0.003 if k == 0 else sw / 2.0 - 0.003
		var z := 0.012 if k == 0 else 0.03
		for sy in [-1.0, 1.0]:
			box(g, Vector3(sw, 0.02, 0.016), pvc, Vector3(cx, float(sy) * (h / 2.0 - 0.01), z))
		for sx in [-1.0, 1.0]:
			box(g, Vector3(0.02, h - 0.04, 0.016), pvc, Vector3(cx + float(sx) * (sw / 2.0 - 0.01), 0, z))
		quad(g, sw - 0.04, h - 0.04, sheen, Vector3(cx, 0, z))
		for sy in [-1.0, 1.0]:
			box(g, Vector3(sw - 0.04, 0.003, 0.002), dk, Vector3(cx, float(sy) * (h / 2.0 - 0.021), z + 0.003))
	var lk := steel(0xb8bcc0, 0.3)
	box(g, Vector3(0.018, 0.04, 0.006), lk, Vector3(0.0, 0, 0.043))
	var lv := box(g, Vector3(0.028, 0.007, 0.005), lk, Vector3(-0.008, 0.008, 0.048))
	lv.rotation.z = 0.5
	if p.get("bars", false):
		var bar := pbr("rust", 0x3a3a3a, 0.55, 0.5)
		for i in range(1, 6):
			cyl(g, 0.006, 0.006, h + 0.06, bar, Vector3(-w / 2.0 + i * w / 6.0, 0, 0.055), 8)
		for sy in [-1.0, 1.0]:
			box(g, Vector3(w + 0.03, 0.01, 0.01), bar, Vector3(0, float(sy) * (h / 2.0 + 0.012), 0.055))
	if p.has("curtain"):
		var cm := cloth_m(int(p["curtain"]))
		var top := h / 2.0 + 0.1
		var bot := -h / 2.0 - 0.15
		rod(g, Vector3(-w / 2.0 - 0.1, top + 0.02, 0.08), Vector3(w / 2.0 + 0.1, top + 0.02, 0.08), 0.007, steel(), 8)
		for sx in [-1.0, 1.0]:
			_drape(g, cm, w * 0.35, top - bot, 0.018, 0.05, Vector3(float(sx) * w * 0.38, (top + bot) / 2.0, 0.08), false)
	return {"g": g}


static func _fluoro() -> Dictionary:
	var g := node(null)
	var body := painted(0xdedbd3, 0.5)
	rbox(g, Vector3(0.62, 0.035, 0.1), 0.005, body, Vector3(0, -0.0175, 0))
	var glow := mat(0xf4f6f2, 0.4, 0.0, {"emit": 0xc8d4cc, "emit_e": 1.4})
	var tb := cyl(g, 0.0135, 0.0135, 0.56, glow, Vector3(0, -0.055, 0), 12)
	tb.rotation.z = PI / 2.0
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(0.02, 0.03, 0.05), 0.004, plastic(0xe8e4d8, 0.5), Vector3(float(sx) * 0.29, -0.05, 0))
		var cap_m := steel(0xaaaaaa, 0.3)
		var c := cyl(g, 0.0138, 0.0138, 0.012, cap_m, Vector3(float(sx) * 0.274, -0.055, 0), 12)
		c.rotation.z = PI / 2.0
	# 끈 스위치
	tube(g, [Vector3(0.2, -0.035, 0.0), Vector3(0.2, -0.2, 0.0), Vector3(0.203, -0.34, 0.002)], 0.0012, mat(0xd8d4c8, 0.9), 4)
	sph(g, 0.009, plastic(0xe0dcd0, 0.4), Vector3(0.203, -0.35, 0.002), 10)
	return {"g": g}


static func _bulb() -> Dictionary:
	var g := node(null)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.038, -0.012), Vector2(0.008, -0.02), Vector2(0.0, -0.02)], plastic(0xe8e4d8, 0.5), Vector3.ZERO, 16)
	tube(g, [Vector3(0, -0.018, 0), Vector3(0.004, -0.15, 0.002), Vector3(0, -0.28, 0)], 0.0028, mat(0x222222, 0.7), 6)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.018, 0.0), Vector2(0.018, 0.03), Vector2(0.022, 0.034), Vector2(0.022, 0.05), Vector2(0.0, 0.05)], plastic(0x2c2c2c, 0.5), Vector3(0, -0.325, 0), 14)
	var bulb_m := mat(0xf6efdc, 0.25, 0.0, {"emit": 0xb89a6a, "emit_e": 0.5})
	var prof := [Vector2(0.0, -0.082), Vector2(0.012, -0.08), Vector2(0.024, -0.07), Vector2(0.032, -0.052), Vector2(0.033, -0.04), Vector2(0.026, -0.024), Vector2(0.018, -0.008), Vector2(0.015, 0.0), Vector2(0.0, 0.0)]
	lathe(g, prof, bulb_m, Vector3(0, -0.325, 0), 18, 80.0)
	return {"g": g}


# ───────────────────────────── 3장
static func _vanity(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.0)
	var d := 0.45
	var wm := painted(0xf6efe9, 0.32)
	var gold := brass(0xd8c08c, 0.3)
	rbox(g, Vector3(w, 0.03, d), 0.006, wm, Vector3(0, 0.745, 0))
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(0.04, 0.73, d), 0.004, wm, Vector3(float(sx) * (w / 2.0 - 0.02), 0.365, 0))
	rbox(g, Vector3(w - 0.08, 0.14, d - 0.04), 0.002, wm, Vector3(0, 0.66, 0))
	# 서랍 앞판 둘과 동그란 금색 손잡이
	for i in 2:
		var cx := -(w - 0.08) / 4.0 + i * (w - 0.08) / 2.0
		rbox(g, Vector3((w - 0.08) / 2.0 - 0.006, 0.13, 0.016), 0.003, painted(0xf9f3ee, 0.28), Vector3(cx, 0.66, d / 2.0 - 0.012))
		lathe(g, [Vector2(0.0, 0.0), Vector2(0.01, 0.0), Vector2(0.008, 0.012), Vector2(0.014, 0.018), Vector2(0.014, 0.024), Vector2(0.0, 0.026)], gold, Vector3.ZERO, 14).position = Vector3(cx, 0.66, d / 2.0 - 0.004)
	# 거울과 전구: 소켓 · 전구 · 뒤 전선
	rbox(g, Vector3(0.76, 0.6, 0.02), 0.012, wm, Vector3(0, 1.3, -d / 2.0 + 0.005))
	quad(g, 0.7, 0.55, tmat("mirror_vanity", 0.12, {"metallic": 0.2}), Vector3(0, 1.3, -d / 2.0 + 0.016))
	var bm := mat(0xfff2dc, 0.25, 0.0, {"emit": 0xffd9a0, "emit_e": 1.0})
	var sock := chrome(0xd8d0c0, 0.25)
	for i in range(4):
		for sx in [-1.0, 1.0]:
			var c := Vector3(float(sx) * 0.36, 1.08 + i * 0.15, -d / 2.0 + 0.016)
			var sk := cyl(g, 0.011, 0.013, 0.018, sock, c + Vector3(0, 0, 0.008), 12)
			sk.rotation.x = PI / 2.0
			sph(g, 0.022, bm, c + Vector3(0, 0, 0.03), 14)
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(0.03, 0.12, 0.012), 0.003, plastic(0xefe9e2, 0.4), Vector3(float(sx) * 0.42, 1.0, -d / 2.0 + 0.012))
	rbox(g, Vector3(0.018, 0.03, 0.006), 0.002, plastic(0x3a3a3c, 0.4), Vector3(0.42, 1.0, -d / 2.0 + 0.019))
	tube(g, [Vector3(0.42, 0.94, -d / 2.0 + 0.008), Vector3(0.43, 0.84, -d / 2.0 + 0.006), Vector3(0.455, 0.05, -d / 2.0 + 0.01)], 0.0032, mat(0xeae6df, 0.7), 5)
	return {"g": g, "foot": Vector2(w, d)}


static func _led() -> Dictionary:
	var g := node(null)
	var m: StandardMaterial3D = tmat("led_sign", 1.0, {"add": true}).duplicate()
	m.albedo_color = Color(1.4, 1.2, 1.3)
	var q := quad(g, 1.0, 0.25, m, Vector3(0, 0, 0.018))
	q.name = "led"
	# 투명 아크릴 판 · 거치 나사 · 변압기와 엉킨 전선
	rbox(g, Vector3(1.04, 0.29, 0.006), 0.012, glass(0xf2f2f6, 0.16, 0.12), Vector3(0, 0, 0.012))
	var gold := brass(0xd8c08c, 0.3)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			cylz(g, 0.006, 0.02, gold, Vector3(float(sx) * 0.5, float(sy) * 0.125, 0.01), 10)
	var cab := rubber(0x202024)
	var white := mat(0xe8e4dd, 0.6)
	tube(g, [Vector3(-0.42, -0.14, 0.004), Vector3(-0.46, -0.28, 0.004), Vector3(-0.32, -0.33, 0.004), Vector3(-0.46, -0.42, 0.006), Vector3(-0.3, -0.52, 0.004), Vector3(-0.42, -0.62, 0.008), Vector3(-0.34, -0.8, 0.006)], 0.0026, cab, 5)
	tube(g, [Vector3(0.4, -0.14, 0.004), Vector3(0.31, -0.24, 0.006), Vector3(0.05, -0.27, 0.006), Vector3(-0.2, -0.26, 0.006), Vector3(-0.32, -0.31, 0.006)], 0.0024, white, 5)
	rbox(g, Vector3(0.08, 0.05, 0.03), 0.006, plastic(0x18181a, 0.5), Vector3(-0.37, -0.47, 0.018))
	sph(g, 0.0025, mat(0x224422, 0.4, 0.0, {"emit": 0x22dd44}), Vector3(-0.35, -0.46, 0.034), 6)
	return {"g": g}


static func _big_mirror() -> Dictionary:
	var g := node(null)
	var f := wood(0xf2ece6, 0.34)
	var bw := 0.03
	rbox(g, Vector3(0.56, bw, 0.03), 0.006, f, Vector3(0, 0.02 + bw / 2.0, 0))
	rbox(g, Vector3(0.56, bw, 0.03), 0.006, f, Vector3(0, 1.63 - bw / 2.0, 0))
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(bw, 1.61, 0.03), 0.006, f, Vector3(float(sx) * 0.265, 0.825, 0))
		tube(g, [Vector3(float(sx) * 0.2, 0.6, -0.02), Vector3(float(sx) * 0.22, 0.02, -0.28)], 0.008, wood(0xe4dcd2, 0.45), 8, false)
	box(g, Vector3(0.52, 1.56, 0.006), mat(0x8a8a8a, 0.8), Vector3(0, 0.82, -0.01))
	quad(g, 0.5, 1.55, tmat("mirror_big", 0.1, {"metallic": 0.22}), Vector3(0, 0.82, 0.0035))
	return {"g": g, "foot": Vector2(0.56, 0.1)}


static func _nightstand(_p: Dictionary) -> Dictionary:
	var g := node(null)
	var wm := painted(0xf3eee8, 0.32)
	rbox(g, Vector3(0.42, 0.02, 0.4), 0.006, wm, Vector3(0, 0.49, 0))
	rbox(g, Vector3(0.4, 0.4, 0.38), 0.003, wm, Vector3(0, 0.27, 0))
	for i in 2:
		var y := 0.17 + i * 0.2
		rbox(g, Vector3(0.38, 0.18, 0.014), 0.003, painted(0xf8f4ef, 0.26), Vector3(0, y, 0.196))
		lathe(g, [Vector2(0.0, 0.0), Vector2(0.008, 0.0), Vector2(0.007, 0.01), Vector2(0.013, 0.016), Vector2(0.012, 0.022), Vector2(0.0, 0.024)], brass(0xd8c08c, 0.3), Vector3(0, 0, 0), 14).position = Vector3(0, y, 0.2)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			tube(g, [Vector3(float(sx) * 0.16, 0.07, float(sz) * 0.15), Vector3(float(sx) * 0.185, 0.002, float(sz) * 0.175)], 0.011, brass(0xd8c08c, 0.3), 8, false)
	return {"g": g, "foot": Vector2(0.42, 0.4)}


## 벨벳 곡면 의자: 둥근 방석과 파이핑 · 세로 골이 진 등받이 · 금색 받침. 앞이 +Z
static func _pink_chair() -> Dictionary:
	var g := node(null)
	var hex := 0xd493a8
	var m := pbr("fleece", hex, 1.0, 0.0, {"rim_enabled": true, "rim": 0.35, "rim_tint": 0.6})
	var gold := brass(0xd8c08c, 0.26)
	lathe(g, [Vector2(0.0, 0.405), Vector2(0.2, 0.405), Vector2(0.24, 0.415), Vector2(0.252, 0.44), Vector2(0.245, 0.472), Vector2(0.2, 0.497), Vector2(0.1, 0.505), Vector2(0.0, 0.506)], m, Vector3.ZERO, 44, 75.0)
	ring(g, 0.25, 0.005, pbr("fabric", shade(hex, 0.18), 0.9), Vector3(0, 0.442, 0), 48, 6).rotation = Vector3.ZERO
	# 뒤쪽을 감싸는 호: 세로 골, 위로 갈수록 바깥으로 벌어지고 위 끝이 둥글다
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.42, 0.075)
	bm.subdivide_width = 44
	bm.subdivide_height = 10
	bm.subdivide_depth = 2
	var mesh := deformed(bm, func(v):
		var a: float = v.x * 2.5
		var t: float = v.y / 0.21
		var flute: float = absf(sin(a * 8.5)) * 0.009
		var r: float = 0.232 + v.z + 0.022 * (t + 1.0) * 0.5 + (flute if v.z < 0.0 else 0.0)
		var edge: float = pow(absf(v.x) * 2.0, 3.0)
		var y: float = v.y + (1.0 - edge) * 0.032 * maxf(t, 0.0) - edge * 0.07 * maxf(t, 0.0)
		return Vector3(-sin(a) * r, y, -cos(a) * r))
	mi(g, mesh, m, Vector3(0, 0.69, 0))
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.2, 0.012), Vector2(0.17, 0.022), Vector2(0.03, 0.04), Vector2(0.02, 0.06), Vector2(0.02, 0.36), Vector2(0.06, 0.39), Vector2(0.17, 0.405), Vector2(0.0, 0.405)], gold, Vector3.ZERO, 32, 50.0)
	return {"g": g, "foot": Vector2(0.5, 0.5)}


static func _wall_shelf(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 0.8)
	rbox(g, Vector3(w, 0.025, 0.2), 0.004, wood(0xf3eee8, 0.4, true), Vector3.ZERO)
	var gold := brass(0xd8c08c, 0.3)
	for sx in [-1.0, 1.0]:
		var bx: float = float(sx) * (w / 2.0 - 0.1)
		box(g, Vector3(0.02, 0.1, 0.004), gold, Vector3(bx, -0.06, -0.098))
		box(g, Vector3(0.02, 0.004, 0.15), gold, Vector3(bx, -0.0145, -0.025))
		rod(g, Vector3(bx, -0.1, -0.095), Vector3(bx, -0.016, 0.03), 0.0028, gold, 6).set_meta("ghost", true)
	for pot in [[-0.31, 0x4f8a4f, 3.1], [0.3, 0x5e8f5a, 7.7]]:
		_pot_plant(g, Vector3(float(pot[0]), 0.0125, 0), int(pot[1]), float(pot[2]))
	return {"g": g}


## 화분: 받침 · 흙 · 잎자루와 잎 여러 장
static func _pot_plant(g: Node3D, c: Vector3, leaf: int, sd: float) -> void:
	var cer := painted(0xfafaf6, 0.26)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.034, 0.0), Vector2(0.046, 0.074), Vector2(0.046, 0.08), Vector2(0.041, 0.08), Vector2(0.038, 0.068), Vector2(0.0, 0.068)], cer, c, 22, 60.0)
	cyl(g, 0.039, 0.039, 0.002, pbr("rust", 0x2f261c, 1.0), c + Vector3(0, 0.069, 0), 18)
	var lm := pbr("leather", leaf, 0.55)
	var stem := mat(shade(leaf, 0.3), 0.8)
	var q := SphereMesh.new()
	q.radius = 0.5
	q.height = 1.0
	q.radial_segments = 6
	q.rings = 3
	for i in 16:
		var a: float = sd + i * 2.399
		var ln: float = 0.05 + 0.055 * fmod(sd * 3.1 + i * 0.37, 1.0)
		var rad: float = 0.012 + i * 0.0035
		var tip := c + Vector3(cos(a) * rad * 2.2, 0.075 + ln * (0.8 + 0.5 * fmod(i * 0.61, 1.0)), sin(a) * rad * 2.2)
		tube(g, [c + Vector3(cos(a) * 0.012, 0.068, sin(a) * 0.012), tip], 0.0014, stem, 4, false)
		var lf := mi(g, q, lm, tip + Vector3(cos(a) * 0.016, 0.004, sin(a) * 0.016))
		lf.scale = Vector3(0.056, 0.004, 0.034)
		lf.rotation = Vector3(0.75 * (1.0 if i % 2 == 0 else -1.0), -a, 0.3 - fmod(i * 0.43, 0.8))
		lf.set_meta("ghost", true)


# ───────────────────────────── 콘센트 · 도어락
static func _plug() -> Dictionary:
	var g := node(null)
	var w := plastic(0xf2f0ea, 0.42)
	var dk := mat(0x2a2a2a, 0.6)
	rbox(g, Vector3(0.28, 0.035, 0.062), 0.008, w, Vector3(0.015, 0.0175, 0))
	# 콘센트 넷: 둥근 홈 · 접지쇠 · 구멍 둘, 각각 달린 스위치와 표시등
	for i in 4:
		var cx := -0.1 + i * 0.058
		lathe(g, [Vector2(0.0, 0.0), Vector2(0.0185, 0.0), Vector2(0.021, 0.004)], mat(0xdcd9d2, 0.5), Vector3(cx, 0.031, -0.008), 22)
		cyl(g, 0.0185, 0.0185, 0.0006, mat(0xe5e2db, 0.5), Vector3(cx, 0.0314, -0.008), 22).set_meta("ghost", true)
		for sx in [-1.0, 1.0]:
			cyl(g, 0.0026, 0.0026, 0.0009, dk, Vector3(cx + float(sx) * 0.0095, 0.0322, -0.008), 8)
		for sz in [-1.0, 1.0]:
			box(g, Vector3(0.008, 0.0012, 0.0016), mat(0xb5b5b5, 0.3, 0.8), Vector3(cx, 0.032, -0.008 + float(sz) * 0.0155))
		var rocker := rbox(g, Vector3(0.014, 0.005, 0.01), 0.0016, plastic(0xe0504a if i != 3 else 0xd4d0c8, 0.35), Vector3(cx, 0.0355, 0.021))
		rocker.rotation.x = 0.16
		sph(g, 0.0014, mat(0xff5533, 0.4, 0.0, {"emit": 0x882211}), Vector3(cx + 0.012, 0.0355, 0.021), 6)
	# 전체 스위치 (주황)
	cyl(g, 0.007, 0.007, 0.04, mat(0xff5533, 0.5, 0.0, {"emit": 0x551100}), Vector3(0.14, 0.018, 0.0), 12)
	var cord := rubber(0x2a2a2a)
	tube(g, [Vector3(0.155, 0.012, 0.0), Vector3(0.21, 0.008, 0.02), Vector3(0.3, 0.006, -0.03), Vector3(0.38, 0.006, -0.05)], 0.0042, cord, 6)
	# 뽑힌 전기장판 플러그
	_mains_plug(g, Vector3(-0.05, 0.016, 0.12), -PI / 2.0, plastic(0xe8e4d8, 0.5))
	tube(g, [Vector3(-0.05, 0.012, 0.142), Vector3(-0.055, 0.008, 0.24), Vector3(-0.03, 0.006, 0.36), Vector3(-0.05, 0.005, 0.55)], 0.0042, cord, 6)
	return {"g": g}


## 도어락: 표시창 · 숫자 건반 · 열림/닫힘 · 지문창 · 비상 전원 단자 · 옆 걸쇠
static func _doorlock() -> Dictionary:
	var g := node(null)
	var cz := pbr("brushed", 0x2a2b30, 0.3, 0.6)
	rbox(g, Vector3(0.084, 0.27, 0.036), 0.012, cz, Vector3(0, 0.02, 0))
	var face_z := 0.0185
	box(g, Vector3(0.072, 0.25, 0.0012), mat(0x101013, 0.18), Vector3(0, 0.02, face_z))
	quad(g, 0.05, 0.03, tmat("doorlock", 0.5, {"unshaded": true}), Vector3(0, 0.1, face_z + 0.0008))
	text(g, "ROOMI", 0.0075, ink(0x8a8c90), Vector3(0, 0.13, face_z + 0.0008))
	var keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"]
	var km := mat(0x202226, 0.35)
	var lit := ink(0x8fd0ff, true)
	for i in keys.size():
		var kx := -0.022 + (i % 3) * 0.022
		var ky := 0.06 - int(i / 3) * 0.02
		rbox(g, Vector3(0.018, 0.015, 0.0025), 0.002, km, Vector3(kx, ky, face_z + 0.0015))
		text(g, keys[i], 0.0085, lit, Vector3(kx, ky, face_z + 0.0029))
	for i in 2:
		var kx := -0.016 + i * 0.032
		rbox(g, Vector3(0.026, 0.013, 0.0025), 0.002, km, Vector3(kx, -0.024, face_z + 0.0015))
		text(g, "열림" if i == 0 else "닫힘", 0.0062, ink(0xd0d0d4, true), Vector3(kx, -0.024, face_z + 0.0029))
	box(g, Vector3(0.018, 0.024, 0.0012), mat(0x0a0a10, 0.06, 0.5), Vector3(0, -0.058, face_z + 0.0006))
	ring(g, 0.0035, 0.0009, steel(0x9a9ca0, 0.3), Vector3(0.028, -0.08, face_z + 0.0005), 12, 6)
	for sy in [-1.0, 1.0]:
		_screw(g, Vector3(0, 0.02 + float(sy) * 0.122, face_z + 0.0002), steel(0x77797d, 0.3), 0.0026)
	# 옆 걸쇠 (안쪽에서 돌려 잠근다)
	var th := node(g, Vector3(0.0, -0.1, face_z))
	cylz(th, 0.012, 0.004, chrome(0xb8bcc0, 0.25), Vector3(0, 0, 0.002), 18)
	rbox(th, Vector3(0.008, 0.024, 0.008), 0.002, chrome(0xc4c8cc, 0.22), Vector3(0, 0, 0.008))
	return {"g": g}


# ───────────────────────────── 4·5장
static func _boiler_room() -> Dictionary:
	var g := node(null)
	var w := 0.6
	var d := 0.45
	var h := 2.1
	var wm := painted(0xe8e4dc, 0.5)
	box(g, Vector3(0.03, h, d), wm, Vector3(-w / 2.0 + 0.015, h / 2.0, 0))
	box(g, Vector3(0.03, h, d), wm, Vector3(w / 2.0 - 0.015, h / 2.0, 0))
	box(g, Vector3(w, 0.04, d), wm, Vector3(0, h - 0.02, 0))
	box(g, Vector3(w, h, 0.02), mat(0xcfc9bd, 0.8), Vector3(0, h / 2.0, -d / 2.0 + 0.01))
	# 가스 보일러: 케이스 · 앞판 · 표시창과 버튼 · 가스 밸브 · 구리관
	var boiler_m := painted(0xf2f2ee, 0.32)
	var bz := -0.07
	rbox(g, Vector3(0.36, 0.5, 0.26), 0.014, boiler_m, Vector3(0, 1.3, bz))
	box(g, Vector3(0.33, 0.47, 0.002), mat(0xdcdcd6, 0.6), Vector3(0, 1.3, bz + 0.1305))
	var pz := bz + 0.132
	box(g, Vector3(0.2, 0.1, 0.002), mat(0xcfd0cb, 0.4), Vector3(0, 1.42, pz))
	box(g, Vector3(0.12, 0.05, 0.0015), mat(0x1b2420, 0.3), Vector3(0, 1.43, pz + 0.0014))
	text(g, "00", 0.03, ink(0x7fe0a0, true), Vector3(0, 1.43, pz + 0.0024))
	var bt := plastic(0xe0dfd9, 0.4)
	for i in 3:
		rbox(g, Vector3(0.028, 0.014, 0.004), 0.0028, bt, Vector3(-0.05 + i * 0.05, 1.388, pz + 0.002))
	text(g, "ROOMI GAS", 0.016, ink(0x9a9a96), Vector3(0, 1.5, pz + 0.0005))
	sph(g, 0.004, mat(0x444444, 0.4, 0.0, {"emit": 0xaa2211}), Vector3(0.085, 1.43, pz + 0.002), 8)
	var cu := mat(0xb87333, 0.3, 0.9)
	for i in 4:
		var x := -0.12 + i * 0.08
		rod(g, Vector3(x, 1.05, bz), Vector3(x, 0.62, bz + 0.02), 0.011, cu if i != 2 else mat(0xd8c02a, 0.5), 10)
		rbox(g, Vector3(0.03, 0.03, 0.03), 0.004, steel(0x9c9c98, 0.35), Vector3(x, 0.8, bz + 0.012))
		var lv := rbox(g, Vector3(0.012, 0.012, 0.05), 0.003, plastic(0xc7372f if i == 2 else 0x2a5ea8, 0.4), Vector3(x, 0.8, bz + 0.05))
		lv.rotation.z = 0.0
	# 연통: 위 칸이 빠져 틈이 벌어져 있고, 벽에 그을음
	var pm := steel(0xb7b7b2, 0.4)
	lathe(g, [Vector2(0.046, 0.0), Vector2(0.048, 0.0), Vector2(0.048, 0.22), Vector2(0.046, 0.22)], pm, Vector3(0, 1.55, bz))
	lathe(g, [Vector2(0.05, 0.0), Vector2(0.052, 0.0), Vector2(0.052, 0.3), Vector2(0.05, 0.3)], pm, Vector3(0.03, 1.81, bz))
	cyl(g, 0.046, 0.046, 0.21, pm, Vector3(0, 1.66, bz), 16)
	cyl(g, 0.05, 0.05, 0.29, pm, Vector3(0.03, 1.96, bz), 16)
	var clamp_m := steel(0x8d8d88, 0.3)
	lathe(g, [Vector2(0.05, 1.74), Vector2(0.053, 1.74), Vector2(0.053, 1.764), Vector2(0.05, 1.764)], clamp_m, Vector3(0, 0, bz), 18)
	box(g, Vector3(0.22, 0.3, 0.004), mat(0x161412, 1.0, 0.0, {"alpha": 0.8}), Vector3(0.01, 1.82, -d / 2.0 + 0.023))
	# 루버 문
	var door := node(g, Vector3(w / 2.0 - 0.015, 0, d / 2.0))
	door.rotation.y = deg_to_rad(70)
	var dw := w - 0.03
	rbox(door, Vector3(dw, 0.1, 0.03), 0.003, wm, Vector3(-dw / 2.0, 0.08, 0))
	rbox(door, Vector3(dw, 0.1, 0.03), 0.003, wm, Vector3(-dw / 2.0, h - 0.08, 0))
	for sx in [0.03, dw - 0.03]:
		rbox(door, Vector3(0.06, h - 0.05, 0.03), 0.003, wm, Vector3(-float(sx), h / 2.0, 0))
	var slat := painted(0xdbd5c9, 0.55)
	for i in 28:
		var s := rbox(door, Vector3(dw - 0.1, 0.05, 0.008), 0.0015, slat, Vector3(-dw / 2.0, 0.17 + i * 0.066, 0.002))
		s.rotation.x = 0.7
	var knob_c := Vector3(-dw + 0.05, 1.0, 0.018)
	lathe(door, [Vector2(0.0, 0.0), Vector2(0.024, 0.0), Vector2(0.024, 0.003), Vector2(0.012, 0.008), Vector2(0.011, 0.02), Vector2(0.024, 0.03), Vector2(0.025, 0.04), Vector2(0.018, 0.05), Vector2(0.0, 0.052)], chrome(), Vector3.ZERO, 18).transform = Transform3D(Basis(Vector3.RIGHT, PI / 2.0), knob_c)
	return {"g": g, "foot": Vector2(w, d)}


## 하드 캐리어: 세로 홈 껍데기 · 지퍼 · 바퀴 넷 · 손잡이 · 안감 끈 · 개어 넣은 옷
static func _suitcase() -> Dictionary:
	var g := node(null)
	var shell := plastic(0x2f5a8a, 0.34)
	var dark := plastic(0x24466e, 0.4)
	var hw := 0.45
	var hd := 0.65
	# 아랫 껍데기
	rbox(g, Vector3(hw, 0.12, hd), 0.03, shell, Vector3(0, 0.06, 0))
	box(g, Vector3(hw - 0.05, 0.002, hd - 0.05), cloth_m(0x8b8f98), Vector3(0, 0.1, 0))
	for i in 7:
		box(g, Vector3(0.014, 0.004, hd - 0.14), dark, Vector3(-0.18 + i * 0.06, 0.001, 0))
	# 지퍼 테두리
	var zip := mat(0x1c1c1e, 0.7)
	_piping(g, hw - 0.012, hd - 0.012, 0.118, zip, 0.005)
	rbox(g, Vector3(0.018, 0.012, 0.03), 0.003, chrome(0xb0b4b8, 0.3), Vector3(hw / 2.0 - 0.006, 0.118, 0.1))
	# 바퀴 · 손잡이 · 다이얼 자물쇠
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var wc := Vector3(float(sx) * (hw / 2.0 - 0.05), 0.0, float(sz) * (hd / 2.0 - 0.055))
			rbox(g, Vector3(0.04, 0.012, 0.04), 0.004, rubber(0x1c1c1e), wc + Vector3(0, -0.006, 0))
	var hg := node(g, Vector3(0, 0.06, -hd / 2.0))
	rbox(hg, Vector3(0.14, 0.024, 0.012), 0.004, plastic(0x18181a, 0.5), Vector3(0, 0, -0.012))
	box(g, Vector3(0.05, 0.022, 0.006), plastic(0x18181a, 0.5), Vector3(0.0, 0.08, hd / 2.0 + 0.0025))
	for i in 3:
		var w0 := cyl(g, 0.006, 0.006, 0.005, mat(0xd8d8d0, 0.4), Vector3(-0.012 + i * 0.012, 0.08, hd / 2.0 + 0.006), 12)
		w0.rotation.z = PI / 2.0
	# 안 내용물
	box(g, Vector3(0.4, 0.05, 0.28), cloth_m(0xd9c7a6), Vector3(0, 0.125, -0.15))
	box(g, Vector3(0.39, 0.002, 0.27), mat(0xa9987a, 0.9), Vector3(0, 0.126, -0.15)).set_meta("ghost", true)
	box(g, Vector3(0.38, 0.04, 0.25), cloth_m(0x6b7a8a), Vector3(0.01, 0.12, 0.16))
	box(g, Vector3(0.37, 0.002, 0.24), mat(0x4b5a6a, 0.9), Vector3(0.01, 0.121, 0.16)).set_meta("ghost", true)
	# 카드 게임 상자
	var cards := node(g, Vector3(0.12, 0.152, 0.18))
	cards.rotation.y = 0.2
	rbox(cards, Vector3(0.1, 0.03, 0.07), 0.003, pbr("card", 0xf2c230, 0.6), Vector3.ZERO)
	text(cards, "CARD", 0.018, ink(0x7a2a2a), Vector3(0, 0.0155, 0), "up")
	# 뚜껑: 뒤로 열려 있고 안감과 고정 끈
	var lid := node(g, Vector3(0, 0.12, -0.325))
	lid.rotation.x = deg_to_rad(-100)
	rbox(lid, Vector3(hw, 0.05, hd), 0.03, shell, Vector3(0, 0.025, 0.325))
	for i in 7:
		box(lid, Vector3(0.014, 0.003, hd - 0.14), dark, Vector3(-0.18 + i * 0.06, 0.0515, 0.325))
	box(lid, Vector3(hw - 0.05, 0.002, hd - 0.05), cloth_m(0x8b8f98), Vector3(0, -0.001, 0.325))
	for sx in [-1.0, 1.0]:
		box(lid, Vector3(0.03, 0.004, hd - 0.1), cloth_m(0x4a5260), Vector3(float(sx) * 0.1, -0.003, 0.325))
	return {"g": g, "foot": Vector2(0.45, 0.66)}


## 키보드: 키 하나하나 (한글 두벌식 표기). 원점은 받침 가운데, w 폭
static func keyboard(g: Node3D, c: Vector3, w: float, d: float, key_m: Material, lbl: Material, base_m: Material, thin := false) -> void:
	var kb := node(g, c)
	var layout := [
		["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "<<2"],
		[">>1.5", "Qㅂ", "Wㅈ", "Eㄷ", "Rㄱ", "Tㅅ", "Yㅛ", "Uㅕ", "Iㅑ", "Oㅐ", "Pㅔ", "[", "]", "\\1.5"],
		["CAP1.8", "Aㅁ", "Sㄴ", "Dㅇ", "Fㄹ", "Gㅎ", "Hㅗ", "Jㅓ", "Kㅏ", "Lㅣ", ";", "'", "ENT2.2"],
		["SHIFT2.3", "Zㅋ", "Xㅌ", "Cㅊ", "Vㅍ", "Bㅠ", "Nㅜ", "Mㅡ", ",", ".", "/", "SHIFT2.7"],
		["CTL1.3", "WIN1.2", "ALT1.2", "한자1.2", " 5.2", "한/영1.3", "ALT1.2", "FN1.2", "CTL1.4"],
	]
	var u := w / 15.2
	var kh := 0.0035 if thin else 0.006
	var rd := d / 5.6
	if not thin:
		rbox(kb, Vector3(w + u * 0.6, 0.012, d + u * 0.5), 0.003, base_m, Vector3(0, 0.006, 0))
	var base_y := 0.0 if thin else 0.012
	for j in layout.size():
		var row: Array = layout[j]
		var total := 0.0
		for k in row:
			total += _key_w(k)
		var x := -total * u / 2.0
		var z := -d / 2.0 + rd * (j + 0.5)
		for k in row:
			var kw := _key_w(k)
			var cx := x + kw * u / 2.0
			var nm := _key_name(k)
			keycap(kb, kw * u - 0.0014, rd - 0.0014, kh, key_m, Vector3(cx, base_y, z))
			if nm.length() >= 2 and nm.unicode_at(1) > 0x2E80 and nm.unicode_at(0) < 128:
				text(kb, nm.substr(0, 1), u * 0.3, lbl, Vector3(cx - u * 0.15, base_y + kh + 0.0003, z - rd * 0.14), "up")
				text(kb, nm.substr(1), u * 0.3, lbl, Vector3(cx + u * 0.16, base_y + kh + 0.0003, z + rd * 0.14), "up")
			elif nm != "":
				text(kb, nm, u * (0.34 if nm.length() == 1 else 0.2), lbl, Vector3(cx, base_y + kh + 0.0003, z), "up")
			x += kw * u


static func _key_w(k: String) -> float:
	var i := 0
	while i < k.length() and not (k[i] >= "0" and k[i] <= "9" and i > 0 and (k.length() - i) <= 3 and k.substr(i).is_valid_float()):
		i += 1
	return float(k.substr(i)) if i < k.length() else 1.0


static func _key_name(k: String) -> String:
	if k.begins_with(" "):
		return ""
	if k.begins_with("<<"):
		return "<"
	if k.begins_with(">>"):
		return ">"
	var i := 0
	while i < k.length() and not (k[i] >= "0" and k[i] <= "9" and i > 0 and (k.length() - i) <= 3 and k.substr(i).is_valid_float()):
		i += 1
	var s := k.substr(0, i)
	return s if s in ["WIN", "ALT", "CTL", "FN", "CAP", "ENT", "SHIFT"] or s.length() <= 2 else s.substr(0, 2)


static func _pc_desk(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.6)
	var d := 0.6
	var h := 0.74
	var top_m := pbr("woodh", 0x1e1f22, 0.34)
	rbox(g, Vector3(w, 0.03, d), 0.004, top_m, Vector3(0, h - 0.015, 0))
	var frame := painted(0x2a2b2e, 0.38)
	for sx in [-1.0, 1.0]:
		var x: float = float(sx) * (w / 2.0 - 0.06)
		rbox(g, Vector3(0.05, h - 0.03, 0.05), 0.006, frame, Vector3(x, (h - 0.03) / 2.0, 0))
		rbox(g, Vector3(0.06, 0.03, d - 0.05), 0.008, frame, Vector3(x, 0.015, 0))
		for sz in [-1.0, 1.0]:
			cyl(g, 0.018, 0.02, 0.006, rubber(), Vector3(x, 0.003, float(sz) * (d / 2.0 - 0.06)), 10)
	rbox(g, Vector3(w - 0.14, 0.06, 0.02), 0.004, frame, Vector3(0, h - 0.06, -d / 2.0 + 0.08))
	# 모니터 두 대
	for i in range(2):
		var mx := -0.27 + i * 0.54
		var mz := -d / 2.0 + 0.12
		var bz := plastic(0x111214, 0.34)
		rbox(g, Vector3(0.52, 0.32, 0.022), 0.006, bz, Vector3(mx, h + 0.3, mz))
		rbox(g, Vector3(0.3, 0.18, 0.03), 0.012, plastic(0x18191c, 0.48), Vector3(mx, h + 0.3, mz - 0.024))
		var scr := tmat("monitor_draw" if i == 0 else "monitor_chat", 0.28, {"emit_tex": true, "emission_energy_multiplier": 0.42})
		quad(g, 0.49, 0.28, scr, Vector3(mx, h + 0.306, mz + 0.0113))
		text(g, "HANBIT", 0.01, ink(0x9a9ca0), Vector3(mx, h + 0.152, mz + 0.0118))
		# 받침 · 목 · 화면 버튼 다섯 · 전원등
		rbox(g, Vector3(0.05, 0.18, 0.03), 0.008, plastic(0x222326, 0.42), Vector3(mx, h + 0.1, mz - 0.03))
		plate(g, 0.24, 0.16, 0.012, 0.03, plastic(0x222326, 0.42), Vector3(mx, h + 0.006, mz - 0.01))
		for k in 5:
			rbox(g, Vector3(0.012, 0.004, 0.006), 0.0012, mat(0x2a2c30, 0.35), Vector3(mx + 0.13 + k * 0.018, h + 0.1395, mz + 0.0115))
		sph(g, 0.0022, mat(0x223344, 0.3, 0.0, {"emit": 0x3a88ff, "emit_e": 1.4}), Vector3(mx + 0.23, h + 0.1395, mz + 0.012), 6)
	# 키보드 · 마우스 · 마우스 패드
	keyboard(g, Vector3(0, h, 0.06), 0.42, 0.13, plastic(0x26282c, 0.42), ink(0xd8d8dc), plastic(0x18191c, 0.5))
	var mp := plate(g, 0.3, 0.22, 0.003, 0.012, pbr("fabric", 0x161619, 0.9), Vector3(0.48, h + 0.0015, 0.08))
	mp.set_meta("ghost", true)
	_mouse(g, Vector3(0.5, h + 0.003, 0.09), 0.15)
	# 본체: 앞판 통풍 · 전원/리셋 · USB · 오디오 단자 · 옆면 유리
	var pc := node(g, Vector3(-w / 2.0 + 0.16, 0, 0))
	var cm := pbr("brushed", 0x141518, 0.32, 0.55)
	rbox(pc, Vector3(0.2, 0.42, 0.42), 0.006, cm, Vector3(0, 0.21, 0))
	rbox(pc, Vector3(0.21, 0.02, 0.43), 0.004, rubber(), Vector3(0, 0.01, 0))
	var fz := 0.211
	for j in 18:
		for i in 7:
			box(pc, Vector3(0.012, 0.012, 0.0015), mat(0x08090a, 0.8), Vector3(-0.06 + i * 0.02, 0.09 + j * 0.0165, fz))
	var btn := plastic(0x303238, 0.32)
	cylz(pc, 0.012, 0.004, chrome(0xc4c8cc, 0.24), Vector3(0.05, 0.395, fz), 20)
	cylz(pc, 0.009, 0.005, btn, Vector3(0.05, 0.395, fz + 0.0015), 18)
	ring(pc, 0.0105, 0.0011, mat(0x113355, 0.3, 0.0, {"emit": 0x3a88ff, "emit_e": 1.6}), Vector3(0.05, 0.395, fz + 0.001), 24, 6)
	cylz(pc, 0.0045, 0.0035, btn, Vector3(0.02, 0.395, fz + 0.0005), 12)
	sph(pc, 0.0018, mat(0xaa1111, 0.3, 0.0, {"emit": 0xcc2211}), Vector3(-0.005, 0.395, fz + 0.0005), 6)
	for i in 2:
		box(pc, Vector3(0.0135, 0.0055, 0.0012), mat(0x08090a, 0.7), Vector3(-0.07 + i * 0.024, 0.395, fz))
		box(pc, Vector3(0.012, 0.0025, 0.0014), mat(0x1a4a9a, 0.4), Vector3(-0.07 + i * 0.024, 0.395, fz + 0.0002))
	for i in 2:
		cylz(pc, 0.0034, 0.0013, mat(0x4ab04a if i == 0 else 0xd86a9a, 0.4), Vector3(-0.092 + i * 0.012, 0.378, fz), 10)
	rbox(pc, Vector3(0.0015, 0.36, 0.38), 0.0005, glass(0x8a9098, 0.42, 0.08), Vector3(-0.1, 0.22, 0)).set_meta("ghost", true)
	# 콘센트로 가는 전선과 헤드셋
	var cab := rubber(0x141416)
	tube(g, [Vector3(-w / 2.0 + 0.16, 0.05, -0.21), Vector3(-w / 2.0 + 0.3, 0.01, -0.27), Vector3(-w / 2.0 + 0.6, 0.008, -0.29), Vector3(-w / 2.0 + 0.9, 0.008, -0.29)], 0.0034, cab, 5)
	for i in 2:
		tube(g, [Vector3(-0.27 + i * 0.54, h + 0.2, -d / 2.0 + 0.09), Vector3(-0.27 + i * 0.54, h + 0.08, -d / 2.0 + 0.06), Vector3(-0.1 + i * 0.2, h + 0.003, -d / 2.0 + 0.03), Vector3(-w / 2.0 + 0.2, h + 0.003, -d / 2.0 + 0.02)], 0.0028, cab, 5)
	var hs := node(g, Vector3(0.72, h, -0.22))
	lathe(hs, [Vector2(0.0, 0.0), Vector2(0.05, 0.0), Vector2(0.05, 0.008), Vector2(0.01, 0.018), Vector2(0.008, 0.2), Vector2(0.0, 0.2)], plastic(0x1c1c20, 0.45), Vector3.ZERO, 18)
	tube(hs, [Vector3(-0.08, 0.13, 0), Vector3(-0.065, 0.2, 0), Vector3(0, 0.235, 0), Vector3(0.065, 0.2, 0), Vector3(0.08, 0.13, 0)], 0.007, plastic(0x16161a, 0.5), 8, true, 8)
	for sx in [-1.0, 1.0]:
		var ear := soft_box(hs, Vector3(0.04, 0.09, 0.07), 0.016, leather(0x202024, 0.6), Vector3(float(sx) * 0.082, 0.1, 0), Vector3i(3, 6, 5))
		ear.set_meta("ghost", true)
	return {"g": g, "foot": Vector2(w, d)}


static func _mouse(parent: Node3D, c: Vector3, ry: float) -> void:
	var n := node(parent, c)
	n.rotation.y = ry
	var body := plastic(0x1b1c20, 0.42)
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 22
	s.rings = 12
	var shell := deformed(s, func(v):
		var y: float = maxf(v.y, -0.04)
		return Vector3(v.x * 0.062 * (1.0 + 0.1 * clampf(v.z * 2.0, -1.0, 1.0)), y * 0.078, v.z * 0.118))
	mi(n, shell, body, Vector3(0, 0.002, 0))
	box(n, Vector3(0.001, 0.008, 0.05), mat(0x08090a, 0.8), Vector3(0, 0.038, -0.03))
	lathe(n, [Vector2(0.0, -0.003), Vector2(0.0078, -0.003), Vector2(0.0085, 0.0), Vector2(0.0078, 0.003), Vector2(0.0, 0.003)], rubber(0x2c2c30), Vector3(0, 0.041, -0.028), 16).rotation.z = PI / 2.0
	for i in 2:
		rbox(n, Vector3(0.0025, 0.0018, 0.011), 0.0006, mat(0x3a3a3e, 0.4), Vector3(-0.0245, 0.0275 + i * 0.0005, 0.012 - i * 0.013)).rotation.z = 0.55
	# 뒤로 나가는 줄
	tube(parent, [c + Vector3(0.0, 0.012, -0.075), c + Vector3(-0.012, 0.004, -0.12), c + Vector3(0.05, 0.004, -0.2), c + Vector3(-0.2, 0.004, -0.27)], 0.002, rubber(0x18181c), 5)


## 게이밍 의자: 측면 볼스터 · 스티치 · 머리 쿠션 · 허리 쿠션 · 팔걸이 · 레버 · 가스실린더 · 별다리 · 바퀴
static func _gaming_chair() -> Dictionary:
	var g := node(null)
	var m := leather(0x1d1f24, 0.5)
	var ac := leather(0x7a2a3a, 0.5)
	var bk := plastic(0x18191c, 0.5)
	# 방석: 양옆 볼스터가 솟아 있다
	var bm := BoxMesh.new()
	bm.size = Vector3(0.52, 0.09, 0.52)
	bm.subdivide_width = 14
	bm.subdivide_depth = 12
	bm.subdivide_height = 2
	var seat := deformed(bm, func(v):
		var ax: float = absf(v.x) / 0.26
		var az: float = absf(v.z) / 0.26
		var bol: float = smoothstep(0.55, 0.95, ax) * 0.04 + smoothstep(0.75, 1.0, az) * 0.012
		var soft: float = (1.0 - pow(ax, 8.0)) * (1.0 - pow(az, 8.0))
		return Vector3(v.x, v.y * (0.45 + 0.55 * soft) + (bol if v.y > 0.0 else 0.0), v.z))
	mi(g, seat, m, Vector3(0, 0.48, 0))
	rbox(g, Vector3(0.34, 0.012, 0.44), 0.003, ac, Vector3(0, 0.525, 0.005)).set_meta("ghost", true)
	# 등판: 위로 좁아지고 양옆이 솟았다. 뒤로 살짝 기울었다
	var back := node(g, Vector3(0, 0.92, 0.26))
	back.rotation.x = 0.12
	var bb := BoxMesh.new()
	bb.size = Vector3(0.5, 0.8, 0.09)
	bb.subdivide_width = 14
	bb.subdivide_height = 16
	bb.subdivide_depth = 2
	var bmesh := deformed(bb, func(v):
		var t: float = (v.y + 0.4) / 0.8
		var ax: float = absf(v.x) / 0.25
		var sq: float = lerpf(1.04, 0.72, smoothstep(0.1, 1.0, t))
		var bol: float = smoothstep(0.55, 0.95, ax) * 0.05 * (1.0 if v.z < 0.0 else 0.0)
		var soft: float = 1.0 - pow(ax, 10.0)
		return Vector3(v.x * sq, v.y, v.z * (0.4 + 0.6 * soft) - bol))
	mi(back, bmesh, m, Vector3.ZERO)
	var seam_m := mat(0x0c0d10, 0.8)
	for sx in [-1.0, 1.0]:
		box(back, Vector3(0.002, 0.62, 0.002), seam_m, Vector3(float(sx) * 0.155, -0.04, 0.0452)).set_meta("ghost", true)
	box(back, Vector3(0.006, 0.42, 0.003), mat(0x1a1a1c, 0.6), Vector3(0, -0.06, 0.0456)).set_meta("ghost", true)
	rbox(back, Vector3(0.05, 0.02, 0.004), 0.002, ac, Vector3(0, 0.27, 0.0458))
	var stripe := soft_box(back, Vector3(0.16, 0.56, 0.02), 0.008, ac, Vector3(0, -0.06, -0.044), Vector3i(4, 10, 2))
	stripe.set_meta("ghost", true)
	# 머리 쿠션 · 허리 쿠션 · 끈
	soft_box(back, Vector3(0.2, 0.1, 0.07), 0.03, ac, Vector3(0, 0.3, -0.07), Vector3i(6, 4, 4)).set_meta("ghost", true)
	soft_box(back, Vector3(0.26, 0.16, 0.08), 0.035, m, Vector3(0, -0.25, -0.07), Vector3i(6, 4, 4)).set_meta("ghost", true)
	text(back, "PRO", 0.04, ink(0xd8d8dc), Vector3(0, 0.3, -0.106)).rotation.y = PI
	for sx in [-1.0, 1.0]:
		box(back, Vector3(0.016, 0.0016, 0.1), rubber(0x2a2a2a), Vector3(float(sx) * 0.08, 0.32, -0.02)).set_meta("ghost", true)
	# 팔걸이: 받침 · 패드 · 높이 버튼
	for sx in [-1.0, 1.0]:
		var x: float = float(sx) * 0.3
		rbox(g, Vector3(0.045, 0.2, 0.05), 0.008, bk, Vector3(x, 0.58, 0.06))
		rbox(g, Vector3(0.05, 0.03, 0.26), 0.012, rubber(0x2a2a2e), Vector3(x, 0.7, 0.02))
		rbox(g, Vector3(0.015, 0.018, 0.012), 0.003, plastic(0x4a4a4e, 0.4), Vector3(x + float(sx) * 0.029, 0.625, 0.02))
	# 받침: 틸트 박스 · 레버 · 가스실린더 · 별다리 · 바퀴
	rbox(g, Vector3(0.22, 0.05, 0.28), 0.008, bk, Vector3(0, 0.41, 0.02))
	for sx in [-1.0, 1.0]:
		tube(g, [Vector3(float(sx) * 0.1, 0.41, 0.02), Vector3(float(sx) * 0.26, 0.4, 0.0)], 0.0065, chrome(0x8c9094, 0.3), 6, false)
		sph(g, 0.012, bk, Vector3(float(sx) * 0.27, 0.4, 0.0), 8)
	lathe(g, [Vector2(0.0, 0.08), Vector2(0.03, 0.08), Vector2(0.03, 0.2), Vector2(0.024, 0.205), Vector2(0.024, 0.4), Vector2(0.0, 0.4)], chrome(0x7c8084, 0.28), Vector3.ZERO, 14, 50.0)
	var leg := painted(0x202226, 0.4)
	for i in range(5):
		var a := i / 5.0 * TAU
		var dir := Vector3(cos(a), 0, sin(a))
		var arm := rbox(g, Vector3(0.3, 0.035, 0.05), 0.012, leg, dir * 0.155 + Vector3(0, 0.08, 0))
		arm.rotation.y = -a
		arm.rotation.z = -0.1
		var wc := dir * 0.3 + Vector3(0, 0.035, 0)
		cyl(g, 0.011, 0.011, 0.04, chrome(0x8a8e92, 0.3), wc + Vector3(0, 0.03, 0), 8)
		var wl := lathe(g, [Vector2(0.0, -0.016), Vector2(0.024, -0.016), Vector2(0.03, -0.01), Vector2(0.03, 0.01), Vector2(0.024, 0.016), Vector2(0.0, 0.016)], rubber(0x18181a), wc - Vector3(0, 0.003, 0), 18)
		wl.rotation.z = PI / 2.0
		wl.rotation.y = -a + 0.5
	return {"g": g, "foot": Vector2(0.55, 0.55)}


## 책장: 책마다 표지 · 책등 띠 · 페이지 덩어리. 드문드문 인형과 눕힌 책
static func _bookshelf(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.0)
	var d := 0.32
	var h := 1.8
	var wm := wood(0x3a3330, 0.55)
	var wa := wood(0x3a3330, 0.55, true)
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(0.03, h, d), 0.003, wm, Vector3(float(sx) * (w / 2.0 - 0.015), h / 2.0, 0))
	box(g, Vector3(w, h, 0.012), wm, Vector3(0, h / 2.0, -d / 2.0 + 0.006))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var cols := [0x8a3a3a, 0x3a5a8a, 0xd8c070, 0x4a7a5a, 0xe8e0d0, 0x6a4a7a, 0x2a2a2e, 0xc06040, 0x7a7f5a, 0x2e4a6a]
	var pages := pbr("paper", 0xe8e0cc, 1.0)
	for s in range(6):
		var y := 0.03 + s * 0.35
		rbox(g, Vector3(w - 0.03, 0.025, d - 0.012), 0.003, wa, Vector3(0, y, 0.002))
		if s == 5:
			break
		var x := -w / 2.0 + 0.05
		while x < w / 2.0 - 0.08:
			var r := rng.randf()
			if r < 0.09:
				var fc: int = cols[rng.randi() % cols.size()]
				_shelf_figure(g, Vector3(x + 0.03, y + 0.0125, 0.03), fc, rng)
				x += 0.09
				continue
			if r < 0.15:
				# 눕혀 쌓은 책
				var ny := y + 0.0125
				for k in 3:
					var bh := 0.02 + rng.randf() * 0.015
					var c: int = cols[rng.randi() % cols.size()]
					var sw := 0.13 + rng.randf() * 0.03
					rbox(g, Vector3(sw, bh, d - 0.1), 0.0015, pbr("paper", c, 0.75), Vector3(x + 0.08, ny + bh / 2.0, 0.015))
					box(g, Vector3(sw - 0.008, bh * 0.75, 0.002), pages, Vector3(x + 0.08, ny + bh / 2.0, 0.015 + (d - 0.1) / 2.0 + 0.0002)).set_meta("ghost", true)
					ny += bh
				x += 0.17
				continue
			var bw: float = 0.02 + rng.randf() * 0.03
			var bh: float = 0.18 + rng.randf() * 0.1
			var c: int = cols[rng.randi() % cols.size()]
			var cm := pbr("paper", c, 0.72)
			var cy := y + 0.0125 + bh / 2.0
			var bz := 0.01
			var book := rbox(g, Vector3(bw, bh, d - 0.08), 0.0012, cm, Vector3(x + bw / 2.0, cy, bz))
			book.set_meta("ghost", true)
			box(g, Vector3(bw - 0.003, bh - 0.008, 0.001), pages, Vector3(x + bw / 2.0, cy, bz - (d - 0.08) / 2.0 - 0.0003)).set_meta("ghost", true)
			# 책등 띠 · 제목 자리
			var fz: float = bz + (d - 0.08) / 2.0 + 0.0003
			var lg := mat(shade(c, -0.45), 0.7)
			box(g, Vector3(bw * 0.86, 0.005, 0.0006), lg, Vector3(x + bw / 2.0, cy + bh * 0.42, fz)).set_meta("ghost", true)
			box(g, Vector3(bw * 0.86, 0.003, 0.0006), lg, Vector3(x + bw / 2.0, cy + bh * 0.38, fz)).set_meta("ghost", true)
			box(g, Vector3(bw * 0.5, bh * 0.36, 0.0006), mat(shade(c, -0.6), 0.75), Vector3(x + bw / 2.0, cy + bh * 0.05, fz)).set_meta("ghost", true)
			box(g, Vector3(bw * 0.86, 0.004, 0.0006), lg, Vector3(x + bw / 2.0, cy - bh * 0.42, fz)).set_meta("ghost", true)
			x += bw + 0.0015
	return {"g": g, "foot": Vector2(w, d)}


static func _shelf_figure(g: Node3D, c: Vector3, col_i: int, rng: RandomNumberGenerator) -> void:
	var cloth := plastic(col_i, 0.5)
	cyl(g, 0.03, 0.032, 0.008, plastic(0x1c1c1e, 0.4), c + Vector3(0, 0.004, 0), 14).set_meta("ghost", true)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.024, 0.0), Vector2(0.03, 0.03), Vector2(0.016, 0.065), Vector2(0.02, 0.09), Vector2(0.012, 0.11), Vector2(0.0, 0.11)], cloth, c + Vector3(0, 0.008, 0), 12).set_meta("ghost", true)
	var skin := mat(0xe8c8a8, 0.55)
	var head_c := c + Vector3(0, 0.135, 0)
	sph(g, 0.026, skin, head_c, 12).set_meta("ghost", true)
	var hair := sph(g, 0.029, plastic(0x2a2030 if rng.randf() < 0.5 else 0x8a5a30, 0.5), head_c + Vector3(0, 0.004, -0.004), 12)
	hair.scale = Vector3(1.04, 0.92, 1.0)
	hair.set_meta("ghost", true)
	for sx in [-1.0, 1.0]:
		sph(g, 0.0028, mat(0x151515, 0.3), head_c + Vector3(float(sx) * 0.011, 0.002, 0.024), 6).set_meta("ghost", true)
		rod(g, c + Vector3(float(sx) * 0.022, 0.095, 0), c + Vector3(float(sx) * 0.037, 0.05, 0.012), 0.006, cloth, 6).set_meta("ghost", true)


## 벽걸이 에어컨: 곡면 앞판 · 위 흡기창 · 바람 날개 · 26 표시창 · 표시등 · 배관
static func _aircon() -> Dictionary:
	var g := node(null)
	var body := painted(0xf4f4f2, 0.28)
	soft_box(g, Vector3(0.8, 0.28, 0.2), 0.05, body, Vector3.ZERO, Vector3i(16, 8, 6))
	# 위 흡기창 슬릿
	for i in 30:
		box(g, Vector3(0.0075, 0.0015, 0.13), mat(0x8a8a86, 0.8), Vector3(-0.36 + i * 0.025, 0.1405, -0.012))
	# 앞판 이음새 · 바람 날개 둘 · 안쪽 어둠
	box(g, Vector3(0.74, 0.002, 0.002), mat(0xb8b8b4, 0.6), Vector3(0, 0.05, 0.1005))
	box(g, Vector3(0.72, 0.04, 0.02), mat(0x181818, 0.9), Vector3(0, -0.12, 0.08))
	for i in 2:
		var fl := rbox(g, Vector3(0.72, 0.03, 0.006), 0.002, painted(0xeaeae6, 0.34), Vector3(0, -0.128 - i * 0.012, 0.095 - i * 0.012))
		fl.rotation.x = 0.55
	for i in 12:
		box(g, Vector3(0.002, 0.036, 0.012), mat(0xc0c0ba, 0.5), Vector3(-0.33 + i * 0.06, -0.115, 0.082))
	# 표시창: 26도, 운전 표시등
	box(g, Vector3(0.1, 0.036, 0.0012), mat(0x0a0f12, 0.25), Vector3(0.25, 0.04, 0.1012))
	text(g, "26", 0.026, ink(0x7fe0ff, true), Vector3(0.235, 0.04, 0.1022))
	text(g, "°", 0.014, ink(0x7fe0ff, true), Vector3(0.265, 0.046, 0.1022))
	sph(g, 0.0025, mat(0x2a2a2a, 0.3, 0.0, {"emit": 0x3aff6a, "emit_e": 2.0}), Vector3(0.32, 0.04, 0.1012), 6)
	sph(g, 0.0025, mat(0x2a2a2a, 0.3, 0.0, {"emit": 0x3a7aff, "emit_e": 1.2}), Vector3(0.335, 0.04, 0.1012), 6)
	text(g, "HANBIT", 0.012, ink(0x9a9a96), Vector3(-0.3, 0.06, 0.1005))
	# 왼쪽 벽을 타고 내려가는 배관 커버
	var cv := painted(0xefefec, 0.45)
	rbox(g, Vector3(0.05, 0.26, 0.05), 0.008, cv, Vector3(-0.44, -0.07, -0.07))
	cylz(g, 0.042, 0.004, cv, Vector3(-0.44, -0.22, -0.097), 22)
	return {"g": g}


## 선풍기: 바닥판과 건반 네 개 · 타이머 · 높이 고정 · 회전 스위치 · 모터 · 날개 다섯 · 철망
static func _fan() -> Dictionary:
	var g := node(null)
	var m := plastic(0xe8e8e4, 0.42)
	var dk := plastic(0xc4c4bf, 0.45)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.18, 0.0), Vector2(0.18, 0.012), Vector2(0.165, 0.04), Vector2(0.05, 0.05), Vector2(0.0, 0.05)], m, Vector3.ZERO, 36, 50.0)
	# 건반: 정지 · 1 · 2 · 3 (누른 건 살짝 들어가 있다)
	var keys := ["0", "1", "2", "3"]
	for i in 4:
		var kx := -0.052 + i * 0.035
		var bt := rbox(g, Vector3(0.03, 0.012, 0.05), 0.004, plastic(0xcf4a3a if i == 0 else 0xd8d8d3, 0.4), Vector3(kx, 0.046 - (0.003 if i == 2 else 0.0), 0.11))
		bt.rotation.x = -0.14
		text(g, keys[i], 0.015, ink(0x2a2a2a if i != 0 else 0xf6f6f2), Vector3(kx, 0.0525 - (0.003 if i == 2 else 0.0), 0.11), "up")
	var tm := lathe(g, [Vector2(0.0, 0.0), Vector2(0.024, 0.0), Vector2(0.022, 0.018), Vector2(0.0, 0.02)], dk, Vector3(0.1, 0.04, 0.08), 18)
	tm.set_meta("ghost", true)
	box(g, Vector3(0.003, 0.003, 0.03), mat(0x2a2a2a, 0.5), Vector3(0.1, 0.0605, 0.08))
	cyl(g, 0.015, 0.015, 0.95, chrome(0xc8cacc, 0.28), Vector3(0, 0.5, 0), 12)
	lathe(g, [Vector2(0.0, 0.05), Vector2(0.038, 0.05), Vector2(0.032, 0.5), Vector2(0.026, 0.53), Vector2(0.0, 0.53)], m, Vector3.ZERO, 20, 60.0)
	var col_y := 0.53
	lathe(g, [Vector2(0.0, col_y), Vector2(0.03, col_y), Vector2(0.03, col_y + 0.024), Vector2(0.018, col_y + 0.03), Vector2(0.0, col_y + 0.03)], dk, Vector3.ZERO, 16)
	var knob := cylz(g, 0.012, 0.022, dk, Vector3(0, col_y + 0.016, 0.03), 12)
	knob.set_meta("ghost", true)
	var head := node(g, Vector3(0, 1.0, 0.02))
	lathe(head, [Vector2(0.0, -0.05), Vector2(0.05, -0.05), Vector2(0.056, -0.03), Vector2(0.056, 0.04), Vector2(0.03, 0.06), Vector2(0.0, 0.06)], m, Vector3.ZERO, 24).rotation.x = -PI / 2.0
	rbox(head, Vector3(0.05, 0.1, 0.05), 0.012, m, Vector3(0, -0.06, -0.02))
	cyl(head, 0.006, 0.006, 0.03, dk, Vector3(0, 0.07, -0.02), 10)
	sph(head, 0.012, dk, Vector3(0, 0.09, -0.02), 10)
	# 날개: 비틀린 다섯 장
	var blade_m := mat(0xaecde0, 0.32, 0.0, {"alpha": 0.72, "cull_off": true})
	var q := QuadMesh.new()
	q.size = Vector2(0.11, 0.13)
	q.subdivide_width = 6
	q.subdivide_depth = 6
	var bl := deformed(q, func(v):
		var r: float = v.y + 0.065
		var w_k: float = 0.45 + 0.55 * sin(clampf(r / 0.13, 0.0, 1.0) * PI * 0.92)
		return Vector3(v.x * w_k + r * 0.18, v.y, v.x * 0.18 * (1.0 + r * 3.0)))
	for i in 5:
		var a := i * TAU / 5.0
		var n := mi(head, bl, blade_m, Vector3(-sin(a) * 0.085, cos(a) * 0.085, 0.07))
		n.rotation.z = a
		n.set_meta("ghost", true)
	var hub := lathe(head, [Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.03, 0.022), Vector2(0.015, 0.03), Vector2(0.0, 0.03)], dk, Vector3(0, 0, 0.06), 18)
	hub.rotation.x = PI / 2.0
	hub.set_meta("ghost", true)
	# 철망: 둥근 테 · 동심원 · 살
	var wire := chrome(0xdcdcd8, 0.3)
	ring(head, 0.17, 0.006, m, Vector3(0, 0, 0.07), 48, 8).set_meta("ghost", true)
	for z in [0.11, 0.04]:
		for r in [0.05, 0.085, 0.12, 0.15]:
			ring(head, float(r), 0.0012, wire, Vector3(0, 0, float(z)), 40, 4).set_meta("ghost", true)
		for i in 20:
			var a := i * TAU / 20.0
			var dir := Vector3(sin(a), cos(a), 0)
			rod(head, dir * 0.03 + Vector3(0, 0, float(z)), dir * 0.17 + Vector3(0, 0, 0.07), 0.001, wire, 3).set_meta("ghost", true)
	var badge := cylz(head, 0.024, 0.002, plastic(0xc4c4bf, 0.4), Vector3(0, 0, 0.113), 18)
	badge.set_meta("ghost", true)
	text(head, "HANBIT", 0.008, ink(0x444444), Vector3(0, 0, 0.1142))
	return {"g": g, "foot": Vector2(0.3, 0.3)}


## 식판 더미: 칸마다 파인 스테인리스 식판과 포개 놓은 그릇, 수저
static func _trays() -> Dictionary:
	var g := node(null)
	for i in range(5):
		var t := node(g, Vector3((i % 2) * 0.01, 0.0 + i * 0.022, (i % 3) * 0.008))
		t.rotation.y = (i - 2) * 0.04
		var m := steel(0xc9c9c2, 0.34) if i % 2 == 0 else steel(0xb9b9b2, 0.4)
		rbox(t, Vector3(0.36, 0.02, 0.27), 0.01, m, Vector3(0, 0.01, 0))
		for c in [[-0.12, -0.06, 0.09, 0.09], [0.0, -0.06, 0.09, 0.09], [0.12, -0.06, 0.09, 0.09], [-0.07, 0.065, 0.16, 0.1], [0.095, 0.065, 0.13, 0.1]]:
			box(t, Vector3(float(c[2]), 0.0006, float(c[3])), mat(0x6a6a66, 0.5, 0.3), Vector3(float(c[0]), 0.0205, float(c[1])))
	for v in [Vector3(-0.09, 0.11, -0.05), Vector3(0.08, 0.11, -0.05)]:
		lathe(g, [Vector2(0.0, 0.0), Vector2(0.035, 0.0), Vector2(0.046, 0.04), Vector2(0.046, 0.044), Vector2(0.041, 0.044), Vector2(0.03, 0.006), Vector2(0.0, 0.006)], painted(0xf2f0ea, 0.2), v, 22, 60.0)
	var sp := steel(0xd0d0cc, 0.26)
	rod(g, Vector3(-0.15, 0.114, 0.09), Vector3(0.12, 0.114, 0.1), 0.0028, sp, 6).set_meta("ghost", true)
	rod(g, Vector3(-0.15, 0.114, 0.103), Vector3(0.12, 0.114, 0.112), 0.0028, sp, 6).set_meta("ghost", true)
	return {"g": g, "foot": Vector2(0.38, 0.3)}


# ───────────────────────────── 문 · 스위치 (room.gd가 쓴다)
## 현관문: 패널 눌림 · 틀 · 경첩 셋 · 레버 손잡이 · 잠금 뭉치 · 도어아이 · 도어클로저 · 문턱.
## 원점은 문 아래 가운데, 앞(+Z)이 방 안쪽. 손잡이는 -x 쪽. deadbolt면 돌림쇠도 단다 (도어락 있는 문은 없음)
static func door(light: bool, handle_y := 1.0, deadbolt := true) -> Dictionary:
	var g := node(null)
	var dm := painted(0xe9e4de, 0.42) if light else painted(0x6e5a48, 0.48)
	var fm := painted(0xffffff, 0.45) if light else wood(0x4e3e30, 0.6)
	rbox(g, Vector3(0.8, 2.0, 0.04), 0.004, dm, Vector3(0, 1.0, 0))
	# 눌러 찍은 면 둘
	var line := mat(shade(0xe9e4de if light else 0x6e5a48, 0.3), 0.7)
	for c in [[0.56, 0.62, 1.38], [0.56, 0.62, 0.44]]:
		var pw: float = c[0]
		var ph: float = c[1]
		var cy: float = c[2]
		rbox(g, Vector3(pw, ph, 0.002), 0.0008, dm, Vector3(0, cy, 0.0208))
		for sx in [-1.0, 1.0]:
			box(g, Vector3(0.002, ph, 0.002), line, Vector3(float(sx) * pw / 2.0, cy, 0.022))
		for sy in [-1.0, 1.0]:
			box(g, Vector3(pw, 0.002, 0.002), line, Vector3(0, cy + float(sy) * ph / 2.0, 0.022))
	# 틀과 문턱
	for sx in [-1.0, 1.0]:
		rbox(g, Vector3(0.06, 2.06, 0.08), 0.004, fm, Vector3(float(sx) * 0.43, 1.03, 0.004))
	rbox(g, Vector3(0.92, 0.06, 0.08), 0.004, fm, Vector3(0, 2.06, 0.004))
	rbox(g, Vector3(0.82, 0.012, 0.09), 0.003, steel(0x9a9a94, 0.42), Vector3(0, 0.006, 0.01))
	# 경첩
	var hm := steel(0xb8bcc0, 0.3)
	for y in [0.25, 1.05, 1.82]:
		_hinge(g, Vector3(0.395, float(y), 0.0205), hm, 0.1)
	# 손잡이 뭉치 (-x쪽)
	if true:
		var hx := -0.3
		var ch := chrome(0xc0c4c8, 0.2)
		var rose := lathe(g, [Vector2(0.0, 0.0), Vector2(0.032, 0.0), Vector2(0.032, 0.003), Vector2(0.024, 0.009), Vector2(0.0, 0.009)], ch, Vector3(hx, handle_y, 0.0205), 24)
		rose.rotation.x = PI / 2.0
		tube(g, [Vector3(hx, handle_y, 0.024), Vector3(hx, handle_y, 0.06), Vector3(hx + 0.015, handle_y, 0.07), Vector3(hx + 0.1, handle_y, 0.072), Vector3(hx + 0.12, handle_y - 0.004, 0.066)], 0.0095, ch, 10, true, 6)
		# 보조 잠금 돌림쇠와 체인 걸쇠
		if deadbolt:
			var ly := 1.18
			var lrose := lathe(g, [Vector2(0.0, 0.0), Vector2(0.027, 0.0), Vector2(0.024, 0.008), Vector2(0.0, 0.008)], ch, Vector3(hx, ly, 0.0205), 22)
			lrose.rotation.x = PI / 2.0
			rbox(g, Vector3(0.044, 0.012, 0.024), 0.0045, ch, Vector3(hx, ly, 0.038))
		box(g, Vector3(0.022, 0.1, 0.004), hm, Vector3(hx + 0.03, 1.45, 0.022))
		var chn := mat(0xb0b4b8, 0.28, 0.85)
		for i in 10:
			var a := float(i) / 9.0
			var q: Vector3 = Vector3(hx + 0.03, 1.5, 0.03).lerp(Vector3(hx - 0.14, 1.44, 0.03), a)
			q.y -= sin(a * PI) * 0.1
			var lk := ring(g, 0.0065, 0.0013, chn, q, 12, 4)
			lk.rotation = Vector3(PI / 2.0 if i % 2 == 0 else 0.0, 0.0, 0.0)
			lk.set_meta("ghost", true)
	# 도어아이
	var eye_c := Vector3(0, 1.5, 0.0205)
	var eye := lathe(g, [Vector2(0.0, 0.0), Vector2(0.011, 0.0), Vector2(0.008, 0.008), Vector2(0.0, 0.009)], brass(0xb89a56, 0.32), eye_c, 14)
	eye.rotation.x = PI / 2.0
	cylz(g, 0.0042, 0.0005, glass(0x202830, 0.9, 0.08), eye_c + Vector3(0, 0, 0.0096), 12)
	# 도어클로저 (위쪽)
	rbox(g, Vector3(0.22, 0.05, 0.05), 0.012, painted(0xd8d4cc, 0.4), Vector3(-0.08, 1.92, 0.046))
	cylz(g, 0.02, 0.02, steel(0x9a9a94, 0.3), Vector3(0.02, 1.92, 0.056), 14)
	var arm := rbox(g, Vector3(0.24, 0.018, 0.012), 0.004, painted(0xa8a49c, 0.45), Vector3(0.14, 1.97, 0.065))
	arm.rotation.z = 0.2
	return {"g": g}


## 스위치 판 · 콘센트. 앞 +Z
static func switch_plate(count: int) -> Dictionary:
	var g := node(null)
	var w := 0.07
	var h := 0.115
	var body := plastic(0xf2f0ea, 0.38)
	platez(g, w, h, 0.006, 0.006, body, Vector3(0, 0, 0.003))
	for i in count:
		var cx := (i - (count - 1) / 2.0) * (w * 0.62 / maxf(1.0, count))
		var bw := w * 0.58 / maxf(1.0, count)
		var rk := rbox(g, Vector3(bw, 0.05, 0.007), 0.002, plastic(0xfaf8f3, 0.32), Vector3(cx, 0.0, 0.0065))
		rk.rotation.x = 0.1
		sph(g, 0.0013, mat(0xff5533, 0.4, 0.0, {"emit": 0x992211}), Vector3(cx, 0.022, 0.0088), 6)
	return {"g": g}


static func outlet() -> Dictionary:
	var g := node(null)
	var body := plastic(0xf2f0ea, 0.38)
	platez(g, 0.07, 0.115, 0.006, 0.006, body, Vector3(0, 0, 0.003))
	for sy in [-1.0, 1.0]:
		var c := Vector3(0, float(sy) * 0.027, 0.0062)
		var r := lathe(g, [Vector2(0.0, 0.0), Vector2(0.0195, 0.0), Vector2(0.0215, -0.0028)], mat(0xdcd9d2, 0.5), c, 20)
		r.rotation.x = PI / 2.0
		for sx in [-1.0, 1.0]:
			cylz(g, 0.0026, 0.0009, mat(0x1d1d1d, 0.7), c + Vector3(float(sx) * 0.0095, 0, 0.0003), 8)
	cylz(g, 0.0024, 0.0014, steel(), Vector3(0, 0, 0.0062), 8)
	return {"g": g}


## 연기 감지기: 천장에 붙고 아래(-Y)를 본다
static func smoke_detector() -> Dictionary:
	var g := node(null)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.05, 0.0), Vector2(0.052, -0.012), Vector2(0.044, -0.03), Vector2(0.0, -0.034)], plastic(0xe8e6de, 0.42), Vector3.ZERO, 26, 50.0)
	for i in 16:
		var a := i * TAU / 16.0
		box(g, Vector3(0.012, 0.012, 0.002), mat(0x8a8880, 0.7), Vector3(cos(a) * 0.046, -0.02, sin(a) * 0.046)).rotation.y = -a
	sph(g, 0.0028, mat(0x441111, 0.3, 0.0, {"emit": 0xcc2211, "emit_e": 1.2}), Vector3(0.02, -0.034, 0), 8)
	return {"g": g}


## 스프링클러: 받침 · 몸통 · 유리구 · 튀김판
static func sprinkler() -> Dictionary:
	var g := node(null)
	var ch := chrome(0xc0c0c0, 0.26)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.038, 0.0), Vector2(0.036, -0.004), Vector2(0.012, -0.012), Vector2(0.0, -0.012)], ch, Vector3.ZERO, 20)
	lathe(g, [Vector2(0.0, -0.012), Vector2(0.01, -0.012), Vector2(0.012, -0.024), Vector2(0.007, -0.03), Vector2(0.0, -0.03)], brass(0xb89a56, 0.3), Vector3.ZERO, 12)
	for sx in [-1.0, 1.0]:
		rod(g, Vector3(float(sx) * 0.008, -0.026, 0), Vector3(float(sx) * 0.006, -0.05, 0), 0.0016, brass(0xb89a56, 0.3), 6)
	cyl(g, 0.0024, 0.0024, 0.018, mat(0xd8452e, 0.15, 0.0, {"alpha": 0.8}), Vector3(0, -0.04, 0), 8)
	lathe(g, [Vector2(0.0, -0.052), Vector2(0.018, -0.052), Vector2(0.016, -0.05), Vector2(0.0, -0.048)], brass(0xb89a56, 0.3), Vector3.ZERO, 14)
	return {"g": g}


## 매입 조명 (꺼져 있거나 희미하게)
static func downlight() -> Dictionary:
	var g := node(null)
	lathe(g, [Vector2(0.056, 0.0), Vector2(0.06, -0.004), Vector2(0.052, -0.005), Vector2(0.044, 0.0)], plastic(0xf0efea, 0.38), Vector3.ZERO, 26, 70.0)
	cyl(g, 0.045, 0.045, 0.002, mat(0xe8e6da, 0.5, 0.0, {"emit": 0x554a36, "emit_e": 0.6}), Vector3(0, -0.002, 0), 22)
	return {"g": g}


## 둥근 천장등: 받침과 젖빛 덮개
static func ceiling_round() -> Dictionary:
	var g := node(null)
	lathe(g, [Vector2(0.0, 0.0), Vector2(0.21, 0.0), Vector2(0.215, -0.02), Vector2(0.2, -0.05), Vector2(0.13, -0.075), Vector2(0.0, -0.082)], plastic(0xf2f0ea, 0.44), Vector3.ZERO, 40, 60.0)
	for i in 3:
		var a := i * TAU / 3.0 + 0.4
		cyl(g, 0.006, 0.006, 0.006, steel(), Vector3(cos(a) * 0.15, -0.044, sin(a) * 0.15), 8)
	return {"g": g}


## 천장 몰딩 · 걸레받이용 단면 상자 (room.gd)
static func trim_strip(len_x: float, h: float, t: float, m: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = _rbox_mesh(Vector3(len_x, h, t), 0.003, 0.0)
	n.material_override = m
	return n


# ───────────────────────────── 3장 고급 침대 · 창문 · 링 라이트, 옷걸이와 옷
## 3장 침대 (p.style == "premium"): 천을 씌운 받침 · 모서리가 둥근 매트리스 · 양옆과 발치로 처지는 이불 ·
## 이불 위로 접어 올린 시트 · 베개 둘과 기대 세운 쿠션 · 세로 줄 머리판 · 발치에 걸친 담요.
## 높이는 다른 침대와 같다 (매트리스 윗면 0.43, 이불 윗면 약 0.5 — 그 위에 놓인 물건들 때문)
static func _bed_premium(p: Dictionary) -> Dictionary:
	var g := node(null)
	var w: float = p.get("w", 1.3)
	var d: float = p.get("d", 2.0)
	var fabric := cloth_m(int(p.get("frame", 0xf1ebe5)))
	var velvet := pbr("fleece", int(p.get("head", 0xc9b5ab)), 1.0, 0.0, {"rim_enabled": true, "rim": 0.35, "rim_tint": 0.6})
	var sheet := cloth_m(int(p.get("sheet", 0xffffff)))
	box(g, Vector3(w - 0.12, 0.06, d - 0.12), mat(0x15120f, 0.9), Vector3(0, 0.03, 0))
	soft_box(g, Vector3(w, 0.17, d), 0.03, fabric, Vector3(0, 0.145, 0), Vector3i(20, 4, 28))
	soft_box(g, Vector3(w - 0.03, 0.2, d - 0.03), 0.045, sheet, Vector3(0, 0.33, 0), Vector3i(24, 6, 32))
	# 이불 · 접어 올린 시트 · 담요는 모두 매트리스 모서리 위 같은 곳(높이 0.38)을 중심으로 돌아 내려간다
	var e := w / 2.0 - 0.06
	var soft: bool = p.get("pattern", "") == "fluffy"
	_cloth(g, tmat(p.get("blanket_tex", "blanket_e1"), 1.0), e, 0.465, 0.07, -0.36, d / 2.0 - 0.06, 0.26, true, 0.016 if soft else 0.012, 1.0)
	_cloth(g, sheet, e, 0.532, 0.03, -0.36, -0.15, 0.3, false, 0.004, 2.0)
	var tm := pbr("knit", int(p.get("throw", 0xb59aa4)), 1.0, 0.0, {"rim_enabled": true, "rim": 0.3, "rim_tint": 0.5})
	_cloth(g, tm, e, 0.53, 0.022, 0.52, 0.88, 0.3, false, 0.004, 3.0)
	# 베개 둘: 바닥은 평평하고 위가 부풀었다. 머리판 쪽으로 살짝 기대 있다
	var pmesh := _puff(Vector3(0.58, 0.14, 0.38), true)
	var pm := cloth_m(int(p.get("pillow", 0xffffff)))
	var pz := -d / 2.0 + 0.25
	for sx in [-1, 1]:
		var pn := mi(g, pmesh, pm, Vector3(sx * 0.305, 0.5, pz))
		pn.rotation = Vector3(0.08, sx * 0.035, 0)
	# 베개 앞에 기대 세운 네모 쿠션
	var cu := mi(g, _puff(Vector3(0.36, 0.13, 0.36), false), pbr("fleece", int(p.get("cushion", 0xc79aa8)), 1.0, 0.0, {"rim_enabled": true, "rim": 0.35, "rim_tint": 0.6}), Vector3(-0.08, 0.6, -0.5))
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
	var trim := painted(0xf4f2ee, 0.5)
	var dep := 0.12
	box(g, Vector3(w + 0.06, 0.03, dep), trim, Vector3(0, h / 2.0 + 0.015, dep / 2.0 - 0.01))
	for sx in [-1.0, 1.0]:
		box(g, Vector3(0.03, h + 0.03, dep), trim, Vector3(sx * (w / 2.0 + 0.015), 0.015, dep / 2.0 - 0.01))
		box(g, Vector3(0.065, h, 0.016), trim, Vector3(sx * (w / 2.0 + 0.0325), 0, dep - 0.002))
	box(g, Vector3(w + 0.13, 0.065, 0.016), trim, Vector3(0, h / 2.0 + 0.0325, dep - 0.002))
	box(g, Vector3(w + 0.22, 0.03, dep + 0.06), painted(0xebe8e3, 0.16), Vector3(0, -h / 2.0 - 0.015, (dep + 0.06) / 2.0 - 0.01))
	box(g, Vector3(w + 0.13, 0.06, 0.014), trim, Vector3(0, -h / 2.0 - 0.06, -0.003))
	# 흰 창틀과 미닫이 두 짝 (왼쪽은 안쪽 레일, 오른쪽은 바깥 레일, 가운데서 겹친다)
	var pvc := painted(int(p.get("frame", 0xffffff)), 0.3)
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
		var cm := pbr("fabric", int(p["curtain"]), 1.0, 0.0, {"rim_enabled": true, "rim": 0.25, "rim_tint": 0.5})
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


## 링 라이트: 벌어진 삼각대와 버팀대 · 고무발 · 두 단 기둥과 조임 손잡이 · 기울기 머리 ·
## 검은 테 안의 빛나는 확산판 (이름 "ring" — 끄고 켤 때 이 재질의 빛 세기를 바꾼다) ·
## 가운데 휴대폰 거치대 · 뒤쪽 조절기와 벽 콘센트까지 늘어진 전선. 앞(+Z)이 비추는 쪽
static func _ring_light() -> Dictionary:
	var g := node(null)
	var m := pbr("brushed", 0x1e1e22, 0.36, 0.7)
	var plastic_m := plastic(0x26262a, 0.55)
	var rubber_m := rubber(0x101011)
	cyl(g, 0.021, 0.021, 0.07, m, Vector3(0, 0.57, 0), 14)
	cyl(g, 0.02, 0.02, 0.045, m, Vector3(0, 0.3, 0), 14)
	for i in range(3):
		var a := i / 3.0 * TAU
		var dir := Vector3(sin(a), 0, cos(a))
		var top := Vector3(0, 0.55, 0) + dir * 0.02
		var ft := dir * 0.31 + Vector3(0, 0.02, 0)
		rod(g, top, ft, 0.0085, m, 8)
		rod(g, Vector3(0, 0.3, 0) + dir * 0.018, top.lerp(ft, 0.5), 0.0055, m, 6)
		cyl(g, 0.013, 0.016, 0.02, rubber_m, Vector3(ft.x, 0.01, ft.z), 10)
	cyl(g, 0.0135, 0.0135, 0.78, m, Vector3(0, 0.67, 0), 12)
	cyl(g, 0.019, 0.019, 0.045, plastic_m, Vector3(0, 1.07, 0), 14)
	rod(g, Vector3(0, 1.07, 0), Vector3(0.048, 1.07, 0), 0.005, m, 6)
	sph(g, 0.013, plastic_m, Vector3(0.054, 1.07, 0), 10)
	cyl(g, 0.0105, 0.0105, 0.28, m, Vector3(0, 1.21, 0), 12)
	box(g, Vector3(0.052, 0.035, 0.04), plastic_m, Vector3(0, 1.345, 0))
	sph(g, 0.012, plastic_m, Vector3(0.034, 1.345, 0), 10)
	var housing := ring(g, 0.228, 0.03, plastic_m, Vector3(0, 1.6, 0))
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
	box(g, Vector3(0.1, 0.022, 0.018), plastic_m, Vector3(0, 1.6, 0.04))
	for sx in [-1.0, 1.0]:
		box(g, Vector3(0.01, 0.03, 0.022), plastic_m, Vector3(sx * 0.045, 1.6, 0.048))
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
	box(ctl, Vector3(0.07, 0.03, 0.022), plastic_m, Vector3.ZERO)
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
	box(g, Vector3(w - 0.02, 0.022, 0.34), wood(0xc9a27a, 0.5, true), Vector3(0, 0.174, 0))
	# 신발 상자 둘 (뚜껑이 조금 크다)
	for b in [[-0.17, 0xf3cfd6, 0xe6b9c3, 0.05], [0.18, 0xf4f1ec, 0x2a2a2e, -0.07]]:
		var bn := node(g, Vector3(b[0], 0.185, 0))
		bn.rotation.y = b[3]
		box(bn, Vector3(0.3, 0.1, 0.19), pbr("card", b[1], 0.7), Vector3(0, 0.05, 0))
		box(bn, Vector3(0.306, 0.026, 0.196), pbr("card", b[2], 0.6), Vector3(0, 0.1, 0))
	var hang := pbr("fleece", 0xe0bcc4, 1.0, 0.0, {"rim_enabled": true, "rim": 0.3, "rim_tint": 0.5})
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
	var m := knit_m(c) if kind == "knit" else cloth_m(c)
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
			var dk := mat(shade(c, 0.4), 0.9)
			_gpatch(g, kind, sd, -0.03, -0.3, 0.17, 0.0, dk)
			_gpatch(g, kind, sd, -0.3, -L + 0.012, 0.005, 0.005, dk)
			for i in 2:
				sph(g, 0.009, mat(0x1a1a1c, 0.4), Vector3(fx.call(0.08, -0.36 - i * 0.12) + 0.005, -0.36 - i * 0.12, 0.02), 8)
			if kind == "long":
				_gpatch(g, kind, sd, -0.42, -0.47, W * 0.9, W * 0.9, mat(shade(c, 0.15), 0.9))
		"shirt":
			_gpatch(g, kind, sd, -0.004, -0.05, 0.16, 0.12, mat(shade(c, -0.12), 0.9))
			_gpatch(g, kind, sd, -0.05, -L + 0.012, 0.022, 0.022, mat(shade(c, 0.08), 0.9))
			var bt := mat(0xf2efe8, 0.4)
			for i in 5:
				sph(g, 0.0055, bt, Vector3(fx.call(0.0, -0.1 - i * 0.1) + 0.005, -0.1 - i * 0.1, 0), 6)
		"knit":
			var rib := mat(shade(c, 0.12), 0.95)
			_gpatch(g, kind, sd, -L + 0.065, -L + 0.004, W * 0.86, W * 0.86, rib)
			_gpatch(g, kind, sd, -0.012, -0.045, 0.17, 0.15, rib)
		"dress":
			_gpatch(g, kind, sd, -0.29, -0.315, W * 0.74, W * 0.74, mat(shade(c, 0.15), 0.9))
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
