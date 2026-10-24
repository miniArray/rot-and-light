class_name Ink
extends MeshInstance3D
## The ink outline pass: a quad that covers the screen and draws
## ink.gdshader over the finished scene. Put it under the Camera3D.

const SHADER := preload("res://game/ink.gdshader")

@export var look: Look

var _material := ShaderMaterial.new()


func _init() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	mesh = quad
	_material.shader = SHADER
	# Draw after every other transparent thing, such as the ground circles.
	_material.render_priority = Material.RENDER_PRIORITY_MAX
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The vertex shader places the quad on the screen, so it must never be
	# culled where it really is.
	extra_cull_margin = 16384.0


func _ready() -> void:
	look.changed.connect(_apply)
	_apply()


func _apply() -> void:
	_material.set_shader_parameter("ink_colour", look.ink_colour)
	_material.set_shader_parameter("ink_width", look.ink_width)
	_material.set_shader_parameter("depth_threshold", look.ink_depth_threshold)
	_material.set_shader_parameter("crease_cos", cos(deg_to_rad(look.ink_crease_degrees)))
	_material.set_shader_parameter("fade_start", look.ink_fade_start)
	_material.set_shader_parameter("fade_end", look.ink_fade_end)
