extends Spatial

# A parent node for all the FloorBooks in a given room, manages updates triggered by BookRegistry

var room_index setget set_room_index


func _ready():
	add_to_group("floor_books")


func set_room_index(ind):
	room_index = ind
	pull_floor_books()


func push_floor_books():
	var children = get_children()
	for child in children:
		remove_child(child)
	BookRegistry.set_floor_books(room_index, children)


func pull_floor_books():
	var children = BookRegistry.get_floor_books(room_index)
	var i = 0
	for child in children:
		child.name = "FloorBook%d" % i
		i += 1
		add_child(child)
