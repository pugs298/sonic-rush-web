extends CharacterBody3D
class_name CourierController
## Tunable low-poly third-person controller with a distinct original wind courier.

@export_category("Movement")
@export var ground_acceleration := 28.0
@export var ground_deceleration := 34.0
@export var top_speed := 13.0
@export var air_acceleration := 10.0
@export var jump_velocity := 10.5
@export var gravity := 25.0
@export var coyote_seconds := 0.12
@export var jump_buffer_seconds := 0.14
@export_category("Dash")
@export var dash_speed := 20.0
@export var dash_duration := 0.22
@export var dash_cooldown := 0.8

var camera_pivot: Node3D
var spring_arm: SpringArm3D
var view_camera: Camera3D
var visual: Node3D
var coyote_left := 0.0
var jump_buffer_left := 0.0
var dash_left := 0.0
var dash_cooldown_left := 0.0
var dash_direction := Vector3.FORWARD
var camera_sensitivity := 0.0025
var camera_enabled := false
var run_phase := 0.0
var base_visual_y := 0.0

func _ready() -> void:
	_ensure_action("move_forward", [KEY_W, KEY_UP])
	_ensure_action("move_back", [KEY_S, KEY_DOWN])
	_ensure_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_action("jump", [KEY_SPACE])
	_ensure_action("dash", [KEY_SHIFT])
	_ensure_action("interact", [KEY_E])
	_ensure_action("pause", [KEY_ESCAPE])
	_ensure_action("restart", [KEY_R])
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.65
	collider.shape = capsule
	collider.position.y = 0.82
	add_child(collider)
	_build_courier()
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.35, 0)
	add_child(camera_pivot)
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 6.2
	spring_arm.margin = 0.25
	spring_arm.collision_mask = 1
	camera_pivot.add_child(spring_arm)
	view_camera = Camera3D.new()
	view_camera.current = true
	view_camera.fov = 74.0
	spring_arm.add_child(view_camera)
	set_physics_process(false)

func _build_courier() -> void:
	visual = Node3D.new()
	visual.name = "OriginalWindCourier"
	add_child(visual)
	var teal := Color("#16a6a0")
	var deep_teal := Color("#116e79")
	var pale := Color("#fff1d2")
	var amber := Color("#f5a64e")
	var dark := Color("#17384c")
	var body := CapsuleMesh.new()
	body.radius = 0.34
	body.height = 1.12
	_part(body, Vector3(0, 0.82, 0), teal, Vector3(1, 1, 0.88))
	var chest := SphereMesh.new()
	chest.radius = 0.27
	chest.height = 0.45
	_part(chest, Vector3(0, 0.86, -0.22), pale, Vector3(1.0, 0.9, 0.42))
	var head := SphereMesh.new()
	head.radius = 0.36
	head.height = 0.68
	_part(head, Vector3(0, 1.48, -0.04), teal, Vector3(1.08, 1.0, 0.92))
	var muzzle := SphereMesh.new()
	muzzle.radius = 0.19
	muzzle.height = 0.24
	_part(muzzle, Vector3(0, 1.36, -0.34), pale, Vector3(1.0, 0.8, 0.8))
	var nose := SphereMesh.new()
	nose.radius = 0.075
	_part(nose, Vector3(0, 1.43, -0.49), dark, Vector3(1.0, 0.8, 0.7))
	var eye_white := SphereMesh.new()
	eye_white.radius = 0.12
	_part(eye_white, Vector3(-0.13, 1.55, -0.325), Color.WHITE, Vector3(0.82, 1.18, 0.42))
	_part(eye_white, Vector3(0.13, 1.55, -0.325), Color.WHITE, Vector3(0.82, 1.18, 0.42))
	var pupil := SphereMesh.new()
	pupil.radius = 0.055
	_part(pupil, Vector3(-0.12, 1.55, -0.375), dark, Vector3(0.8, 1.1, 0.55))
	_part(pupil, Vector3(0.14, 1.55, -0.375), dark, Vector3(0.8, 1.1, 0.55))
	# Swept leaf-like wind fins give the courier a unique aerodynamic silhouette.
	var fin := SphereMesh.new()
	fin.radius = 0.25
	var fin_left := _part(fin, Vector3(-0.24, 1.72, 0.23), deep_teal, Vector3(0.72, 0.42, 1.9))
	fin_left.rotation.x = -0.28
	fin_left.rotation.z = -0.34
	var fin_mid := _part(fin, Vector3(0, 1.79, 0.27), teal.darkened(0.08), Vector3(0.72, 0.42, 2.0))
	fin_mid.rotation.x = -0.25
	var fin_right := _part(fin, Vector3(0.24, 1.72, 0.23), deep_teal, Vector3(0.72, 0.42, 1.9))
	fin_right.rotation.x = -0.28
	fin_right.rotation.z = 0.34
	var ear := CylinderMesh.new()
	ear.top_radius = 0.015
	ear.bottom_radius = 0.13
	ear.height = 0.34
	var ear_l := _part(ear, Vector3(-0.25, 1.79, -0.01), teal, Vector3.ONE)
	ear_l.rotation.z = 0.18
	var ear_r := _part(ear, Vector3(0.25, 1.79, -0.01), teal, Vector3.ONE)
	ear_r.rotation.z = -0.18
	var ear_inner := SphereMesh.new()
	ear_inner.radius = 0.07
	_part(ear_inner, Vector3(-0.25, 1.78, -0.1), amber, Vector3(0.8, 1.3, 0.35))
	_part(ear_inner, Vector3(0.25, 1.78, -0.1), amber, Vector3(0.8, 1.3, 0.35))
	# Scarf tails stream behind, in warm amber, instead of copying a familiar mascot outfit.
	var scarf := BoxMesh.new()
	scarf.size = Vector3(0.68, 0.13, 0.34)
	var scarf_part := _part(scarf, Vector3(0, 1.18, 0.29), amber, Vector3.ONE)
	scarf_part.rotation.x = -0.22
	var tail := BoxMesh.new()
	tail.size = Vector3(0.18, 0.1, 0.68)
	var tail_l := _part(tail, Vector3(-0.2, 1.13, 0.7), amber, Vector3.ONE)
	tail_l.rotation.x = -0.3
	tail_l.rotation.z = -0.12
	var tail_r := _part(tail, Vector3(0.2, 1.13, 0.7), amber.lightened(0.12), Vector3.ONE)
	tail_r.rotation.x = -0.3
	tail_r.rotation.z = 0.12
	# Short arms, bright gloves and oversized trail boots make the silhouette readable at speed.
	var limb := CapsuleMesh.new()
	limb.radius = 0.105
	limb.height = 0.48
	var arm_l := _part(limb, Vector3(-0.37, 0.88, -0.02), teal.darkened(0.1), Vector3(1, 1, 1))
	arm_l.rotation.z = 0.28
	var arm_r := _part(limb, Vector3(0.37, 0.88, -0.02), teal.darkened(0.1), Vector3(1, 1, 1))
	arm_r.rotation.z = -0.28
	var glove := SphereMesh.new()
	glove.radius = 0.14
	_part(glove, Vector3(-0.43, 0.64, -0.07), pale, Vector3(1.0, 0.8, 1.0))
	_part(glove, Vector3(0.43, 0.64, -0.07), pale, Vector3(1.0, 0.8, 1.0))
	var boot := CapsuleMesh.new()
	boot.radius = 0.17
	boot.height = 0.46
	var boot_l := _part(boot, Vector3(-0.2, 0.2, -0.1), amber, Vector3(1.0, 0.8, 1.2))
	boot_l.rotation.x = PI * 0.5
	var boot_r := _part(boot, Vector3(0.2, 0.2, -0.1), amber.lightened(0.08), Vector3(1.0, 0.8, 1.2))
	boot_r.rotation.x = PI * 0.5
	var sole := BoxMesh.new()
	sole.size = Vector3(0.3, 0.08, 0.48)
	_part(sole, Vector3(-0.2, 0.075, -0.12), dark, Vector3.ONE)
	_part(sole, Vector3(0.2, 0.075, -0.12), dark, Vector3.ONE)
	base_visual_y = visual.position.y

func _part(mesh: Mesh, at: Vector3, color: Color, mesh_scale: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.scale = mesh_scale
	instance.material_override = _material(color)
	visual.add_child(instance)
	return instance

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.68
	return material

func _ensure_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func set_active(active: bool) -> void:
	set_physics_process(active)
	camera_enabled = active
	if not active:
		dash_left = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not camera_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * camera_sensitivity)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - event.relative.y * camera_sensitivity, -0.75, 0.65)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_left = jump_buffer_seconds
	else:
		jump_buffer_left = maxf(0.0, jump_buffer_left - delta)
	if is_on_floor():
		coyote_left = coyote_seconds
	else:
		coyote_left = maxf(0.0, coyote_left - delta)
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	var raw := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward := -camera_pivot.global_basis.z
	var right := camera_pivot.global_basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var wish := (right * raw.x + forward * -raw.y).normalized()
	if dash_left > 0.0:
		dash_left = maxf(0.0, dash_left - delta)
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
	else:
		var horizontal := Vector3(velocity.x, 0.0, velocity.z)
		if wish.length_squared() > 0.001:
			var acceleration := ground_acceleration if is_on_floor() else air_acceleration
			horizontal = horizontal.move_toward(wish * top_speed, acceleration * delta)
		else:
			var deceleration := ground_deceleration if is_on_floor() else air_acceleration * 0.35
			horizontal = horizontal.move_toward(Vector3.ZERO, deceleration * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.z
		if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
			dash_direction = wish if wish.length_squared() > 0.001 else forward
			dash_left = dash_duration
			dash_cooldown_left = dash_cooldown
			velocity.y = maxf(velocity.y, 1.5)
	if not is_on_floor():
		velocity.y -= gravity * delta
	if jump_buffer_left > 0.0 and coyote_left > 0.0:
		velocity.y = jump_velocity
		jump_buffer_left = 0.0
		coyote_left = 0.0
	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.55
	move_and_slide()
	var motion := Vector3(velocity.x, 0.0, velocity.z)
	var speed_ratio := clampf(motion.length() / top_speed, 0.0, 1.0)
	if motion.length_squared() > 0.4:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-motion.x, -motion.z), 12.0 * delta)
	run_phase += delta * (5.0 + speed_ratio * 10.0)
	visual.position.y = base_visual_y + (sin(run_phase * 2.0) * 0.035 * speed_ratio if is_on_floor() else 0.0)
	visual.rotation.z = lerpf(visual.rotation.z, -raw.x * 0.12, 7.0 * delta)
	if dash_left > 0.0:
		view_camera.fov = lerpf(view_camera.fov, 80.0, 10.0 * delta)
	else:
		view_camera.fov = lerpf(view_camera.fov, 74.0 + speed_ratio * 2.0, 3.0 * delta)
