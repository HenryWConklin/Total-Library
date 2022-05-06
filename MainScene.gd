extends Node

export(PackedScene) var main_scene


func _on_MainMenu_start_game():
	$AnimationPlayer.play("SceneTransition")


# Called by animation player to transition between scenes
func transition_scenes():
	$MainMenu.queue_free()
	$MainMenu.hide()
	remove_child($MainMenu)
	add_child(main_scene.instance())
