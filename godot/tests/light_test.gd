extends "res://tests/scene_base.gd"
## Rule 2, light: walk the lord to a lamp with the move actions; a following
## minion that stands in the light loses health and dies, and one outside
## the light does not burn.
##
##   godot4 --headless --path godot --script res://tests/light_test.gd

func _run(main: Node):
	var tuning: Tuning = main.tuning
	var rig: CameraRig = main.get_node("CameraRig")
	var horde: Horde = main.get_node("Horde")
	var lord: DarkLord = main.get_node("DarkLord")
	var lamp: Lamp = main.get_node("Lamps/Lamp2")
	var post := lamp.global_position

	if not await InputDriver.face(self, rig, post):
		return fail("the camera did not turn to face the lamp")
	var at_post := func() -> bool: return flat_distance(lord.global_position, post) < 1.6
	if not await InputDriver.hold_until(self, "move_forward", at_post, 8.0):
		return fail("the lord did not reach the lamp")

	# Let the horde settle into its slots behind the lord, then pick one
	# follower in the light and one outside it.
	await create_timer(1.0).timeout
	var lit: Minion = null
	var dark: Minion = null
	for minion in horde.minions:
		if lamp.lights(minion.global_position):
			if lit == null or minion.health > lit.health:
				lit = minion
		elif dark == null:
			dark = minion
	if lit == null:
		return fail("no follower stands in the lamp light")
	var start_health := lit.health
	await create_timer(1.0).timeout
	if not is_instance_valid(lit):
		return fail("the lit minion died before its health could be read")
	var lost := start_health - lit.health
	if lit.hazard != Minion.Hazard.BURN or lost <= 0.0 or lost < tuning.light_burn_rate * 0.8:
		return fail("in the light for 1 s, a minion lost %.1f health (hazard %s)" % [lost, lit.hazard])
	print("ok: a minion in the light lost %.1f health in 1 s and burns" % lost)
	if dark and dark.hazard == Minion.Hazard.BURN:
		return fail("a minion outside the light burns")

	# By id: a lambda must not hold the minion once it is freed.
	var lit_id := lit.get_instance_id()
	var limit := lit.max_health / maxf(tuning.light_burn_rate, 0.01) + 2.0
	if not await wait_until(func() -> bool: return not is_instance_id_valid(lit_id), limit):
		return fail("the minion in the light did not die within %.1f s" % limit)
	for minion in horde.minions:
		if minion.get_instance_id() == lit_id:
			return fail("a dead minion is still in the horde")
	print("ok: the minion in the light died; the horde has %d left" % horde.minions.size())
