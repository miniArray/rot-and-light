extends "res://tests/scene_base.gd"
## Rule 2, the spore cloud, through the input actions:
## 1. Send the horde beyond the cloud. Running there on task, no minion
##    withers. Idle out there, they wither. The lord walks back to them in
##    time and recalls: every minion survives and heals.
## 2. Send the horde beyond the cloud again and walk away: every minion left
##    outside withers and dies.
##
##   godot4 --headless --path godot --script res://tests/wither_test.gd

## How far beyond the cloud's edge the horde is sent, metres.
const BEYOND := 4.0


func _run(main: Node):
	var tuning: Tuning = main.tuning
	var rig: CameraRig = main.get_node("CameraRig")
	var aim: Aim = main.get_node("Aim")
	var horde: Horde = main.get_node("Horde")
	var lord: DarkLord = main.get_node("DarkLord")
	var count := horde.minions.size()

	# 1. Toward open ground behind the start (+z).
	if not await InputDriver.face(self, rig, lord.global_position + Vector3(0.0, 0.0, 10.0)):
		return fail("the camera did not turn")
	if not await _send_beyond(aim, lord, tuning):
		return
	var on_task_withering := 0
	while horde.count(Minion.Order.MOVE) > 0:
		var moving_and_withering := horde.minions.filter(func(m: Minion) -> bool:
			return m.order == Minion.Order.MOVE and m.hazard == Minion.Hazard.WITHER)
		on_task_withering = maxi(on_task_withering, moving_and_withering.size())
		await physics_frame
	if on_task_withering > 0:
		return fail("%d minions withered while running to the send point" % on_task_withering)
	print("ok: no minion withered while on task outside the cloud")

	var withering := func() -> bool:
		return horde.minions.all(func(m: Minion) -> bool: return m.hazard == Minion.Hazard.WITHER)
	if not await wait_until(withering, 3.0):
		return fail("idle minions outside the cloud do not wither (%d of %d)" % [
			horde.count_hazard(Minion.Hazard.WITHER), horde.minions.size()])
	await create_timer(2.0).timeout
	var lost := _most_lost(horde)
	if lost < tuning.wither_rate * 1.5:
		return fail("after 2 s outside the cloud no minion lost more than %.1f health" % lost)
	print("ok: idle minions outside the cloud wither (up to %.1f health lost)" % lost)

	var all_hear := func() -> bool: return horde.minions.all(horde.hears)
	if not await InputDriver.hold_until(self, "move_forward", all_hear, 5.0):
		return fail("walking toward the horde never brought it into the cloud")
	InputDriver.tap("recall")
	await create_timer(2.0).timeout
	if horde.minions.size() != count:
		return fail("%d of %d minions died although the lord came back in time" % [count - horde.minions.size(), count])
	if _most_lost(horde) >= lost:
		return fail("brought back into the cloud, the minions do not heal")
	print("ok: brought back in time, all %d minions survived and heal (up to %.1f health lost)" % [count, _most_lost(horde)])

	# 2. Toward open ground to the right of the walk (+x), then walk away.
	await create_timer(1.0).timeout
	if not await InputDriver.face(self, rig, lord.global_position + Vector3(10.0, 0.0, 10.0)):
		return fail("the camera did not turn")
	if not await _send_beyond(aim, lord, tuning):
		return
	await wait_until(func() -> bool: return horde.count(Minion.Order.MOVE) == 0, 5.0)
	await InputDriver.hold(self, "move_back", 2.0)
	var limit := tuning.minion_health * (1.0 + tuning.minion_health_spread) / tuning.wither_rate + 3.0
	if not await wait_until(func() -> bool: return horde.minions.is_empty(), limit):
		return fail("%d minions left outside the cloud still live after %.0f s" % [horde.minions.size(), limit])
	print("ok: all %d minions left outside the cloud withered and died within %.0f s" % [count, limit])


## Tilts the aim beyond the spore cloud and taps send. Calls fail() on a
## problem and returns false.
func _send_beyond(aim: Aim, lord: DarkLord, tuning: Tuning) -> bool:
	var distance := tuning.spore_cloud_radius + tuning.group_radius(tuning.minion_count) + BEYOND
	if not await InputDriver.aim_at_least(self, aim, lord, distance):
		return fail("the aim could not reach %.1f m" % distance)
	if aim.target:
		return fail("the aim beyond the cloud is on a target; pick open ground")
	InputDriver.tap("send")
	await settle()
	return true


## The most health any minion is missing from its own full health.
func _most_lost(horde: Horde) -> float:
	var most := 0.0
	for minion in horde.minions:
		most = maxf(most, minion.max_health - minion.health)
	return most
