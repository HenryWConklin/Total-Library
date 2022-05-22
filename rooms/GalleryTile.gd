extends Spatial

# Logic for a room with bookshelves in it.

export(Resource) var room_index
export(Array, NodePath) var top_shelves
export(Array, NodePath) var bottom_shelves
export(NodePath) var upper_room_area
export(NodePath) var lower_room_area
export(NodePath) var floor_books_path: NodePath

onready var floor_books: Spatial = get_node(floor_books_path)


func _ready():
	if room_index != null:
		set_room_index(room_index)


func set_room_index(ind: RoomIndex):
	var side = 0
	for shelf_path in bottom_shelves:
		var shelf = get_node(shelf_path)
		var shelf_index = ShelfIndex.new()
		shelf_index.room.x = ind.x
		shelf_index.room.y = ind.y
		shelf_index.room.z = ind.z
		shelf_index.shelf = side
		shelf.shelf_index = shelf_index

		side += 1
	side = 0
	for shelf_path in top_shelves:
		var shelf = get_node(shelf_path)
		var shelf_index = ShelfIndex.new()
		shelf_index.room.x = ind.x
		shelf_index.room.y = ind.y
		shelf_index.room.z = ind.z + 1
		shelf_index.shelf = side
		shelf.shelf_index = shelf_index

		side += 1

	var lower_room = get_node(lower_room_area)
	lower_room.room_index = RoomIndex.new()
	lower_room.room_index.x = ind.x
	lower_room.room_index.y = ind.y
	lower_room.room_index.z = ind.z

	var upper_room = get_node(upper_room_area)
	upper_room.room_index = RoomIndex.new()
	upper_room.room_index.x = ind.x
	upper_room.room_index.y = ind.y
	upper_room.room_index.z = ind.z + 1

	floor_books.room_index = room_index
