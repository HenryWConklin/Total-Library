class_name ShelfIndex
extends Resource

enum Side { NORTH = 0, EAST = 1, SOUTH = 2, WEST = 3 }

export(Resource) var room = RoomIndex.new()
export(Side) var shelf: int = Side.NORTH


func to_key() -> PoolIntArray:
	return PoolIntArray([room.x, room.y, room.z, shelf])
