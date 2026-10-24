class_name RotPatch
extends MeshInstance3D
## Rot on the ground: the mottled patch of rot.gdshader and a scatter of
## small glowing caps that grow on it. A lamp shows one where its light
## was once it goes out. Set the size with set_radius().

const SHADER := preload("res://game/rot.gdshader")
## Height above the ground, metres. Above the spore cloud, below lamp light.
const LIFT := 0.025
## Caps keep this far from the centre, so they stay clear of a lamp post.
const CLEAR_CENTRE := 0.8

@export var look: Look

var _material := ShaderMaterial.new()
var _radius := 1.0
var _caps := MultiMeshInstance3D.new()


func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = PlaneMesh.new()
	_material.shader = SHADER
	material_override = _material
	var cap := SphereMesh.new()
	cap.is_hemisphere = true
	cap.radius = 0.17
	cap.height = 0.14
	cap.radial_segments = 12
	cap.rings = 4
	var caps := MultiMesh.new()
	caps.transform_format = MultiMesh.TRANSFORM_3D
	caps.mesh = cap
	_caps.multimesh = caps
	_caps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_caps)


func _ready() -> void:
	position.y = LIFT
	_caps.position.y = -LIFT
	_material.set_shader_parameter("seed", fmod(absf(global_position.x * 1.3 + global_position.z * 0.7), 17.0))
	_caps.material_override = look.minion_material(&"cap")
	look.changed.connect(_apply)
	_apply()


func set_radius(radius: float) -> void:
	_radius = radius
	var plane := mesh as PlaneMesh
	# The ragged edge reaches past the radius by up to 4 %.
	var across := 2.0 * radius * 1.1
	plane.size = Vector2(across, across)
	_material.set_shader_parameter("radius", radius)
	if is_node_ready():
		_scatter()


func _apply() -> void:
	_material.set_shader_parameter("deep", look.rot_deep)
	_material.set_shader_parameter("bloom", look.rot_bloom)
	_material.set_shader_parameter("speck", look.rot_speck)
	_material.set_shader_parameter("speck_strength", look.rot_speck_strength)
	_scatter()


## Places the caps at the same spots every time for this patch.
func _scatter() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = hash(Vector2i(roundi(global_position.x * 10.0), roundi(global_position.z * 10.0)))
	var caps := _caps.multimesh
	caps.instance_count = look.rot_caps
	for i in look.rot_caps:
		var r := lerpf(CLEAR_CENTRE, _radius * 0.85, sqrt(random.randf()))
		var at := Vector3.RIGHT.rotated(Vector3.UP, random.randf() * TAU) * r
		var size := random.randf_range(0.6, 1.4)
		var turn := Basis(Vector3.UP, random.randf() * TAU).scaled(Vector3(size, size * random.randf_range(0.8, 1.3), size))
		caps.set_instance_transform(i, Transform3D(turn, at))
