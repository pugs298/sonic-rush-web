extends Node3D
## Skyline Rush: a small original 3D momentum-platformer prototype.
## Everything is generated from code so the project stays asset-free and easy to export.

const SPEED := 18.0
const ACCEL := 32.0
const AIR_ACCEL := 12.0
const JUMP_VELOCITY := 11.5
const GRAVITY := 28.0
const LEVEL_END := 190.0

var player: CharacterBody3D
var camera: Camera3D
var ui: Label
var message: Label
var distance := 0.0
var rings := 0
var elapsed := 0.0
var finished := false
var start_time := 0.0
var ring_nodes: Array[Node3D] = []
var obstacle_nodes: Array[Node3D] = []

func _ready() -> void:
	_build_world()
	_build_player()
	_build_camera()
	_build_ui()
	start_time = Time.get_ticks_msec() / 1000.0

func mat(color: Color, emission := Color.BLACK) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.72
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 1.8
	return m

func box(parent: Node3D, pos: Vector3, size: Vector3, material: Material, name := "Platform") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	parent.add_child(body)
	var mesh := MeshInstance3D.new()
	var shape := CollisionShape3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = material
	var collision := BoxShape3D.new()
	collision.size = size
	shape.shape = collision
	body.add_child(mesh)
	body.add_child(shape)
	return body

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#101c46")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#9bbcff")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = Color("#ffe7b0")
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)
	var ground_mat := mat(Color("#24346b"))
	var track_mat := mat(Color("#3d5fa8"))
	box(self, Vector3(0, -1.5, 95), Vector3(28, 3, 210), ground_mat, "Ground")
	box(self, Vector3(0, 0, 95), Vector3(12, 0.45, 205), track_mat, "Track")
	# Decorative city blocks make the route readable without external assets.
	for z in range(0, 210, 14):
		for side in [-1, 1]:
			var h := 4.0 + float((z * 7 + side * 3) % 13)
			var building_mat := mat(Color(0.08 + h / 120.0, 0.12, 0.28 + h / 90.0))
			box(self, Vector3(side * (9.0 + float(z % 5)), h / 2.0 - 1.5, z), Vector3(5, h, 8), building_mat, "CityBlock")
	# Boost pads are bright strips on the route.
	for z in [24, 67, 112, 154]:
		box(self, Vector3(0, 0.28, z), Vector3(4.0, 0.12, 3.2), mat(Color("#ffdb4d"), Color("#ffb300")), "BoostPad")
	# Ring line and gentle elevation changes represented by floating pickups.
	for z in range(10, 186, 8):
		_add_ring(Vector3(0, 2.0 + sin(float(z) * 0.25) * 0.6, z))
	# A few hazard blocks require jumping.
	for z in [43, 91, 137, 176]:
		_add_obstacle(Vector3(0, 1.1, z))
	# Finish gate.
	box(self, Vector3(-5.3, 4, LEVEL_END), Vector3(0.7, 9, 0.7), mat(Color("#ff4f9a"), Color("#ff247f")), "FinishLeft")
	box(self, Vector3(5.3, 4, LEVEL_END), Vector3(0.7, 9, 0.7), mat(Color("#ff4f9a"), Color("#ff247f")), "FinishRight")
	box(self, Vector3(0, 8.2, LEVEL_END), Vector3(11, 0.7, 0.7), mat(Color("#ffe05c"), Color("#ffc400")), "FinishTop")

func _add_ring(pos: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.34
	torus.outer_radius = 0.48
	ring.mesh = torus
	ring.material_override = mat(Color("#ffd84a"), Color("#ff9d00"))
	ring.position = pos
	ring.rotation_degrees.x = 90
	add_child(ring)
	ring_nodes.append(ring)

func _add_obstacle(pos: Vector3) -> void:
	var obstacle := box(self, pos, Vector3(3.0, 2.2, 2.0), mat(Color("#e84d68"), Color("#9e1836")), "Hazard")
	obstacle_nodes.append(obstacle)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Runner"
	player.position = Vector3(0, 1.4, 3)
	add_child(player)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.65
	capsule.height = 1.8
	shape.shape = capsule
	player.add_child(shape)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.78
	sphere.height = 1.56
	mesh.mesh = sphere
	mesh.material_override = mat(Color("#39d8ff"), Color("#0879ff"))
	player.add_child(mesh)
	var light := OmniLight3D.new()
	light.light_color = Color("#27cfff")
	light.light_energy = 1.3
	light.omni_range = 5.0
	player.add_child(light)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0, 5.5, -10)
	camera.current = true
	add_child(camera)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Label.new()
	ui.position = Vector2(28, 22)
	ui.add_theme_font_size_override("font_size", 24)
	ui.add_theme_color_override("font_color", Color("#ffffff"))
	layer.add_child(ui)
	message = Label.new()
	message.position = Vector2(28, 655)
	message.add_theme_font_size_override("font_size", 18)
	message.add_theme_color_override("font_color", Color("#c9ddff"))
	message.text = "A / D or Arrow Keys: steer    Space: jump    R: restart"
	layer.add_child(message)

func _physics_process(delta: float) -> void:
	if finished:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	elapsed += delta
	var steer := Input.get_axis("move_left", "move_right")
	var target_x := steer * 9.0
	var horizontal_accel := ACCEL if player.is_on_floor() else AIR_ACCEL
	player.velocity.x = move_toward(player.velocity.x, target_x, horizontal_accel * delta)
	player.velocity.z = move_toward(player.velocity.z, SPEED, 24.0 * delta)
	if player.is_on_floor() and Input.is_action_just_pressed("jump"):
		player.velocity.y = JUMP_VELOCITY
	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	player.move_and_slide()
	player.position.x = clamp(player.position.x, -5.2, 5.2)
	if player.position.y < -4:
		get_tree().reload_current_scene()
	for ring in ring_nodes:
		if is_instance_valid(ring):
			ring.rotate_y(delta * 4.0)
			if ring.position.distance_to(player.position) < 1.5:
				ring.queue_free()
				rings += 1
	for obstacle in obstacle_nodes:
		if is_instance_valid(obstacle) and obstacle.global_position.distance_to(player.global_position) < 1.8:
			get_tree().reload_current_scene()
	camera.position = camera.position.lerp(Vector3(player.position.x * 0.45, 5.3, player.position.z - 10.5), 5.0 * delta)
	camera.look_at(Vector3(player.position.x * 0.25, 1.3, player.position.z + 13), Vector3.UP)
	distance = max(distance, player.position.z)
	ui.text = "SKYLINE RUSH   |   DIST %03d / %03d   |   RINGS %02d   |   TIME %05.1f" % [int(distance), int(LEVEL_END), rings, elapsed]
	if player.position.z >= LEVEL_END - 2:
		finished = true
		message.text = "FINISH!  Time: %.2f seconds   Rings: %d   |   Press R to run again" % [elapsed, rings]
