extends Node3D
## 1단계 — 현장 진입 및 방역 (1인칭)

const L_SOLID := 1
const L_ITEM := 2
const L_ENV := 4
const L_STAIN := 8
const L_DOOR := 16
const RAY_MASK := 31
const NECK_UP := 0.1
const NECK_BACK := 0.08
const WALK := 1.45
const FLASH_E := 2.2
## 시작 화면 카메라가 도는 빠르기 (라디안/초), 배경을 만들 때 한 프레임에 쓸 시간 (ms)
const PAN_SPEED := 0.085
const BG_SLICE_MS := 6
const STRIDE := 0.72

var ep: Dictionary
var S: Dictionary
var R: Dictionary
var preview := false
var W := 2.0
var D := 2.0
var H := 2.3
var eye := 1.6

var world_env: WorldEnvironment
var player: CharacterBody3D
var head: Node3D
var cam: Camera3D
var flash: SpotLight3D
var tools := {}
var spray_fx: CPUParticles3D
var items: Array = []
var envs: Array = []
var stains: Array = []
var lights: Array = []
var flies: Array = []
var walkers: Array = []

var tool := 1
var using := false
var scrub_motion := 0.0
var switch_t := 0.0
var flash_on := true
var card = null
var complete := false
var exiting := false
var aim = null
var yaw := 0.0
var pitch := -0.12
var bob := 0.0
var step_t := 0.0
var moving := 0.0
var t := 0.0
var breath_t := 0.0
var breath_stage := 0
var no_foam_warned := {}
var first_item_hint := false
var sens := 0.0022
var hud: CanvasLayer
var H_ := {}
var tmove := Vector2.ZERO
var touchpad: Control
var stain_aim = null
var crouch := 0.0
var crouch_toggle := false
var hint_said := false
var trigger: Node3D
## 시작 화면 배경: 아직 안 보이는 방 / 다 만들었는지 / 만들다 취소 / 카메라가 왼쪽에서 오른쪽으로 도는 범위
var bg_wait := false
var bg_done := false
var bg_cancel := false
var _bg_t := 0
var shot_l := 0.5
var shot_r := -0.5
var shot_len := 12.0
var nozzle := Vector3.ZERO
var step_n := 0
var spray_t := 0.0
var roll := 0.0


func setup(e: Dictionary, state: Dictionary, is_preview := false) -> void:
	ep = e
	S = state
	R = e.room
	preview = is_preview
	W = R.size[0]
	D = R.size[1]
	H = R.size[2]
	eye = R.eye
	sens = 0.0022 * float(Game.settings.get("sens", 1.0))
	Build.detail = 0 if Game.settings.get("quality", "high") == "low" or Game.touch else 1
	_build_env()
	_build_shell()
	_build_furniture()
	_build_door()
	for sd in R.stains:
		stains.append(Stain.new(sd, self))
	_build_items()
	_build_envs()
	_build_lights()
	_build_player()
	if preview:
		flash.light_energy = 0.0
		return
	_build_flies()
	_build_tools()
	_build_hud()
	_update_hud()
	select_tool(1, true)
	_warm_tools()
	Sfx.set_loop("amb", 0.22)


func _exit_tree() -> void:
	if is_instance_valid(world_env) and world_env.get_parent() == null:
		world_env.free()
	if not preview:
		for n in ["spray", "scrub", "flies", "hum", "amb"]:
			Sfx.set_loop(n, 0.0)


# ───────────────────────────── 만들기
func _build_env() -> void:
	var e := Environment.new()
	var fogc := Build.col(int(R.fog[0]))
	e.background_mode = Environment.BG_COLOR
	e.background_color = fogc
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Build.col(int(R.hemi[0]))
	e.ambient_light_energy = float(R.hemi[2]) * 1.6
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.05
	e.ssao_enabled = true
	e.ssao_intensity = 1.8
	e.glow_enabled = true
	e.glow_intensity = 0.4
	e.fog_enabled = true
	e.fog_light_color = fogc.lightened(0.08)
	e.fog_density = float(R.fog[1]) * 0.5
	e.volumetric_fog_enabled = true
	e.volumetric_fog_density = 0.025
	e.volumetric_fog_albedo = Color(0.85, 0.84, 0.8)
	e.volumetric_fog_length = 9.0
	e.adjustment_enabled = true
	e.adjustment_saturation = 0.82
	e.adjustment_contrast = 1.08
	e.adjustment_brightness = float(Game.settings.get("bright", 1.0))
	e.set_meta("vfog", true)
	Game.apply_quality_env(e)
	world_env = WorldEnvironment.new()
	world_env.environment = e
	if not bg_wait:
		add_child(world_env)


func _static_box(size: Vector3, pos: Vector3, layer := L_SOLID, parent: Node = self) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = layer
	b.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	parent.add_child(b)
	b.position = pos
	return b


func _solidify(g: Node) -> void:
	var nodes: Array = g.find_children("*", "Node3D", true, false)
	nodes.append(g)
	for n in nodes:
		if not n.has_meta("solids"):
			continue
		for s in n.get_meta("solids"):
			var b := _static_box(s[1], Vector3.ZERO, L_SOLID, n)
			b.transform = s[0]


## 방 표면 재질: 그려 둔 그림 위에 미터 단위의 잔결 (긁힘 · 벽지 굴곡)
func _surface_mat(tex_name: String, rough: float, detail_kind: String) -> StandardMaterial3D:
	var m: StandardMaterial3D = Build.tmat(tex_name, rough).duplicate()
	if Build.detail > 0 and detail_kind != "":
		m.detail_enabled = true
		m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
		m.detail_albedo = Build.tex("pbr/%s_a" % detail_kind)
		m.detail_normal = Build.tex("pbr/%s_n" % detail_kind)
		m.normal_enabled = true
		m.normal_scale = 0.3
	return m


func _build_shell() -> void:
	var k := "e%d" % int(ep.no)
	var floor_m := _surface_mat(k + "_floor", 0.72, "scuff")
	floor_m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	Build.sheet(self, W, D, "up", floor_m, Vector3.ZERO, 2.2)
	var ceil_n := Build.sheet(self, W, D, "up", _surface_mat(k + "_ceil", 1.0, ""), Vector3(0, H, 0), 2.0)
	ceil_n.rotation.x = PI
	var bbc := 0xffffff if R.wall == "officetel" else (0x5a4632 if R.wall == "banjiha" else 0x8a7a64)
	var bb := Build.painted(bbc, 0.46)
	var bb2 := Build.painted(Build.shade(bbc, -0.06), 0.42)
	var walls := [[W, Vector3(0, H / 2, -D / 2), 0.0], [W, Vector3(0, H / 2, D / 2), PI], [D, Vector3(-W / 2, H / 2, 0), PI / 2], [D, Vector3(W / 2, H / 2, 0), -PI / 2]]
	for i in walls.size():
		var wd: Array = walls[i]
		var wall_m := _surface_mat("%s_wall%d" % [k, i], 0.92, "")
		var hole := _wall_hole(i)
		var q: MeshInstance3D
		if hole.size.x > 0.0:
			q = Build.wall_holed(self, wd[0], H, hole, wall_m, wd[1], 2.4)
		else:
			q = Build.sheet(self, wd[0], H, "wall", wall_m, wd[1], 2.4)
		q.rotation.y = wd[2]
		var n := Vector3(sin(wd[2]), 0, cos(wd[2]))
		var along := Vector3(cos(wd[2]), 0, -sin(wd[2]))
		# 걸레받이: 몸판과 위로 깎인 턱. 문이 있는 벽은 문 양옆만
		var hw: float = float(wd[0]) / 2.0
		var spans := [[-hw, hw]]
		if i == 1:
			spans = [[-hw, hole.position.x - 0.065], [hole.end.x + 0.065, hw]]
		for sp in spans:
			var l0: float = sp[0]
			var l1: float = sp[1]
			if l1 - l0 < 0.02:
				continue
			var c: Vector3 = wd[1] + along * (l0 + l1) / 2.0
			var b := Build.rbox(self, Vector3(l1 - l0, 0.07, 0.015), 0.003, bb, Vector3(c.x, 0.035, c.z) + n * 0.0075)
			b.rotation.y = wd[2]
			var b2 := Build.rbox(self, Vector3(l1 - l0, 0.012, 0.02), 0.004, bb2, Vector3(c.x, 0.074, c.z) + n * 0.01)
			b2.rotation.y = wd[2]
	_static_box(Vector3(W + 0.4, 0.2, D + 0.4), Vector3(0, -0.1, 0))
	_static_box(Vector3(W + 0.4, 0.2, D + 0.4), Vector3(0, H + 0.1, 0))
	_static_box(Vector3(W + 0.4, H, 0.2), Vector3(0, H / 2, -D / 2 - 0.1))
	_static_box(Vector3(W + 0.4, H, 0.2), Vector3(0, H / 2, D / 2 + 0.1))
	_static_box(Vector3(0.2, H, D + 0.4), Vector3(-W / 2 - 0.1, H / 2, 0))
	_static_box(Vector3(0.2, H, D + 0.4), Vector3(W / 2 + 0.1, H / 2, 0))
	_build_fixtures()


## 벽에 뚫을 구멍: 뒷벽은 창문, 앞벽은 문. 벽 가운데를 원점으로 한 사각형
func _wall_hole(i: int) -> Rect2:
	if i == 1:
		var o := Furn.door_opening()
		return Rect2(-float(R.door.x) - o.x / 2.0, -H / 2.0, o.x, o.y)
	if i == 0:
		for f in R.furniture:
			if f.t == "window" and absf(float(f.z) + D / 2.0) < 0.06:
				var w_o := Furn.window_opening(f.get("p", {}))
				return Rect2(float(f.x) - w_o.x / 2.0, float(f.y) - H / 2.0 - w_o.y / 2.0, w_o.x, w_o.y)
	return Rect2()


## 스위치 · 콘센트 · 천장 설비 (장마다 가구를 피한 자리)
## [벽 (n/s/w/e), 벽을 따른 좌표, 높이]
const OUTLETS := {1: [["e", 0.9, 0.3], ["n", 0.75, 0.3]], 2: [["s", -0.25, 0.3], ["e", -0.6, 0.3]], 3: [["w", 0.05, 0.3], ["e", 0.2, 0.32]], 4: [["e", 0.9, 0.3], ["n", 1.0, 0.3]], 5: [["n", 0.6, 0.3], ["w", -0.3, 0.3]]}
## 문을 기준으로 스위치를 둘 쪽 (세상 x 부호)
const SWITCH_SIDE := {1: -1.0, 2: 1.0, 3: -1.0, 4: -1.0, 5: 1.0}


func _wall_fixture(res: Dictionary, wall: String, along: float, y: float) -> void:
	Build.finish(res)
	var g: Node3D = res.g
	add_child(g)
	match wall:
		"n":
			g.position = Vector3(along, y, -D / 2)
		"s":
			g.position = Vector3(along, y, D / 2)
			g.rotation.y = PI
		"w":
			g.position = Vector3(-W / 2, y, along)
			g.rotation.y = PI / 2
		"e":
			g.position = Vector3(W / 2, y, along)
			g.rotation.y = -PI / 2


func _ceil_fixture(res: Dictionary, x: float, z: float) -> void:
	Build.finish(res)
	var g: Node3D = res.g
	add_child(g)
	g.position = Vector3(x, H, z)


func _build_fixtures() -> void:
	var no := int(ep.no)
	var side: float = SWITCH_SIDE.get(no, 1.0)
	_wall_fixture(Furn.switch_plate(2 if no in [3, 5] else 1), "s", float(R.door.x) + side * 0.56, 1.2)
	for o in OUTLETS.get(no, []):
		_wall_fixture(Furn.outlet(), o[0], o[1], o[2])
	_ceil_fixture(Furn.smoke_detector(), W * 0.2, D * 0.25)
	if no in [1, 3]:
		_ceil_fixture(Furn.sprinkler(), -W * 0.2, D * 0.12)
	if no == 3:
		for p in [[-1.0, 0.9], [1.0, 0.9], [-1.0, -0.9], [0.0, 0.0]]:
			_ceil_fixture(Furn.downlight(), p[0], p[1])
	if no == 5:
		_ceil_fixture(Furn.ceiling_round(), 0.0, 0.0)


func _build_furniture() -> void:
	for f in R.furniture:
		_add_furniture(f)


func _add_furniture(f: Dictionary) -> void:
	var res := Build.furniture(f.t, f.get("p", {}))
	var g: Node3D = res.g
	add_child(g)
	g.position = Vector3(f.x, f.get("y", 0.0), f.z)
	g.rotation.y = deg_to_rad(f.get("ry", 0.0))
	if not preview:
		_solidify(g)
	if res.has("walker"):
		walkers.append({"n": res.walker, "m": res.walker_m, "x": 0.0, "dir": 1.0, "wait": randf_range(0.5, 3.0), "sp": 1.2, "who": 0})


func _build_door() -> void:
	var light: bool = R.wall == "officetel"
	var res := Build.finish(Furn.door(String(R.wall), 0.84 if light else 1.0, not light))
	var g: Node3D = res.g
	add_child(g)
	g.position = Vector3(R.door.x, 0, D / 2 - 0.025)
	g.rotation.y = PI
	var body := _static_box(Vector3(0.8, 2.0, 0.06), Vector3(R.door.x, 1.0, D / 2 - 0.035), L_DOOR)
	body.set_meta("ref", {"type": "door"})


func _local_aabb(root: Node3D) -> AABB:
	var inv := root.global_transform.affine_inverse()
	var out := AABB()
	var first := true
	for m in root.find_children("*", "MeshInstance3D", true, false):
		if m.has_meta("uv_only"):
			continue
		var a: AABB = (inv * m.global_transform) * m.get_aabb()
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out


func _build_items() -> void:
	for d in ep.items:
		_add_item(d)


func _add_item(d: Dictionary) -> void:
	if d.get("extra", false):
		return
	var res := Build.item(d.model, d.get("p", {}))
	var root := Node3D.new()
	add_child(root)
	root.position = Vector3(d.pos[0], d.pos[1], d.pos[2])
	root.rotation.y = deg_to_rad(d.get("ry", 0.0))
	var g: Node3D = res.g
	root.add_child(g)
	if d.get("lie", false) and res.has("lie"):
		g.rotation.z = PI / 2
		g.position.y = res.lie
	for u in res.get("uv", []):
		u.visible = false
	var it := {"def": d, "root": root, "state": "idle", "hidden": d.get("hidden", false), "base": root.transform}
	var a := _local_aabb(root)
	var body := StaticBody3D.new()
	body.collision_layer = L_ITEM
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = a.size.max(Vector3(0.04, 0.04, 0.04))
	cs.shape = bs
	cs.position = a.get_center()
	body.add_child(cs)
	root.add_child(body)
	body.set_meta("ref", {"type": "item", "obj": it})
	it.body = body
	it.shape = cs
	it.radius = a.size.length() / 2.0
	if it.hidden:
		root.visible = false
		cs.disabled = true
	items.append(it)


func _build_envs() -> void:
	for d in R.env:
		var b := StaticBody3D.new()
		b.collision_layer = L_ENV
		b.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = d.get("r", 0.2)
		cs.shape = sp
		b.add_child(cs)
		add_child(b)
		b.position = Vector3(d.pos[0], d.pos[1], d.pos[2])
		var en := {"def": d, "shape": cs, "used": false, "disabled": false}
		b.set_meta("ref", {"type": "env", "obj": en})
		envs.append(en)


func _build_lights() -> void:
	for L in R.lights:
		var o := OmniLight3D.new()
		o.light_color = Build.col(int(L.color))
		o.light_energy = float(L.i) * (1.05 if L.get("name", "") == "ring" else 2.0)
		o.omni_range = float(L.d)
		o.omni_attenuation = 1.3
		o.light_volumetric_fog_energy = 0.6
		if Game.settings.get("quality", "high") == "high" and lights.is_empty():
			o.shadow_enabled = true
			o.shadow_blur = 1.6
			o.omni_shadow_mode = OmniLight3D.SHADOW_CUBE
		add_child(o)
		o.position = Vector3(L.pos[0], L.pos[1], L.pos[2])
		lights.append({"light": o, "base": o.light_energy, "flicker": L.get("flicker", false), "name": L.get("name", ""), "on": true})
	if R.lights.any(func(l): return l.get("flicker", false)) and not preview:
		Sfx.set_loop("hum", 0.12)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	player.collision_layer = 0
	player.collision_mask = L_SOLID
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.24
	cap.height = 1.5
	cs.shape = cap
	cs.position.y = 0.86
	player.add_child(cs)
	add_child(player)
	player.position = Vector3(R.spawn[0], 0, R.spawn[1])
	# 머리: 목(눈 아래 NECK_UP, 뒤 NECK_BACK)을 축으로 숙이므로 내려다보면 눈이 앞으로 나간다
	head = Node3D.new()
	head.position.y = eye - NECK_UP
	player.add_child(head)
	cam = Camera3D.new()
	cam.position = Vector3(0, NECK_UP, -NECK_BACK)
	cam.fov = Game.DEFAULT_SETTINGS.fov if preview else float(Game.settings.get("fov", Game.DEFAULT_SETTINGS.fov))
	cam.near = 0.03
	cam.far = 40.0
	head.add_child(cam)
	if not bg_wait:
		cam.current = true
	flash = SpotLight3D.new()
	flash.light_color = Color(1.0, 0.94, 0.84)
	flash.light_energy = FLASH_E
	flash.spot_attenuation = 0.7
	flash.spot_range = 9.0
	flash.spot_angle = 31.0
	flash.spot_angle_attenuation = 1.3
	flash.shadow_enabled = Game.settings.get("quality", "high") != "low"
	flash.light_volumetric_fog_energy = 1.2
	flash.position = Vector3(0.06, -0.05, 0)
	flash.light_cull_mask = 1
	cam.add_child(flash)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.8, 0.84, 0.92)
	fill.light_energy = 0.3
	fill.omni_range = 2.4
	fill.light_cull_mask = 1
	cam.add_child(fill)
	# 팔 전용 빛: 방이 어두워도 손이 보이되 너무 밝지 않게
	var hand_fill := OmniLight3D.new()
	hand_fill.light_color = Color(1.0, 0.96, 0.9)
	hand_fill.light_energy = 0.42
	hand_fill.omni_range = 1.4
	hand_fill.light_cull_mask = Viewmodel.LAYER
	hand_fill.position = Vector3(0.05, 0.12, -0.12)
	cam.add_child(hand_fill)
	pitch = -0.12
	yaw = 0.0
	if preview:
		_aim_shot()


func _build_flies() -> void:
	for st in stains:
		if not st.def.get("flies", false):
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = 14
		var bm := BoxMesh.new()
		bm.size = Vector3(0.009, 0.004, 0.006)
		mm.mesh = bm
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Build.mat(0x050505, 0.4)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		var ph := []
		for i in range(14):
			ph.append([randf() * 6.0, randf() * 6.0, randf() * 6.0, 0.6 + randf() * 1.4])
		flies.append({"st": st, "mmi": mmi, "ph": ph, "alive": 1.0})


func _build_tools() -> void:
	var vm := Viewmodel.make(cam)
	tools = {1: vm[1], 2: vm[2], 3: vm[3]}
	trigger = vm.trigger
	nozzle = vm.nozzle + (vm[2] as Node3D).get_meta("base")
	spray_fx = CPUParticles3D.new()
	spray_fx.emitting = false
	spray_fx.amount = 200
	spray_fx.lifetime = 0.45
	spray_fx.local_coords = false
	spray_fx.direction = Vector3(-0.12, 0.08, -1)
	spray_fx.spread = 7.0
	spray_fx.gravity = Vector3(0, -2.5, 0)
	spray_fx.initial_velocity_min = 3.0
	spray_fx.initial_velocity_max = 4.6
	spray_fx.scale_amount_min = 0.5
	spray_fx.scale_amount_max = 1.2
	var pq := QuadMesh.new()
	pq.size = Vector2(0.018, 0.018)
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pm.albedo_color = Color(0.92, 0.97, 0.95, 0.3)
	var pgrad := Gradient.new()
	pgrad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	pgrad.colors = PackedColorArray([Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.34), Color(1, 1, 1, 0)])
	var ptex := GradientTexture2D.new()
	ptex.gradient = pgrad
	ptex.fill = GradientTexture2D.FILL_RADIAL
	ptex.fill_from = Vector2(0.5, 0.5)
	ptex.fill_to = Vector2(1.0, 0.5)
	ptex.width = 32
	ptex.height = 32
	pm.albedo_texture = ptex
	pq.material = pm
	spray_fx.mesh = pq
	cam.add_child(spray_fx)
	spray_fx.position = Viewmodel.to_world(nozzle, cam.fov)
	for tn in tools.values():
		tn.position = tn.get_meta("base")


## 도구 재질을 입장 안내 화면 뒤에서 미리 그려, 처음 바꿀 때 끊기지 않게 한다
func _warm_tools() -> void:
	for k in tools:
		tools[k].visible = true
	for i in 3:
		await get_tree().process_frame
	if is_inside_tree():
		for k in tools:
			tools[k].visible = k == tool


# ───────────────────────────── HUD
class Cross extends Control:
	var live := false
	func _draw() -> void:
		var c := size / 2.0
		if live:
			draw_arc(c, 9.0, 0, TAU, 32, Color(1, 0.9, 0.75, 0.9), 2.0, true)
		else:
			draw_circle(c, 2.4, Color(1, 1, 1, 0.8))


func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var root := Control.new()
	Ui.full(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Ui.theme
	hud.add_child(root)
	var vg := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.1), Color(0, 0, 0, 0.62)])
	gt.gradient = grad
	vg.texture = gt
	vg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vg.stretch_mode = TextureRect.STRETCH_SCALE
	Ui.full(vg)
	vg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vg)
	H_.vignette = vg
	var tl := Ui.vbox(2)
	Ui.pin(tl, 0, 0, 30, 24)
	tl.add_child(Ui.shadow(Ui.label("1단계  현장 정리", 13, Ui.ACCENT, Ui.spaced)))
	tl.add_child(Ui.shadow(Ui.label("%d장 · %s" % [int(ep.no), ep.place], 23, Ui.TEXT, Ui.serif_b)))
	root.add_child(tl)
	var tr := Ui.vbox(6)
	Ui.pin(tr, 1, 0, -30, 26, -1, 1)
	tr.alignment = BoxContainer.ALIGNMENT_END
	for k in ["o1", "o2", "o4", "o3"]:
		var l := Ui.shadow(Ui.label("", 16, Ui.TEXT, Ui.sans), 3)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tr.add_child(l)
		H_[k] = l
	root.add_child(tr)
	var cr := Cross.new()
	cr.custom_minimum_size = Vector2(24, 24)
	Ui.pin(cr, 0.5, 0.5, 0, 0, 0, 0)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cr)
	H_.cross = cr
	var pr := Ui.vbox(2)
	Ui.pin(pr, 0.5, 0.5, 0, 26, 0, 1)
	pr.alignment = BoxContainer.ALIGNMENT_BEGIN
	var pn := Ui.shadow(Ui.label("", 19, Ui.TEXT, Ui.sans_b), 4)
	pn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ph := Ui.shadow(Ui.label("", 15, Color("d8d2c8"), Ui.sans), 3)
	ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pr.add_child(pn)
	pr.add_child(ph)
	root.add_child(pr)
	H_.pname = pn
	H_.phint = ph
	var tb := Ui.hbox(26)
	Ui.pin(tb, 0, 1, 32, -30, 1, -1)
	H_.tools = []
	for i in range(3):
		var l := Ui.shadow(Ui.label(["1  손", "2  소독 분무기", "3  스크러버"][i], 16, Ui.DIM, Ui.sans_b), 3)
		tb.add_child(l)
		H_.tools.append(l)
	var inv := Ui.shadow(Ui.label("I  보관함", 16, Color(1, 1, 1, 0.38), Ui.sans_b), 3)
	tb.add_child(inv)
	tb.add_child(Ui.shadow(Ui.label("C  숙이기" if OS.has_feature("web") else "Ctrl  숙이기", 16, Color(1, 1, 1, 0.38), Ui.sans_b), 3))
	tb.visible = not Game.touch
	root.add_child(tb)
	var fl := Ui.shadow(Ui.label("", 14, Ui.DIM, Ui.sans), 3)
	Ui.pin(fl, 1, 1, -32, -30, -1, -1)
	root.add_child(fl)
	H_.flash = fl
	# 분류 카드 (종이 꼬리표)
	var card_p := Ui.panel(Ui.paper_box(false, 26))
	card_p.custom_minimum_size = Vector2(380, 0)
	Ui.pin(card_p, 1, 0.5, -70, 0, -1, 0)
	var cv := Ui.vbox(8)
	cv.add_child(Ui.label("유품 분류표", 13, Ui.INK_DIM, Ui.spaced))
	var cn := Ui.label("", 27, Ui.INK, Ui.serif_b, true)
	var cd := Ui.label("", 17, Ui.INK, Ui.serif, true)
	cd.custom_minimum_size = Vector2(326, 0)
	cv.add_child(cn)
	cv.add_child(cd)
	cv.add_child(Ui.gap(4))
	var line := ColorRect.new()
	line.color = Color(Ui.INK, 0.25)
	line.custom_minimum_size = Vector2(0, 1)
	cv.add_child(line)
	if Game.touch:
		cv.add_child(Ui.label("보관 · 폐기 · 내려놓기 중에 고른다", 16, Ui.INK, Ui.sans_b))
	else:
		cv.add_child(Ui.label("왼쪽 클릭 · E     보관함에 넣기", 16, Ui.INK, Ui.sans_b))
		cv.add_child(Ui.label("Q     폐기", 16, Ui.INK, Ui.sans_b))
		cv.add_child(Ui.label("오른쪽 클릭 · X     내려놓기", 16, Ui.INK, Ui.sans_b))
	var cm := Ui.label("", 15, Ui.RED, Ui.sans, true)
	cm.custom_minimum_size = Vector2(326, 0)
	cv.add_child(cm)
	card_p.add_child(cv)
	card_p.visible = false
	card_p.rotation = deg_to_rad(-1.2)
	root.add_child(card_p)
	H_.card = card_p
	H_.cname = cn
	H_.cdesc = cd
	H_.cmsg = cm
	if Game.touch and not preview:
		touchpad = load("res://scripts/touch.gd").new()
		touchpad.room = self
		root.add_child(touchpad)


func _counts() -> Dictionary:
	# 아직 열어 보지 않은 서랍 · 장롱 · 가방 안의 물건은 찾기 전까지 세지 않는다
	var total := 0
	var sorted := 0
	for it in items:
		if it.state == "gone":
			sorted += 1
			total += 1
		elif not it.hidden or _env_opened_for(it):
			total += 1
	var sdone := 0
	var avg := 0.0
	for st in stains:
		if st.done:
			sdone += 1
		avg += 1.0 if st.done else max(0.0, st.progress)
	avg /= max(1, stains.size())
	return {"total": total, "sorted": sorted, "sdone": sdone, "stotal": stains.size(), "avg": avg}


func _update_hud() -> void:
	if not H_.has("o1"):
		return
	var c := _counts()
	var ok := func(b): return "■ " if b else "□ "
	H_.o1.text = ok.call(c.sdone == c.stotal) + "오염 제거   %d / %d   (%d%%)" % [c.sdone, c.stotal, int(c.avg * 100)]
	H_.o2.text = ok.call(c.sorted == c.total) + "유품 분류   %d / %d" % [c.sorted, c.total]
	# 보이는 건 다 분류했는데 숨은 물건(서랍 · 장롱 · 가방 안)이 남았으면 숫자가 왜 모자란지 알려 준다
	if hidden_left() > 0 and c.sorted == c.total:
		H_.o2.text += "   · 아직 열어 보지 않은 곳이 있다"
	H_.o4.text = "기록한 단서   %d" % S.clues.size()
	H_.o3.text = ok.call(false) + "현관으로 나가 작업실 복귀"
	H_.o1.add_theme_color_override("font_color", Ui.OK if c.sdone == c.stotal else Ui.TEXT)
	H_.o2.add_theme_color_override("font_color", Ui.OK if c.sorted == c.total else Ui.TEXT)
	H_.o3.add_theme_color_override("font_color", Ui.ACCENT if complete else Color(1, 1, 1, 0.4))


func refresh() -> void:
	_update_hud()


func _update_prompt() -> void:
	var n := ""
	var h := ""
	var live := false
	if card == null and stain_aim != null and (tool != 1 or aim == null or aim.type == "stain" or aim.type == "solid"):
		var st: Stain = stain_aim.obj
		n = st.def.name
		var how := "분무기  ·  스크러버" if Game.touch else "2 분무기  ·  3 스크러버"
		if tool == 2:
			how = ("뿌리기 버튼을 누르고 있기" if Game.touch else "클릭 유지: 소독약 분사") if stain_aim.dist < 3.0 else "조금 더 가까이"
		elif tool == 3:
			how = ("문지르기 버튼을 누르고 있기" if Game.touch else "클릭 유지 + 마우스로 문지르기") if stain_aim.dist < 2.3 else "조금 더 가까이"
		h = "오염도 %d%%   ·   %s" % [int((1.0 - max(0.0, st.progress)) * 100), how]
		live = true
	elif card == null and aim != null:
		match aim.type:
			"item":
				if aim.dist < 2.4:
					n = aim.obj.def.name
					h = "집기 버튼으로 살펴보기" if Game.touch else "E  살펴보기     Q  바로 폐기"
			"env":
				if aim.dist < 2.4:
					n = aim.obj.def.name
					var act := "조사하기"
					if aim.obj.used and aim.obj.def.has("anim"):
						act = "닫기" if aim.obj.get("open", true) else "열기"
					h = ("집기 버튼으로 " + act) if Game.touch else ("E  " + act)
			"door":
				if aim.dist < 2.6:
					n = "현관문"
					h = ("집기 버튼: 작업 종료 · 작업실로" if Game.touch else "E  작업 종료 · 작업실로") if complete else "아직 정리가 남았다"
			"stain":
				var st: Stain = aim.obj
				if not st.done and aim.dist < 2.9:
					n = st.def.name
					var how := "분무기  ·  스크러버" if Game.touch else "2 분무기  ·  3 스크러버"
					if tool == 2:
						how = "뿌리기 버튼을 누르고 있기" if Game.touch else "클릭 유지: 소독약 분사"
					elif tool == 3:
						how = ("문지르기 버튼을 누르고 있기" if Game.touch else "클릭 유지 + 마우스로 문지르기") if aim.dist < 2.2 else "조금 더 가까이"
					h = "오염도 %d%%   ·   %s" % [int((1.0 - max(0.0, st.progress)) * 100), how]
		live = n != ""
	H_.pname.text = n
	H_.phint.text = h
	if H_.cross.live != live:
		H_.cross.live = live
		H_.cross.queue_redraw()


# ───────────────────────────── 입력
func _unhandled_input(event: InputEvent) -> void:
	if preview or Game.paused or exiting:
		return
	if Game.touch and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = event.relative
		var s := sens
		if using and tool == 3:
			scrub_motion += abs(rel.x) + abs(rel.y)
			s *= 0.25
		yaw -= rel.x * s
		pitch = clamp(pitch - rel.y * s * (-1.0 if Game.settings.get("invert", false) else 1.0), -1.45, 1.45)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				return
			set_use(event.pressed)
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if card != null:
				card_action("cancel")
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_tool(tool % 3 + 1)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_tool((tool + 1) % 3 + 1)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: select_tool(1)
			KEY_2: select_tool(2)
			KEY_3: select_tool(3)
			KEY_E: interact()
			KEY_Q: quick_trash()
			KEY_X, KEY_BACKSPACE:
				if card != null:
					card_action("cancel")
			KEY_F: toggle_flash()
			KEY_I, KEY_TAB: Game.open_inventory()
			KEY_C, KEY_CTRL:
				# 숙이기 '한 번씩': 누를 때마다 숙이기 · 일어서기 (웹은 Ctrl 대신 C)
				if not Game.settings.get("crouch_hold", true) and (event.physical_keycode == KEY_C or not OS.has_feature("web")):
					crouch_toggle = not crouch_toggle


func look(rel: Vector2) -> void:
	var s := sens * 1.5
	if using and tool == 3:
		scrub_motion += abs(rel.x) + abs(rel.y)
		s *= 0.25
	yaw -= rel.x * s
	pitch = clamp(pitch - rel.y * s * (-1.0 if Game.settings.get("invert", false) else 1.0), -1.45, 1.45)


func set_use(v: bool) -> void:
	if card != null:
		if v:
			card_action("keep")
		using = false
		return
	if v and tool == 1:
		interact()
		return
	using = v


func release() -> void:
	using = false


func select_tool(n: int, silent := false) -> void:
	if n == tool and not silent:
		return
	tool = n
	switch_t = 0.25
	using = false
	for k in tools:
		tools[k].visible = k == tool
	if H_.has("tools"):
		for i in range(3):
			H_.tools[i].add_theme_color_override("font_color", Ui.TEXT if i + 1 == tool else Color(1, 1, 1, 0.38))
	if not silent:
		Sfx.play("tool", 0.5)


func toggle_flash() -> void:
	flash_on = not flash_on
	flash.light_energy = FLASH_E if flash_on else 0.0
	Sfx.play("flick", 0.6)
	H_.flash.text = "" if flash_on else "손전등 꺼짐 (F)"


func interact() -> void:
	if card != null:
		card_action("keep")
		return
	if aim == null:
		return
	match aim.type:
		"item":
			if aim.dist < 2.4:
				open_card(aim.obj)
		"env":
			if aim.dist < 2.4:
				use_env(aim.obj)
		"door":
			if aim.dist < 2.6:
				try_exit()


func quick_trash() -> void:
	if card != null:
		card_action("trash")
		return
	if aim == null or aim.type != "item" or aim.dist > 2.4:
		return
	var it = aim.obj
	if it.def.kind == "clue":
		Game.say("(이건 그냥 버릴 물건이 아니다. 살펴보자. [E])", 2.6)
		Sfx.play("error", 0.6)
		return
	sort_item(it, false)


# ───────────────────────────── 분류
func open_card(it) -> void:
	card = it
	it.state = "held"
	it.home = it.root.global_transform
	it.shape.disabled = true
	it.liftable = it.radius < 0.32
	H_.cname.text = it.def.name
	H_.cdesc.text = it.def.get("desc", "")
	H_.cmsg.text = ""
	H_.card.visible = true
	H_.card.modulate.a = 0.0
	create_tween().tween_property(H_.card, "modulate:a", 1.0, 0.15)
	Sfx.play("pick", 0.7)
	if not first_item_hint and int(ep.no) == 1:
		first_item_hint = true
		Game.say("(유족이 받고 싶어 할 물건과 단서는 보관함으로. 나머지는 폐기.)", 4.2)


func card_action(act: String) -> void:
	if card == null:
		return
	var it = card
	if act == "trash" and it.def.kind == "clue":
		H_.cmsg.text = "이건 그냥 버릴 물건이 아니다. 무언가 알려 줄지도 모른다."
		Sfx.play("error", 0.6)
		return
	card = null
	H_.card.visible = false
	if act == "cancel":
		it.state = "returning"
		var tw := create_tween()
		tw.tween_property(it.root, "global_transform", it.home, 0.25)
		tw.tween_callback(func():
			it.state = "idle"
			it.shape.disabled = false)
		return
	sort_item(it, act == "keep")


func sort_item(it, keep: bool) -> void:
	it.state = "gone"
	it.shape.disabled = true
	S.sorted[it.def.id] = "keep" if keep else "trash"
	if keep:
		if it.def.kind == "trash":
			S.err.kept_trash += 1
			Game.say(["(이걸 유족이 받고 싶어 할까…)", "(보관함이 쓸데없이 무거워졌다.)"].pick_random(), 2.6)
		elif not S.kept.has(it.def.id):
			S.kept.append(it.def.id)
	elif it.def.kind == "keep":
		S.err.lost_keep += 1
		Game.say("(…방금 그건, 남겨 둘 걸 그랬나.)", 3.2)
	Sfx.play("keep" if keep else "trash", 0.7)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(it.root, "scale", Vector3.ONE * 0.01, 0.35)
	tw.tween_property(it.root, "position:y", it.root.position.y - 0.4, 0.35)
	var root: Node3D = it.root
	tw.chain().tween_callback(func(): root.visible = false)
	it.tw = tw
	_update_hud()
	_check_complete()


# ───────────────────────────── 보관함
func kept_items() -> Array:
	var out := []
	for id in S.sorted:
		if S.sorted[id] != "keep":
			continue
		for it in items:
			if it.def.id == id:
				out.append(it)
	return out


func trashed_items() -> Array:
	var out := []
	for id in S.sorted:
		if S.sorted[id] != "trash":
			continue
		for it in items:
			if it.def.id == id:
				out.append(it)
	return out


## 보관함이나 폐기 봉투에서 꺼내 원래 자리로 돌려놓는다
func take_out(it) -> void:
	var was: String = S.sorted.get(it.def.id, "")
	if was == "":
		return
	if it.has("tw") and it.tw.is_valid():
		it.tw.kill()
	S.sorted.erase(it.def.id)
	if was == "keep":
		S.kept.erase(it.def.id)
		if it.def.kind == "trash":
			S.err.kept_trash = max(0, S.err.kept_trash - 1)
	elif it.def.kind == "keep":
		S.err.lost_keep = max(0, S.err.lost_keep - 1)
	it.root.transform = it.base
	it.root.visible = true
	it.hidden = false
	it.state = "idle"
	it.shape.disabled = false
	# 서랍 · 문 안에서 나온 물건: 열려 있으면 열린 서랍 안으로, 닫혀 있으면 다시 열 때까지 가려 둔다
	for en in envs:
		if en.def.get("reveal", "") == it.def.id and en.def.has("anim") and en.used:
			if en.get("open", true):
				it.root.position += _reveal_offset(it)
			else:
				it.hidden = true
				it.root.visible = false
				it.shape.disabled = true
	complete = false
	_update_hud()


func _check_complete() -> void:
	var c := _counts()
	if not complete and c.sorted == c.total and c.sdone == c.stotal:
		complete = true
		Sfx.play("done", 0.6)
		Game.say("(정리가 끝났다. 현관으로 나가 작업실로 돌아가자.)", 4.5)
		_update_hud()
	if c.sorted == c.total and hidden_left() > 0 and not hint_said:
		# 보이는 물건은 다 분류했는데 열어 보지 않은 곳이 남았다: 어디인지 일러 준다 (나가도 되지만, 열어 보면 더 있다)
		hint_said = true
		var place := hidden_place()
		if place != "":
			Game.say("(눈에 보이는 건 다 분류했다. %s%s 아직 열어 보지 않았다.)" % [place, _obj_particle(place)], 4.6)
		else:
			Game.say("(눈에 보이는 건 다 분류했는데… 아직 열어 보지 않은 곳이 있다.)", 4.2)


## 아직 찾지 못한(숨은 채로 남은) 물건 수
func hidden_left() -> int:
	var n := 0
	for it in items:
		if it.hidden and it.state != "gone" and S.sorted.get(it.def.id, "") == "" and not _env_opened_for(it):
			n += 1
	return n


func _env_opened_for(it) -> bool:
	for en in envs:
		if en.def.get("reveal", "") == it.def.id and en.used:
			return true
	return false


## 숨은 물건이 들어 있는 곳의 이름 (아직 열지 않은 서랍 · 장롱 · 가방)
func hidden_place() -> String:
	for it in items:
		if it.hidden and it.state != "gone" and not _env_opened_for(it):
			for en in envs:
				if en.def.get("reveal", "") == it.def.id:
					return str(en.def.name)
	return ""


## 받침에 따라 '을/를'
static func _obj_particle(word: String) -> String:
	if word == "":
		return "를"
	var c := word.unicode_at(word.length() - 1)
	if c < 0xAC00 or c > 0xD7A3:
		return "를"
	return "을" if (c - 0xAC00) % 28 != 0 else "를"


static func _subj_particle(word: String) -> String:
	if word == "":
		return "가"
	var c := word.unicode_at(word.length() - 1)
	if c < 0xAC00 or c > 0xD7A3:
		return "가"
	return "이" if (c - 0xAC00) % 28 != 0 else "가"


func _stain_done(st: Stain) -> void:
	S.stains[st.def.id] = 1
	Game.toast(st.def.name + " 제거 완료")
	Sfx.play("done", 0.5)
	_update_hud()
	_check_complete()


func use_env(en) -> void:
	var d: Dictionary = en.def
	# 한 번 연 서랍 · 문은 다시 닫고 열 수 있다
	if en.used and d.has("anim"):
		_swing_env(en, not en.get("open", true))
		return
	Game.note(d.name, d.text)
	Sfx.play("click", 0.6)
	if d.has("clue"):
		Game.add_clue(d.clue)
	if not en.used:
		if d.has("anim"):
			en.base = {}
			for a in d.anim:
				var o := find_child(a.name, true, false) as Node3D
				if o:
					en.base[a.name] = [o.position, o.rotation.y]
			_swing_env(en, true, true)
		if d.has("reveal"):
			for it in items:
				if it.def.id == d.reveal:
					get_tree().create_timer(0.4).timeout.connect(func():
						if not en.get("open", true):
							return
						it.hidden = false
						it.root.visible = true
						it.shape.disabled = false
						if complete and it.state != "gone":
							complete = false
						_update_hud())
		if d.has("reveal") and not d.has("anim"):
			en.disabled = true
			en.shape.disabled = true
	if d.has("toggleLight"):
		for L in lights:
			if L.name == d.toggleLight:
				L.on = not L.on
				L.light.light_energy = L.base if L.on else 0.0
				var ring := find_child("ring", true, false) as MeshInstance3D
				if ring:
					(ring.material_override as StandardMaterial3D).emission_energy_multiplier = 2.0 if L.on else 0.0
		Sfx.play("switch", 0.7)
	en.used = true


## 서랍 · 문을 열거나 닫는다. 안에서 나온 물건을 아직 집지 않았으면 닫을 때 같이 가려진다
func _swing_env(en, open: bool, first := false) -> void:
	var d: Dictionary = en.def
	en.open = open
	Sfx.play("drawer", 0.8 if open else 0.6, 1.0 if open else 0.85)
	for a in d.anim:
		var o := find_child(a.name, true, false) as Node3D
		if o == null or not en.base.has(a.name):
			continue
		var b: Array = en.base[a.name]
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if a.has("move"):
			tw.tween_property(o, "position", b[0] + (Vector3(a.move[0], a.move[1], a.move[2]) if open else Vector3.ZERO), 0.7 if open else 0.5)
		if a.has("rotY"):
			tw.tween_property(o, "rotation:y", b[1] + (deg_to_rad(a.rotY) if open else 0.0), 0.8 if open else 0.6)
	# 서랍 안에서 나온 물건은 아직 집지 않았으면 서랍과 함께 나오고 들어간다
	if d.has("reveal"):
		for it in items:
			if it.def.id == d.reveal and it.state == "idle" and S.sorted.get(it.def.id, "") == "":
				create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(it.root, "position", it.base.origin + _reveal_offset(it, open), 0.7 if open else 0.5)
	if first:
		return
	Game.note(d.name, "다시 열었다." if open else "닫았다.")
	if d.has("reveal"):
		for it in items:
			if it.def.id == d.reveal and it.state == "idle" and S.sorted.get(it.def.id, "") == "":
				it.hidden = not open
				it.shape.disabled = not open
				if open:
					get_tree().create_timer(0.35).timeout.connect(func(): it.root.visible = not it.hidden)
				else:
					it.root.visible = false


## 서랍에서 나온 물건이 서랍과 함께 움직인 거리 (열린 서랍의 앞으로 빠진 만큼)
func _reveal_offset(it, open := true) -> Vector3:
	if not open:
		return Vector3.ZERO
	for en in envs:
		if en.def.get("reveal", "") == it.def.id and en.def.has("anim"):
			for a in en.def.anim:
				if a.has("move"):
					return Vector3(a.move[0], a.move[1], a.move[2]).rotated(Vector3.UP, _furn_rot(a.name))
	return Vector3.ZERO


## 움직이는 가구 부품이 놓인 가구의 방향 (서랍이 앞으로 빠지는 방향을 방 좌표로 바꿀 때)
func _furn_rot(part: String) -> float:
	var o := find_child(part, true, false) as Node3D
	if o == null or o.get_parent() == null:
		return 0.0
	var p := o.get_parent() as Node3D
	return p.global_rotation.y if p else 0.0


func try_exit() -> void:
	var c := _counts()
	if not complete:
		var parts := []
		if c.sdone < c.stotal:
			parts.append("얼룩 %d곳" % (c.stotal - c.sdone))
		if c.sorted < c.total:
			parts.append("미분류 %d개" % (c.total - c.sorted))
		Game.say("(아직 끝나지 않았다 — %s)" % ", ".join(parts), 2.8)
		Sfx.play("error", 0.6)
		return
	if exiting:
		return
	exiting = true
	using = false
	var auto := []
	for it in items:
		if it.state != "gone" and it.hidden and not _env_opened_for(it) and it.def.kind != "trash":
			it.state = "gone"
			S.sorted[it.def.id] = "keep"
			if not S.kept.has(it.def.id):
				S.kept.append(it.def.id)
			auto.append(it)
	for it in auto:
		var place := ""
		for en in envs:
			if en.def.get("reveal", "") == it.def.id:
				place = str(en.def.name)
		if place != "":
			Game.say("(나가기 전에 %s%s 열어 보니 %s%s 있었다. 챙겨 간다.)" % [place, _obj_particle(place), it.def.name, _subj_particle(it.def.name)], 4.6)
	Sfx.play("door", 0.9)
	var s := 0.0
	for st in stains:
		s += 1.0 if st.done else st.progress
	S.clean_pct = s / max(1, stains.size())
	Game.finish_room()


# ───────────────────────────── 갱신
func _physics_process(dt: float) -> void:
	if preview:
		_preview_cam(dt)
		return
	if Game.paused or exiting:
		spray_fx.emitting = false
		return
	t += dt
	S.t1 += dt
	var inp := Vector2.ZERO
	if true:
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			inp.y += 1
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			inp.y -= 1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			inp.x += 1
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			inp.x -= 1
	inp += Vector2(tmove.x, -tmove.y)
	inp = inp.limit_length(1.0)
	if Game.touch and using and tool == 3 and card == null:
		scrub_motion += 700.0 * dt
	player.rotation.y = yaw
	head.rotation.x = pitch
	var b := player.global_transform.basis
	var hold_key := Input.is_physical_key_pressed(KEY_C) or (not OS.has_feature("web") and Input.is_physical_key_pressed(KEY_CTRL))
	var want_crouch: bool = crouch_toggle or (Game.settings.get("crouch_hold", true) and hold_key)
	crouch = move_toward(crouch, 1.0 if want_crouch else 0.0, dt * 5.0)
	var target := (-b.z * inp.y + b.x * inp.x) * WALK * (1.0 - 0.45 * crouch)
	target.y = 0
	player.velocity = player.velocity.lerp(target, min(1.0, dt * 10.0))
	player.move_and_slide()
	player.position.y = 0
	moving = Vector2(player.velocity.x, player.velocity.z).length()
	if moving > 0.2:
		# 한 걸음(STRIDE)마다 머리가 한 번 오르내린다
		bob += dt * moving * PI / STRIDE
		var n := int(bob / PI)
		if n != step_n:
			step_n = n
			Sfx.step()
	var low: float = lerp(eye, max(0.85, eye - 0.62), crouch)
	var sway_on: float = (1.0 if Game.settings.get("bob", true) else 0.0) * min(1.0, moving / WALK)
	head.position.y = low - NECK_UP + (absf(sin(bob)) - 0.64) * 0.022 * sway_on
	head.position.x = sin(bob) * 0.008 * sway_on
	var side_v: float = player.velocity.dot(b.x) / WALK
	roll = lerpf(roll, (-side_v * 0.012 + sin(bob) * 0.0035) * (1.0 if Game.settings.get("bob", true) else 0.0), min(1.0, dt * 8.0))
	cam.rotation.z = roll
	if card != null and card.liftable:
		var tgt: Vector3 = cam.global_transform * Vector3(0, -0.05, -0.5)
		card.root.global_position = card.root.global_position.lerp(tgt, min(1.0, dt * 12.0))
		card.root.rotate_y(dt * 0.6)
	_raycast()
	var spray_on := 0.0
	var scrub_on := 0.0
	spray_fx.emitting = using and tool == 2 and card == null
	if using and card == null:
		if tool == 2:
			spray_on = 0.25
			if stain_aim != null and stain_aim.dist < 3.0:
				var st: Stain = stain_aim.obj
				st.spray(st.uv_of(stain_aim.pos), 0.09 + 0.06 * stain_aim.dist, dt)
				if st.update_progress():
					_stain_done(st)
		elif tool == 3:
			if stain_aim != null and stain_aim.dist < 2.3:
				var st: Stain = stain_aim.obj
				var motion: float = min(1.0, scrub_motion / (dt * 900.0 + 1.0))
				var f := st.scrub(st.uv_of(stain_aim.pos), dt, motion)
				if st.update_progress():
					_stain_done(st)
				scrub_on = 0.2 + motion * 0.25
				if f < 0.08 and not no_foam_warned.has(st.def.id) and st.progress < 0.5:
					no_foam_warned[st.def.id] = true
					Game.say("(잘 안 닦인다. 분무기로 소독약을 먼저 뿌리자.)" if Game.touch else "(잘 안 닦인다. [2] 소독약을 먼저 뿌리자.)", 2.6)
	scrub_motion = 0.0
	Sfx.set_loop("spray", spray_on)
	Sfx.set_loop("scrub", scrub_on)
	for st in stains:
		st.tick(dt)
	_update_flies(dt)
	_update_lights()
	var c := _counts()
	var e := world_env.environment
	e.fog_density = float(R.fog[1]) * 0.5 * (0.4 + 0.6 * (1.0 - c.avg))
	e.volumetric_fog_density = 0.025 * (0.35 + 0.65 * (1.0 - c.avg))
	var period := 3.1 if using else 4.3
	breath_t += dt
	if breath_t >= period:
		breath_t = 0.0
		breath_stage = 0
	var ph := breath_t / period
	var strength: float = 0.3 + (1.0 - c.avg) * 0.5
	if breath_stage == 0:
		breath_stage = 1
		Sfx.breath(strength, true)
	elif breath_stage == 1 and ph >= 0.5:
		breath_stage = 2
		Sfx.breath(strength, false)
	H_.vignette.modulate.a = 0.82 + 0.18 * (0.5 + 0.5 * sin(ph * TAU - PI / 2))
	_tick_outside(dt)
	_update_tools(dt)
	_update_prompt()


## 손으로 집을 때 한가운데가 살짝 비껴가면 둘레(약 1.5° · 2.5°)도 살핀다
const AIM_ASSIST := [Vector2(0.025, 0), Vector2(-0.025, 0), Vector2(0, 0.025), Vector2(0, -0.025), Vector2(0.045, 0), Vector2(-0.045, 0), Vector2(0, 0.045), Vector2(0, -0.045)]


func _raycast() -> void:
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 3.2
	_stain_target()
	aim = _aim_ray(from, to)
	# 작은 물건을 겨누다 살짝 비껴가도 E · 클릭이 헛돌지 않게, 가까운 물건 · 서랍 · 문을 잡는다
	if tool == 1 and card == null and (aim == null or not (aim.type in ["item", "env", "door"])):
		var b := cam.global_transform.basis
		for o in AIM_ASSIST:
			var dir: Vector3 = (-b.z + b.x * o.x + b.y * o.y).normalized()
			var a2 = _aim_ray(from, from + dir * 3.2)
			if a2 != null and a2.type in ["item", "env", "door"]:
				aim = a2
				break


func _aim_ray(from: Vector3, to: Vector3):
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, RAY_MASK))
	if hit.is_empty():
		return null
	# 가구는 겉모양을 감싼 상자로 막는다. 이불 위 다이어리처럼 그 상자에 살짝 묻힌 물건도
	# 겨눈 곳 바로 뒤(8cm 안)에 있으면 집을 수 있다
	if not hit.collider.has_meta("ref"):
		var h2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, L_ITEM))
		if not h2.is_empty() and from.distance_to(h2.position) - from.distance_to(hit.position) < 0.08:
			hit = h2
	# 서랍 · 장롱을 조사하는 범위(보이지 않는 공) 안이나 바로 뒤에 물건이 있으면 물건을 먼저 잡는다
	# (열어 둔 자개장 안의 자개함을 집으려다 문이 닫히던 문제)
	if hit.collider.has_meta("ref") and hit.collider.get_meta("ref").type == "env":
		var h3 := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, RAY_MASK & ~L_ENV))
		if not h3.is_empty() and not h3.collider.has_meta("ref"):
			var h4 := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, L_ITEM))
			if not h4.is_empty() and from.distance_to(h4.position) - from.distance_to(h3.position) < 0.08:
				h3 = h4
		if not h3.is_empty() and h3.collider.has_meta("ref") and h3.collider.get_meta("ref").type == "item":
			hit = h3
	var dist := from.distance_to(hit.position)
	if hit.collider.has_meta("ref"):
		var ref: Dictionary = hit.collider.get_meta("ref")
		if ref.type == "stain" and ref.obj.dead:
			return null
		return {"type": ref.type, "obj": ref.get("obj"), "dist": dist, "pos": hit.position}
	return {"type": "solid", "obj": null, "dist": dist, "pos": hit.position}


## 분무기 · 스크러버가 닿는 얼룩. 물건은 통과하고 벽 · 가구에서는 멈춘다.
## 얼룩 판 위나 가장자리에서 9cm 안쪽을 겨누면 그 얼룩으로 본다.
func _stain_target() -> void:
	stain_aim = null
	var from := cam.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from - cam.global_transform.basis.z * 3.2, L_SOLID | L_STAIN)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var pos: Vector3 = hit.position
	var best = null
	var best_d := 1e9
	for st in stains:
		if st.dead or st.done:
			continue
		var l: Vector3 = st.node.to_local(pos)
		if abs(l.y) > 0.05 or abs(l.x) > st.w * 0.5 + 0.09 or abs(l.z) > st.h * 0.5 + 0.09:
			continue
		var d2: float = Vector2(max(0.0, abs(l.x) - st.w * 0.5), max(0.0, abs(l.z) - st.h * 0.5)).length() + abs(l.y)
		if d2 < best_d:
			best_d = d2
			best = st
	if best != null:
		stain_aim = {"obj": best, "pos": pos, "dist": from.distance_to(pos)}


func _update_flies(dt: float) -> void:
	var buzz := 0.0
	for f in flies:
		var st: Stain = f.st
		if st.done:
			f.alive = max(0.0, f.alive - dt * 0.5)
		if f.alive <= 0.0:
			f.mmi.visible = false
			continue
		var c := Vector3(st.def.pos[0], st.def.pos[1], st.def.pos[2])
		var sx: float = st.w * 0.5
		var sz: float = st.h * 0.5
		var spread: float = 1.0 + (1.0 - f.alive) * 6.0
		for i in range(14):
			var p: Array = f.ph[i]
			var k: float = p[3]
			var pos := c + Vector3(sin(t * 2.1 * k + p[0]) * sx * 0.7 * spread + sin(t * 9.0 * k + p[1]) * 0.03,
				0.12 + abs(sin(t * 1.3 * k + p[1])) * 0.35 * spread,
				cos(t * 1.7 * k + p[2]) * sz * 0.7 * spread + cos(t * 8.0 * k + p[0]) * 0.03)
			f.mmi.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, t * 9.0 + i), pos))
		var d := Vector2(cam.global_position.x - c.x, cam.global_position.z - c.z).length()
		buzz = max(buzz, max(0.0, 1.0 - d / 3.2) * 0.45 * f.alive)
	Sfx.set_loop("flies", buzz)


func _update_lights() -> void:
	# 깜빡임 줄이기: 깜빡이던 전등 · 손전등을 고르게 켠다
	var calm: bool = Game.settings.get("calm", false)
	for L in lights:
		if L.flicker and L.on:
			if calm:
				L.light.light_energy = L.base * 0.85
			else:
				var f := sin(t * 13.0) + sin(t * 31.7) + sin(t * 3.3)
				L.light.light_energy = 0.0 if f > 2.1 else L.base * (0.2 if randf() < 0.02 else 1.0)
	if flash_on:
		flash.light_energy = FLASH_E * (0.3 if randf() < 0.004 and not calm else 1.0)


## 2장 창밖: 이따금 사람들의 다리가 지나간다 (두 걸음 그림을 번갈아)
func _tick_outside(dt: float) -> void:
	for wk in walkers:
		if wk.wait > 0.0:
			wk.wait -= dt
			wk.n.visible = false
			if wk.wait <= 0.0:
				wk.dir = 1.0 if randf() < 0.5 else -1.0
				wk.x = -wk.dir * 3.0
				wk.who = randi() % 3
				wk.sp = randf_range(1.0, 1.5)
			continue
		wk.n.visible = true
		wk.x += wk.dir * wk.sp * dt
		wk.n.position.x = wk.x
		wk.n.scale.x = wk.dir
		var stride: int = int(absf(wk.x) / 0.34) % 2
		wk.m.uv1_offset = Vector3((wk.who * 2 + stride) / 6.0, 0, 0)
		if absf(wk.x) > 3.0 and signf(wk.x) == wk.dir:
			wk.wait = randf_range(3.0, 9.0)


func _update_tools(dt: float) -> void:
	switch_t = max(0.0, switch_t - dt)
	var g: Node3D = tools.get(tool)
	if g == null:
		return
	var base: Vector3 = g.get_meta("base")
	var bb: float = min(1.0, moving)
	var p := base + Vector3(sin(bob) * 0.006 * bb, absf(cos(bob)) * 0.008 * bb - switch_t * 0.8, 0)
	if trigger != null:
		trigger.rotation.x = lerpf(trigger.rotation.x, 0.42 if using and tool == 2 and card == null else 0.0, min(1.0, dt * 22.0))
	spray_fx.position = Viewmodel.to_world(nozzle, cam.fov)
	# 뿌리기를 멈추면 조금 뒤에 입자를 치운다 (화면에 남지 않게)
	spray_t = 0.7 if using and tool == 2 and card == null else maxf(0.0, spray_t - dt)
	spray_fx.visible = spray_t > 0.0
	if using and tool == 2:
		p += Vector3(0, randf() * 0.003, 0.008 + randf() * 0.004)
	if using and tool == 3:
		p += Vector3(cos(t * 14.0) * 0.03, sin(t * 14.0) * 0.02, 0)
	if card != null:
		p.y -= 0.25
	g.position = p


# ───────────────────────────── 타이틀 배경용
## 문 쪽에 서서 방 왼쪽 끝에서 오른쪽 끝까지 훑는 범위를 정한다
func _aim_shot() -> void:
	var px := float(R.spawn[0]) * 0.55
	var pz := float(R.spawn[1])
	player.position = Vector3(px, 0, pz)
	var far_z := -D / 2.0 + 0.3
	var left := atan2(px - (-W / 2.0 + 0.25), pz - far_z)
	var right := atan2(px - (W / 2.0 - 0.25), pz - far_z)
	shot_l = maxf(left * 1.25, 0.5)
	shot_r = minf(right * 1.25, -0.5)
	shot_len = (shot_l - shot_r) / PAN_SPEED
	t = 0.0
	_preview_cam(0.0)


## 지금 보이는 장면이 끝나기까지 남은 시간
func shot_left() -> float:
	return shot_len - t


## 다음 배경 방을 화면을 멈추지 않고 조금씩 만든다. 끝나면 bg_done
func build_background(e: Dictionary, state: Dictionary) -> void:
	ep = e
	S = state
	R = e.room
	preview = true
	bg_wait = true
	W = R.size[0]
	D = R.size[1]
	H = R.size[2]
	eye = R.eye
	Build.detail = 0 if Game.settings.get("quality", "high") == "low" or Game.touch else 1
	visible = false
	set_physics_process(false)
	_bg_t = Time.get_ticks_msec()
	_build_env()
	if await _bg_pause():
		return
	_build_shell()
	for f in R.furniture:
		if await _bg_pause():
			return
		_add_furniture(f)
	if await _bg_pause():
		return
	_build_door()
	for sd in R.stains:
		if await _bg_pause():
			return
		stains.append(Stain.new(sd, self))
	for d in ep.items:
		if await _bg_pause():
			return
		_add_item(d)
	if await _bg_pause():
		return
	_build_envs()
	_build_lights()
	_build_player()
	flash.light_energy = 0.0
	bg_done = true
	if bg_cancel:
		queue_free()


## 이번 프레임 몫을 다 썼으면 다음 프레임으로 넘긴다. 취소되면 방을 치우고 true
func _bg_pause() -> bool:
	if Time.get_ticks_msec() - _bg_t >= BG_SLICE_MS or Game.title_input_recent():
		await get_tree().process_frame
		# 메뉴를 만지는 동안에는 짓지 않고 기다린다
		while Game.title_input_recent() and not bg_cancel:
			await get_tree().process_frame
		_bg_t = Time.get_ticks_msec()
	if bg_cancel:
		queue_free()
		return true
	return false


func cancel_background() -> void:
	bg_cancel = true
	if bg_done:
		queue_free()


## 다 만든 방을 화면에 내보낸다
func show_background() -> void:
	bg_wait = false
	visible = true
	add_child(world_env)
	cam.make_current()
	set_physics_process(true)
	t = 0.0
	_preview_cam(0.0)


func _preview_cam(dt: float) -> void:
	t += dt
	# 왼쪽에서 오른쪽으로 일정하게 돈다. 다음 방이 늦으면 조금 더 돈다
	player.rotation.y = lerpf(shot_l, shot_r, minf(t / shot_len, 1.25))
	head.rotation.x = -0.13 + sin(t * 0.32) * 0.008
	_tick_outside(dt)
	_update_lights()
	for st in stains:
		st.tick(dt)
