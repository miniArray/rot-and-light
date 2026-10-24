extends "res://tests/scene_base.gd"
## Headless test of the touch controls, played with injected screen touches:
## the left stick walks the lord, a right-side drag turns the camera, the
## buttons send, recall, and reload, and two fingers work at once.
##
##   godot4 --headless --path godot --script res://tests/touch_test.gd -- --touch
##
## Exits 0 on pass, 1 on failure.

## Galaxy Z Fold 7 screens in landscape, in dp (headless reports 96 dpi, so
## one pixel is one dp here): the folded cover screen and the unfolded one.
const FOLDED := Vector2i(970, 415)
const UNFOLDED := Vector2i(840, 757)
## Smallest touch target, dp.
const MIN_TARGET_DP := 48.0


func _precheck() -> String:
	if not TouchControls.wanted():
		return "touch controls are hidden; run the test with `-- --touch`"
	return ""


func _run(main: Node):
	var tuning: Tuning = main.tuning
	var touch: TouchControls = main.get_node("Hud/TouchControls")
	for shape in [UNFOLDED, FOLDED]:
		# The headless window ignores resizes; the controls follow their own
		# rect, which on a phone follows the window.
		touch.set_anchors_preset(Control.PRESET_TOP_LEFT)
		touch.size = shape
		for i in 3:
			await physics_frame
		var problem := _layout_problem(touch, tuning)
		if problem:
			fail("layout at %s: %s" % [shape, problem])
			return
		print("ok: layout fits %s" % shape)

	var rig: CameraRig = main.get_node("CameraRig")
	var horde: Horde = main.get_node("Horde")
	var lord: DarkLord = main.get_node("DarkLord")
	if not touch.visible:
		fail("the touch controls are not visible")
		return
	var reach := tuning.touch_stick_radius * touch.px_per_dp()
	var right_side := touch.safe_area().get_center() + Vector2(touch.safe_area().size.x * 0.25, -touch.safe_area().size.y * 0.25)

	# Stick: a thumb on the left pushed up walks the lord forward (-z).
	var start := lord.global_position
	var thumb := touch.stick_rest()
	_touch(0, thumb, true)
	await settle()
	_drag(0, thumb + Vector2(0.0, -reach))
	await create_timer(1.0).timeout
	if not Input.is_action_pressed("move_forward"):
		fail("the stick did not press move_forward")
		return
	var walked := start.z - lord.global_position.z
	if walked < 2.0:
		fail("the lord walked %.2f m forward in 1 s of full stick" % walked)
		return
	print("ok: full stick walked the lord %.2f m forward in 1 s" % walked)

	# A second finger taps Send while the thumb still holds the stick.
	_touch(1, touch.send_button.centre, true)
	await settle()
	_touch(1, touch.send_button.centre, false)
	for i in 3:
		await physics_frame
	var following := horde.count(Minion.Order.FOLLOW)
	if following != 0:
		fail("after Send, %d minions still follow" % following)
		return
	if not Input.is_action_pressed("move_forward"):
		fail("tapping Send released the stick")
		return
	print("ok: Send with a second finger sent all %d minions while the stick held" % horde.minions.size())

	_touch(0, thumb + Vector2(0.0, -reach), false)
	await settle()
	for action in TouchControls.MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			fail("%s is still pressed after the thumb lifted" % action)
			return
	print("ok: lifting the thumb released every move action")

	# Recall.
	_touch(2, touch.recall_button.centre, true)
	await settle()
	_touch(2, touch.recall_button.centre, false)
	for i in 3:
		await physics_frame
	following = horde.count(Minion.Order.FOLLOW)
	if following != horde.minions.size():
		fail("after Recall, only %d of %d minions follow" % [following, horde.minions.size()])
		return
	print("ok: Recall brought all %d minions back to follow" % following)

	# Camera: a drag on the right side turns it and does not move the lord.
	var yaw := rig.yaw
	var standing := lord.global_position
	_touch(3, right_side, true)
	await settle()
	for i in 10:
		_drag(3, right_side + Vector2(20.0 * (i + 1), 0.0), Vector2(20.0, 0.0))
		await process_frame
	_touch(3, right_side + Vector2(200.0, 0.0), false)
	await settle()
	var turned := rad_to_deg(angle_difference(yaw, rig.yaw))
	var expected := -200.0 / touch.px_per_dp() * tuning.touch_look_sensitivity
	if absf(turned - expected) > 1.0:
		fail("a 200 px drag turned the camera %.1f degrees, expected %.1f" % [turned, expected])
		return
	if lord.global_position.distance_to(standing) > 0.5:
		fail("a camera drag moved the lord")
		return
	print("ok: a 200 px drag on the right turned the camera %.1f degrees" % turned)

	# Reload.
	var reloads := [0]
	tuning.changed.connect(func() -> void: reloads[0] += 1)
	_touch(4, touch.reload_button.centre, true)
	await settle()
	_touch(4, touch.reload_button.centre, false)
	for i in 3:
		await process_frame
	if reloads[0] != 1:
		fail("Reload reloaded the tuning %d times, expected once" % reloads[0])
		return
	print("ok: Reload reloaded tuning.tres")



## Why the layout is unusable at the current size, or "" when it is fine:
## every control inside the safe area, at least MIN_TARGET_DP across, and
## no two overlapping.
func _layout_problem(touch: TouchControls, tuning: Tuning) -> String:
	var dp := touch.px_per_dp()
	var safe := touch.safe_area()
	var areas := {
		"stick": [touch.stick_rest(), tuning.touch_stick_radius * dp],
		"send": [touch.send_button.centre, touch.send_button.radius],
		"recall": [touch.recall_button.centre, touch.recall_button.radius],
		"reload": [touch.reload_button.centre, touch.reload_button.radius],
	}
	var names := areas.keys()
	for name in names:
		var centre: Vector2 = areas[name][0]
		var radius: float = areas[name][1]
		if radius * 2.0 < MIN_TARGET_DP * dp:
			return "%s is %.0f dp across" % [name, radius * 2.0 / dp]
		var box := Rect2(centre - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
		if not safe.encloses(box):
			return "%s %s is outside the safe area %s" % [name, box, safe]
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: Array = areas[names[i]]
			var b: Array = areas[names[j]]
			if (a[0] as Vector2).distance_to(b[0]) < a[1] + b[1]:
				return "%s overlaps %s" % [names[i], names[j]]
	return ""


func _touch(index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	Input.parse_input_event(event)


func _drag(index: int, at: Vector2, relative := Vector2.ZERO) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	event.relative = relative
	Input.parse_input_event(event)

