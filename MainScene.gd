extends Node

export(PackedScene) var main_scene
export(NodePath) var held_book_preload_path: NodePath


func _ready():
	# Simulate picking up the book to force shader to compile in the menu instead of on first pickup.
	# Should be the same as the shelf books but for some reason it's a different shader compile.
	var book_text = BookRegistry.get_book_text(BookIndex.new())
	var held_book_preload = get_node(held_book_preload_path)
	held_book_preload.pull_from_shelf(book_text, Transform(), held_book_preload.global_transform)


func _on_MainMenu_start_game():
	$AnimationPlayer.play("SceneTransition")


# Called by animation player to transition between scenes
func transition_scenes():
	$MainMenu.queue_free()
	$MainMenu.hide()
	remove_child($MainMenu)
	add_child(main_scene.instance())
