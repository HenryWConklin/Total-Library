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

# Finds an event for an action that matches the current control scheme,
# i.e. keyboard or controller.
func _get_active_event(action: String) -> InputEvent:
	var events = InputMap.get_action_list(action)
	for e in events:
		var is_active_event = (
			(_input_method == InputUtil.InputType.KEYBOARD
				and (e is InputEventKey or e is InputEventMouse))
			or (_input_method == InputUtil.InputType.CONTROLLER
				and (e is InputEventJoypadButton or e is InputEventJoypadMotion)))
		if is_active_event:
			return e
	assert(false, "No matching event")
	return null

func _get_action_str(action: String) -> String:
	var event = _get_active_event(action)
	if event == null:
		return ""
	return InputUtil.get_event_string(event)
