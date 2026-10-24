class_name Tuning
extends Resource
## Every feel value of the slice. The values live only in res://tuning.tres;
## this script holds their types and meaning. The game shares one instance.
## Edit that file while the game runs and press reload_tuning
## (F5 / gamepad Back / RELOAD) to apply it without a restart.

@export_group("Dark lord")
## Top walk speed, metres per second.
@export var lord_speed: float
## How fast the lord reaches top speed and stops, metres per second squared.
@export var lord_accel: float
## How fast the lord turns to face where he walks, degrees per second.
@export var lord_turn_speed: float

@export_group("Horde")
## Number of minions at the start. Growth and deaths change the count later.
@export_range(0, 200) var minion_count: int
## The horde never grows past this many minions.
@export_range(0, 200) var horde_cap: int
## Top run speed of a minion, metres per second. Keep it above lord_speed
## so the horde can catch up.
@export var minion_speed: float
## Minion acceleration, metres per second squared.
@export var minion_accel: float
## Within this distance of its goal a minion starts to slow down, metres.
@export var minion_slow_radius: float
## Room each minion gets in the follow group and in a sent group, metres.
## The groups grow with the horde.
@export var minion_spacing: float
## Gap from the lord to the front of the follow group, metres.
@export var follow_gap: float
## Minions closer than this push each other apart, metres.
@export var separation_radius: float
## Strength of that push at zero distance, metres per second.
@export var separation_strength: float
## Average health of a minion.
@export var minion_health: float
## Each minion's health differs from minion_health by up to this fraction,
## up or down, picked when it is born. Without it a horde sent into light
## burns to death all at once; with it the weakest go first.
@export_range(0.0, 0.9) var minion_health_spread: float
## Health a minion regains per second while it neither burns nor withers.
@export var minion_regen: float

@export_group("Spore cloud")
## Radius of the spore cloud around the lord, metres. Send and recall reach
## only minions inside it.
##
## Withering: a minion outside the cloud loses wither_rate health per
## second, unless it is on task. A minion is on task while it runs to a send
## point or attacks a target, and that point or target is within
## send_max_range of the lord. An idle or following minion outside the
## cloud withers; so does a worker whose lord walks out of send range.
@export var spore_cloud_radius: float
## Health per second a minion outside the cloud loses, as described above.
@export var wither_rate: float

@export_group("Sprouts")
## A broken crate grows a random number of new minions in this range,
## never past horde_cap.
@export_range(0, 20) var sprouts_min: int
@export_range(0, 20) var sprouts_max: int
## Seconds a sprout takes to grow out of the ground before it follows.
@export var sprout_grow_time: float

@export_group("Light")
## Radius of the hard-edged circle of light under a lamp, metres.
@export var lamp_light_radius: float
## Health per second a minion inside lamp light loses.
@export var light_burn_rate: float
## Health of a lamp. At zero it goes out and its ground stays dark.
@export var lamp_health: float

@export_group("Send")
## Furthest the horde can be sent from the lord, metres. Also the range that
## keeps working minions on task (see spore_cloud_radius).
@export var send_max_range: float
## An aim point this close to a target's edge targets it, metres.
@export var aim_snap_radius: float
## A sent minion that arrives this close to a target's edge attacks it, metres.
@export var crate_seek_radius: float
## Height of the aim reticle on screen, 0 = top, 1 = bottom.
@export_range(0.05, 0.95) var aim_screen_y: float

@export_group("Attack")
## Damage of one minion hit.
@export var attack_damage: float
## Seconds between the hits of one minion.
@export var attack_interval: float
## A minion hits a target when it is this close to the target's edge, metres.
@export var attack_reach: float
## Health of a new crate.
@export var crate_health: float

@export_group("Camera")
## Distance from the camera to the point it orbits, metres.
@export var camera_distance: float
## Height of the orbit point above the lord's feet, metres.
@export var camera_height: float
## Pitch at start, degrees. Negative looks down.
@export var camera_pitch_default: float
@export var camera_pitch_min: float
@export var camera_pitch_max: float
## Degrees of turn per pixel of mouse motion.
@export var mouse_sensitivity: float
## Degrees per second at full right-stick tilt.
@export var stick_look_speed: float
## Higher is a tighter camera follow. 0 freezes the camera.
@export var camera_follow_sharpness: float
@export var invert_y: bool

@export_group("Touch")
## Degrees of camera turn per dp of finger drag on the right side.
@export var touch_look_sensitivity: float
## Finger travel from the stick centre to full speed, dp.
@export var touch_stick_radius: float


## Radius of a group of [param count] minions at minion_spacing, metres.
func group_radius(count: int) -> float:
	return minion_spacing * sqrt(maxf(count, 1) / PI)


## Distance from the lord to the centre of the follow group, metres.
func follow_distance(count: int) -> float:
	return follow_gap + group_radius(count)


## Furthest a following minion should settle from the lord, metres.
## Derived, so the follow group and the check for it cannot disagree.
func follow_radius(count: int) -> float:
	return follow_gap + 2.0 * group_radius(count) + separation_radius


## Copies every exported value from [param other] into this instance and
## emits [signal Resource.changed]. Nodes keep their reference to this one.
func copy_from(other: Tuning) -> void:
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			set(property.name, other.get(property.name))
	emit_changed()
