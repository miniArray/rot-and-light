class_name Minion
extends CharacterBody3D
## One member of the horde. A minion always has exactly one order; the Horde
## gives orders, calls step() each physics frame with its separation push,
## and calls expose() with the hazards at its spot.

enum Order {
	## Keep to follow_point, a slot in the loose group behind the lord.
	FOLLOW,
	## Run to order_point; on arrival attack a crate in reach, else idle.
	MOVE,
	## Run to order_target and hit it until it breaks, then idle.
	ATTACK,
	## Stand at the current spot.
	IDLE,
}

## What hurts a minion at its spot this frame.
enum Hazard { NONE, WITHER, BURN }

## Radius of the body, metres. Matches the collision capsule.
const BODY_RADIUS := 0.25
const ARRIVE_TOLERANCE := 0.15
const TURN_SPEED := 12.0
## How fast the burning and withering looks ease in and out, per second.
const STATE_EASE := 5.0
## A withering minion shows at least this much of the withered look at once,
## so the state reads before its health has dropped.
const WITHER_SHOWS := 0.45
const EMBER_LIFETIME := 0.7

var tuning: Tuning
var look: Look
## The lord this minion serves. A settled follower turns to face him.
var lord: Node3D
var order := Order.FOLLOW
## Goal of a MOVE order. Unused by other orders.
var order_point := Vector3.ZERO
## Target of an ATTACK order. Unused by other orders.
var order_target: Breakable = null
## The minion's slot in the follow group. The Horde updates it every frame.
var follow_point := Vector3.ZERO
var health := 0.0
## This minion's full health: minion_health, give or take
## minion_health_spread.
var max_health := 0.0
## The hazard of the last expose() call.
var hazard := Hazard.NONE

var _cooldown := 0.0
var _growing := 0.0
## The shown burning and withering, 0 to 1. They ease toward the hazard.
var _burn := 0.0
var _wither := 0.0
var _shown_burn := -1.0
var _shown_wither := -1.0
var _embers := CPUParticles3D.new()

@onready var _body: Node3D = $Body
@onready var _pose: Node3D = $Body/Pose
@onready var _stalk: MeshInstance3D = $Body/Pose/Stalk
@onready var _cap: MeshInstance3D = $Body/Pose/Cap


func _ready() -> void:
	max_health = tuning.minion_health * (1.0 + randf_range(-1.0, 1.0) * tuning.minion_health_spread)
	health = max_health
	_stalk.material_override = look.minion_material(&"stalk")
	_cap.material_override = look.minion_material(&"cap")
	($Body/Pose/Eyes as MeshInstance3D).material_override = look.material(&"ink_colour")
	var phase := randf() * TAU
	_stalk.set_instance_shader_parameter(&"phase", phase)
	_cap.set_instance_shader_parameter(&"phase", phase)
	# The pose moves every drawn frame (shake, droop), not on physics ticks.
	_pose.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_make_embers()
	look.changed.connect(_paint_embers)


func _process(delta: float) -> void:
	var burn_goal := 1.0 if hazard == Hazard.BURN else 0.0
	var wither_goal := 0.0
	if hazard == Hazard.WITHER:
		wither_goal = lerpf(WITHER_SHOWS, 1.0, clampf(1.0 - health / max_health, 0.0, 1.0))
	var blend := 1.0 - exp(-STATE_EASE * delta)
	_burn = lerpf(_burn, burn_goal, blend)
	_wither = lerpf(_wither, wither_goal, blend)
	_show_state()


## Burning: the shader flickers and rims the minion in warm light; here it
## shakes and throws embers. Withering: the shader fades its colour and cap
## glow; here it droops forward and shrinks.
func _show_state() -> void:
	if absf(_burn - _shown_burn) > 0.01 or absf(_wither - _shown_wither) > 0.01:
		_shown_burn = _burn
		_shown_wither = _wither
		for part in [_stalk, _cap]:
			part.set_instance_shader_parameter(&"burn", _burn)
			part.set_instance_shader_parameter(&"wither", _wither)
		var size := lerpf(1.0, look.wither_shrink, _wither)
		_pose.scale = Vector3(size, size * lerpf(1.0, 0.85, _wither), size)
		_pose.rotation.x = -deg_to_rad(look.wither_droop_degrees) * _wither
	if _burn > 0.05:
		var shake := look.burn_shake * _burn
		_pose.position = Vector3(randf_range(-shake, shake), absf(randf_range(-shake, shake)), randf_range(-shake, shake))
	elif _pose.position != Vector3.ZERO:
		_pose.position = Vector3.ZERO
	_embers.emitting = _burn > 0.5


## One spark mesh for every minion's embers.
static var _spark_mesh: QuadMesh


static func _spark() -> QuadMesh:
	if _spark_mesh:
		return _spark_mesh
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 0.14
	# A soft round spark, made here: no image file.
	var spark := GradientTexture2D.new()
	spark.width = 16
	spark.height = 16
	spark.fill = GradientTexture2D.FILL_RADIAL
	spark.fill_from = Vector2(0.5, 0.5)
	spark.fill_to = Vector2(1.0, 0.5)
	spark.gradient = Gradient.new()
	spark.gradient.set_color(0, Color.WHITE)
	spark.gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var glow := StandardMaterial3D.new()
	glow.albedo_texture = spark
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	glow.vertex_color_use_as_albedo = true
	quad.material = glow
	_spark_mesh = quad
	return quad


func _make_embers() -> void:
	_embers.mesh = _spark()
	_embers.emitting = false
	_embers.lifetime = EMBER_LIFETIME
	_embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_embers.emission_sphere_radius = 0.28
	_embers.direction = Vector3.UP
	_embers.spread = 35.0
	_embers.initial_velocity_min = 1.2
	_embers.initial_velocity_max = 2.6
	_embers.gravity = Vector3(0.0, 1.5, 0.0)
	_embers.scale_amount_min = 0.6
	_embers.scale_amount_max = 1.3
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 0.85, 1.0))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	_embers.color_ramp = fade
	_embers.position = Vector3.UP * 0.55
	_embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_embers)
	_paint_embers()


func _paint_embers() -> void:
	_embers.amount = maxi(1, roundi(look.ember_rate * EMBER_LIFETIME))
	_embers.color = Color(look.burn_colour * 1.8, 1.0)
	# Apply droop and shrink again on the next frame, with the new values.
	_shown_burn = -1.0


## Grows the minion out of the ground over sprout_grow_time. It stands
## still until grown.
func sprout() -> void:
	_growing = tuning.sprout_grow_time
	_body.scale = Vector3.ONE * 0.05
	var grow := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	grow.tween_property(_body, "scale", Vector3.ONE, tuning.sprout_grow_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func is_growing() -> bool:
	return _growing > 0.0


func is_dead() -> bool:
	return health <= 0.0


func follow() -> void:
	order = Order.FOLLOW
	order_target = null


func move_to(point: Vector3) -> void:
	order = Order.MOVE
	order_point = point
	order_target = null


func attack(target: Breakable) -> void:
	order = Order.ATTACK
	order_target = target
	# Spread the first hits so the horde does not strike in unison.
	_cooldown = randf() * tuning.attack_interval


func idle() -> void:
	order = Order.IDLE
	order_target = null


## True while the minion carries out a send whose point or target is within
## [param send_range] of [param lord_position]. See Tuning.spore_cloud_radius.
func is_on_task(lord_position: Vector3, send_range: float) -> bool:
	match order:
		Order.MOVE:
			return _flat(order_point - lord_position).length() <= send_range
		Order.ATTACK:
			return _target_alive() and _flat(order_target.global_position - lord_position).length() <= send_range
	return false


## Applies one frame of [param what]: burning and withering take health,
## no hazard heals. The Horde removes the minion once it is dead.
func expose(what: Hazard, delta: float) -> void:
	hazard = what
	match what:
		Hazard.BURN:
			health -= tuning.light_burn_rate * delta
		Hazard.WITHER:
			health -= tuning.wither_rate * delta
		Hazard.NONE:
			health = minf(health + tuning.minion_regen * delta, max_health)


func step(delta: float, separation: Vector3) -> void:
	var wanted := Vector3.ZERO
	if _growing > 0.0:
		_growing -= delta
	else:
		wanted = (_order_velocity(delta) + separation).limit_length(tuning.minion_speed * 1.25)
	var flat := Vector3(velocity.x, 0.0, velocity.z).move_toward(wanted, tuning.minion_accel * delta)
	velocity.x = flat.x
	velocity.z = flat.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity += get_gravity() * delta
	move_and_slide()
	_face(flat, delta)


func _order_velocity(delta: float) -> Vector3:
	match order:
		Order.FOLLOW:
			return _arrive(follow_point, ARRIVE_TOLERANCE)
		Order.MOVE:
			# A crate in the way, or one near the goal, gets attacked.
			var bumped := _nearest_lure(tuning.attack_reach)
			if bumped:
				attack(bumped)
				return Vector3.ZERO
			if _flat(order_point - global_position).length() <= tuning.minion_slow_radius * 0.5:
				var lure := _nearest_lure(tuning.crate_seek_radius)
				if lure:
					attack(lure)
				else:
					idle()
				return Vector3.ZERO
			return _arrive(order_point, 0.0)
		Order.ATTACK:
			if not _target_alive():
				idle()
				return Vector3.ZERO
			var touch := order_target.radius() + BODY_RADIUS
			var gap := _flat(order_target.global_position - global_position).length() - touch
			if gap > tuning.attack_reach:
				return _arrive(order_target.global_position, touch + tuning.attack_reach * 0.5)
			_cooldown -= delta
			if _cooldown <= 0.0:
				_cooldown += tuning.attack_interval
				_hit(order_target)
			return Vector3.ZERO
	return Vector3.ZERO


## True when this minion is close enough to its ATTACK target to hit it.
func is_hitting() -> bool:
	if order != Order.ATTACK or not _target_alive():
		return false
	var gap := _flat(order_target.global_position - global_position).length() - order_target.radius() - BODY_RADIUS
	return gap <= tuning.attack_reach


func _hit(target: Breakable) -> void:
	target.take_damage(tuning.attack_damage)
	var lunge := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	lunge.tween_property(_body, "position:z", -0.3, 0.07)
	lunge.tween_property(_body, "position:z", 0.0, 0.15)


func _arrive(target: Vector3, stop_distance: float) -> Vector3:
	var to := _flat(target - global_position)
	var distance := to.length()
	if distance <= stop_distance + 0.001:
		return Vector3.ZERO
	var speed := tuning.minion_speed * clampf((distance - stop_distance) / tuning.minion_slow_radius, 0.0, 1.0)
	return to / distance * speed


func _target_alive() -> bool:
	return is_instance_valid(order_target) and not order_target.is_broken


## The nearest unbroken target that draws minions without an aimed send
## (a crate, not a lamp) whose edge is within [param max_gap] of this
## minion's edge, or null.
func _nearest_lure(max_gap: float) -> Breakable:
	var best: Breakable = null
	var best_gap := max_gap
	for node in get_tree().get_nodes_in_group("breakables"):
		var target := node as Breakable
		if target.is_broken or not target.lures_minions():
			continue
		var gap := _flat(target.global_position - global_position).length() - target.radius() - BODY_RADIUS
		if gap <= best_gap:
			best = target
			best_gap = gap
	return best


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _face(flat_velocity: Vector3, delta: float) -> void:
	var look := flat_velocity
	if order == Order.ATTACK and _target_alive():
		look = order_target.global_position - global_position
	elif order == Order.FOLLOW and flat_velocity.length_squared() < 0.25:
		look = lord.global_position - global_position
	look.y = 0.0
	if look.length_squared() < 0.04:
		return
	var facing := atan2(-look.x, -look.z)
	rotation.y = lerp_angle(rotation.y, facing, 1.0 - exp(-TURN_SPEED * delta))
