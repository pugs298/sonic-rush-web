extends Node3D
## Extra open-zone spectacle, built from original low-cost procedural meshes.
## Inspired by broad adventure vistas and speed-platformer readability, not any specific game.

var _materials: Dictionary = {}
var _animated: Array[Node3D] = []
var _floaters: Array[Dictionary] = []
var _time := 0.0

func _ready() -> void:
	call_deferred("_build_expansion")

func _process(delta: float) -> void:
	_time += delta
	for item in _animated:
		if is_instance_valid(item):
			item.rotate_y(delta * 0.32)
	for item in _floaters:
		var node: Node3D = item.node
		if is_instance_valid(node):
			var p: Vector3 = item.origin
			p.y += sin(_time * float(item.rate) + float(item.phase)) * 0.16
			node.position = p

func _build_expansion() -> void:
	# Strong silhouettes establish a larger world beyond the playable garden.
	_add_horizon_islands()
	_add_wayfinder_monoliths()
	_add_ancient_wind_rings()
	_add_aerial_wind_ribbons()
	_add_route_gates()
	_add_rock_spires()
	_add_sky_glyphs()
	_add_floating_seed_lights()
	_add_cloud_banks()

func _mat(color: Color, glow := false, transparent := false) -> StandardMaterial3D:
	var key := color.to_html() + str(glow) + str(transparent)
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.78
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.75
	_materials[key] = m
	return m

func _add_mesh(mesh: Mesh, position: Vector3, color: Color, scale_value := Vector3.ONE, rotation := Vector3.ZERO, glow := false, transparent := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.scale = scale_value
	instance.rotation = rotation
	instance.material_override = _mat(color, glow, transparent)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func _box(position: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(mesh, position, color, Vector3.ONE, rotation)

func _add_horizon_islands() -> void:
	var islands := [
		[Vector3(-35, 7, -22), Vector3(14, 5, 15)],
		[Vector3(32, 10, -39), Vector3(17, 7, 18)],
		[Vector3(-39, 13, -62), Vector3(18, 8, 17)],
		[Vector3(39, 9, -83), Vector3(16, 6, 18)],
		[Vector3(-28, 17, -111), Vector3(20, 9, 20)],
		[Vector3(26, 15, -124), Vector3(22, 10, 21)]
	]
	for idx in range(islands.size()):
		var place: Vector3 = islands[idx][0]
		var size: Vector3 = islands[idx][1]
		var cap := SphereMesh.new()
		cap.radius = 1.0
		_add_mesh(cap, place, Color("#658b75"), Vector3(size.x * 0.5, size.y * 0.24, size.z * 0.5))
		var underside := PrismMesh.new()
		underside.size = Vector3(size.x * 0.88, size.y * 1.2, size.z * 0.82)
		_add_mesh(underside, place + Vector3(0, -size.y * 0.55, 0), Color("#786b58"), Vector3.ONE, Vector3(0, float(idx) * 0.3, 0))
		# Tiny temple silhouette is only a landmark, not a traversable object.
		var tower := CylinderMesh.new()
		tower.top_radius = 0.45
		tower.bottom_radius = 0.8
		tower.height = 3.2 + float(idx % 3)
		_add_mesh(tower, place + Vector3(0, size.y * 0.26 + 2.0, 0), Color("#c5ad7b"))
		var crown := TorusMesh.new()
		crown.inner_radius = 1.0
		crown.outer_radius = 1.16
		var crown_node := _add_mesh(crown, place + Vector3(0, size.y * 0.26 + 3.6, 0), Color("#65dfcc"), Vector3(1.0, 1.0, 1.0), Vector3(PI * 0.5, 0, 0), true)
		_animated.append(crown_node)

func _add_wayfinder_monoliths() -> void:
	var positions := [Vector3(-12, 0.1, -8), Vector3(12, 0.1, -25), Vector3(-11, 0.0, -55), Vector3(11, 0.2, -74), Vector3(0, 0.3, -88)]
	for i in range(positions.size()):
		var p: Vector3 = positions[i]
		var shaft := PrismMesh.new()
		shaft.size = Vector3(0.75, 4.0 + float(i % 2), 0.75)
		_add_mesh(shaft, p + Vector3(0, 2.0, 0), Color("#9f8967"), Vector3.ONE, Vector3(0, float(i) * 0.24, 0))
		var cap := BoxMesh.new()
		cap.size = Vector3(1.3, 0.24, 1.3)
		_add_mesh(cap, p + Vector3(0, 4.1 + float(i % 2), 0), Color("#d4bd86"))
		var rune := BoxMesh.new()
		rune.size = Vector3(0.12, 1.6, 0.08)
		_add_mesh(rune, p + Vector3(0, 2.2, -0.39), Color("#65dfcc"), Vector3.ONE, Vector3.ZERO, true)
		var base := TorusMesh.new()
		base.inner_radius = 0.62
		base.outer_radius = 0.78
		_add_mesh(base, p + Vector3(0, 0.12, 0), Color("#d9b866"), Vector3.ONE, Vector3(PI * 0.5, 0, 0))

func _add_ancient_wind_rings() -> void:
	# Landmark-sized vertical rings frame key route changes and echo the game's wind motif.
	var placements := [
		[Vector3(0, 4.5, -20), 5.3],
		[Vector3(2, 4.6, -45), 4.2],
		[Vector3(0, 5.0, -80), 5.7]
	]
	for item in placements:
		var p: Vector3 = item[0]
		var radius: float = item[1]
		var hoop := TorusMesh.new()
		hoop.inner_radius = radius - 0.16
		hoop.outer_radius = radius
		var hoop_node := _add_mesh(hoop, p, Color("#65dfcc"), Vector3.ONE, Vector3(PI * 0.5, 0, 0), true)
		_animated.append(hoop_node)
		var inner := TorusMesh.new()
		inner.inner_radius = radius - 0.32
		inner.outer_radius = radius - 0.27
		_add_mesh(inner, p, Color("#e9d39a"), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		for tick in range(8):
			var angle := TAU * float(tick) / 8.0
			var jewel := SphereMesh.new()
			jewel.radius = 0.16
			_add_mesh(jewel, p + Vector3(cos(angle) * radius, sin(angle) * radius, 0), Color("#f5ae51"), Vector3.ONE, Vector3.ZERO, true)

func _add_aerial_wind_ribbons() -> void:
	# Broken translucent strips suggest wind currents without particles or expensive shader effects.
	var paths := [
		[Vector3(-14, 3.8, -8), Vector3(-9, 6.5, -18), Vector3(-3, 7.0, -29)],
		[Vector3(14, 4.8, -32), Vector3(9, 7.4, -43), Vector3(2, 6.2, -55)],
		[Vector3(-14, 7.5, -60), Vector3(-8, 9.0, -73), Vector3(0, 8.0, -84)]
	]
	for path in paths:
		for segment in range(path.size() - 1):
			var a: Vector3 = path[segment]
			var b: Vector3 = path[segment + 1]
			var delta := b - a
			var count := 8
			for i in range(count):
				var t := float(i) / float(count)
				var p := a.lerp(b, t)
				var streak := BoxMesh.new()
				streak.size = Vector3(0.09, 0.09, maxf(0.4, delta.length() / float(count) * 0.78))
				var node := _add_mesh(streak, p, Color(0.57, 0.96, 0.88, 0.64), Vector3.ONE, Vector3(0, atan2(delta.x, delta.z), -0.22), true, true)
				if i % 2 == 0:
					_floaters.append({"node": node, "origin": p, "rate": 0.7 + float(segment) * 0.15, "phase": float(i) * 0.5})

func _add_route_gates() -> void:
	var gates := [Vector3(-5.4, 2.2, -7), Vector3(5.4, 2.0, -38), Vector3(-5.4, 2.3, -68)]
	for p in gates:
		for side in [-1.0, 1.0]:
			var post := CylinderMesh.new()
			post.top_radius = 0.12
			post.bottom_radius = 0.22
			post.height = 4.4
			_add_mesh(post, p + Vector3(side * 4.8, 0, 0), Color("#b39a70"))
			var marker := SphereMesh.new()
			marker.radius = 0.28
			_add_mesh(marker, p + Vector3(side * 4.8, 2.1, 0), Color("#f5ae51"), Vector3.ONE, Vector3.ZERO, true)
		var lintel := BoxMesh.new()
		lintel.size = Vector3(9.8, 0.32, 0.42)
		_add_mesh(lintel, p + Vector3(0, 2.0, 0), Color("#d5c18c"))
		var band := BoxMesh.new()
		band.size = Vector3(7.5, 0.08, 0.5)
		_add_mesh(band, p + Vector3(0, 1.78, -0.01), Color("#65dfcc"), Vector3.ONE, Vector3.ZERO, true)

func _add_rock_spires() -> void:
	var placements := [Vector3(-16, -1.5, -16), Vector3(16, -1.8, -33), Vector3(-16, -1.6, -50), Vector3(15, -1.6, -67), Vector3(-17, -1.8, -88)]
	for i in range(placements.size()):
		var p: Vector3 = placements[i]
		for rock_index in range(4):
			var shard := PrismMesh.new()
			shard.size = Vector3(1.0 + float(rock_index % 2) * 0.45, 3.0 + float((i + rock_index) % 3) * 1.2, 1.1)
			var offset := Vector3((float(rock_index) - 1.5) * 0.8, -0.5, float(rock_index % 2) * 0.8)
			_add_mesh(shard, p + offset, Color("#766b59"), Vector3.ONE, Vector3(0.0, float(rock_index) * 0.42, 0.08 * float(rock_index % 2)))

func _add_sky_glyphs() -> void:
	# A few distant floating glyphs make the ancient wind network visible against the sky.
	for item in [[Vector3(-23, 12, -30), 2.4], [Vector3(24, 13, -57), 3.2], [Vector3(-22, 16, -92), 2.8]]:
		var p: Vector3 = item[0]
		var r: float = item[1]
		var hoop := TorusMesh.new()
		hoop.inner_radius = r - 0.08
		hoop.outer_radius = r
		var node := _add_mesh(hoop, p, Color("#f5ae51"), Vector3.ONE, Vector3(PI * 0.5, 0, 0), true)
		_animated.append(node)
		var vertical := BoxMesh.new()
		vertical.size = Vector3(0.08, r * 1.5, 0.08)
		_add_mesh(vertical, p, Color("#d7e9c9"), Vector3.ONE, Vector3.ZERO, true)

func _add_floating_seed_lights() -> void:
	for i in range(18):
		var z := -5.0 - float(i) * 4.9
		var side := -1.0 if i % 2 == 0 else 1.0
		var p := Vector3(side * (8.5 + float(i % 3) * 1.2), 2.0 + float(i % 4) * 0.65, z)
		var seed := PrismMesh.new()
		seed.size = Vector3(0.2, 0.42, 0.2)
		var node := _add_mesh(seed, p, Color("#ffe08b"), Vector3.ONE, Vector3(0, float(i), 0), true)
		_floaters.append({"node": node, "origin": p, "rate": 0.65 + float(i % 4) * 0.1, "phase": float(i) * 0.61})

func _add_cloud_banks() -> void:
	# Layered cloud silhouettes sit below and behind the traversable island network.
	for cluster in [Vector3(-29, -7, -28), Vector3(30, -8, -55), Vector3(-31, -8, -88), Vector3(29, -6, -108)]:
		for i in range(5):
			var puff := SphereMesh.new()
			puff.radius = 1.0
			var offset := Vector3((float(i) - 2.0) * 2.0, sin(float(i) * 0.9) * 0.6, cos(float(i) * 0.7) * 1.2)
			_add_mesh(puff, cluster + offset, Color("#d7eee6"), Vector3(2.2, 0.65, 1.5))
