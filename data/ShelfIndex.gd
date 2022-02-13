extends Resource
class_name ShelfIndex
enum Side { NORTH = 0, EAST = 1, SOUTH = 2, WEST = 3 }

export(Resource) var room = RoomIndex.new()  # : RoomIndex (Can't add type constraint or interpreter complains)
export(Side) var shelf: int = Side.NORTH


func to_key() -> PoolIntArray:
	return PoolIntArray([room.x, room.y, room.z, shelf])
