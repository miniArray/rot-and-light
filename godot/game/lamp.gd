class_name Lamp
extends Breakable
## A post with a glowing top that lights a hard-edged circle on the ground.
## Minions in the light burn. The horde can be sent at the post; at zero
## health the lamp goes out, its light disappears, and rot spreads over the
## ground where the light was. The rot stays.

## Radius of the post's base, metres. Matches the collision shape.
const POST_RADIUS := 0.45
## Height of the flame above the ground, metres. Matches the Top node.
const FLAME_HEIGHT := 3.2
## Height at which the reach of the light on things matches the lit disc:
## the middle of a minion, metres.
const LIT_HEIGHT := 0.45

@export var look: Look

@onready var _post: MeshInstance3D = $Post
@onready var _base: MeshInstance3D = $Base
@onready var _top: MeshInstance3D = $Top
@onready var _glow: OmniLight3D = $Glow
@onready var _light: GroundCircle = $Light
@onready var _rot: RotPatch = $Rot
@onready var _bar: Node3D = $HealthBar


func _ready() -> void:
	super()
	add_to_group("lamps")
	_rot.visible = false
	_bar.visible = false
	tuning.changed.connect(_size_light)
	look.changed.connect(_paint)
	_paint()
	_size_light()


func radius() -> float:
	return POST_RADIUS


## True while the lamp burns and [param point] is inside its light.
func lights(point: Vector3) -> bool:
	if is_broken:
		return false
	var offset := point - global_position
	return Vector2(offset.x, offset.z).length() <= tuning.lamp_light_radius


func _max_health() -> float:
	return tuning.lamp_health


func _on_hit() -> void:
	_bar.visible = true
	_bar.scale.x = maxf(health / tuning.lamp_health, 0.001)
	_top.set_instance_shader_parameter("flash", 1.0)
	var flash := create_tween()
	flash.tween_method(func(f: float) -> void: _top.set_instance_shader_parameter(&"flash", f), 1.0, 0.0, 0.12)


func _on_broken() -> void:
	_light.visible = false
	_glow.visible = false
	_bar.visible = false
	_top.material_override = look.material(&"lamp_iron")
	_rot.visible = true
	# The rot spreads out from the post.
	_rot.scale = Vector3.ONE * 0.1
	var spread := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	spread.tween_property(_rot, "scale", Vector3.ONE, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _paint() -> void:
	var iron := look.material(&"lamp_iron")
	_post.material_override = iron
	_base.material_override = iron
	if not is_broken:
		_top.material_override = look.material(&"flame", &"flame", &"flame_glow")
	_glow.light_color = look.lamp_colour
	_glow.light_energy = look.lamp_energy
	_light.paint(look.lamp_ground, look.lamp_ground_alpha, look.lamp_rim, 1.0, look.lamp_rim_width)


## The lit disc and the reach of the lamp's light on things both match
## lamp_light_radius, so whatever stands in the burning zone is lit, and
## nothing outside it.
func _size_light() -> void:
	_light.set_radius(tuning.lamp_light_radius)
	_rot.set_radius(tuning.lamp_light_radius)
	# The light hangs at the flame. Its range is a sphere, so it reaches the
	# edge of the burning zone exactly at LIT_HEIGHT, a little inside it at
	# the feet and a little outside it at the cap.
	_glow.omni_range = sqrt(tuning.lamp_light_radius ** 2 + (FLAME_HEIGHT - LIT_HEIGHT) ** 2)
