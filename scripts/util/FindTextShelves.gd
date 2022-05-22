extends Node

# Finds and saves the shelves in the room containing the target string as a book. Used to generate
# the main menu background.

export(String) var output_path: String
export(String) var target_string: String


func _ready():
	var ind = BookRegistry.book_util.find_text(target_string)
	BookRegistry.book_util.origin = ind
	var index = ShelfIndex.new()
	index.room.x = -1
	for i in range(4):
		print(i)
		index.shelf = i
		var shelf = BookRegistry.get_shelf(index)
		var name = ShelfIndex.Side.keys()[i]
		assert(ResourceSaver.save(output_path + name + ".res", shelf) == OK)
	get_tree().quit()
