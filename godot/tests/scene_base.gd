extends SceneTree
## Base for the headless tests: loads main.tscn, waits for it to settle, runs
## the test's _run(main), and quits with 0 on pass, 1 on a failure or when
## the watchdog fires. A test extends this file and overrides _run().

var watchdog_seconds := 90.0
var _finished := false
var _errors := ErrorLog.new()


## Collects every error and script error the engine reports, so a test with
## a broken script fails even when the engine carries on.
class ErrorLog:
	extends Logger

	var _lock := Mutex.new()
	var _messages: PackedStringArray = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_lock.lock()
		_messages.append("%s (%s:%d %s)" % [rationale if rationale else code, file, line, function])
		_lock.unlock()

	func messages() -> PackedStringArray:
		_lock.lock()
		var copy := _messages.duplicate()
		_lock.unlock()
		return copy


func _initialize() -> void:
	OS.add_logger(_errors)
	create_timer(watchdog_seconds, true, false, true).timeout.connect(
		func() -> void: fail("watchdog: the test did not finish in %d s" % watchdog_seconds))
	var problem := _precheck()
	if problem:
		fail(problem)
		return
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	_start(main)


func _start(main: Node) -> void:
	for i in 3:
		await physics_frame
	await _run(main)
	var errors := _errors.messages()
	if not errors.is_empty():
		fail("the engine reported %d errors; the first: %s" % [errors.size(), errors[0]])
	if not _finished:
		_finished = true
		print("PASS ", _name())
		quit(0)


## The test. On a failure, `return fail(reason)`; returning passes.
## No return type, so a test can return fail()'s value. This default runs
## only when the test's own script did not compile, and fails.
func _run(_main: Node):
	return fail("the test has no _run(); did its script compile?")


## A reason the test cannot run here, or "".
func _precheck() -> String:
	return ""


## Records a failure and quits with 1. Returns false, so a test can write
## `return fail(reason)`.
func fail(message: String) -> bool:
	if not _finished:
		_finished = true
		printerr("FAIL ", _name(), ": ", message)
		quit(1)
	return false


func failed() -> bool:
	return _finished


func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Waits up to [param timeout] seconds for [param done] to return true.
func wait_until(done: Callable, timeout: float) -> bool:
	var deadline := now() + timeout
	while not done.call():
		if now() > deadline:
			return false
		await physics_frame
	return true


## Waits until injected events have reached the game. Headless can take a
## frame or two to flush them.
func settle() -> void:
	for i in 3:
		await process_frame


func _name() -> String:
	return (get_script() as Script).resource_path.get_file().get_basename()
