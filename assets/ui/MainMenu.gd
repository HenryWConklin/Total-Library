extends Control

# Logic for the main menu buttons

signal start_game

export(NodePath) var initial_focus: NodePath
export(NodePath) var main_buttons: NodePath
export(NodePath) var options_popup: NodePath
export(NodePath) var quit_button: NodePath


func _ready():
	get_node(initial_focus).grab_focus()
	# Quitting in HTML just crashes
	if OS.get_name() == "HTML5":
		get_node(quit_button).hide()


func _on_OptionsButton_pressed():
	get_node(options_popup).show()


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_StartButton_pressed():
	emit_signal("start_game")


func _on_OptionsPopup_visibility_changed():
	get_node(main_buttons).visible = !get_node(options_popup).visible
	if not get_node(options_popup).visible:
		get_node(initial_focus).grab_focus()


func _on_GodotLinkButton_pressed():
	var err = OS.shell_open("https://godotengine.org")
	assert(err == OK)
