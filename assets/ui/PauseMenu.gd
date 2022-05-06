extends Control

export(NodePath) var initial_focus: NodePath
export(NodePath) var main_buttons: NodePath
export(NodePath) var options_popup: NodePath

onready var _options_popup: Control = get_node(options_popup)


func _unhandled_input(event: InputEvent):
	if self.visible:
		if event.is_action_pressed("ui_cancel"):
			_on_ResumeButton_pressed()
			get_tree().set_input_as_handled()


func _on_OptionButton_pressed():
	_options_popup.show()


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_ResumeButton_pressed():
	get_tree().paused = false
	get_node(options_popup).hide()
	self.hide()


func _on_pause_requested():
	get_tree().paused = true
	self.show()
	get_node(initial_focus).grab_focus()


func _on_OptionsPopup_visibility_changed():
	get_node(main_buttons).visible = !get_node(options_popup).visible
	if !_options_popup.visible:
		get_node(initial_focus).grab_focus()
