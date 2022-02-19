class_name RoomIndex
extends Resource

export(int) var x: int = 0
export(int) var y: int = 0
export(int) var z: int = 0


func to_key() -> PoolIntArray:
	return PoolIntArray([x, y, z])
