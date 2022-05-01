extends Control

signal start_game

export(NodePath) var options_popup: NodePath


func _on_OptionsButton_pressed():
	get_node(options_popup).popup()


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_StartButton_pressed():
	emit_signal("start_game")
