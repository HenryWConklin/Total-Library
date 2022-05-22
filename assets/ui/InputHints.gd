extends Label

# A label that displays hints about what buttons to press based on signals from scripts/Player.gd.
# Configured in Library.tscn

var _targeted: bool = false
var _held: bool = false
var _input_method: int = InputUtil.InputType.KEYBOARD


func _refresh_text():
	var lines = PoolStringArray()
	if _held:
		lines.append(
			"Turn pages: {0}/{1}".format(
				[_get_action_str("turn_page_forward"), _get_action_str("turn_page_back")]
			)
		)
	if _targeted:
		lines.append("Pick up/drop: {0}".format([_get_action_str("pick_up")]))
	text = lines.join("\n")


func _on_Player_book_targeted(targeted):
	_targeted = targeted
	_refresh_text()


func _on_Player_last_input_method_changed(method):
	_input_method = method
	_refresh_text()


func _on_Player_book_held(held):
	_held = held
	_refresh_text()


func _get_action_str(action: String) -> String:
	var events = InputMap.get_action_list(action)
	for e in events:
		if (
			_input_method == InputUtil.InputType.KEYBOARD
			and (e is InputEventKey or e is InputEventMouse)
		):
			return InputUtil.get_event_string(e)
		elif (
			_input_method == InputUtil.InputType.CONTROLLER
			and (e is InputEventJoypadButton or e is InputEventJoypadMotion)
		):
			return InputUtil.get_event_string(e)
	assert(false, "No matching event")
	return ""
