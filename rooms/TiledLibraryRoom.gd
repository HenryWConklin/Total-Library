extends Spatial

const LibraryRoomScene = preload("res://rooms/LibraryRoom.tscn")
const PortalPlane = preload("res://props/PortalPlane.tscn")

const portal_viewport_ppu = 50

export(Vector3) var tile_size = Vector3(20, 2.74, 20)
export(Vector3) var tile_extent = Vector3(2, 2, 2) setget set_tile_extent
export(Vector3) var tile_center_offset = Vector3(0, 0.5, 0)
export(Vector2) var door_size = Vector2(10, 2.74)
export(Vector2) var floor_hole_size = Vector2(8, 8)

var tiles: Dictionary = Dictionary()
var center_tile: Vector3 = Vector3(0,0,0)

func _ready():
	_update_tiles()
	_update_portals()

func set_tile_extent(extent: Vector3):
	tile_extent = extent.round()

# Maps tile index to a position in the world, with assumption that the center
# tile is at the origin
func tile_index_to_world_position(ind: Vector3):
	return (ind - center_tile + tile_center_offset) * tile_size

# Maps a position in the world to the index of the tile that contains it,
# assuming the center tile is at the origin
func world_position_to_tile_index(pos: Vector3):
	return library_position_to_tile_index(pos) + center_tile

func tile_index_to_library_position(ind: Vector3):
	return (ind + tile_center_offset) * tile_size

func library_position_to_tile_index(pos: Vector3):
	return ((pos  / tile_size) - tile_center_offset).round()

func _update_tiles():
	var tile_pool: Array = []
	var indices = _get_visible_tile_indices()
	for k in tiles.keys():
		if not k in indices:
			tile_pool.append(tiles.get(k))
			tiles.erase(k)
	for k in indices:
		if not tiles.has(k):
			var tile = tile_pool.pop_back()
			if tile == null: 
				tile = _make_tile(k)
			else:
				_move_tile(tile, k)
			tiles[k] = tile
	for t in tile_pool:
		t.queue_free()

func _get_visible_tile_indices() -> Array:
	var inds = []
	for dx in range(-tile_extent.x, tile_extent.x + 1):
		for dy in range(-tile_extent.y, tile_extent.y + 1):
			for dz in range(-tile_extent.z, tile_extent.z + 1):
				inds.append(Vector3(dx, dy, dz))
	return inds

func _move_tile(tile: Spatial, ind: Vector3):
	tile.translate((ind * tile_size) - tile.translation)

func _make_tile(ind: Vector3) -> Spatial:
	var tile: Spatial = LibraryRoomScene.instance()
	tile.translate(ind * tile_size)
	add_child(tile)
	return tile

func _update_portals():
	# Start with back wall, i.e. no rotation
	var xz_off = Vector3(0, 0, -1)
	for i in range(4):
		for dy in [-2, -1, 0, 1, 2]:
			var cell = xz_off * tile_extent + Vector3(0, dy, 0)
			_make_portal_plane(cell, i+1, Vector3(0, 0, 1))
			var perp = xz_off.rotated(Vector3(0, 1, 0), PI/2) * tile_extent
			# Can't see most diagonals up/down a Y level
			if dy == 0:
				# Diagonals offset by two rooms so the door they're rendering
				# from matches the angle of the door with the plane
				_make_portal_plane(cell + perp, i+1, Vector3(2, 0, 2))
				_make_portal_plane(cell - perp, i+1, Vector3(-2, 0, 2))
		# Floor/Ceiling holes, one away on either X or Z and on Y
		# Broken if X or Z extents less than Y extents, may be wrong face or cell
		var extent_mag = (tile_extent * xz_off).length()
		for extra_off in range(extent_mag-1):
			_make_portal_plane((xz_off + Vector3(0, 1, 0)) * tile_extent.y + xz_off * extra_off, 
						0, 2*Vector3(-xz_off.x, -xz_off.z, 1))
			_make_portal_plane((xz_off + Vector3(0, -1, 0)) * tile_extent.y + xz_off * extra_off, 
						5, 2*Vector3(-xz_off.x, xz_off.z, 1))

		xz_off = xz_off.rotated(Vector3(0, 1, 0), PI/2)

	# Can see these two diagonals up a Y level
	_make_portal_plane(Vector3(tile_extent.x, 1, tile_extent.z), 4, Vector3(-2, 0, 2))
	_make_portal_plane(Vector3(-tile_extent.x, 1, -tile_extent.z), 1, Vector3(2, 0, 2))
	

func _make_portal_plane(cell: Vector3, cube_side: int, offset: Vector3):
	var portal = PortalPlane.instance()
	add_child(portal)
	portal.global_translate((cell + tile_center_offset) * tile_size)
	portal.viewport_pixels_per_unit = portal_viewport_ppu
	# Ceiling
	if cube_side == 0:
		portal.rotation.x = PI/2
		portal.render_offset = offset * tile_size.rotated(Vector3(1,0,0), PI/2).abs()
		portal.global_translate(Vector3(0, tile_size.y/2, 0))
		portal.portal_size = floor_hole_size
	# Walls
	elif cube_side >= 1 and cube_side <= 4:
		portal.rotation.y = PI/2 * (cube_side - 1)
		portal.render_offset = offset * tile_size.rotated(Vector3(0,1,0), portal.rotation.y).abs()
		# Because it's already rotated, can do a local translate along -Z to
		# get into position
		portal.translate(Vector3(0, 0, -tile_size.z/2))
		portal.portal_size = door_size
	# Floor
	elif cube_side == 5:
		portal.rotation.x = -PI/2
		portal.render_offset = offset * tile_size.rotated(Vector3(1,0,0), -PI/2).abs()
		# Extra .2 up to match floor-level and not bottom of the tile
		portal.global_translate(Vector3(0, -tile_size.y/2 + 0.2, 0))
		portal.portal_size = floor_hole_size

	return portal
