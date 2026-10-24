class_name Crate
extends Breakable
## A breakable box. At zero health it bursts into debris and leaves the
## scene; the Horde grows sprouts where it stood.

## Half the edge length of the box, metres. Matches the collision shape.
@export var half_size := 0.7
@export var look: Look

const DEBRIS := preload("res://game/burst.gd")

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _bar: Node3D = $HealthBar
var _flash: Tween


func _ready() -> void:
	super()
	# Shared by every crate; a hit flashes through a per-instance parameter.
	_mesh.material_override = look.material(&"crate_wood", &"", &"", &"crate_hit")
	_bar.visible = false


func radius() -> float:
	return half_size


func grows_sprouts() -> bool:
	return true


func lures_minions() -> bool:
	return true


func _max_health() -> float:
	return tuning.crate_health


func _on_hit() -> void:
	_bar.visible = true
	_bar.scale.x = maxf(health / tuning.crate_health, 0.001)
	if _flash:
		_flash.kill()
	_mesh.scale = Vector3.ONE * 1.06
	_flash = create_tween().set_parallel().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_flash.tween_method(_set_flash, 1.0, 0.0, 0.15)
	_flash.tween_property(_mesh, "scale", Vector3.ONE, 0.15)


func _on_broken() -> void:
	var debris := DEBRIS.new()
	debris.material = look.material(&"crate_wood")
	debris.colour = look.crate_wood
	debris.size = half_size * 2.0
	get_parent().add_child(debris)
	debris.global_position = global_position + Vector3.UP * half_size
	queue_free()


func _set_flash(amount: float) -> void:
	_mesh.set_instance_shader_parameter(&"flash", amount)
