class_name GroundCircle
extends MeshInstance3D
## A circle drawn flat on the ground with ground_circle.gdshader. Set its
## colours with paint() (the owner reads them from look.tres), the shape with
## the exports, and the size with set_radius().

const SHADER := preload("res://game/ground_circle.gdshader")
## Height above the ground, metres. Higher circles draw over lower ones.
@export var lift := 0.02
## Half-width of the fade at the outer edge, metres.
@export var softness := 0.02

var _material := ShaderMaterial.new()


func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = PlaneMesh.new()
	_material.shader = SHADER
	material_override = _material


func _ready() -> void:
	position.y = lift
	_material.set_shader_parameter("softness", softness)


## Sets the fill colour and alpha, and the colour, alpha, and width (metres)
## of the band at the edge.
func paint(fill: Color, fill_alpha: float, edge: Color, edge_alpha: float, edge_width: float) -> void:
	_material.set_shader_parameter("colour", fill)
	_material.set_shader_parameter("fill_alpha", fill_alpha)
	_material.set_shader_parameter("edge_colour", edge)
	_material.set_shader_parameter("edge_alpha", edge_alpha)
	_material.set_shader_parameter("edge_width", edge_width)


func set_radius(radius: float) -> void:
	var plane := mesh as PlaneMesh
	var across := 2.0 * (radius + softness + 0.1)
	plane.size = Vector2(across, across)
	_material.set_shader_parameter("radius", radius)
