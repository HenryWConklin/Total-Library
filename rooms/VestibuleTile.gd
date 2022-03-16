extends Spatial

export(Resource) var room_index
export(NodePath) var upper_room_area
export(NodePath) var lower_room_area
export(NodePath) var floor_books_path


func _ready():
	if room_index != null:
		set_room_index(room_index)


func set_room_index(ind: RoomIndex):
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

	get_node(floor_books_path).room_index = room_index
