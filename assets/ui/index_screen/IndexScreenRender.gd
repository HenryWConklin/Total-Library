extends Viewport


func update_cursor_position(position: Vector2, relative: Vector2):
	var mouse_input = InputEventMouseMotion.new()
	mouse_input.relative = relative
	mouse_input.position = position
	mouse_input.global_position = position
	input(mouse_input)
	# Mouse motion event gets eaten somewhere, can't use to move the mouse cursor
	# element around so need to pass directly
	$IndexScreenUI.update_cursor_position(position)
