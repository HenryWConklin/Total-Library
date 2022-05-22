extends Control

# A button that handles remapping a single event for an action. Handles either the keyboard/mouse or
# gamepad input event.

export(String) var action
export(InputUtil.InputType) var key_type

var _event


func _ready():
	assert(key_type in InputUtil.InputType.values())
	assert(InputMap.has_action(action))
	assert(Options.connect("options_reloaded", self, "_on_options_reloaded") == OK)
	set_process_unhandled_input(false)
	reload_event()


func reload_event():
	var events = Options.get_action_events(action)
	# Pull the first event that matches the configured type
	for event in events:
		if _event_type_matches(event):
			_event = event
	_set_button_text()


func _set_button_text():
	$Button.text = InputUtil.get_event_string(_event)


func _bind_event(event):
	Options.replace_action_binding(action, _event, event)
	_event = event
	_set_button_text()


func _event_type_matches(event) -> bool:
	match key_type:
		InputUtil.InputType.KEYBOARD:
			return event is InputEventKey or event is InputEventMouseButton
		InputUtil.InputType.CONTROLLER:
			return event is InputEventJoypadButton
		_:
			assert(false, "Invalid enum type")
			return false


func _unhandled_input(event):
	if _event_type_matches(event):
		_bind_event(event)
		set_process_unhandled_input(false)
		get_tree().set_input_as_handled()
		$Popup.hide()


func _on_Button_pressed():
	$Popup.popup()
	$Button.release_focus()
	# The input that pressed the button gets fed to _unhandled_input
	# if it's enabled on the same frame, using deferred avoids that
	call_deferred("set_process_unhandled_input", true)


func _on_options_reloaded():
	reload_event()


func _on_Popup_popup_hide():
	set_process_unhandled_input(false)
