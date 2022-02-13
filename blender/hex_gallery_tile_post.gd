extends Spatial

export(Resource) var room_index
export(Array, NodePath) var top_shelves
export(Array, NodePath) var bottom_shelves


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
