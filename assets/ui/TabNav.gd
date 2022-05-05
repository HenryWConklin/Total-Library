extends TabContainer


func _input(event):
	if event.is_action_pressed("ui_tab_next") and current_tab < get_child_count() - 1:
		current_tab += 1
	if event.is_action_pressed("ui_tab_prev") and current_tab > 0:
		current_tab -= 1
