extends Node

enum InputType { KEYBOARD = 0, CONTROLLER = 1 }


static func get_event_string(event: InputEvent) -> String:
	var text = event.as_text()
	if event is InputEventKey:
		if event.scancode == 0:
			text = OS.get_scancode_string(event.physical_scancode)
		else:
			text = OS.get_scancode_string(event.scancode)
	elif event is InputEventMouseButton:
		match event.button_index:
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
	elif event is InputEventJoypadButton:
		text = Input.get_joy_button_string(event.button_index)
	return text
