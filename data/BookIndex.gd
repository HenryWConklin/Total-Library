extends Resource 
class_name BookIndex

export(Resource) var room = RoomIndex.new() #: RoomIndex (Can't add type or interpreter complains) 
export(ShelfIndex.Side) var shelf: int 
export(int) var book: int = 0

func shelf_index() -> ShelfIndex:
	var ind = ShelfIndex.new()
	ind.room = room
	ind.shelf = shelf
	return ind

func to_key() -> PoolIntArray:
	return PoolIntArray([room.x, room.y, room.z, shelf, book])

