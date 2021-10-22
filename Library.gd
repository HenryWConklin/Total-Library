extends Spatial

const LibraryRoomScene = preload("res://rooms/LibraryRoom.tscn")

export(Vector3) var tile_size = Vector3(20, 2.74, 20)
export(Vector3) var tile_extent = Vector3(2, 2, 2)
export(String) var player_node_name = "Player"
export(String) var room_area_path = "RoomArea"

var tiles: Dictionary = Dictionary()

func _ready():
	for ind in get_visible_tile_indices(Vector3(0,0,0)):
		var tile = _make_tile(ind)
		add_child(tile)
		tiles[ind] = tile
		
func tile_index_to_position(ind: Vector3):
	return ind * tile_size

func position_to_tile_index(pos: Vector3):
	return ((pos + Vector3(0, tile_size.y/2, 0)) / tile_size).round()

func get_visible_tile_indices(center: Vector3) -> Array:
	var inds = []
	for dx in range(-tile_extent.x, tile_extent.x + 1):
		for dy in range(-tile_extent.y, tile_extent.y + 1):
			for dz in range(-tile_extent.z, tile_extent.z + 1):
				inds.append(Vector3(center.x + dx, center.y + dy, center.z + dz))
	return inds

func update_tiles(center: Vector3):
	var tile_pool: Array = []
	var indices = get_visible_tile_indices(center)
	for k in tiles.keys():
		if not k in indices:
			tile_pool.append(tiles.get(k))
			tiles.erase(k)
	for k in indices:
		if not tiles.has(k):
			var tile = tile_pool.pop_back()
			_move_tile(tile, k)
			tiles[k] = tile
					
func _move_tile(tile: Spatial, ind: Vector3):
	tile.translation = tile_index_to_position(ind)
	tile.get_node("RoomArea").disconnect("body_entered", self, "_on_room_area_entered")
	tile.get_node("RoomArea").connect("body_entered", self, "_on_room_area_entered", [ind])

func _make_tile(ind: Vector3) -> Spatial:
	var tile: Spatial = LibraryRoomScene.instance(PackedScene.GEN_EDIT_STATE_DISABLED)
	tile.translate(tile_index_to_position(ind))
	tile.get_node("RoomArea").connect("body_entered", self, "_on_room_area_entered", [ind])
	return tile
	
func _on_room_area_entered(body, ind):
	if body.name == player_node_name:
		self.call_deferred("update_tiles", ind)
