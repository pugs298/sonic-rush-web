extends Node3D
## Skyrail vertical slice. Procedural geometry and interface keep the project asset-light.

const PLAYER_SCRIPT = preload("res://scripts/player_controller.gd")
const FALL_LIMIT := -18.0
const BEACON_POS := Vector3(0, 1.1, -94)

var player: CharacterBody3D
var camera: Camera3D
var hud_layer: CanvasLayer
var hud_label: Label
var prompt_label: Label
var menu_root: Control
var menu_panel: PanelContainer
var mode := "title"
var shards := 0
var total_shards := 0
var elapsed := 0.0
var checkpoint := Vector3(0, 1.0, 1)
var checkpoint_reached := false
var active_challenge := ""
var challenge_time := 0.0
var challenge_message := ""
var rail_timer := 0.0
var grinding := false
var dash_flash := 0.0
var shard_nodes: Array[Area3D] = []
var launcher_nodes: Array[Area3D] = []
var challenge_stations: Array[Dictionary] = []
var rail_segments: Array[Dictionary] = []
var beacon_active := false
var hint := "WASD move  ·  Mouse look  ·  Space jump  ·  Shift dash"
var materials := {}

func _ready() -> void:
	_build_environment()
	_build_zone()
	_build_player()
	_build_interface()
	_show_screen("title")

func _process(delta: float) -> void:
	if mode != "play":
		return
	elapsed += delta
	dash_flash = maxf(0.0, dash_flash - delta)
	if active_challenge != "":
		challenge_time += delta
		if active_challenge == "Shard Sweep" and shards >= 3:
			_complete_challenge("Shard Sweep complete — lovely route!")
		if active_challenge == "Rail Glider" and rail_timer >= 3.0:
			_complete_challenge("Rail Glider complete — clean ride!")
		_update_proximity_and_status()
		_update_hud()

func _physics_process(_delta: float) -> void:
	if mode != "play" or player == null:
		return
	if player.global_position.y < FALL_LIMIT:
		_respawn()
		return
	if Input.is_action_just_pressed("pause"):
		_open_pause()
		return
	if Input.is_action_just_pressed("restart"):
		_respawn()
		return
	if Input.is_action_just_pressed("interact"):
		_interact()
	_handle_rail()

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#2879b8")
	sky_material.sky_horizon_color = Color("#b9e8e4")
	sky_material.ground_bottom_color = Color("#355b66")
	sky_material.ground_horizon_color = Color("#c6e7d8")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d8f1e8")
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("#ffe2b0")
	sun.light_energy = 1.15
	sun.shadow_enabled = false
	add_child(sun)

func _mat(key: String, color: Color, glow := false) -> StandardMaterial3D:
	if materials.has(key):
		return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.25
	materials[key] = material
	return material

func _make_box(parent: Node3D, position: Vector3, size: Vector3, color: Color, label: String, solid := true, glow := false) -> Node3D:
	var holder: Node3D
	if solid:
		holder = StaticBody3D.new()
	else:
		holder = Node3D.new()
	holder.name = label
	holder.position = position
	parent.add_child(holder)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = _mat(label + color.to_html(), color, glow)
	holder.add_child(mesh)
	if solid:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		holder.add_child(shape)
	return holder

func _build_zone() -> void:
	var island := Node3D.new()
	island.name = "OvergrowthIsland"
	add_child(island)
	# Broad connected central route with forgiving landings.
	_make_box(island, Vector3(0, -1.0, 0), Vector3(18, 2, 20), Color("#719b57"), "StartGarden")
	for data in [
		[Vector3(0, -0.7, -15), Vector3(15, 1.6, 16)],
		[Vector3(2, -0.9, -31), Vector3(13, 1.6, 15)],
		[Vector3(-1, -1.0, -48), Vector3(14, 1.6, 15)],
		[Vector3(1, -0.8, -65), Vector3(13, 1.6, 15)],
		[Vector3(0, -0.5, -81), Vector3(15, 1.6, 16)],
		[Vector3(0, -0.5, -96), Vector3(22, 1.8, 20)]
	]:
		_make_box(island, data[0], data[1], Color("#6f9954"), "GardenPath")
	# Lower discovery route and a bridge shortcut unlocked at the checkpoint.
	_make_box(island, Vector3(-8, -4.6, -34), Vector3(10, 1.2, 18), Color("#527a58"), "LowerGrotto")
	_make_box(island, Vector3(-6, -3.4, -48), Vector3(7, 1.0, 12), Color("#658951"), "GrottoLanding")
	var shortcut := _make_box(island, Vector3(8, 2.5, -57), Vector3(9, 0.55, 24), Color("#c79c58"), "WindBridge")
	shortcut.visible = false
	shortcut.set_meta("shortcut", true)
	# High route: stepping stones climb toward the wind arch and return to the main island.
	for data in [
		[Vector3(-7, 2.2, -13), Vector3(7, 1.0, 8)],
		[Vector3(-10, 4.1, -24), Vector3(7, 1.0, 9)],
		[Vector3(-7, 5.2, -36), Vector3(8, 1.0, 9)],
		[Vector3(-2, 4.1, -45), Vector3(8, 1.0, 8)],
		[Vector3(5, 3.3, -51), Vector3(9, 1.0, 10)]
	]:
		_make_box(island, data[0], data[1], Color("#91a968"), "HighRoutePlatform")
	# Floating rock undersides, stylized silhouettes only.
	for data in [[-13.0, -1.0, -20.0], [12.0, -1.8, -45.0], [-13.0, -1.0, -72.0], [14.0, -2.0, -90.0]]:
		_make_box(island, Vector3(data[0], data[1], data[2]), Vector3(8, 3, 10), Color("#887454"), "WindWornStone", false)
	_build_rail(island, [Vector3(-10, 5.6, -19), Vector3(-9, 6.3, -27), Vector3(-6, 6.4, -35), Vector3(-1, 5.2, -43)])
	_add_shard(island, Vector3(0, 1.3, -7))
	_add_shard(island, Vector3(4, 1.2, -17))
	_add_shard(island, Vector3(-4, 1.2, -27))
	_add_shard(island, Vector3(-8, -3.5, -32))
	_add_shard(island, Vector3(-8, -3.3, -39))
	_add_shard(island, Vector3(-6, -2.4, -48))
	_add_shard(island, Vector3(-9, 5.6, -24))
	_add_shard(island, Vector3(-6, 6.5, -36))
	_add_shard(island, Vector3(4, 4.2, -51))
	_add_shard(island, Vector3(0, 1.7, -72))
	_add_shard(island, Vector3(0, 1.7, -91))
	_add_launcher(island, Vector3(5, 0.3, -27), Vector3(-2, 9, -8))
	_add_launcher(island, Vector3(-1, -0.1, -62), Vector3(0, 10, -5))
	_add_marker(island, Vector3(0, 0.1, -94), "WIND BEACON", Color("#f5ae51"))
	_add_marker(island, Vector3(0, 0.1, -13), "TIME TRIAL · E", Color("#f5ae51"))
	_add_marker(island, Vector3(-8, -2.8, -33), "SHARD SWEEP · E", Color("#65dfcc"))
	_add_marker(island, Vector3(-10, 6.7, -20), "RAIL GLIDER · E", Color("#65dfcc"))
	_add_checkpoint_marker(island, Vector3(0, 0.1, -48))
	_build_landmark(island)
	# Distant low-poly sky islands decorate the horizon without expensive effects.
	for data in [[-24.0, 4.0, -28.0], [23.0, 2.0, -58.0], [-26.0, 7.0, -83.0], [25.0, 5.0, -110.0]]:
		_make_box(island, Vector3(data[0], data[1], data[2]), Vector3(10, 4, 12), Color("#608c76"), "DistantFloatingIsland", false)

func _build_landmark(parent: Node3D) -> void:
	var landmark := Node3D.new()
	landmark.name = "WindArchLandmark"
	landmark.position = Vector3(0, 0.4, -95)
	parent.add_child(landmark)
	_make_box(landmark, Vector3(-5, 4, 0), Vector3(1.0, 8, 1.2), Color("#c3a36a"), "ArchPillar")
	_make_box(landmark, Vector3(5, 4, 0), Vector3(1.0, 8, 1.2), Color("#c3a36a"), "ArchPillar")
	_make_box(landmark, Vector3(0, 8, 0), Vector3(11, 1.0, 1.3), Color("#d6b976"), "ArchLintel")
	_make_box(landmark, Vector3(0, 5, -0.6), Vector3(0.35, 3.2, 0.3), Color("#f5ae51"), "BeaconCore", false, true)

func _build_rail(parent: Node3D, points: Array[Vector3]) -> void:
	for i in range(points.size() - 1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var direction := b - a
		var mesh_instance := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.14
		cylinder.bottom_radius = 0.14
		cylinder.height = direction.length()
		mesh_instance.mesh = cylinder
		mesh_instance.position = (a + b) * 0.5
		mesh_instance.quaternion = Quaternion(Vector3.UP, direction.normalized())
		mesh_instance.material_override = _mat("RailGlow", Color("#63e1d0"), true)
		parent.add_child(mesh_instance)
		rail_segments.append({"a": a, "b": b})

func _add_shard(parent: Node3D, position: Vector3) -> void:
	var area := Area3D.new()
	area.name = "WindShard"
	area.position = position
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.8
	shape.shape = sphere_shape
	area.add_child(shape)
	var mesh := MeshInstance3D.new()
	var shard_mesh := PrismMesh.new()
	shard_mesh.size = Vector3(0.55, 0.8, 0.3)
	mesh.mesh = shard_mesh
	mesh.material_override = _mat("Shard", Color("#65dfcc"), true)
	area.add_child(mesh)
	parent.add_child(area)
	area.body_entered.connect(_on_shard_body_entered.bind(area))
	shard_nodes.append(area)
	total_shards += 1

func _on_shard_body_entered(body: Node3D, shard: Area3D) -> void:
	if body != player or not is_instance_valid(shard):
		return
	shards += 1
	shard.queue_free()
	shard_nodes.erase(shard)
	hint = "Wind shard collected · %d / %d" % [shards, total_shards]
	if active_challenge == "Shard Sweep" and shards >= 3:
		_complete_challenge("Shard Sweep complete — lovely route!")

func _add_launcher(parent: Node3D, position: Vector3, impulse: Vector3) -> void:
	var area := Area3D.new()
	area.name = "WindLauncher"
	area.position = position
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.5
	shape.shape = sphere
	area.add_child(shape)
	var pad := _make_box(area, Vector3.ZERO, Vector3(2.2, 0.35, 2.2), Color("#f5ae51"), "LauncherPad", false, true)
	pad.rotation_degrees.x = -12
	area.set_meta("impulse", impulse)
	parent.add_child(area)
	area.body_entered.connect(_on_launcher_body_entered.bind(area))
	launcher_nodes.append(area)

func _on_launcher_body_entered(body: Node3D, launcher: Area3D) -> void:
	if body != player or mode != "play":
		return
	var now := Time.get_ticks_msec()
	if now - int(launcher.get_meta("last_launch", 0)) < 1000:
		return
	launcher.set_meta("last_launch", now)
	player.velocity = launcher.get_meta("impulse")
	hint = "Wind launcher! Steer toward the next garden."

func _add_marker(parent: Node3D, position: Vector3, title: String, color: Color) -> void:
	var marker := Node3D.new()
	marker.position = position
	marker.name = title.replace(" ", "_")
	parent.add_child(marker)
	var post := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.12
	cylinder.bottom_radius = 0.12
	cylinder.height = 1.4
	post.mesh = cylinder
	post.position.y = 0.7
	post.material_override = _mat("marker_" + title, color, true)
	marker.add_child(post)
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.42
	orb.mesh = sphere
	orb.position.y = 1.55
	orb.material_override = _mat("orb_" + title, color, true)
	marker.add_child(orb)
	marker.set_meta("label", title)
	if title.begins_with("TIME"):
		challenge_stations.append({"name": "Time Trial", "position": position, "finish": Vector3(2, 0, -31)})
	elif title.begins_with("SHARD"):
		challenge_stations.append({"name": "Shard Sweep", "position": position, "finish": position})
	elif title.begins_with("RAIL"):
		challenge_stations.append({"name": "Rail Glider", "position": position, "finish": Vector3(-1, 5, -43)})

func _add_checkpoint_marker(parent: Node3D, position: Vector3) -> void:
	var marker := Node3D.new()
	marker.name = "CheckpointWindTotem"
	marker.position = position
	parent.add_child(marker)
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.25
	cylinder.bottom_radius = 0.55
	cylinder.height = 2.5
	mesh.mesh = cylinder
	mesh.position.y = 1.25
	mesh.material_override = _mat("Checkpoint", Color("#f5ae51"), true)
	marker.add_child(mesh)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Courier"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0, 1.0, 1)
	player.collision_layer = 1
	player.collision_mask = 1
	add_child(player)
	camera = player.get_node("CameraPivot/SpringArm3D/Camera3D")

func _build_interface() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "Interface"
	add_child(hud_layer)
	var hud := Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(hud)
	hud_label = Label.new()
	hud_label.position = Vector2(26, 20)
	hud_label.add_theme_font_size_override("font_size", 22)
	hud_label.add_theme_color_override("font_color", Color("#fff9e9"))
	hud_label.add_theme_color_override("font_shadow_color", Color("#153747"))
	hud_label.add_theme_constant_override("shadow_offset_x", 2)
	hud_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(hud_label)
	prompt_label = Label.new()
	prompt_label.anchor_left = 0.0
	prompt_label.anchor_right = 1.0
	prompt_label.anchor_top = 1.0
	prompt_label.anchor_bottom = 1.0
	prompt_label.offset_left = 24
	prompt_label.offset_top = -58
	prompt_label.offset_right = -24
	prompt_label.offset_bottom = -18
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_color", Color("#fff9e9"))
	hud.add_child(prompt_label)
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.visible = false
	hud_layer.add_child(menu_root)

func _show_screen(screen: String) -> void:
	mode = screen
	player.set_active(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud_label.visible = false
	prompt_label.visible = false
	for child in menu_root.get_children():
		child.queue_free()
	menu_root.visible = true
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.12, 0.18, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f0f1d8")
	style.border_color = Color("#d9a85d")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var title := Label.new()
	title.text = "SKYRAIL\nECHOES OF THE OVERGROWTH" if screen == "title" else _screen_title(screen)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30 if screen == "title" else 26)
	title.add_theme_color_override("font_color", Color("#174b4d"))
	column.add_child(title)
	if screen == "title":
		_add_small_text(column, "A courier’s route through a floating garden network.")
		_add_button(column, "PLAY", _start_game)
		_add_button(column, "OPTIONS", func(): _show_screen("options"))
		_add_button(column, "CONTROLS", func(): _show_screen("controls"))
		_add_small_text(column, "Original procedural prototype · no external art or audio")
	elif screen == "options":
		_add_small_text(column, "Master volume")
		var volume := HSlider.new()
		volume.min_value = 0
		volume.max_value = 1
		volume.step = 0.05
		volume.value = db_to_linear(AudioServer.get_bus_volume_db(0))
		volume.value_changed.connect(_set_volume)
		column.add_child(volume)
		_add_small_text(column, "Frame rate cap")
		var fps := OptionButton.new()
		fps.add_item("60 FPS", 60)
		fps.add_item("30 FPS", 30)
		fps.select(0 if Engine.max_fps != 30 else 1)
		fps.item_selected.connect(func(index: int): Engine.max_fps = fps.get_item_id(index))
		column.add_child(fps)
		_add_button(column, "BACK", func(): _show_screen("title" if mode == "options" and not checkpoint_reached and elapsed == 0.0 else "pause"))
	elif screen == "controls":
		_add_small_text(column, "WASD / arrows — move    Mouse — camera look")
		_add_small_text(column, "Space — jump (hold for height)    Shift — dash")
		_add_small_text(column, "E — activate / interact    Esc — pause    R — checkpoint reset")
		_add_button(column, "BACK", func(): _show_screen("title"))
	elif screen == "pause":
		_add_small_text(column, "The wind waits while you plan your next route.")
		_add_button(column, "RESUME", _resume_game)
		_add_button(column, "OPTIONS", func(): _show_screen("options"))
		_add_button(column, "CONTROLS", func(): _show_screen("controls"))
		_add_button(column, "RETURN TO TITLE", func(): _show_screen("title"))
	elif screen == "complete":
		_add_small_text(column, "The beacon sings again. The island paths are yours to explore.")
		_add_small_text(column, "Time: %s    Wind shards: %d / %d" % [_format_time(elapsed), shards, total_shards])
		_add_button(column, "KEEP EXPLORING", _resume_game)
		_add_button(column, "RETURN TO TITLE", func(): _show_screen("title"))
		_add_button(column, "PLAY AGAIN", _start_game)
	elif screen == "challenge_complete":
		_add_small_text(column, challenge_message)
		_add_button(column, "CONTINUE", _resume_game)

func _screen_title(screen: String) -> String:
	match screen:
		"options": return "OPTIONS"
		"controls": return "CONTROLS"
		"pause": return "PAUSED"
		"complete": return "BEACON RESTORED"
		"challenge_complete": return "CHALLENGE COMPLETE"
	return screen.to_upper()

func _add_small_text(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#315c58"))
	parent.add_child(label)

func _add_button(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 46)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("#164e4c"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#d1e4c2")
	normal.set_corner_radius_all(9)
	button.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#b7d9c0")
	hover.set_corner_radius_all(9)
	button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(action)
	parent.add_child(button)

func _set_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.001)))

func _start_game() -> void:
	if elapsed > 0.0 or shards > 0:
		get_tree().reload_current_scene()
		return
	_resume_game()

func _resume_game() -> void:
	mode = "play"
	menu_root.visible = false
	hud_label.visible = true
	prompt_label.visible = true
	player.set_active(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_hud()

func _open_pause() -> void:
	_show_screen("pause")

func _update_proximity_and_status() -> void:
	var player_pos := player.global_position
	var near_prompt := ""
	for station in challenge_stations:
		if player_pos.distance_to(station.position) < 3.2:
			near_prompt = "E  ·  start %s" % station.name
			break
	if player_pos.distance_to(BEACON_POS) < 5.0:
		near_prompt = "E  ·  restore the wind beacon"
	if not checkpoint_reached and player_pos.distance_to(Vector3(0, 0.5, -48)) < 3.5:
		checkpoint_reached = true
		checkpoint = Vector3(0, 1.0, -46)
		var bridge := get_node_or_null("OvergrowthIsland/WindBridge")
		if bridge:
			bridge.visible = true
		hint = "Checkpoint reached · the eastern wind bridge opened"
	if active_challenge == "Time Trial" and player_pos.distance_to(Vector3(2, 0, -31)) < 4.0:
		if challenge_time <= 22.0:
			_complete_challenge("Time Trial complete in %s" % _format_time(challenge_time))
		else:
			active_challenge = ""
			challenge_message = "Time Trial ended — press E at its marker to retry."
			hint = challenge_message
	if grinding:
		rail_timer += get_process_delta_time()
		near_prompt = "Grinding · Space to jump off"
	else:
		rail_timer = 0.0
	prompt_label.text = near_prompt if near_prompt != "" else hint

func _interact() -> void:
	if player.global_position.distance_to(BEACON_POS) < 5.0:
		beacon_active = true
		_show_screen("complete")
		return
	for station in challenge_stations:
		if player.global_position.distance_to(station.position) < 3.2:
			active_challenge = station.name
			challenge_time = 0.0
			if station.name == "Rail Glider":
				hint = "Ride the luminous rail for 3 seconds."
			elif station.name == "Shard Sweep":
				hint = "Collect any three wind shards to finish this route."
			else:
				hint = "Reach the amber gate before the 22 second timer ends!"
			return

func _handle_rail() -> void:
	if player.is_on_floor() and Input.is_action_just_pressed("jump") and grinding:
		grinding = false
		player.velocity.y = player.jump_velocity * 0.85
		return
	var best_distance := 999.0
	var best_direction := Vector3.ZERO
	for segment in rail_segments:
		var a: Vector3 = segment.a
		var b: Vector3 = segment.b
		var ab := b - a
		var denom := maxf(ab.length_squared(), 0.001)
		var t := clampf((player.global_position - a).dot(ab) / denom, 0.0, 1.0)
		var nearest := a + ab * t
		var distance := player.global_position.distance_to(nearest)
		if distance < best_distance:
			best_distance = distance
			best_direction = ab.normalized()
	if best_distance < 1.25 and player.velocity.length() > 3.0:
		grinding = true
		player.velocity = best_direction * maxf(player.velocity.length(), 9.0)
		player.global_position = player.global_position.lerp(player.global_position + Vector3(0, 5.7, -20) * 0.0, 0.0)
		if Input.is_action_just_pressed("jump"):
			grinding = false
			player.velocity.y = player.jump_velocity
	else:
		grinding = false

func _complete_challenge(message: String) -> void:
	active_challenge = ""
	challenge_message = message
	hint = message
	_show_screen("challenge_complete")

func _respawn() -> void:
	player.global_position = checkpoint
	player.velocity = Vector3.ZERO
	grinding = false
	hint = "Back at your latest checkpoint."

func _update_hud() -> void:
	var extra := ""
	if active_challenge != "":
		extra = "   ·   %s %s" % [active_challenge, _format_time(challenge_time)]
	hud_label.text = "SKYRAIL   ·   WIND SHARDS %02d / %02d   ·   TIME %s%s" % [shards, total_shards, _format_time(elapsed), extra]

func _format_time(value: float) -> String:
	var minutes := int(value) / 60
	var seconds := fmod(value, 60.0)
	return "%02d:%04.1f" % [minutes, seconds]
