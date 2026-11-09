class_name Viewmodel
extends Build
## 1인칭으로 보이는 오른팔과 도구: 방호복 소매 · 테이프 · 니트릴 장갑 · 트리거 분무기 · 손 솔(스크러버).
## 재질에 FOV와 깊이 보정을 걸어, 시야 설정이 바뀌어도 팔 크기가 그대로이고 벽에 파묻히지 않는다

const VM_FOV := 54.0
## 팔은 이 층에만 그린다: 손전등 빛을 받지 않아 하얗게 날아가지 않는다
const LAYER := 2
## 손바닥 쪽으로 굽히는 각도: 손가락마다 [밑, 가운데, 끝]
const OPEN := [[12.0, 15.0, 10.0], [9.0, 15.0, 10.0], [11.0, 17.0, 12.0], [15.0, 19.0, 14.0]]
## 분무기: 검지 · 중지는 방아쇠에, 약지 · 소지는 병목을 감는다
const GRIP_SPRAY := [[18.0, 56.0, 42.0], [34.0, 66.0, 44.0], [58.0, 76.0, 48.0], [62.0, 78.0, 50.0]]
## 솔: 네 손가락 모두 손잡이를 감는다
const GRIP_BRUSH := [[52.0, 74.0, 46.0], [56.0, 76.0, 48.0], [58.0, 78.0, 48.0], [62.0, 80.0, 50.0]]
## 손목에서 잰 엄지 관절 자리 (왼쪽이 -X)
const THUMB_OPEN := [Vector3(-0.031, -0.006, -0.034), Vector3(-0.056, -0.01, -0.06), Vector3(-0.073, -0.014, -0.086), Vector3(-0.083, -0.016, -0.108)]
const THUMB_SPRAY := [Vector3(-0.03, -0.01, -0.036), Vector3(-0.046, -0.03, -0.058), Vector3(-0.054, -0.05, -0.07), Vector3(-0.052, -0.066, -0.08)]
const THUMB_BRUSH := [Vector3(-0.03, -0.01, -0.036), Vector3(-0.044, -0.03, -0.06), Vector3(-0.044, -0.05, -0.08), Vector3(-0.036, -0.06, -0.098)]
## 쥔 손에서 물체 중심 자리 (손목 기준, 쥔 손은 z축으로 -90도 돌아 엄지가 위)
const FIST := Vector3(-0.042, 0.0, -0.076)
## 분무기 몸통 원점을 주먹에서 얼마나 내리는가 (방아쇠가 검지 높이에 오게)
const SPRAY_DROP := -0.067


## 도구 번호 → 노드 사전과 분무구 위치를 돌려준다. plain이면 사진용 (보정 없이)
static func make(cam: Node3D, plain := false) -> Dictionary:
	var glove := pbr("plastic", 0x35639c, 0.34, 0.0, {}, 4.0)
	# 1: 맨손
	var h := node(null)
	_arm(h)
	var open_n := node(h)
	_hand(open_n, glove, OPEN, THUMB_OPEN)
	h.set_meta("base", Vector3(0.262, -0.238, -0.47))
	h.rotation = Vector3(0.3, 0.42, 0.2)
	finish({"g": h})
	# 2: 트리거 분무기
	var s := node(null)
	_arm(s)
	var gs := node(s)
	gs.rotation.z = -PI / 2.0
	_hand(gs, glove, GRIP_SPRAY, THUMB_SPRAY)
	var tool := node(s, FIST + Vector3(0, SPRAY_DROP, 0))
	var sp := _spray(tool)
	s.set_meta("base", Vector3(0.215, -0.2, -0.42))
	s.rotation = Vector3(0.12, 0.34, 0.04)
	finish({"g": s, "trigger": sp.trigger})
	# 3: 손 솔
	var c := node(null)
	_arm(c)
	var gc := node(c)
	gc.rotation.z = -PI / 2.0
	_hand(gc, glove, GRIP_BRUSH, THUMB_BRUSH)
	var sc := node(c, FIST)
	sc.rotation = Vector3(0.0, 0.62, 0.0)
	sc.scale = Vector3.ONE * 0.86
	_brush(sc)
	c.set_meta("base", Vector3(0.235, -0.2, -0.42))
	c.rotation = Vector3(0.16, 0.34, 0.14)
	finish({"g": c})
	for n in [h, s, c]:
		if not plain:
			_vm_mats(n)
		cam.add_child(n)
	var nz: Vector3 = s.basis * (FIST + Vector3(0, SPRAY_DROP, 0) + (tool.basis * sp.nozzle))
	return {1: h, 2: s, 3: c, "trigger": sp.trigger, "nozzle": nz}


## 팔 재질은 화면에 붙여 그린다: 세상과 다른 시야각, 카메라 쪽으로 당긴 깊이
static func _vm_mats(root: Node3D) -> void:
	var nodes: Array = root.find_children("*", "MeshInstance3D", true, false)
	for n in nodes:
		var mi_n := n as MeshInstance3D
		mi_n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi_n.layers = LAYER
		var am := mi_n.mesh as ArrayMesh
		if am == null:
			continue
		for i in am.get_surface_count():
			var mt: BaseMaterial3D = am.surface_get_material(i).duplicate()
			mt.use_z_clip_scale = true
			mt.z_clip_scale = 0.14
			mt.use_fov_override = true
			mt.fov_override = VM_FOV
			am.surface_set_material(i, mt)


## 팔 좌표 (시야각 VM_FOV)를 세상 시야각으로 그릴 때 같은 화면 자리가 되도록 옮긴다 (물 분사 위치)
static func to_world(p: Vector3, world_fov: float) -> Vector3:
	var k := tan(deg_to_rad(world_fov) * 0.5) / tan(deg_to_rad(VM_FOV) * 0.5)
	return Vector3(p.x * k, p.y * k, p.z)


## 방호복 소매 (손목에서 +Z로, 카메라 뒤까지) · 장갑과 소매를 감은 회색 테이프 · 끝이 들뜬 테이프 귀
static func _arm(p: Node3D) -> void:
	var suit := pbr("paper", 0xe6e6df, 0.92, 0.0, {}, 3.0)
	var L := 0.75
	var cm := CylinderMesh.new()
	cm.top_radius = 0.036
	cm.bottom_radius = 0.054
	cm.height = L
	cm.radial_segments = 18
	cm.rings = 30
	cm.cap_top = false
	cm.cap_bottom = false
	var mesh := deformed(cm, func(v: Vector3) -> Vector3:
		var t: float = 0.5 - v.y / L
		var a: float = atan2(v.x, v.z)
		var k: float = 1.0 + sin(t * 44.0 + a * 2.0) * 0.042 + sin(t * 97.0 - a * 3.0) * 0.02 + sin(a * 5.0 + t * 13.0) * 0.016
		return Vector3(v.x * k * 1.05, v.z * k * 0.9, t * L))
	mi(p, mesh, suit, Vector3.ZERO)
	var tape := pbr("paper", 0x7f8286, 0.5)
	var tp := lathe(p, [Vector2(0.0385, -0.02), Vector2(0.041, -0.018), Vector2(0.0425, 0.0), Vector2(0.044, 0.02), Vector2(0.0445, 0.04), Vector2(0.043, 0.042)], tape, Vector3(0, 0, 0.012), 22)
	tp.rotation.x = PI / 2.0
	tp.scale = Vector3(1.05, 1.0, 0.9)
	# 테이프 감긴 자리
	for i in 2:
		var lp := lathe(p, [Vector2(0.0432 + i * 0.0006, 0.0), Vector2(0.0442 + i * 0.0006, 0.0005), Vector2(0.0432 + i * 0.0006, 0.001)], mat(0x5f6266, 0.7), Vector3(0, 0, 0.018 + i * 0.016), 22, 80.0)
		lp.rotation.x = PI / 2.0
		lp.scale = Vector3(1.05, 1.0, 0.9)


## 손: 손목에서 손끝으로 이어지는 손바닥 · 엄지 두덩 · 새끼 두덩 · 손가락 · 장갑 끝 말림. 등이 +Y, 손가락 끝이 -Z
static func _hand(p: Node3D, m: Material, pose: Array, thumb: Array) -> void:
	loft(p, [
		[Vector3(0, 0.0, -0.002), 0.027, 0.0165, 2.5],
		[Vector3(0, 0.0005, -0.02), 0.03, 0.0158, 2.7],
		[Vector3(0, 0.001, -0.045), 0.0372, 0.0148, 3.0],
		[Vector3(0, 0.001, -0.07), 0.0425, 0.0134, 3.3],
		[Vector3(0, 0.0, -0.09), 0.0445, 0.0114, 3.6],
		[Vector3(0, -0.001, -0.106), 0.042, 0.0078, 3.2],
	], m, Vector3.ZERO, 26, 5)
	# 손바닥 쪽 살집
	var mound := sph(p, 0.024, m, Vector3(-0.024, -0.009, -0.04), 14)
	mound.scale = Vector3(0.9, 0.6, 1.32)
	var hypo := sph(p, 0.016, m, Vector3(0.028, -0.009, -0.05), 12)
	hypo.scale = Vector3(0.85, 0.55, 1.8)
	# 손목과 장갑 끝 말림
	var wr := lathe(p, [Vector2(0.0, -0.02), Vector2(0.03, -0.02), Vector2(0.033, 0.0), Vector2(0.036, 0.03), Vector2(0.0395, 0.032), Vector2(0.0395, 0.036), Vector2(0.033, 0.038)], m, Vector3(0, 0, -0.01), 22, 70.0)
	wr.rotation.x = PI / 2.0
	wr.scale = Vector3(1.05, 1.0, 0.86)
	# 네 손가락
	var xs := [-0.0322, -0.0108, 0.0106, 0.031]
	var lens := [[0.043, 0.027, 0.022], [0.048, 0.03, 0.023], [0.045, 0.028, 0.023], [0.035, 0.021, 0.02]]
	var rad := [0.0094, 0.0098, 0.0093, 0.0082]
	var splay := [-2.5, -0.8, 1.2, 4.0]
	for i in 4:
		var base := Vector3(float(xs[i]), 0.001, -0.098)
		_finger(p, m, base, lens[i], pose[i], float(rad[i]), float(splay[i]))
		# 손등 마디 (장갑 속에 살짝)
		var kn := sph(p, float(rad[i]) * 1.28, m, base + Vector3(0, 0.0048, 0.003), 12)
		kn.scale = Vector3(1.0, 0.36, 1.0)
	# 엄지
	tube(p, thumb, 0.012, m, 12, true, 5, Vector3.ZERO, [0.0138, 0.0128, 0.0116, 0.0102])
	var tip := sph(p, 0.0102, m, thumb[thumb.size() - 1], 12)
	tip.scale = Vector3(1.0, 0.92, 1.08)


static func _finger(p: Node3D, m: Material, base: Vector3, lens: Array, curl: Array, r0: float, splay: float) -> void:
	var yaw := deg_to_rad(splay)
	var fwd := Vector3.FORWARD.rotated(Vector3.UP, -yaw)
	var side := Vector3.RIGHT.rotated(Vector3.UP, -yaw)
	var pts := [base - fwd * 0.018, base]
	var radii := [r0 * 1.02, r0 * 1.06]
	var a := base
	var ang := 0.0
	for j in 3:
		ang += float(curl[j])
		var d := fwd.rotated(side, deg_to_rad(-ang))
		a = a + d * float(lens[j])
		pts.append(a)
		radii.append(r0 * (0.98 - j * 0.09))
	tube(p, pts, r0, m, 12, true, 5, Vector3.ZERO, radii)
	var tip := sph(p, r0 * 0.8, m, a, 12)
	tip.scale = Vector3(1.0, 0.92, 1.08)


## 트리거 분무기: 물이 든 병 (바닥 턱 · 잘록한 허리 · 눈금 · 라벨) · 톱니 잠금 고리 · 손잡이처럼 굽은 분사 머리 ·
## 돌려 여닫는 네모 노즐 · 손가락 홈이 있는 방아쇠와 피스톤. 원점은 병 몸통 가운데
static func _spray(t: Node3D) -> Dictionary:
	var bottle := mat(0x7fcabb, 0.14, 0.0, {"alpha": 0.42, "metallic_specular": 0.75})
	var liquid := mat(0x3f9f8e, 0.18, 0.0, {"alpha": 0.62})
	var white := plastic(0xe9e7e1, 0.34)
	var grey := plastic(0xc4c2bb, 0.4)
	var red := plastic(0xc8402a, 0.36)
	lathe(t, [Vector2(0.0, -0.075), Vector2(0.028, -0.075), Vector2(0.0315, -0.073), Vector2(0.0355, -0.066), Vector2(0.037, -0.056), Vector2(0.037, -0.012), Vector2(0.034, -0.004), Vector2(0.031, 0.006), Vector2(0.031, 0.03), Vector2(0.034, 0.04), Vector2(0.03, 0.056), Vector2(0.022, 0.07), Vector2(0.0172, 0.078), Vector2(0.0172, 0.09)], bottle, Vector3.ZERO, 30, 62.0)
	lathe(t, [Vector2(0.0, -0.072), Vector2(0.0335, -0.072), Vector2(0.0345, -0.056), Vector2(0.0345, -0.012), Vector2(0.0315, -0.004), Vector2(0.0, 0.0)], liquid, Vector3.ZERO, 26, 62.0)
	cyl(t, 0.0028, 0.0028, 0.17, mat(0xeeeeea, 0.5), Vector3(0, 0.012, 0), 8).set_meta("ghost", true)
	band(t, 0.0375, 0.046, tmat("spray_label", 0.55), -0.034)
	for y in [-0.0635, -0.0595]:
		var rg := ring(t, 0.0368, 0.0009, bottle, Vector3(0, float(y), 0), 30, 4)
		rg.rotation = Vector3.ZERO
	# 눈금: 라벨 반대쪽
	var tick := mat(0xf2f2ee, 0.5)
	for i in 5:
		var y := -0.052 + i * 0.01
		box(t, Vector3(0.012 if i % 2 == 0 else 0.007, 0.0012, 0.0008), tick, Vector3(0, y, -0.0374)).set_meta("ghost", true)
	# 잠금 고리: 세로 톱니 · 위 턱 · 목
	var cy := 0.09
	lathe(t, [Vector2(0.0, cy), Vector2(0.0212, cy), Vector2(0.0212, cy + 0.016), Vector2(0.0185, cy + 0.0185), Vector2(0.0135, cy + 0.0195), Vector2(0.0, cy + 0.0195)], white, Vector3.ZERO, 26, 62.0)
	if detail > 0:
		for i in 30:
			var a := i * TAU / 30.0
			box(t, Vector3(0.0013, 0.0145, 0.0011), white, Vector3(sin(a) * 0.0216, cy + 0.008, cos(a) * 0.0216)).rotation.y = a
	cyl(t, 0.0118, 0.0128, 0.02, grey, Vector3(0, cy + 0.027, 0.0), 18).set_meta("ghost", true)
	# 분사 머리: 뒤가 불룩하고 앞으로 가늘어지며 살짝 들린다
	loft(t, [
		[Vector3(0, 0.1265, 0.039), 0.004, 0.0045, 2.0],
		[Vector3(0, 0.1265, 0.0345), 0.0115, 0.0115, 2.4],
		[Vector3(0, 0.1245, 0.02), 0.0172, 0.0178, 2.8],
		[Vector3(0, 0.1235, 0.0), 0.0192, 0.0212, 3.1],
		[Vector3(0, 0.1255, -0.02), 0.0176, 0.0184, 3.1],
		[Vector3(0, 0.1295, -0.04), 0.0142, 0.0138, 2.9],
		[Vector3(0, 0.1335, -0.06), 0.0118, 0.0106, 2.5],
		[Vector3(0, 0.1352, -0.073), 0.0098, 0.0096, 2.2],
		[Vector3(0, 0.1352, -0.0775), 0.0072, 0.0072, 2.0],
	], white, Vector3.ZERO, 26, 6)
	# 금형 이음선 · 윗면 공기구멍 · 측면 글자
	box(t, Vector3(0.0006, 0.0004, 0.09), mat(0xa8a69f, 0.6), Vector3(0, 0.1468, -0.008)).set_meta("ghost", true)
	cyl(t, 0.0022, 0.0022, 0.0008, mat(0x2a2a2a, 0.7), Vector3(0, 0.1446, 0.01), 8).set_meta("ghost", true)
	var label_side := text(t, "ROOMI", 0.009, ink(0x7a7870), Vector3(0.01925, 0.123, 0.004))
	label_side.rotation.y = PI / 2.0
	# 노즐: 뒤 턱 · 돌리는 네모 머리 · 표시 · 분사 구멍
	var nc := Vector3(0, 0.1352, -0.0815)
	var flange := cylz(t, 0.0108, 0.0032, red, nc + Vector3(0, 0, 0.0038), 18)
	flange.set_meta("ghost", true)
	rbox(t, Vector3(0.0212, 0.0212, 0.0135), 0.0034, red, nc + Vector3(0, 0, -0.0048))
	text(t, "ON", 0.0052, ink(0xf2ece4), nc + Vector3(0, 0.01065, -0.0048), "up")
	var off_t := text(t, "OFF", 0.0048, ink(0xf2ece4), nc + Vector3(0.01065, 0, -0.0048), "up")
	off_t.rotation.z = -PI / 2.0
	cylz(t, 0.0044, 0.0008, plastic(0x8a2a1c, 0.4), nc + Vector3(0, 0, -0.0118), 14).set_meta("ghost", true)
	cylz(t, 0.0013, 0.001, mat(0x120806, 0.8), nc + Vector3(0, 0, -0.0124), 8).set_meta("ghost", true)
	# 피스톤: 방아쇠에서 머리 속으로
	var pst := cylz(t, 0.0045, 0.022, chrome(0xc8ccd0, 0.28), Vector3(0, 0.1085, -0.046), 12)
	pst.set_meta("ghost", true)
	# 방아쇠: 앞 축에 달려 당겨진다. 앞면에 손가락 홈 셋
	var trig := pivot(t, "trigger", Vector3(0, 0.122, -0.058))
	cyl(t, 0.0034, 0.0034, 0.024, grey, Vector3(0, 0.122, -0.058), 10).rotation.z = PI / 2.0
	loft(trig, [
		[Vector3(0, 0.002, 0.003), 0.0085, 0.0046, 2.4],
		[Vector3(0, -0.014, -0.006), 0.0104, 0.0048, 3.0],
		[Vector3(0, -0.034, -0.0095), 0.0116, 0.0046, 3.2],
		[Vector3(0, -0.052, -0.004), 0.0112, 0.0046, 3.2],
		[Vector3(0, -0.066, 0.006), 0.0092, 0.0046, 2.8],
		[Vector3(0, -0.0705, 0.01), 0.0048, 0.0028, 2.0],
	], red, Vector3.ZERO, 18, 6)
	for i in 3:
		var y := -0.024 - i * 0.012
		var rb_n := rbox(trig, Vector3(0.0196, 0.0016, 0.0018), 0.0006, plastic(0xa8301e, 0.4), Vector3(0, y, -0.0142 + i * 0.0012))
		rb_n.set_meta("ghost", true)
	rod(trig, Vector3(0, -0.014, 0.0), Vector3(0, -0.0135, 0.016), 0.0036, red, 8).set_meta("ghost", true)
	return {"trigger": trig, "nozzle": nc + Vector3(0, 0, -0.0135)}


## 손 솔: 다리미처럼 잡는 D자 손잡이와 고무 그립 · 끝이 좁은 몸통 · 칸마다 심은 솔 다발 · 걸이 구멍.
## 원점은 그립 가운데, 손잡이는 Y축, 몸통과 솔은 -Z쪽
static func _brush(b: Node3D) -> void:
	var blue := plastic(0xd4a01e, 0.36)
	var dark := plastic(0xa87a12, 0.42)
	var grip := rubber(0x23262b)
	# 손잡이: 몸통 양 끝에서 솟아 뒤로 둥글게 이어진다
	loft(b, [
		[Vector3(0, 0.094, -0.058), 0.015, 0.0125, 3.0],
		[Vector3(0, 0.084, -0.036), 0.0146, 0.0126, 3.0],
		[Vector3(0, 0.067, -0.012), 0.0135, 0.0135, 2.6],
		[Vector3(0, 0.045, -0.002), 0.013, 0.0146, 2.4],
		[Vector3(0, 0.0, 0.0), 0.0125, 0.015, 2.2],
		[Vector3(0, -0.045, -0.002), 0.013, 0.0146, 2.4],
		[Vector3(0, -0.067, -0.012), 0.0135, 0.0135, 2.6],
		[Vector3(0, -0.084, -0.036), 0.0146, 0.0126, 3.0],
		[Vector3(0, -0.094, -0.058), 0.015, 0.0125, 3.0],
	], blue, Vector3.ZERO, 18, 6)
	# 고무 그립과 미끄럼 방지 턱
	loft(b, [
		[Vector3(0, 0.05, -0.0015), 0.0120, 0.0138, 2.4],
		[Vector3(0, 0.046, -0.0015), 0.0142, 0.016, 2.4],
		[Vector3(0, 0.0, 0.0), 0.0138, 0.0166, 2.2],
		[Vector3(0, -0.046, -0.0015), 0.0142, 0.016, 2.4],
		[Vector3(0, -0.05, -0.0015), 0.012, 0.0138, 2.4],
	], grip, Vector3.ZERO, 18, 4)
	if detail > 0:
		for i in 11:
			var y := -0.04 + i * 0.008
			var rg := ring(b, 0.0146, 0.0009, grip, Vector3(0, y, 0), 22, 4)
			rg.rotation = Vector3.ZERO
			rg.scale = Vector3(1.0, 1.0, 1.16)
			rg.set_meta("ghost", true)
	# 몸통: 양 끝이 좁은 배 모양 (뒷면이 살짝 굽었다)
	var body_zc := func(y: float) -> float: return -0.058 - pow(absf(y) / 0.11, 2.0) * 0.007
	var sects := []
	for row in [[0.114, 0.006, 0.0042], [0.108, 0.018, 0.0086], [0.092, 0.029, 0.0106], [0.06, 0.0362, 0.0116], [0.0, 0.0396, 0.012], [-0.06, 0.0362, 0.0116], [-0.092, 0.029, 0.0106], [-0.108, 0.018, 0.0086], [-0.114, 0.006, 0.0042]]:
		sects.append([Vector3(0, float(row[0]), body_zc.call(float(row[0]))), float(row[1]), float(row[2]), 2.8])
	loft(b, sects, blue, Vector3.ZERO, 26, 6)
	# 둘레 고무 턱 (벽에 부딪혀도 긁히지 않게)
	var rim := []
	for row in [[0.115, 0.0, 0.0], [0.106, 0.019, 0.0], [0.09, 0.0305, 0.0], [0.06, 0.0376, 0.0], [0.0, 0.041, 0.0], [-0.06, 0.0376, 0.0], [-0.09, 0.0305, 0.0], [-0.106, 0.019, 0.0], [-0.115, 0.0, 0.0]]:
		rim.append([Vector3(0, float(row[0]), body_zc.call(float(row[0])) - 0.0035), maxf(float(row[1]), 0.002), 0.0016, 2.4])
	var rim_n := loft(b, rim, dark, Vector3.ZERO, 22, 6)
	rim_n.set_meta("ghost", true)
	var print_t := text(b, "ROOMI", 0.013, ink(0x3a2c08), Vector3(0, 0.074, body_zc.call(0.074) + 0.0116))
	print_t.rotation.z = -PI / 2.0
	# 걸이 구멍
	var hole := cylz(b, 0.0034, 0.0006, mat(0x0c0c10, 0.8), Vector3(0, -0.102, body_zc.call(-0.102) + 0.0088), 10)
	hole.set_meta("ghost", true)
	# 솔 다발: 엇갈린 줄로 심었다. 다발마다 길이 · 기울기가 조금씩 다르다
	var nylon := mat(0xece6d6, 0.6)
	var nylon2 := mat(0xcfc7b2, 0.68)
	var row_i := 0
	var y := -0.098
	while y <= 0.0985:
		var half: float = 0.0398 * sqrt(maxf(0.0, 1.0 - pow(absf(y) / 0.122, 2.0))) - 0.0052
		var step := 0.0086
		var offset := 0.0 if row_i % 2 == 0 else step / 2.0
		var x := -floorf(half / step) * step + offset
		while x <= half:
			var jit := hash3(Vector3(x * 91.0, y * 57.0, 1.0))
			var ln: float = 0.0235 + jit * 0.0035
			var zb: float = body_zc.call(y) - 0.0095
			var tuft := cyl(b, 0.0037, 0.0023, ln, nylon if jit < 0.72 else nylon2, Vector3(x, y, zb - ln / 2.0), 6)
			tuft.rotation = Vector3(-PI / 2.0 + y * 0.5, 0.0, 0.0)
			tuft.rotation.z = -x * 0.9
			tuft.set_meta("ghost", true)
			x += step
		y += 0.0088
		row_i += 1
