class_name InputDriver
extends RefCounted
## Plays the game through its input actions, the same way a player does.
## The debug demo and the headless tests use it; normal play never does.

const FACE_TOLERANCE := deg_to_rad(3.0)


## One press and release of [param action], as input events.
static func tap(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	press.strength = 1.0
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


## Turns the camera with look_left / look_right until it faces [param target].
## Returns false if that takes longer than [param timeout] seconds.
static func face(tree: SceneTree, rig: CameraRig, target: Vector3, timeout := 6.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	var faced := false
	while Time.get_ticks_msec() < deadline:
		var to := target - rig.global_position
		var error := wrapf(atan2(-to.x, -to.z) - rig.yaw, -PI, PI)
		if absf(error) < FACE_TOLERANCE:
			faced = true
			break
		# Ease off near the target so the turn does not overshoot.
		var strength := clampf(absf(error) / deg_to_rad(25.0), 0.35, 1.0)
		Input.action_release("look_left")
		Input.action_release("look_right")
		Input.action_press("look_right" if error < 0.0 else "look_left", strength)
		await tree.process_frame
	Input.action_release("look_left")
	Input.action_release("look_right")
	return faced


## Holds move_forward until the aim targets [param target].
## Returns false if that takes longer than [param timeout] seconds.
static func walk_until_aimed(tree: SceneTree, aim: Aim, target: Breakable, timeout := 10.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	Input.action_press("move_forward")
	while aim.target != target and Time.get_ticks_msec() < deadline:
		await tree.physics_frame
	Input.action_release("move_forward")
	return aim.target == target


## Holds [param action] for [param seconds] of game time.
static func hold(tree: SceneTree, action: StringName, seconds: float) -> void:
	Input.action_press(action)
	await tree.create_timer(seconds, false, true).timeout
	Input.action_release(action)


## Holds [param action] until [param done] returns true. Returns false if
## that takes longer than [param timeout] seconds.
static func hold_until(tree: SceneTree, action: StringName, done: Callable, timeout := 10.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	Input.action_press(action)
	while not done.call() and Time.get_ticks_msec() < deadline:
		await tree.physics_frame
	Input.action_release(action)
	return done.call()


## Tilts the camera up with look_up until the aim point is at least
## [param distance] metres from [param lord]. Returns false on timeout.
static func aim_at_least(tree: SceneTree, aim: Aim, lord: Node3D, distance: float, timeout := 6.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	var far := func() -> bool:
		var offset := aim.point - lord.global_position
		return Vector2(offset.x, offset.z).length() >= distance
	Input.action_press("look_up", 0.4)
	while not far.call() and Time.get_ticks_msec() < deadline:
		await tree.physics_frame
	Input.action_release("look_up")
	# One more physics frame so the aim reflects the final camera.
	await tree.physics_frame
	return far.call()
