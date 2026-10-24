class_name Horde
extends Node3D
## Owns the minions. Turns send and recall into orders for the minions inside
## the lord's spore cloud, gives each follower its slot behind the lord,
## keeps minions apart, applies light and withering, removes the dead, and
## grows sprouts where crates break.

## Emitted when minions join or leave.
signal size_changed(count: int)
## Emitted after [param target] broke and grew [param count] sprouts (0 at
## the cap).
signal sprouts_grown(target: Breakable, count: int)

@export var tuning: Tuning
@export var look: Look
@export var lord: DarkLord
@export var aim: Aim

const MINION_SCENE := preload("res://game/minion.tscn")
const BURST := preload("res://game/burst.gd")
const GOLDEN_ANGLE := PI * (3.0 - sqrt(5.0))
## Furthest a sprout lands from the centre of what broke, metres.
const SPROUT_SCATTER := 0.9

var minions: Array[Minion] = []


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("breakables"):
		var target := node as Breakable
		target.broken.connect(_on_broken.bind(target))
	for i in tuning.minion_count:
		var slot := _follow_offset(i, tuning.minion_count)
		_add_minion(lord.global_transform * slot)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("send"):
		send()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("recall"):
		recall()
		get_viewport().set_input_as_handled()


## True when [param minion] is inside the spore cloud and can hear orders.
func hears(minion: Minion) -> bool:
	return _flat(minion.global_position - lord.global_position).length() <= tuning.spore_cloud_radius


## Sends every minion in the spore cloud to the aim: at its target if it has
## one, else to a spread of points around the aim point.
func send() -> void:
	var listening := minions.filter(func(minion: Minion) -> bool:
		return hears(minion) and not minion.is_growing())
	var target := aim.target
	var spread := tuning.group_radius(listening.size())
	for i in listening.size():
		if target:
			listening[i].attack(target)
		else:
			listening[i].move_to(aim.point + _disc_offset(i, listening.size(), spread))


## Adds up to [param count] minions at the back of the follow group, never
## past horde_cap. The debug demo uses it to measure a full horde.
func add_followers(count: int) -> void:
	var room := maxi(tuning.horde_cap - minions.size(), 0)
	for i in mini(count, room):
		var n := minions.size() + 1
		_add_minion(lord.global_transform * _follow_offset(n - 1, n))


## Calls every minion in the spore cloud back to follow.
func recall() -> void:
	for minion in minions:
		if hears(minion):
			minion.follow()


func count(order: Minion.Order) -> int:
	var total := 0
	for minion in minions:
		if minion.order == order:
			total += 1
	return total


func count_hazard(hazard: Minion.Hazard) -> int:
	var total := 0
	for minion in minions:
		if minion.hazard == hazard:
			total += 1
	return total


## What hurts a minion at [param point] with its current order.
func hazard_at(minion: Minion) -> Minion.Hazard:
	var point := minion.global_position
	for node in get_tree().get_nodes_in_group("lamps"):
		if (node as Lamp).lights(point):
			return Minion.Hazard.BURN
	if not hears(minion) and not minion.is_on_task(lord.global_position, tuning.send_max_range):
		return Minion.Hazard.WITHER
	return Minion.Hazard.NONE


func _physics_process(delta: float) -> void:
	var lord_transform := lord.global_transform
	var n := minions.size()
	for i in n:
		minions[i].follow_point = lord_transform * _follow_offset(i, n)
	var pushes := _separation()
	for i in n:
		minions[i].step(delta, pushes[i])
		minions[i].expose(hazard_at(minions[i]), delta)
	var dead := minions.filter(func(minion: Minion) -> bool: return minion.is_dead())
	for minion in dead:
		_kill(minion)


## Pushes, one per minion, away from neighbours and the lord that are too
## close. A push grows linearly from zero at the edge of the radius.
func _separation() -> Array[Vector3]:
	var pushes: Array[Vector3] = []
	pushes.resize(minions.size())
	pushes.fill(Vector3.ZERO)
	var radius := tuning.separation_radius
	for i in minions.size():
		var a := minions[i].global_position
		for j in range(i + 1, minions.size()):
			var apart := _flat(a - minions[j].global_position)
			var distance := apart.length()
			if distance >= radius:
				continue
			# Two minions on the same spot still need a direction.
			var away := apart / distance if distance > 0.001 else Vector3.RIGHT.rotated(Vector3.UP, i)
			var push := away * tuning.separation_strength * (1.0 - distance / radius)
			pushes[i] += push
			pushes[j] -= push
		var lord_radius := lord.body_radius + Minion.BODY_RADIUS + radius * 0.5
		var from_lord := _flat(a - lord.global_position)
		var lord_distance := from_lord.length()
		if lord_distance < lord_radius and lord_distance > 0.001:
			pushes[i] += from_lord / lord_distance * tuning.separation_strength * (1.0 - lord_distance / lord_radius)
	return pushes


## Slot i of n in the follow group, in the lord's local space.
func _follow_offset(i: int, n: int) -> Vector3:
	return Vector3(0.0, 0.0, tuning.follow_distance(n)) + _disc_offset(i, n, tuning.group_radius(n))


## Point i of n spread evenly over a disc of the given radius (a sunflower
## pattern), in the XZ plane.
func _disc_offset(i: int, n: int, radius: float) -> Vector3:
	var r := radius * sqrt((i + 0.5) / maxf(n, 1))
	var angle := i * GOLDEN_ANGLE
	return Vector3(cos(angle) * r, 0.0, sin(angle) * r)


func _add_minion(at: Vector3) -> Minion:
	var minion: Minion = MINION_SCENE.instantiate()
	minion.tuning = tuning
	minion.look = look
	minion.lord = lord
	add_child(minion)
	minion.global_position = at
	minion.rotation.y = lord.rotation.y
	minion.reset_physics_interpolation()
	minions.append(minion)
	size_changed.emit(minions.size())
	return minion


func _kill(minion: Minion) -> void:
	minions.erase(minion)
	var burst := BURST.new()
	burst.material = look.material(&"wither_colour")
	burst.colour = look.wither_colour
	burst.size = 0.6
	add_child(burst)
	burst.global_position = minion.global_position + Vector3.UP * 0.4
	minion.queue_free()
	size_changed.emit(minions.size())


func _on_broken(target: Breakable) -> void:
	if not target.grows_sprouts():
		return
	var room := maxi(tuning.horde_cap - minions.size(), 0)
	var grown := mini(randi_range(tuning.sprouts_min, tuning.sprouts_max), room)
	for i in grown:
		var scatter := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * randf() * SPROUT_SCATTER
		var sprout := _add_minion(Vector3(target.global_position.x, lord.global_position.y, target.global_position.z) + scatter)
		sprout.sprout()
	sprouts_grown.emit(target, grown)


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
