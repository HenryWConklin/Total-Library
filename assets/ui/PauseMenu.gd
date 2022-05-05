extends Control

export(NodePath) var options_popup: NodePath

onready var _options_popup: WindowDialog = get_node(options_popup)


func _unhandled_input(event: InputEvent):
	if self.visible:
		if event.is_action_pressed("ui_cancel"):
			_on_ResumeButton_pressed()
			get_tree().set_input_as_handled()


func _on_OptionButton_pressed():
	_options_popup.popup()


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_ResumeButton_pressed():
	get_tree().paused = false
	self.hide()


func _on_pause_requested():
	get_tree().paused = true
	self.show()
