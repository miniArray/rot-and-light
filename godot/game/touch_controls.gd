class_name TouchControls
extends Control
## On-screen controls for a touchscreen. They feed the same input actions as
## the keyboard and gamepad: a floating stick on the left half presses the
## move_* actions with analog strength; the Send, Recall, and Reload buttons
## send the send, recall, and reload_tuning actions as input events. A drag
## on the right half turns the camera through CameraRig.orbit, as the mouse
## does. Every touch keeps the role it started with until it lifts, so the
## stick, the camera, and the buttons work at the same time.
##
## Shown only on a touchscreen, or when the game runs with `-- --touch`.
## Sizes are in dp (1/160 inch) and the layout stays inside the safe area.

## Emitted after the layout changes: on start, fold, or rotation.
signal layout_changed

@export var tuning: Tuning
@export var camera_rig: CameraRig

const BASE_DPI := 160.0
const MARGIN_DP := 20.0
const GAP_DP := 16.0
const SEND_RADIUS_DP := 46.0
const RECALL_RADIUS_DP := 36.0
const RELOAD_RADIUS_DP := 24.0
const KNOB_RADIUS_DP := 26.0
## A touch this much outside a button's circle still counts as on it.
const BUTTON_SLOP := 1.15
const FILL := Color(1.0, 1.0, 1.0, 0.18)
const FILL_HELD := Color(1.0, 1.0, 1.0, 0.45)
const EDGE := Color(1.0, 1.0, 1.0, 0.7)

const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_forward", &"move_back"]


## A round on-screen button bound to one input action.
class TouchButton:
	var action: StringName
	var label: String
	var radius_dp: float
	var centre := Vector2.ZERO
	var radius := 0.0
	## Index of the touch holding the button, or -1.
	var touch := -1

	func _init(p_action: StringName, p_label: String, p_radius_dp: float) -> void:
		action = p_action
		label = p_label
		radius_dp = p_radius_dp

	func contains(point: Vector2) -> bool:
		return point.distance_to(centre) <= radius * BUTTON_SLOP


var send_button := TouchButton.new(&"send", "SEND", SEND_RADIUS_DP)
var recall_button := TouchButton.new(&"recall", "RECALL", RECALL_RADIUS_DP)
var reload_button := TouchButton.new(&"reload_tuning", "RELOAD", RELOAD_RADIUS_DP)

var _buttons: Array[TouchButton] = [send_button, recall_button, reload_button]
var _px_per_dp := 1.0
var _safe := Rect2()
## Index of the touch driving the stick, or -1.
var _stick_touch := -1
var _stick_rest := Vector2.ZERO
var _stick_origin := Vector2.ZERO
var _stick := Vector2.ZERO
## Indexes of touches turning the camera.
var _look_touches: Dictionary[int, bool] = {}


## True when the game should show touch controls.
static func wanted() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch")


func _ready() -> void:
	visible = wanted()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_layout()


## Pixels per dp on this screen. Never below 1.
func px_per_dp() -> float:
	return _px_per_dp


## The part of this control no notch, cutout, or system bar covers, pixels.
func safe_area() -> Rect2:
	return _safe


## Where the stick rests when no finger is on it, pixels.
func stick_rest() -> Vector2:
	return _stick_rest


## The current stick deflection, length 0 to 1. Up is negative y.
func stick() -> Vector2:
	return _stick


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_release_all()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin(event.index, event.position)
		else:
			_end(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position, event.relative)
		get_viewport().set_input_as_handled()


func _begin(index: int, at: Vector2) -> void:
	for button in _buttons:
		if button.touch == -1 and button.contains(at):
			button.touch = index
			_send_action(button.action, true)
			queue_redraw()
			return
	if at.x < _safe.get_center().x:
		if _stick_touch == -1:
			_stick_touch = index
			# The stick centres under the thumb, kept inside the safe area.
			var reach := tuning.touch_stick_radius * _px_per_dp
			_stick_origin = at.clamp(_safe.position + Vector2.ONE * reach, _safe.end - Vector2.ONE * reach)
			_set_stick(at)
	else:
		_look_touches[index] = true


func _drag(index: int, at: Vector2, relative: Vector2) -> void:
	if index == _stick_touch:
		_set_stick(at)
	elif _look_touches.has(index):
		camera_rig.orbit(relative / _px_per_dp * tuning.touch_look_sensitivity)


func _end(index: int) -> void:
	for button in _buttons:
		if button.touch == index:
			button.touch = -1
			_send_action(button.action, false)
			queue_redraw()
	if index == _stick_touch:
		_stick_touch = -1
		_stick = Vector2.ZERO
		_apply_stick()
	_look_touches.erase(index)


func _set_stick(at: Vector2) -> void:
	var reach := tuning.touch_stick_radius * _px_per_dp
	_stick = ((at - _stick_origin) / reach).limit_length(1.0)
	_apply_stick()


func _apply_stick() -> void:
	var strengths := [-_stick.x, _stick.x, -_stick.y, _stick.y]
	for i in MOVE_ACTIONS.size():
		if strengths[i] > 0.0:
			Input.action_press(MOVE_ACTIONS[i], strengths[i])
		else:
			Input.action_release(MOVE_ACTIONS[i])
	queue_redraw()


func _send_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


## Lifts every finger. A fold, a rotation, or losing focus can drop touch
## releases, and a stuck stick would walk the lord forever.
func _release_all() -> void:
	for button in _buttons:
		if button.touch != -1:
			button.touch = -1
			_send_action(button.action, false)
	if _stick_touch != -1:
		_stick_touch = -1
		_stick = Vector2.ZERO
		_apply_stick()
	_look_touches.clear()
	queue_redraw()


func _on_resized() -> void:
	_release_all()
	_layout()


func _layout() -> void:
	_px_per_dp = maxf(1.0, DisplayServer.screen_get_dpi() / BASE_DPI)
	_safe = Rect2(Vector2.ZERO, size)
	var screen_safe := DisplayServer.get_display_safe_area()
	if screen_safe.has_area():
		var window_position := Vector2(get_window().position)
		var safe := Rect2(Vector2(screen_safe.position) - window_position, Vector2(screen_safe.size))
		safe = safe.intersection(_safe)
		if safe.has_area():
			_safe = safe

	var margin := MARGIN_DP * _px_per_dp
	var gap := GAP_DP * _px_per_dp
	for button in _buttons:
		button.radius = button.radius_dp * _px_per_dp
	send_button.centre = _safe.end - Vector2.ONE * (margin + send_button.radius)
	recall_button.centre = Vector2(
		send_button.centre.x - send_button.radius - gap - recall_button.radius,
		_safe.end.y - margin - recall_button.radius)
	reload_button.centre = Vector2(
		_safe.end.x - margin - reload_button.radius,
		_safe.position.y + margin + reload_button.radius)
	var reach := tuning.touch_stick_radius * _px_per_dp
	_stick_rest = Vector2(_safe.position.x + margin + reach, _safe.end.y - margin - reach)
	queue_redraw()
	layout_changed.emit()


func _draw() -> void:
	var reach := tuning.touch_stick_radius * _px_per_dp
	var centre := _stick_origin if _stick_touch != -1 else _stick_rest
	draw_circle(centre, reach, FILL)
	draw_arc(centre, reach, 0.0, TAU, 48, EDGE, 2.0 * _px_per_dp, true)
	draw_circle(centre + _stick * reach, KNOB_RADIUS_DP * _px_per_dp, FILL_HELD if _stick_touch != -1 else EDGE)

	var font := get_theme_default_font()
	for button in _buttons:
		draw_circle(button.centre, button.radius, FILL_HELD if button.touch != -1 else FILL)
		draw_arc(button.centre, button.radius, 0.0, TAU, 48, EDGE, 2.0 * _px_per_dp, true)
		var font_size := int(button.radius * 0.38)
		var text_size := font.get_string_size(button.label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var baseline := button.centre + Vector2(-text_size.x * 0.5, font.get_ascent(font_size) * 0.5 - font.get_descent(font_size) * 0.5)
		draw_string(font, baseline, button.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
