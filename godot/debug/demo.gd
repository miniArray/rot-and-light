extends Node
## Debug-only scripted demo, for screenshots on a machine nobody is playing
## on. main.gd adds it only in debug builds run with `-- --demo`.
## It plays through the input actions and prints "demo: <state>" when each
## state is on screen, then holds that state for HOLD seconds:
##
##   idle -> crate attack (paused) -> sprouts grown -> withering (paused)
##   -> recalled -> near a lit lamp -> lamp attack (paused) -> lamp out
##
## `-- --demo --demo-hold=45` holds each state for 45 s instead.
##
## While it holds a state it measures frame time for PERF_SECONDS from
## Godot's own monitors and prints a `demo perf:` line.
## `--demo-horde=40` grows the horde to 40 at the start (never past
## horde_cap), to measure a full horde. `--demo-uncapped` turns V-Sync off,
## so the frame rate shows the real cost instead of the display rate.

const DEFAULT_HOLD := 20.0
## How long the demo measures frame time in each state, seconds.
const PERF_SECONDS := 3.0
## Attacks are short, so the demo pauses the game while it holds them.
const HITTING_TO_PAUSE := 8
## How far outside the light's edge the lord stops near the lamp, metres.
const LAMP_STANDOFF := 2.5

var _hold := DEFAULT_HOLD
var _tree: SceneTree
var _rig: CameraRig
var _aim: Aim
var _horde: Horde
var _lord: DarkLord


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var horde_size := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--demo-hold=") and arg.get_slice("=", 1).is_valid_float():
			_hold = arg.get_slice("=", 1).to_float()
		if arg.begins_with("--demo-horde=") and arg.get_slice("=", 1).is_valid_int():
			horde_size = arg.get_slice("=", 1).to_int()
		if arg == "--demo-uncapped":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	var horde: Horde = get_parent().get_node("Horde")
	horde.add_followers(horde_size - horde.minions.size())
	_run()


func _run() -> void:
	var main := get_parent()
	_tree = get_tree()
	_rig = main.get_node("CameraRig")
	_aim = main.get_node("Aim")
	_horde = main.get_node("Horde")
	_lord = main.get_node("DarkLord")
	var crate: Crate = main.get_node("Crates/Crate1")
	var lamp: Lamp = main.get_node("Lamps/Lamp1")

	await _wait(1.0)
	await InputDriver.hold(_tree, "move_forward", 1.5)
	await _wait(2.0)
	await _hold_state("idle")

	if not await _attack(crate, "crate attack"):
		return
	while is_instance_valid(crate) and not crate.is_broken:
		await _tree.physics_frame
	await _wait(1.0)
	await _hold_state("sprouts grown")
	InputDriver.tap("recall")
	await _wait(3.0)

	if not await _wither():
		return
	InputDriver.tap("recall")
	await _wait(4.0)
	await _hold_state("recalled")

	if not await InputDriver.face(_tree, _rig, lamp.global_position):
		_announce("failed: could not face the lamp")
		return
	var near := func() -> bool:
		var offset := lamp.global_position - _lord.global_position
		return Vector2(offset.x, offset.z).length() <= _lord.tuning.lamp_light_radius + LAMP_STANDOFF
	await InputDriver.hold_until(_tree, "move_forward", near, 8.0)
	await _wait(2.5)
	await _hold_state("near a lit lamp")

	if not await _attack(lamp, "lamp attack"):
		return
	while not lamp.is_broken:
		await _tree.physics_frame
	await _wait(1.5)
	InputDriver.tap("recall")
	await _wait(3.0)
	await _hold_state("lamp out")


## Sends the horde past the spore cloud toward open ground, holds the game
## paused once it withers, then walks back so the horde hears a recall.
## Returns false when it cannot aim.
func _wither() -> bool:
	if not await InputDriver.face(_tree, _rig, _lord.global_position + Vector3(0.0, 0.0, 10.0)):
		_announce("failed: could not face open ground")
		return false
	var beyond := _lord.tuning.spore_cloud_radius + _lord.tuning.group_radius(_horde.minions.size()) + 2.0
	if not await InputDriver.aim_at_least(_tree, _aim, _lord, beyond):
		_announce("failed: could not aim past the cloud")
		return false
	InputDriver.tap("send")
	await _wait(2.0)
	var withering := func() -> bool:
		return _horde.count_hazard(Minion.Hazard.WITHER) * 2 > _horde.minions.size()
	if not await _until(withering, 6.0):
		_announce("failed: the horde past the cloud did not wither")
		return false
	await _wait(1.5)
	_tree.paused = true
	await _hold_state("withering (paused, %d minions withering)" % _horde.count_hazard(Minion.Hazard.WITHER))
	_tree.paused = false
	await InputDriver.hold_until(_tree, "move_forward", func() -> bool: return _horde.minions.all(_horde.hears), 6.0)
	# Tilt the camera back down to where it started.
	var level := deg_to_rad(_lord.tuning.camera_pitch_default)
	await InputDriver.hold_until(_tree, "look_down", func() -> bool: return _rig.pitch <= level, 3.0)
	return true


## Waits up to [param timeout] seconds for [param done] to return true.
func _until(done: Callable, timeout: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not done.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await _tree.physics_frame
	return true


## Aims at [param target], sends, and holds the game paused once enough
## minions hit it. Returns false when it cannot aim.
func _attack(target: Breakable, state: String) -> bool:
	if not await InputDriver.face(_tree, _rig, target.global_position):
		_announce("failed: could not face the %s" % state)
		return false
	if not await InputDriver.walk_until_aimed(_tree, _aim, target):
		_announce("failed: could not aim for the %s" % state)
		return false
	InputDriver.tap("send")
	while _hitting() < HITTING_TO_PAUSE and is_instance_valid(target) and not target.is_broken:
		await _tree.physics_frame
	_tree.paused = true
	await _hold_state("%s (paused, %d minions hitting)" % [state, _hitting()])
	_tree.paused = false
	return true


func _hitting() -> int:
	return _horde.minions.filter(func(m: Minion) -> bool: return m.is_hitting()).size()


func _hold_state(state: String) -> void:
	_announce(state)
	var held := _tree.create_timer(_hold, true)
	await _measure(state)
	if held.time_left > 0.0:
		await held.timeout


## Averages frame, process, physics, and render times over PERF_SECONDS
## and prints them.
func _measure(state: String) -> void:
	var viewport := get_viewport().get_viewport_rid()
	var frames := 0
	var process := 0.0
	var physics := 0.0
	var render_cpu := 0.0
	var render_gpu := 0.0
	var draws := 0.0
	var start := Time.get_ticks_usec()
	while Time.get_ticks_usec() - start < PERF_SECONDS * 1e6:
		await _tree.process_frame
		frames += 1
		process += Performance.get_monitor(Performance.TIME_PROCESS)
		physics += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		render_cpu += RenderingServer.viewport_get_measured_render_time_cpu(viewport) + RenderingServer.get_frame_setup_time_cpu()
		render_gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var seconds := (Time.get_ticks_usec() - start) / 1e6
	print("demo perf: %s; %s; %d minions; %.1f fps (%.2f ms a frame); process %.2f ms, physics %.2f ms, render CPU %.2f ms, render GPU %.2f ms; %.0f draw calls" % [
		state, RenderingServer.get_current_rendering_method(), _horde.minions.size(),
		frames / seconds, seconds * 1000.0 / frames, process * 1000.0 / frames, physics * 1000.0 / frames,
		render_cpu / frames, render_gpu / frames, draws / frames])


func _wait(seconds: float) -> void:
	await _tree.create_timer(seconds).timeout


func _announce(state: String) -> void:
	print("demo: %s at %.1f s; horde %d" % [state, Time.get_ticks_msec() / 1000.0, _horde.minions.size()])
