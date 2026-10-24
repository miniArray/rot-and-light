extends "res://tests/scene_base.gd"
## Rule 1 through the input actions: a broken crate grows sprouts_min to
## sprouts_max new minions that follow, and growth stops at horde_cap.
##
##   godot4 --headless --path godot --script res://tests/sprout_test.gd
##
## First crate: normal tuning, expect 1 to 3 sprouts. Second crate: the cap
## set one above the horde and 3 sprouts asked for, expect exactly 1.
## Third crate: the horde at the cap, expect none.

const BREAK_LIMIT := 25.0

var _grown: Array[int] = []
var _target_id := 0
## For each break: whether every new sprout was growing in follow right then.
var _fresh_ok: Array[bool] = []


func _run(main: Node):
	var tuning: Tuning = main.tuning
	var horde: Horde = main.get_node("Horde")
	# Growth needs a stable horde count. Lamp2 can burn followers near Crate2
	# while the camera turns for Crate3, opening a slot after the cap is set.
	# Light and burning remain covered by the separate lamp/light tests.
	for lamp in main.get_node("Lamps").get_children():
		lamp.free()
	horde.sprouts_grown.connect(func(target: Breakable, count: int) -> void:
		if target.get_instance_id() != _target_id:
			fail("unexpected growth signal from %s" % target.name)
			return
		_grown.append(count)
		var fresh := horde.minions.slice(horde.minions.size() - count)
		_fresh_ok.append(fresh.all(func(m: Minion) -> bool:
			return m.order == Minion.Order.FOLLOW and m.is_growing())))

	var before := horde.minions.size()
	var grown: int = await _break(main, "Crates/Crate1")
	if failed():
		return
	if grown < tuning.sprouts_min or grown > tuning.sprouts_max:
		return fail("the crate grew %d sprouts; tuning allows %d to %d" % [grown, tuning.sprouts_min, tuning.sprouts_max])
	if not _fresh_ok[0]:
		return fail("a new sprout was not growing in follow when it appeared")
	await create_timer(tuning.sprout_grow_time + 0.2).timeout
	if horde.minions.any(func(m: Minion) -> bool: return m.is_growing()):
		return fail("sprouts still grow longer than sprout_grow_time")
	print("ok: crate 1 grew %d sprouts (allowed %d to %d); the horde went from %d to %d" % [
		grown, tuning.sprouts_min, tuning.sprouts_max, before, horde.minions.size()])

	tuning.horde_cap = horde.minions.size() + 1
	tuning.sprouts_min = 3
	tuning.sprouts_max = 3
	grown = await _break(main, "Crates/Crate2")
	if failed():
		return
	if grown != 1 or horde.minions.size() > tuning.horde_cap:
		return fail("one below the cap with 3 sprouts asked for, the crate grew %d; horde %d, cap %d" % [
			grown, horde.minions.size(), tuning.horde_cap])
	print("ok: crate 2 grew 1 sprout of 3 asked for, stopping at the cap of %d" % tuning.horde_cap)

	tuning.horde_cap = horde.minions.size()
	# The same horde is at the cap: no sprout can fit.
	grown = await _break(main, "Crates/Crate3")
	if failed():
		return
	if grown != 0:
		return fail("at the cap the crate grew %d sprouts" % grown)
	print("ok: crate 3 grew nothing with the horde at the cap of %d" % tuning.horde_cap)


## Recalls the horde, aims at the crate at [param path], sends, and returns
## the number of sprouts it grew. Calls fail() on a problem.
func _break(main: Node, path: String) -> int:
	var rig: CameraRig = main.get_node("CameraRig")
	var aim: Aim = main.get_node("Aim")
	var horde: Horde = main.get_node("Horde")
	var crate: Crate = main.get_node(path)
	var spot := crate.global_position
	var before := horde.minions.size()
	_target_id = crate.get_instance_id()

	InputDriver.tap("recall")
	await settle()
	if not await InputDriver.face(self, rig, spot):
		fail("the camera did not turn to face %s" % path)
		return -1
	if not await InputDriver.walk_until_aimed(self, aim, crate):
		fail("the aim never reached %s" % path)
		return -1
	if horde.minions.size() != before:
		fail("the horde changed from %d to %d before sending at %s" % [before, horde.minions.size(), path])
		return -1
	var reports := _grown.size()
	InputDriver.tap("send")
	if not await wait_until(func() -> bool: return _grown.size() > reports, BREAK_LIMIT):
		fail("%s did not break within %.0f s" % [path, BREAK_LIMIT])
		return -1
	# Walk to the spot so the horde is inside the spore cloud for the next send.
	await InputDriver.hold_until(self, "move_forward",
		func() -> bool: return flat_distance(horde.lord.global_position, spot) < 3.0, 4.0)
	if horde.minions.size() != before + _grown[reports]:
		fail("the horde lost minions while breaking %s; the cap precondition did not hold" % path)
		return -1
	return _grown[reports]
