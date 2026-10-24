class_name Breakable
extends StaticBody3D
## Something the horde can be sent to attack: it has health, minions hit it,
## and at zero it breaks. Crates and lamps extend this; each decides what
## breaking looks like in _on_broken().

## Emitted once, when health reaches zero. The node is still valid then.
signal broken

@export var tuning: Tuning

var health := 0.0
var is_broken := false


func _enter_tree() -> void:
	# In the group before any _ready, so the Horde finds every breakable.
	if not is_broken:
		add_to_group("breakables")


func _ready() -> void:
	health = _max_health()


## Distance from the centre at which a minion counts as touching it, metres.
func radius() -> float:
	return 0.5


## True when a broken one leaves sprouts behind.
func grows_sprouts() -> bool:
	return false


## True when sent minions that arrive near it attack it unasked. False for
## things the player must aim at on purpose.
func lures_minions() -> bool:
	return false


func take_damage(amount: float) -> void:
	if is_broken:
		return
	health = maxf(health - amount, 0.0)
	_on_hit()
	if health <= 0.0:
		is_broken = true
		remove_from_group("breakables")
		broken.emit()
		_on_broken()


## Health at the start. Each kind reads it from the tuning.
func _max_health() -> float:
	return 1.0


func _on_hit() -> void:
	pass


func _on_broken() -> void:
	pass
