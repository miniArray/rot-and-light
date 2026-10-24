extends Control
## Screen overlay: the aim reticle, the horde's orders, and the control hint.
## With touch controls shown, the text scales to the screen density, keeps to
## the safe area, and the hint describes touch instead of keys.

@export var aim: Aim
@export var horde: Horde
@export var touch: TouchControls

const TOUCH_HINT := "Left thumb: move\nDrag the right side: look\nSEND / RECALL: command the horde"
const TEXT_DP := 14.0
const MARGIN_DP := 12.0

@onready var _status: Label = $Status
@onready var _controls: Label = $Controls


func _ready() -> void:
	if touch.visible:
		_controls.text = TOUCH_HINT
		touch.layout_changed.connect(_place_for_touch)
		_place_for_touch()


func _process(_delta: float) -> void:
	_status.text = "Horde %d / %d    %d follow  %d moving  %d attacking  %d idle    %d burning  %d withering" % [
		horde.minions.size(),
		horde.tuning.horde_cap,
		horde.count(Minion.Order.FOLLOW),
		horde.count(Minion.Order.MOVE),
		horde.count(Minion.Order.ATTACK),
		horde.count(Minion.Order.IDLE),
		horde.count_hazard(Minion.Hazard.BURN),
		horde.count_hazard(Minion.Hazard.WITHER),
	]
	queue_redraw()


func _draw() -> void:
	var centre := aim.reticle_position()
	var colour := Color(1.0, 0.35, 0.25) if aim.target else Color(1.0, 1.0, 1.0, 0.8)
	var scale := touch.px_per_dp() if touch.visible else 1.0
	draw_arc(centre, 9.0 * scale, 0.0, TAU, 24, colour, 2.0 * scale, true)
	draw_circle(centre, 1.5 * scale, colour)


## Top-left of the safe area: the status line, then the touch hint under it.
func _place_for_touch() -> void:
	var dp := touch.px_per_dp()
	var font_size := roundi(TEXT_DP * dp)
	var corner := touch.safe_area().position + Vector2.ONE * MARGIN_DP * dp
	for label in [_status, _controls]:
		label.add_theme_font_size_override("font_size", font_size)
		label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.size = Vector2.ZERO
	_status.position = corner
	_controls.position = corner + Vector2(0.0, font_size * 2.0)
