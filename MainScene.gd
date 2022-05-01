extends Node

export(PackedScene) var main_scene


func _on_MainMenu_start_game():
	$MainMenu.queue_free()
	$MainMenu.hide()
	remove_child($MainMenu)
	add_child(main_scene.instance())
