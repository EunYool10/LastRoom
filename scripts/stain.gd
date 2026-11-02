class_name Stain
extends RefCounted
## 소독약을 뿌리고 문질러 지우는 얼룩

var def: Dictionary
var node: Node3D
var body: StaticBody3D
var gw := 48
var gh := 48
var w := 1.0
var h := 1.0
var dirt := PackedFloat32Array()
var foam := PackedFloat32Array()
var sum0 := 0.0
var img: Image
var tex: ImageTexture
var bytes := PackedByteArray()
var color := Color.BLACK
var progress := 0.0
var done := false
var dirty := true
var render_t := 0.0
var fade := 0.0
var dead := false
var foam_any := false


func _init(d: Dictionary, parent: Node3D) -> void:
	def = d
	w = d.size[0]
	h = d.size[1]
	color = Color8(int(d.color[0]), int(d.color[1]), int(d.color[2]))
	var is_text: bool = d.has("text")
	if is_text:
		gw = 112
		gh = int(round(112.0 * h / w))
	dirt.resize(gw * gh)
	foam.resize(gw * gh)
	if is_text:
		_init_text(d.get("mask", ""))
	else:
		_init_blob(int(d.get("seed", 1)))
	for i in dirt.size():
		sum0 += dirt[i]
	bytes.resize(gw * gh * 4)
	img = Image.create_empty(gw, gh, false, Image.FORMAT_RGBA8)
	tex = ImageTexture.create_from_image(img)
	node = Node3D.new()
	parent.add_child(node)
	node.position = Vector3(d.pos[0], d.pos[1], d.pos[2])
	match String(d.surf):
		"wallN": node.rotation = Vector3(PI / 2, 0, 0)
		"wallS": node.rotation = Vector3(PI / 2, PI, 0)
		"wallW": node.rotation = Vector3(PI / 2, PI / 2, 0)
		"wallE": node.rotation = Vector3(PI / 2, -PI / 2, 0)
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, h)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.25 if d.get("gloss", false) else 0.85
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)
	body = StaticBody3D.new()
	body.collision_layer = 8
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w, 0.006, h)
	cs.shape = bs
	cs.position.y = 0.003
	body.add_child(cs)
	node.add_child(body)
	body.set_meta("ref", {"type": "stain", "obj": self})
	render()


func _smooth(a: float, b: float, x: float) -> float:
	var k: float = clamp((x - a) / (b - a), 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


func _init_blob(seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7919
	var blobs := []
	var k := 5 + rng.randi() % 4
	for q in range(k):
		var spread := 0.15 if q == 0 else 0.45
		blobs.append([0.5 + (rng.randf() - 0.5) * spread, 0.5 + (rng.randf() - 0.5) * spread, 0.1 + rng.randf() * 0.17])
	for j in range(gh):
		for i in range(gw):
			var u := (i + 0.5) / gw
			var v := (j + 0.5) / gh
			var s := 0.0
			for b in blobs:
				var dx: float = (u - b[0]) / b[2]
				var dy: float = (v - b[1]) / b[2]
				s += exp(-(dx * dx + dy * dy) * 1.6)
			s += (Build.hash3(Vector3(i * 0.37, j * 0.37, seed)) - 0.5) * 0.4
			s *= min(1.0, min(min(u, 1.0 - u), min(v, 1.0 - v)) * 7.0)
			dirt[j * gw + i] = _smooth(0.3, 0.75, s)
	for q in range(14):
		var cx := rng.randi() % gw
		var cy := rng.randi() % gh
		if cx > 1 and cy > 1 and cx < gw - 2 and cy < gh - 2:
			dirt[cy * gw + cx] = max(dirt[cy * gw + cx], 0.8)
			dirt[cy * gw + cx + 1] = max(dirt[cy * gw + cx + 1], 0.5)


func _init_text(mask: String) -> void:
	var t: Texture2D = Build.tex(mask)
	var im := t.get_image()
	if im.is_compressed():
		im.decompress()
	im.resize(gw, gh, Image.INTERPOLATE_BILINEAR)
	for j in range(gh):
		for i in range(gw):
			dirt[j * gw + i] = min(1.0, im.get_pixel(i, j).a * 1.4)


func render() -> void:
	var fc := Color8(222, 238, 228)
	foam_any = false
	for i in range(gw * gh):
		var d := dirt[i]
		var f: float = min(1.0, foam[i])
		if f > 0.01:
			foam_any = true
		var k := f * 0.8
		var c := color.lerp(fc, k)
		bytes[i * 4] = int(c.r * 255.0)
		bytes[i * 4 + 1] = int(c.g * 255.0)
		bytes[i * 4 + 2] = int(c.b * 255.0)
		bytes[i * 4 + 3] = int(clamp(d * 0.96 + f * 0.5, 0.0, 1.0) * 255.0)
	img.set_data(gw, gh, false, Image.FORMAT_RGBA8, bytes)
	tex.update(img)
	dirty = false


func uv_of(world: Vector3) -> Vector2:
	var l := node.to_local(world)
	return Vector2(l.x / w + 0.5, l.z / h + 0.5)


func _cells(uv: Vector2, radius: float) -> Array:
	var out := []
	var cx := uv.x * gw
	var cy := uv.y * gh
	var rx := radius / w * gw
	var ry := radius / h * gh
	for j in range(max(0, int(floor(cy - ry))), min(gh - 1, int(ceil(cy + ry))) + 1):
		for i in range(max(0, int(floor(cx - rx))), min(gw - 1, int(ceil(cx + rx))) + 1):
			var dx := (i + 0.5 - cx) / rx
			var dy := (j + 0.5 - cy) / ry
			var q := dx * dx + dy * dy
			if q < 1.0:
				out.append([j * gw + i, 1.0 - q])
	return out


func spray(uv: Vector2, radius: float, dt: float) -> void:
	for c in _cells(uv, radius):
		foam[c[0]] = min(1.4, foam[c[0]] + dt * 2.6 * c[1])
		dirt[c[0]] = max(0.0, dirt[c[0]] - dt * 0.03 * c[1])
	dirty = true


## 반환값: 문지른 곳의 평균 거품 양
func scrub(uv: Vector2, dt: float, motion: float) -> float:
	var fsum := 0.0
	var cells := _cells(uv, 0.13)
	for c in cells:
		var i: int = c[0]
		var eff: float = (0.1 + 0.9 * min(1.0, foam[i] / 0.45)) * (0.35 + 0.65 * motion)
		dirt[i] = max(0.0, dirt[i] - dt * 1.5 * c[1] * eff)
		foam[i] = max(0.0, foam[i] - dt * 1.1 * c[1])
		fsum += foam[i]
	dirty = true
	return fsum / max(1, cells.size())


## 진행도 갱신. 막 완료되었으면 true
func update_progress() -> bool:
	var s := 0.0
	for i in dirt.size():
		s += dirt[i]
	progress = 1.0 - s / sum0 if sum0 > 0.0 else 1.0
	if not done and progress >= 0.95:
		done = true
		fade = 1.0
		return true
	return false


func tick(dt: float) -> void:
	if fade > 0.0:
		fade -= dt * 1.4
		for i in dirt.size():
			dirt[i] *= 0.9
			foam[i] *= 0.9
		dirty = true
		if fade <= 0.0:
			node.visible = false
			dead = true
			body.process_mode = Node.PROCESS_MODE_DISABLED
			for c in body.get_children():
				c.disabled = true
	elif foam_any:
		for i in foam.size():
			if foam[i] > 0.0:
				foam[i] = max(0.0, foam[i] - dt * 0.025)
		dirty = true
	render_t -= dt
	if dirty and render_t <= 0.0:
		render()
		render_t = 0.06
