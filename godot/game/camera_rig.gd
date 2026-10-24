class_name CameraRig
extends Node3D
## Third-person orbit camera. The rig sits above the target and turns by yaw
## and pitch; its Camera3D child sits camera_distance behind it.
## The look_* actions turn it at a rate; mouse motion (while captured) and
## touch drags turn it by distance through orbit().

@export var tuning: Tuning
@export var target: Node3D

var yaw := 0.0
var pitch := 0.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	# The rig moves in _process from the target's interpolated transform, so
	# physics interpolation must not smooth it a second time.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true
	pitch = deg_to_rad(tuning.camera_pitch_default)
	yaw = target.global_rotation.y
	global_position = _pivot()
	_apply()


## Rotation of the camera about the vertical axis only. Movement input is
## relative to this.
func yaw_basis() -> Basis:
	return Basis(Vector3.UP, yaw)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		orbit(event.screen_relative * tuning.mouse_sensitivity)


## Turns the camera as a drag of [param degrees] would: positive x turns
## right, positive y looks down. Mouse and touch drags both come here.
func orbit(degrees: Vector2) -> void:
	_turn(-deg_to_rad(degrees.x), -deg_to_rad(degrees.y))


func _input(event: InputEvent) -> void:
	# The first click only captures the mouse; it must not also send the horde.
	if event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	var turn := deg_to_rad(tuning.stick_look_speed) * delta
	_turn(-look.x * turn, -look.y * turn)
	var blend := 1.0 - exp(-tuning.camera_follow_sharpness * delta)
	global_position = global_position.lerp(_pivot(), blend)
	_apply()


func _turn(yaw_delta: float, pitch_delta: float) -> void:
	yaw = wrapf(yaw + yaw_delta, -PI, PI)
	if tuning.invert_y:
		pitch_delta = -pitch_delta
	pitch += pitch_delta


func _apply() -> void:
	pitch = clampf(pitch, deg_to_rad(tuning.camera_pitch_min), deg_to_rad(tuning.camera_pitch_max))
	rotation = Vector3(pitch, yaw, 0.0)
	camera.position = Vector3(0.0, 0.0, tuning.camera_distance)


func _pivot() -> Vector3:
	return target.get_global_transform_interpolated().origin + Vector3.UP * tuning.camera_height
