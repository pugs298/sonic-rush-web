extends Node3D
## Lightweight procedural set dressing for the floating-island route.
## Decorations are mesh-only, use shared materials, and add no physics bodies.

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
	var plants := [
		Vector3(-6, 0.05, 5), Vector3(6, 0.05, 4), Vector3(-6, 0.05, -5), Vector3(5, 0.05, -9),
		Vector3(-5, 0.1, -18), Vector3(7, 0.1, -21), Vector3(-4, 0.0, -29), Vector3(6, 0.0, -34),
		Vector3(-6, -0.1, -44), Vector3(5, -0.1, -51), Vector3(-5, 0.1, -62), Vector3(5, 0.1, -69),
		Vector3(-6, 0.3, -77), Vector3(6, 0.3, -84), Vector3(-8, -3.8, -35), Vector3(-5, -2.8, -48),
		Vector3(-10, 2.8, -14), Vector3(-10, 4.7, -25), Vector3(-6, 5.8, -37), Vector3(7, 3.9, -51)
	]
	for i in range(plants.size()):
		_add_plant(plants[i], i)
	_add_path_accents()
	_add_wind_arches()
	_add_wind_turbines()
	_add_cliff_details()
	_add_cloud_islets()

func _material(key: String, color: Color, glow := false) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.8
	_materials[key] = material
	return material

func _mesh(mesh: Mesh, at: Vector3, color: Color, size: Vector3 = Vector3.ONE, rotation := Vector3.ZERO, glow := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.scale = size
	instance.rotation = rotation
	instance.material_override = _material(color.to_html() + str(glow), color, glow)
	add_child(instance)
	return instance

func _box(at: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(mesh, at, color, Vector3.ONE, rotation)

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
		var leaf_mesh := _mesh(leaf, at + offset, greens[(index + leaf_index) % greens.size()], Vector3(1.0, 0.62, 1.25), Vector3(0, -angle, 0))
		leaf_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if index % 3 == 0:
		var bloom := SphereMesh.new()
		bloom.radius = 0.08
		_mesh(bloom, at + Vector3(0, 0.75, 0), Color("#ffcf70"), Vector3.ONE, Vector3.ZERO, true)

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

func _add_wind_arches() -> void:
	for place in [Vector3(0, 0.05, -16), Vector3(2, 0.1, -32), Vector3(0, 0.2, -82)]:
		_box(place + Vector3(-5.3, 2.2, 0), Vector3(0.42, 4.4, 0.5), Color("#c9aa72"))
		_box(place + Vector3(5.3, 2.2, 0), Vector3(0.42, 4.4, 0.5), Color("#c9aa72"))
		_box(place + Vector3(0, 4.35, 0), Vector3(11.0, 0.42, 0.55), Color("#e1c987"))
		_box(place + Vector3(0, 3.98, 0), Vector3(8.7, 0.08, 0.65), Color("#65dfcc"), Vector3.ZERO)

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
		rotor.add_child(hub_instance)
		for blade_index in range(3):
			var blade := BoxMesh.new()
			blade.size = Vector3(0.16, 1.55, 0.12)
			var blade_instance := MeshInstance3D.new()
			blade_instance.mesh = blade
			blade_instance.position.y = 0.93
			blade_instance.rotation.z = float(blade_index) * TAU / 3.0
			blade_instance.material_override = _material("wind_blade", Color("#e7d19a"))
			rotor.add_child(blade_instance)
		_wind_rotors.append(rotor)

func _add_cliff_details() -> void:
	# Layered angular rock ribs beneath the garden paths help the islands read as floating landforms.
	for place in [Vector3(-12, -3.0, -20), Vector3(12, -3.1, -44), Vector3(-12, -3.0, -69), Vector3(13, -2.8, -88)]:
		for rib in range(3):
			var rock := PrismMesh.new()
			rock.size = Vector3(1.4, 4.2 - float(rib) * 0.45, 1.0)
			var x_offset := (float(rib) - 1.0) * 1.05
			var rock_mesh := _mesh(rock, place + Vector3(x_offset, -1.6, float(rib % 2) * 1.1), Color("#806e55"), Vector3.ONE, Vector3(0, float(rib) * 0.3, 0))
			rock_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Small stone caps and amber wind marks punctuate the lower grotto entrance.
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
			var cloud := _mesh(puff, place + offset, Color("#e0f3e8"), Vector3(1.8, 0.65, 1.1))
			cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
