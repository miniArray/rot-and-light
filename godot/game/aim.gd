class_name Aim
extends Node3D
## Where a send would go. Each physics frame it casts a ray from the camera
## through the on-screen reticle and finds the point on the ground, clamped
## to send_max_range from the lord, and the target there, if any: a crate or
## lamp the ray hits or the point is near, else a lamp whose light holds the
## point. The child Marker shows the point; it turns red over a target.

@export var tuning: Tuning
@export var camera_rig: CameraRig
@export var lord: Node3D

const WORLD_LAYERS := 1 | 8  # world, breakables
const RAY_LENGTH := 500.0
const GROUND_COLOUR := Color(0.95, 0.9, 0.5, 0.8)
const TARGET_COLOUR := Color(1.0, 0.3, 0.2, 0.9)

## The aim point on the ground.
var point := Vector3.ZERO
## The crate or lamp the aim targets, or null.
var target: Breakable = null

@onready var _marker: MeshInstance3D = $Marker
@onready var _marker_material: StandardMaterial3D = _marker.get_active_material(0)


func _ready() -> void:
	top_level = true


## Screen position of the reticle in the viewport, pixels.
func reticle_position() -> Vector2:
	var size := get_viewport().get_visible_rect().size
	return Vector2(size.x * 0.5, size.y * tuning.aim_screen_y)


func _physics_process(_delta: float) -> void:
	var camera := camera_rig.camera
	var screen := reticle_position()
	var from := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * RAY_LENGTH, WORLD_LAYERS)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)

	var lord_position := lord.global_position
	var ground: Vector3
	if hit:
		ground = hit.position
	elif direction.y < -0.001:
		ground = from + direction * (lord_position.y - from.y) / direction.y
	else:
		ground = lord_position + Vector3(direction.x, 0.0, direction.z).normalized() * tuning.send_max_range

	var offset := Vector3(ground.x - lord_position.x, 0.0, ground.z - lord_position.z)
	if offset.length() > tuning.send_max_range:
		offset = offset.normalized() * tuning.send_max_range
	point = Vector3(lord_position.x + offset.x, lord_position.y, lord_position.z + offset.z)

	if hit and hit.collider is Breakable and not hit.collider.is_broken and offset.length() < tuning.send_max_range:
		target = hit.collider
	else:
		target = _target_near(point)

	global_position = point
	_marker_material.albedo_color = TARGET_COLOUR if target else GROUND_COLOUR


func _target_near(at: Vector3) -> Breakable:
	var best: Breakable = null
	var best_gap := tuning.aim_snap_radius
	for node in get_tree().get_nodes_in_group("breakables"):
		var candidate := node as Breakable
		var gap := Vector2(at.x - candidate.global_position.x, at.z - candidate.global_position.z).length() - candidate.radius()
		if gap <= best_gap:
			best = candidate
			best_gap = gap
	if best:
		return best
	for node in get_tree().get_nodes_in_group("lamps"):
		if (node as Lamp).lights(at):
			return node
	return null
