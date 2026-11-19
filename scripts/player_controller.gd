extends CharacterBody3D
class_name CourierController
## Tunable low-poly third-person controller: forgiving jumps, air steering and a short burst.

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
	visual = Node3D.new()
	visual.name = "CourierVisual"
	add_child(visual)
	var body_mesh := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.4
	capsule_mesh.height = 1.55
	body_mesh.mesh = capsule_mesh
	body_mesh.position.y = 0.82
	body_mesh.material_override = _material(Color("#167a78"))
	visual.add_child(body_mesh)
	var scarf := MeshInstance3D.new()
	var scarf_mesh := BoxMesh.new()
	scarf_mesh.size = Vector3(0.82, 0.18, 0.34)
	scarf.mesh = scarf_mesh
	scarf.position = Vector3(0, 1.25, 0.32)
	scarf.material_override = _material(Color("#f4a64e"))
	visual.add_child(scarf)
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.35, 0)
	add_child(camera_pivot)
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 6.2
	spring_arm.margin = 0.25
	spring_arm.collision_mask = 1
	camera_pivot.add_child(spring_arm)
	view_camera = Camera3D.new()
	view_camera.current = true
	view_camera.fov = 72.0
	spring_arm.add_child(view_camera)
	set_physics_process(false)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
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
	if motion.length_squared() > 0.4:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-motion.x, -motion.z), 12.0 * delta)
