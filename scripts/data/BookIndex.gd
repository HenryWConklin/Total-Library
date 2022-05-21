class_name BookIndex
extends Resource

export(Resource) var room = RoomIndex.new()  #: RoomIndex (Can't add type or interpreter complains)
export(ShelfIndex.Side) var shelf: int
export(int) var book: int = 0


func from_book_text(book_text):
	room.x = book_text.room_x
	room.y = book_text.room_y
	room.z = book_text.room_z
	shelf = book_text.shelf
	book = book_text.book
	return self


func shelf_index() -> ShelfIndex:
	var ind = ShelfIndex.new()
	ind.room = room
	ind.shelf = shelf
	return ind


func to_key() -> PoolIntArray:
	return PoolIntArray([room.x, room.y, room.z, shelf, book])


func from_key(key: PoolIntArray):
	room.x = key[0]
	room.y = key[1]
	room.z = key[2]
	shelf = key[3]
	book = key[4]
