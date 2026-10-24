extends "res://tests/scene_base.gd"
## Send the horde at a crate through the input actions: the crate breaks in
## time. Walk until the whole horde is inside the spore cloud, recall: every
## minion returns to the follow group without overlapping another.
##
##   godot4 --headless --path godot --script res://tests/horde_test.gd

const BREAK_LIMIT := 20.0
const RECALL_LIMIT := 10.0


func _run(main: Node):
	var tuning: Tuning = main.tuning
	var rig: CameraRig = main.get_node("CameraRig")
	var aim: Aim = main.get_node("Aim")
	var horde: Horde = main.get_node("Horde")
	var lord: DarkLord = main.get_node("DarkLord")
	var crate: Crate = main.get_node("Crates/Crate1")

	if horde.minions.size() != tuning.minion_count:
		return fail("expected %d minions, found %d" % [tuning.minion_count, horde.minions.size()])

	if not await InputDriver.face(self, rig, crate.global_position):
		return fail("the camera did not turn to face the crate")
	if not await InputDriver.walk_until_aimed(self, aim, crate):
		return fail("the aim never reached the crate")
	InputDriver.tap("send")

	var sent_at := now()
	var most_hitting := 0
	while is_instance_valid(crate) and not crate.is_broken:
		if now() - sent_at > BREAK_LIMIT:
			return fail("the crate still has %.0f health %.0f s after send" % [crate.health, BREAK_LIMIT])
		var hitting := 0
		for minion in horde.minions:
			if minion.is_hitting():
				hitting += 1
		most_hitting = maxi(most_hitting, hitting)
		await physics_frame
	print("ok: crate broke %.1f s after send; up to %d minions hit it at once" % [now() - sent_at, most_hitting])

	# Recall reaches only minions inside the spore cloud.
	var all_hear := func() -> bool: return horde.minions.all(horde.hears)
	if not await InputDriver.hold_until(self, "move_forward", all_hear, 5.0):
		return fail("walking forward never brought the whole horde into the spore cloud")
	InputDriver.tap("recall")
	var recalled_at := now()
	while true:
		var radius := tuning.follow_radius(horde.minions.size())
		var farthest := 0.0
		for minion in horde.minions:
			farthest = maxf(farthest, flat_distance(minion.global_position, lord.global_position))
		var following := horde.count(Minion.Order.FOLLOW)
		if farthest <= radius and following == horde.minions.size():
			print("ok: all %d minions within %.1f m of the lord %.1f s after recall (farthest %.2f m)" % [
				following, radius, now() - recalled_at, farthest])
			break
		if now() - recalled_at > RECALL_LIMIT:
			return fail("%.0f s after recall: %d of %d follow, farthest %.2f m > %.1f m" % [
				RECALL_LIMIT, following, horde.minions.size(), farthest, radius])
		await physics_frame

	# Measure spacing once the group has come to rest; minions that still run
	# into their slots can pass close to each other.
	var settled := func() -> bool:
		return horde.minions.all(func(m: Minion) -> bool: return Vector2(m.velocity.x, m.velocity.z).length() < 0.3)
	if not await wait_until(settled, 6.0):
		return fail("the follow group did not come to rest within 6 s of returning")
	var closest := INF
	for i in horde.minions.size():
		for j in range(i + 1, horde.minions.size()):
			closest = minf(closest, flat_distance(horde.minions[i].global_position, horde.minions[j].global_position))
	if closest < Minion.BODY_RADIUS * 2.0:
		return fail("two minions overlap: centres %.2f m apart" % closest)
	print("ok: closest two minions are %.2f m apart" % closest)
