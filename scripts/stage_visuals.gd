extends Node3D
## Procedural low-poly set dressing for the floating-island route.
## Decorations are mesh-only, share materials, disable shadows and use no runtime lights.

var _materials: Dictionary = {}
var _wind_rotors: Array[Node3D] = []
var _time := 0.0

func _ready() -> void:
	call_deferred("_dress_world")

func _process(delta: float) -> void:
	_time += delta
	for rotor in _wind_rotors:
		if is_instance_valid(rotor):
			rotor.rotation.z = _time * 0.8

func _dress_world() -> void:
	var root := get_parent()
	if root == null or root.get_node_or_null("OvergrowthIsland") == null:
		return
	_add_garden_beds()
	_add_path_accents()
	_add_wind_arches()
	_add_wind_turbines()
	_add_cliff_details()
	_add_cloud_islets()
	_add_ruined_waystations()
	_add_crystal_gardens()
	_add_waterfall_ribbons()
	_add_ambient_route_lanterns()
	_add_wind_banners()
	_add_grotto_details()

func _material(key: String, color: Color, glow := false, transparent := false) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.8
	_materials[key] = material
	return material

func _mesh(mesh: Mesh, at: Vector3, color: Color, size: Vector3 = Vector3.ONE, rotation := Vector3.ZERO, glow := false, transparent := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.scale = size
	instance.rotation = rotation
	instance.material_override = _material(color.to_html() + str(glow) + str(transparent), color, glow, transparent)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func _box(at: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(mesh, at, color, Vector3.ONE, rotation)

func _add_garden_beds() -> void:
	var plants := [
		Vector3(-6, 0.05, 5), Vector3(6, 0.05, 4), Vector3(-6, 0.05, -5), Vector3(5, 0.05, -9),
		Vector3(-5, 0.1, -18), Vector3(7, 0.1, -21), Vector3(-4, 0.0, -29), Vector3(6, 0.0, -34),
		Vector3(-6, -0.1, -44), Vector3(5, -0.1, -51), Vector3(-5, 0.1, -62), Vector3(5, 0.1, -69),
		Vector3(-6, 0.3, -77), Vector3(6, 0.3, -84), Vector3(-8, -3.8, -35), Vector3(-5, -2.8, -48),
		Vector3(-10, 2.8, -14), Vector3(-10, 4.7, -25), Vector3(-6, 5.8, -37), Vector3(7, 3.9, -51)
	]
	for i in range(plants.size()):
		_add_plant(plants[i], i)
	# Small stone-edged beds break up long flat grass surfaces and make route edges legible.
	for bed in [Vector3(-6.5, 0.04, -2), Vector3(6.6, 0.04, -7), Vector3(-4.8, 0.1, -25), Vector3(5.2, 0.1, -38), Vector3(5.2, 0.15, -73)]:
		_box(bed, Vector3(2.2, 0.10, 1.1), Color("#9b805b"), Vector3(0, 0.28, 0))
		for i in range(3):
			var tuft := SphereMesh.new()
			tuft.radius = 0.24
			_mesh(tuft, bed + Vector3(-0.55 + float(i) * 0.55, 0.22, 0), Color("#4a9860"), Vector3(1.4, 0.55, 1.0))
	# Stone fragments and scattered seed pods add scale without collision or shadows.
	for i in range(24):
		var z := -float(i) * 3.4 - 2.0
		var side := -1.0 if i % 2 == 0 else 1.0
		var pebble := PrismMesh.new()
		pebble.size = Vector3(0.26 + float(i % 3) * 0.08, 0.18, 0.22)
		_mesh(pebble, Vector3(side * (6.2 + float(i % 3) * 0.45), 0.04, z), Color("#a5906d"), Vector3.ONE, Vector3(0, float(i) * 0.4, 0))

func _add_plant(at: Vector3, index: int) -> void:
	var greens := [Color("#2f8059"), Color("#4a9860"), Color("#7aa64e")]
	var stem := CylinderMesh.new()
	stem.top_radius = 0.035
	stem.bottom_radius = 0.055
	stem.height = 0.55
	_mesh(stem, at + Vector3(0, 0.28, 0), Color("#396d49"))
	for leaf_index in range(3):
		var leaf := SphereMesh.new()
		leaf.radius = 0.22
		var angle := float(leaf_index) * TAU / 3.0 + float(index) * 0.37
		var offset := Vector3(cos(angle) * 0.2, 0.43 + float(leaf_index % 2) * 0.08, sin(angle) * 0.2)
		_mesh(leaf, at + offset, greens[(index + leaf_index) % greens.size()], Vector3(1.0, 0.62, 1.25), Vector3(0, -angle, 0))
	if index % 3 == 0:
		var bloom := SphereMesh.new()
		bloom.radius = 0.08
		_mesh(bloom, at + Vector3(0, 0.75, 0), Color("#ffcf70"), Vector3.ONE, Vector3.ZERO, true)
		for petal in range(4):
			var angle := float(petal) * TAU / 4.0
			var petal_mesh := SphereMesh.new()
			petal_mesh.radius = 0.055
			_mesh(petal_mesh, at + Vector3(cos(angle) * 0.11, 0.75, sin(angle) * 0.11), Color("#f4e3a0"))

func _add_path_accents() -> void:
	var segments := [
		[Vector3(0, 0.03, -3), 18.0], [Vector3(0, 0.13, -15), 15.0],
		[Vector3(2, 0.1, -31), 13.0], [Vector3(-1, 0.0, -48), 14.0],
		[Vector3(1, 0.08, -65), 13.0], [Vector3(0, 0.3, -81), 15.0]
	]
	for item in segments:
		var center: Vector3 = item[0]
		var width: float = item[1]
		_box(center + Vector3(-width * 0.38, 0.02, 0), Vector3(0.11, 0.035, 8.0), Color("#d9b866"))
		_box(center + Vector3(width * 0.38, 0.02, 0), Vector3(0.11, 0.035, 8.0), Color("#d9b866"))
		for dash_index in range(3):
			_box(center + Vector3(0, 0.035, -2.4 + dash_index * 2.4), Vector3(1.1, 0.04, 0.14), Color("#b9d88b"))
	# Amber arrowhead inlays point toward the beacon landmark.
	for marker in [Vector3(0, 0.065, -10), Vector3(1, 0.06, -27), Vector3(-1, 0.06, -61), Vector3(0, 0.35, -78)]:
		var arrow := PrismMesh.new()
		arrow.size = Vector3(0.9, 0.09, 0.68)
		_mesh(arrow, marker, Color("#f5ae51"), Vector3.ONE, Vector3(0, PI, 0), true)

func _add_wind_arches() -> void:
	for place in [Vector3(0, 0.05, -16), Vector3(2, 0.1, -32), Vector3(0, 0.2, -82)]:
		_box(place + Vector3(-5.3, 2.2, 0), Vector3(0.42, 4.4, 0.5), Color("#c9aa72"))
		_box(place + Vector3(5.3, 2.2, 0), Vector3(0.42, 4.4, 0.5), Color("#c9aa72"))
		_box(place + Vector3(0, 4.35, 0), Vector3(11.0, 0.42, 0.55), Color("#e1c987"))
		_box(place + Vector3(0, 3.98, 0), Vector3(8.7, 0.08, 0.65), Color("#65dfcc"))
		for side in [-1.0, 1.0]:
			var cap := SphereMesh.new()
			cap.radius = 0.35
			_mesh(cap, place + Vector3(side * 5.3, 4.45, 0), Color("#f5ae51"), Vector3(1.0, 0.65, 1.0), Vector3.ZERO, true)
			var rune := BoxMesh.new()
			rune.size = Vector3(0.12, 1.0, 0.12)
			_mesh(rune, place + Vector3(side * 5.3, 2.1, -0.29), Color("#65dfcc"), Vector3.ONE, Vector3.ZERO, true)

func _add_wind_turbines() -> void:
	for place in [Vector3(-7.0, 0.2, -11.0), Vector3(6.5, 0.1, -41.0), Vector3(6.0, 0.4, -77.0)]:
		var mast := CylinderMesh.new()
		mast.top_radius = 0.12
		mast.bottom_radius = 0.24
		mast.height = 4.2
		_mesh(mast, place + Vector3(0, 2.1, 0), Color("#9b815b"))
		var rotor := Node3D.new()
		rotor.position = place + Vector3(0, 4.2, 0)
		add_child(rotor)
		var hub := SphereMesh.new()
		hub.radius = 0.28
		var hub_instance := MeshInstance3D.new()
		hub_instance.mesh = hub
		hub_instance.material_override = _material("amber_hub", Color("#f5ae51"), true)
		hub_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rotor.add_child(hub_instance)
		for blade_index in range(3):
			var blade := BoxMesh.new()
			blade.size = Vector3(0.16, 1.55, 0.12)
			var blade_instance := MeshInstance3D.new()
			blade_instance.mesh = blade
			blade_instance.position.y = 0.93
			blade_instance.rotation.z = float(blade_index) * TAU / 3.0
			blade_instance.material_override = _material("wind_blade", Color("#e7d19a"))
			blade_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			rotor.add_child(blade_instance)
		_wind_rotors.append(rotor)

func _add_cliff_details() -> void:
	for place in [Vector3(-12, -3.0, -20), Vector3(12, -3.1, -44), Vector3(-12, -3.0, -69), Vector3(13, -2.8, -88)]:
		for rib in range(3):
			var rock := PrismMesh.new()
			rock.size = Vector3(1.4, 4.2 - float(rib) * 0.45, 1.0)
			var x_offset := (float(rib) - 1.0) * 1.05
			_mesh(rock, place + Vector3(x_offset, -1.6, float(rib % 2) * 1.1), Color("#806e55"), Vector3.ONE, Vector3(0, float(rib) * 0.3, 0))
	for n in range(4):
		var angle := TAU * float(n) / 4.0
		var marker := CylinderMesh.new()
		marker.top_radius = 0.18
		marker.bottom_radius = 0.25
		marker.height = 1.4
		_mesh(marker, Vector3(-8 + cos(angle) * 4.0, -3.7, -34 + sin(angle) * 5.0), Color("#b09265"))

func _add_cloud_islets() -> void:
	for place in [Vector3(-20, 7, -37), Vector3(21, 8, -72), Vector3(-20, 10, -101)]:
		for puff_index in range(3):
			var puff := SphereMesh.new()
			puff.radius = 1.0
			var offset := Vector3(float(puff_index - 1) * 1.4, sin(float(puff_index)) * 0.45, 0)
			_mesh(puff, place + offset, Color("#e0f3e8"), Vector3(1.8, 0.65, 1.1))

func _add_ruined_waystations() -> void:
	# Three small, readable ruins act as scenic chapters along the approach to the beacon.
	for place in [Vector3(-7.0, 0.1, -23.0), Vector3(7.0, 0.0, -55.0), Vector3(-6.0, 0.3, -76.0)]:
		for side in [-1.0, 1.0]:
			var pillar := PrismMesh.new()
			pillar.size = Vector3(0.75, 2.7, 0.75)
			_mesh(pillar, place + Vector3(side * 1.6, 1.35, 0), Color("#b39a70"), Vector3.ONE, Vector3(0, side * 0.12, 0))
			var capital := BoxMesh.new()
			capital.size = Vector3(1.05, 0.22, 1.05)
			_mesh(capital, place + Vector3(side * 1.6, 2.75, 0), Color("#d7c18d"))
		var lintel := BoxMesh.new()
		lintel.size = Vector3(3.9, 0.34, 0.62)
		_mesh(lintel, place + Vector3(0, 2.86, 0), Color("#d7c18d"))
		var rune := BoxMesh.new()
		rune.size = Vector3(0.16, 0.8, 0.09)
		_mesh(rune, place + Vector3(0, 2.2, -0.36), Color("#65dfcc"), Vector3.ONE, Vector3.ZERO, true)
		for side in [-1.0, 1.0]:
			var step := BoxMesh.new()
			step.size = Vector3(1.1, 0.18, 0.62)
			_mesh(step, place + Vector3(side * 0.7, 0.12, 1.0), Color("#ad936b"))

func _add_crystal_gardens() -> void:
	var beds := [Vector3(8.0, -3.85, -36.0), Vector3(-5.0, -2.75, -46.0), Vector3(8.0, 0.15, -70.0), Vector3(-8.0, 5.75, -34.0)]
	for bed_index in range(beds.size()):
		var place: Vector3 = beds[bed_index]
		for crystal_index in range(4):
			var crystal := PrismMesh.new()
			crystal.size = Vector3(0.32 + float(crystal_index % 2) * 0.12, 0.8 + float(crystal_index % 3) * 0.3, 0.32)
			var angle := float(crystal_index) * TAU / 4.0
			var offset := Vector3(cos(angle) * 0.65, 0.42 + float(crystal_index % 2) * 0.12, sin(angle) * 0.65)
			var color := Color("#65dfcc") if crystal_index % 2 == 0 else Color("#f5ae51")
			_mesh(crystal, place + offset, color, Vector3.ONE, Vector3(0, angle, 0), true)
		var ring := TorusMesh.new()
		ring.inner_radius = 0.72
		ring.outer_radius = 0.82
		_mesh(ring, place + Vector3(0, 0.04, 0), Color("#d8c38b"), Vector3.ONE, Vector3(PI * 0.5, 0, 0))

func _add_waterfall_ribbons() -> void:
	# Thin translucent turquoise falls visually connect the floating landmasses; no particle simulation.
	for place in [Vector3(-12.4, -5.3, -20.0), Vector3(12.1, -5.2, -45.0), Vector3(-12.1, -5.1, -70.0), Vector3(13.0, -5.0, -88.0)]:
		var ribbon := PlaneMesh.new()
		ribbon.size = Vector2(1.4, 5.4)
		_mesh(ribbon, place, Color(0.26, 0.86, 0.82, 0.4), Vector3.ONE, Vector3.ZERO, true, true)
		var foam := BoxMesh.new()
		foam.size = Vector3(1.5, 0.08, 0.25)
		_mesh(foam, place + Vector3(0, 2.65, 0), Color("#d9fff3"), Vector3.ONE, Vector3.ZERO, true)

func _add_ambient_route_lanterns() -> void:
	for place in [Vector3(-7.6, 0.1, -9.0), Vector3(7.2, 0.0, -29.0), Vector3(6.8, 0.1, -63.0), Vector3(-7.0, 0.2, -80.0)]:
		var post := CylinderMesh.new()
		post.top_radius = 0.07
		post.bottom_radius = 0.13
		post.height = 1.8
		_mesh(post, place + Vector3(0, 0.9, 0), Color("#806b4e"))
		var housing := SphereMesh.new()
		housing.radius = 0.28
		_mesh(housing, place + Vector3(0, 1.95, 0), Color("#f5ae51"), Vector3(1.0, 0.72, 0.72), Vector3.ZERO, true)
		var band := TorusMesh.new()
		band.inner_radius = 0.21
		band.outer_radius = 0.25
		_mesh(band, place + Vector3(0, 1.95, 0), Color("#fff0bd"), Vector3.ONE, Vector3(PI * 0.5, 0, 0), true)

func _add_wind_banners() -> void:
	for place in [Vector3(-7.4, 0.2, -17.0), Vector3(7.4, 0.2, -49.0), Vector3(-6.7, 0.3, -79.0)]:
		var pole := CylinderMesh.new()
		pole.top_radius = 0.045
		pole.bottom_radius = 0.07
		pole.height = 3.8
		_mesh(pole, place + Vector3(0, 1.9, 0), Color("#896f4f"))
		var cloth := BoxMesh.new()
		cloth.size = Vector3(1.15, 0.65, 0.08)
		_mesh(cloth, place + Vector3(0.62, 3.15, 0), Color("#e6a658"), Vector3.ONE, Vector3(0, 0, -0.06))
		var stripe := BoxMesh.new()
		stripe.size = Vector3(0.15, 0.65, 0.09)
		_mesh(stripe, place + Vector3(0.22, 3.15, -0.01), Color("#65dfcc"), Vector3.ONE, Vector3.ZERO, true)

func _add_grotto_details() -> void:
	# Cave-mouth ribs, teal crystal lights and a clear stepping-stone trail enliven the lower detour.
	for side in [-1.0, 1.0]:
		var rib := CylinderMesh.new()
		rib.top_radius = 0.18
		rib.bottom_radius = 0.3
		rib.height = 3.0
		_mesh(rib, Vector3(-8 + side * 4.4, -2.9, -34.0), Color("#8a7658"), Vector3.ONE, Vector3(0, 0, side * 0.12))
	for i in range(6):
		var pebble := SphereMesh.new()
		pebble.radius = 0.18
		var x := -8.0 + sin(float(i) * 0.8) * 1.5
		var z := -31.0 - float(i) * 2.4
		_mesh(pebble, Vector3(x, -3.92, z), Color("#c0aa7b"), Vector3(1.5, 0.35, 1.0))
	for place in [Vector3(-11.0, -3.4, -35.0), Vector3(-5.0, -2.2, -45.0)]:
		var crystal := PrismMesh.new()
		crystal.size = Vector3(0.28, 1.1, 0.3)
		_mesh(crystal, place, Color("#65dfcc"), Vector3.ONE, Vector3(0.08, 0.3, -0.1), true)
