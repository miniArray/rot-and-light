extends "res://tests/scene_base.gd"
## Rule 2, putting out a lamp through the input actions: aim at the lamp and
## send; the lamp goes out, its light is gone, the ground turns to rot, and
## minions standing where the light was no longer burn. Putting it out has a
## price: some of the horde burns to death, but the horde still wins.
##
##   godot4 --headless --path godot --script res://tests/lamp_test.gd

const OUT_LIMIT := 25.0


func _run(main: Node):
	var tuning: Tuning = main.tuning
	var rig: CameraRig = main.get_node("CameraRig")
	var aim: Aim = main.get_node("Aim")
	var horde: Horde = main.get_node("Horde")
	var lamp: Lamp = main.get_node("Lamps/Lamp1")
	var post := lamp.global_position

	if not await InputDriver.face(self, rig, post):
		return fail("the camera did not turn to face the lamp")
	if not await InputDriver.walk_until_aimed(self, aim, lamp):
		return fail("the aim never reached the lamp")
	var sent := horde.minions.size()
	InputDriver.tap("send")
	var sent_at := now()
	# Seconds after send of the first burn and the first death, and the
	# lamp's health at the first death.
	var first := [-1.0, -1.0, 0.0]
	var out := func() -> bool:
		if first[0] < 0.0 and horde.count_hazard(Minion.Hazard.BURN) > 0:
			first[0] = now() - sent_at
		if first[1] < 0.0 and horde.minions.size() < sent:
			first[1] = now() - sent_at
			first[2] = lamp.health
		return lamp.is_broken or horde.minions.is_empty()
	var lasted := func() -> String:
		if first[1] < 0.0:
			return "the first burned %.1f s after send; none died" % first[0]
		return "the first burned %.1f s and died %.1f s after send, with the lamp at %.0f health" % first
	if not await wait_until(out, OUT_LIMIT) or not lamp.is_broken:
		return fail("the lamp still has %.0f of %.0f health %.1f s after send; %d of %d minions left; %s" % [
			lamp.health, tuning.lamp_health, now() - sent_at, horde.minions.size(), sent, lasted.call()])
	var survived := horde.minions.size()
	print("ok: the lamp went out %.1f s after send; %d of %d minions survived; %s" % [
		now() - sent_at, survived, sent, lasted.call()])
	if survived >= sent:
		return fail("putting out the lamp cost no minions; it should cost some")
	print("ok: putting out the lamp cost %d of %d minions" % [sent - survived, sent])

	if lamp.lights(post) or (lamp.get_node("Light") as Node3D).visible or (lamp.get_node("Glow") as Node3D).visible:
		return fail("the lamp is out but its light still shows or burns")
	if not (lamp.get_node("Rot") as Node3D).visible:
		return fail("the ground under the lamp did not turn to rot")
	# The aim updates before the horde in a physics frame, so it sees the
	# lamp go out one frame later.
	for i in 2:
		await physics_frame
	if aim.target == lamp:
		return fail("the aim still targets the lamp that is out")
	print("ok: the light is gone and the ground under the lamp turned to rot")

	await create_timer(0.5).timeout
	var in_spot: Array[Minion] = []
	for minion in horde.minions:
		if flat_distance(minion.global_position, post) <= tuning.lamp_light_radius:
			in_spot.append(minion)
	if in_spot.is_empty():
		return fail("no minion stands where the light was")
	for minion in in_spot:
		if minion.hazard == Minion.Hazard.BURN:
			return fail("a minion where the light was still burns")
	# Idle minions outside the spore cloud wither, which is not burning;
	# walk over so they are inside it, then their health must not drop.
	# A survivor the light left with little health can wither away before
	# the lord gets there; that is the cloud rule, not the light.
	# Untyped: a freed minion cannot pass a Minion parameter.
	var living := func() -> Array:
		return in_spot.filter(func(m) -> bool: return is_instance_valid(m))
	var all_hear := func() -> bool: return living.call().all(horde.hears)
	if not await InputDriver.hold_until(self, "move_forward", all_hear, 5.0):
		return fail("walking never brought the minions at the lamp into the cloud")
	var heard: Array = living.call()
	if heard.is_empty():
		return fail("every minion where the light was died before the lord reached them")
	var health_before := heard.map(func(m: Minion) -> float: return m.health)
	await create_timer(1.0).timeout
	for i in heard.size():
		if not is_instance_valid(heard[i]):
			return fail("a minion in the cloud where the light was died")
		var minion: Minion = heard[i]
		if minion.hazard != Minion.Hazard.NONE or minion.health < health_before[i]:
			return fail("a minion where the light was still loses health (%.1f -> %.1f)" % [health_before[i], minion.health])
	print("ok: %d minions stand where the light was; none burn, and in the cloud none lose health (%d withered on the way)" % [
		heard.size(), in_spot.size() - heard.size()])
