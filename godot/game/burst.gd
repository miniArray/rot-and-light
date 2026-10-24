extends Node3D
## A short burst for something that breaks or dies: small cubes fly out,
## fall, and shrink away, then the node frees itself.

const PIECES := 12
const LIFETIME := 0.9
const GRAVITY := 18.0

## Material of the pieces, such as a shared toon material from Look.
var material: Material
## Colour of the puff on the ground.
var colour := Color.WHITE
## Size of the thing that burst, metres.
var size := 1.4

var _age := 0.0
var _pieces: Array[MeshInstance3D] = []
var _velocities: Array[Vector3] = []
var _spins: Array[Vector3] = []


func _ready() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * size * 0.28
	mesh.material = material
	for i in PIECES:
		var piece := MeshInstance3D.new()
		piece.mesh = mesh
		piece.position = Vector3(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4), randf_range(-0.4, 0.4)) * size
		add_child(piece)
		_pieces.append(piece)
		var out := Vector3(piece.position.x, 0.0, piece.position.z).normalized()
		_velocities.append(out * randf_range(2.0, 5.0) + Vector3.UP * randf_range(3.0, 7.0))
		_spins.append(Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9)))
	# A flat puff on the ground that grows and fades.
	var puff := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = size * 0.6
	disc.bottom_radius = size * 0.6
	disc.height = 0.02
	var puff_material := StandardMaterial3D.new()
	puff_material.albedo_color = Color(colour, 0.6)
	puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material = puff_material
	puff.mesh = disc
	puff.position = Vector3.DOWN * size * 0.48
	add_child(puff)
	var grow := create_tween().set_parallel().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	grow.tween_property(puff, "scale", Vector3(3.0, 1.0, 3.0), LIFETIME)
	grow.tween_property(puff_material, "albedo_color:a", 0.0, LIFETIME)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var floor_y := -size * 0.5
	var shrink := 1.0 - pow(_age / LIFETIME, 3.0)
	for i in _pieces.size():
		var piece := _pieces[i]
		_velocities[i].y -= GRAVITY * delta
		piece.position += _velocities[i] * delta
		if piece.position.y < floor_y:
			piece.position.y = floor_y
			_velocities[i] *= Vector3(0.6, -0.3, 0.6)
		piece.rotation += _spins[i] * delta
		piece.scale = Vector3.ONE * shrink
