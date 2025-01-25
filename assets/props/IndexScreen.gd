extends Spatial

var _last_cursor_position: Vector2
var _is_targeted: bool = false


func _ready():
	# Use a shared Index Screen UI in preloads so all screens show the same content
	var material = $MeshInstance.get_active_material(0)
	material.albedo_texture = IndexScreenRender.get_texture()


func _unhandled_input(event):
	if not _is_targeted:
		return

	if event.is_action("pick_up"):
		var select_event = InputEventMouseButton.new()
		select_event.position = _last_cursor_position
		select_event.global_position = _last_cursor_position
		select_event.button_index = BUTTON_LEFT
		select_event.pressed = event.is_action_pressed("pick_up")
		IndexScreenRender.input(select_event)


func _on_IndexScreenRaycastArea_targeted_position(local_pos):
	var mesh_size = $MeshInstance.mesh.size
	local_pos /= mesh_size
	local_pos += Vector2(0.5, 0.5)
	local_pos.y = 1.0 - local_pos.y
	local_pos *= IndexScreenRender.size
	IndexScreenRender.update_cursor_position(local_pos, local_pos - _last_cursor_position)
	_last_cursor_position = local_pos


func _on_IndexScreenRaycastArea_is_targeted(targeted):
	_is_targeted = targeted
