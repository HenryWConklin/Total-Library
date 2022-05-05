extends Control

enum Type { KEYBOARD = 0, CONTROLLER = 1 }

export(String) var action
export(Type) var key_type

var _event

# TODO: Rework this, needs to push/pull from Options which should actually set the input map


func _ready():
	assert(key_type in Type.values())
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
	var text = _event.as_text()
	if _event is InputEventKey:
		if _event.scancode == 0:
			text = OS.get_scancode_string(_event.physical_scancode)
		else:
			text = OS.get_scancode_string(_event.scancode)
	elif _event is InputEventMouseButton:
		match _event.button_index:
			BUTTON_LEFT:
				text = "Left mouse"
			BUTTON_RIGHT:
				text = "Right mouse"
			BUTTON_MIDDLE:
				text = "Middle mouse"
			# Think mouse 4/5 is the more common name for these
			BUTTON_XBUTTON1:
				text = "Mouse 4"
			BUTTON_XBUTTON2:
				text = "Mouse 5"
	elif _event is InputEventJoypadButton:
		text = Input.get_joy_button_string(_event.button_index)
	$Button.text = text


func _bind_event(event):
	Options.replace_action_binding(action, _event, event)
	_event = event
	_set_button_text()


func _event_type_matches(event) -> bool:
	match key_type:
		Type.KEYBOARD:
			return event is InputEventKey or event is InputEventMouseButton
		Type.CONTROLLER:
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
	$Popup.release_focus()
	set_process_unhandled_input(true)


func _on_options_reloaded():
	reload_event()


func _on_Popup_popup_hide():
	set_process_unhandled_input(false)
