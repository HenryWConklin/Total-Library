extends Node

# AutoLoad for common utility functions related to input

enum InputType { KEYBOARD = 0, CONTROLLER = 1 }


static func get_event_string(event: InputEvent) -> String:
	if event is InputEventKey:
		if event.scancode == 0:
			return OS.get_scancode_string(event.physical_scancode)
		else:
			return OS.get_scancode_string(event.scancode)
	elif event is InputEventMouseButton:
		match event.button_index:
			BUTTON_LEFT:
				return "Left mouse"
			BUTTON_RIGHT:
				return "Right mouse"
			BUTTON_MIDDLE:
				return "Middle mouse"
			# Think mouse 4/5 is the more common name for these
			BUTTON_XBUTTON1:
				return "Mouse 4"
			BUTTON_XBUTTON2:
				return "Mouse 5"
	elif event is InputEventJoypadButton:
		return Input.get_joy_button_string(event.button_index)
	return event.as_text()
