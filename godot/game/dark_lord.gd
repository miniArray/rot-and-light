class_name DarkLord
extends CharacterBody3D
## The player. Walks on the move_* actions, relative to the camera's yaw,
## and turns to face where he walks. His spore cloud shows on the ground.

@export var tuning: Tuning
@export var look: Look
@export var camera_rig: CameraRig

## Radius minions keep clear of, metres. Matches the collision capsule.
@export var body_radius := 0.45

## Width of the brighter band at the edge of the spore cloud, metres.
const CLOUD_EDGE_WIDTH := 0.5

@onready var _cloud: GroundCircle = $SporeCloud


func _ready() -> void:
	($Capsule as MeshInstance3D).material_override = look.material(&"lord_robe")
	($Visor as MeshInstance3D).material_override = look.material(&"lord_eyes", &"lord_eyes", &"lord_glow")
	($Crown as MeshInstance3D).material_override = look.minion_material(&"crown")
	tuning.changed.connect(_size_cloud)
	look.changed.connect(_paint_cloud)
	_size_cloud()
	_paint_cloud()


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := camera_rig.yaw_basis() * Vector3(input.x, 0.0, input.y)
	var wanted := direction * tuning.lord_speed
	var flat := Vector3(velocity.x, 0.0, velocity.z).move_toward(wanted, tuning.lord_accel * delta)
	velocity.x = flat.x
	velocity.z = flat.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity += get_gravity() * delta
	move_and_slide()

	if direction.length_squared() > 0.01:
		var facing := atan2(-direction.x, -direction.z)
		var step := deg_to_rad(tuning.lord_turn_speed) * delta
		rotation.y = rotate_toward(rotation.y, facing, step)


func _size_cloud() -> void:
	_cloud.set_radius(tuning.spore_cloud_radius)


func _paint_cloud() -> void:
	_cloud.paint(look.spore_colour, look.spore_fill_alpha, look.spore_colour, look.spore_edge_alpha, CLOUD_EDGE_WIDTH)
