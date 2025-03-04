extends Node

# Manages all game state and provides a wrapper around a BookUtil. Also manages various
# optimizations around caching and deciding which shelves to update. Set up as an AutoLoad.

const LRUCache = preload("res://scripts/data/LRUCache.gd")

const PARAMS = preload("res://scripts/data/room_gen_params.res")
const FLOOR_BOOK = preload("res://assets/props/FloorBook.tscn")
const LOWER_REAL_ROOMS = [PoolIntArray([1, 0, 0]), PoolIntArray([-1, 0, 0])]
const UPPER_REAL_ROOMS = [PoolIntArray([0, 1, 1]), PoolIntArray([0, -1, 1])]
const SAVE_PATH = "user://save.data"

# Dicts below use PoolIntArrays as keys since the Book/Shelf/RoomIndex objects would be compared by
# reference equality. PoolIntArrays are compared by value.

# List of non-offset rooms that are currently being updated with non-placeholder shelves.
# Updated when the player goes up/down stairs to match the set of shelves they can see.
var real_shelf_rooms = LOWER_REAL_ROOMS
# NativeScript object that implements all the expensive computations, see native/src/book_util.cpp
var book_util: BookUtil = BookUtil.new()
# Cache of shelf multimeshes, map from ShelfIndex -> MultiMesh
var shelf_cache = LRUCache.new(500)
# Dict of ShelfIndex -> (int -> Optional[BookIndex]). For each shelf, the books that have been
# changed, with null if removed, or a BookIndex if a different book has been placed into a slot
var shelf_diff = {}
# Dict of RoomIndex -> [FloorBook instance], refs to the rigid body books in each room
var floor_books = {}
# Index of the currently held book. If null there is no currently held book.
var held_book = null
# Page the held book is open to.
var held_book_page = 0
# Offset from the static indexes stored on each room to what is displayed in them. Updated
# whenever the player moves between rooms and is teleported back.
var room_offset: RoomIndex = RoomIndex.new()
# An arbitrary fixed shelf for use on shelves that are too far away to be legible.
var placeholder_shelf: MultiMesh
# Seed fed to book_util.randomize_origin to generate the full origin index. Takes less space to
# save than the full origin (4B vs 20KB)
var origin_seed: int

onready var book_shape = PARAMS.book_mesh.get_aabb()


func _init():
	book_util.room_gen_params = PARAMS
	# Use an arbitrary shelf as the placeholder
	placeholder_shelf = book_util.make_shelf_multimesh(0, 0, 0, 0)


func _notification(what):
	match what:
		NOTIFICATION_PREDELETE:
			# Floor books holds a bunch of orphan nodes, free them manually
			for books in floor_books.values():
				for b in books:
					if is_instance_valid(b):
						b.free()
			floor_books.clear()


func add_room_offset(off: Vector3):
	_push_floor_books()
	room_offset.x += int(off.x)
	room_offset.y += int(off.y)
	room_offset.z += int(off.z)
	if off.z > 0:
		real_shelf_rooms = LOWER_REAL_ROOMS
	elif off.z < 0:
		real_shelf_rooms = UPPER_REAL_ROOMS
	_refresh_rooms()


func _push_floor_books():
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "floor_books", "push_floor_books")


func _refresh_rooms():
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "floor_books", "remove_children")
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "floor_books", "pull_floor_books")
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "shelves", "regenerate_multimesh")


# Computes an AABB for a shelf MultiMesh, MultiMeshInstances need their AABB set manually for culling.
func get_shelf_aabb() -> AABB:
	var book_size = book_shape.size
	var size = Vector3(
		book_size.x,
		(PARAMS.num_shelves) * PARAMS.shelf_spacing - (PARAMS.shelf_spacing - book_size.y),
		PARAMS.books_per_shelf * (book_size.z + PARAMS.book_spacing) - PARAMS.book_spacing
	)
	var position = Vector3(-size.x / 2, 0, -size.z / 2)
	return AABB(position, size)


# Returns a BookIndex for the book slot under the given position on the bounding box for a shelf,
# or null if the position is invalid.
func get_book_index_at_point(ind: ShelfIndex, local_pos: Vector3) -> BookIndex:
	if fposmod(local_pos.y, PARAMS.shelf_spacing) > book_shape.size.y:
		return null
	var shelf_aabb = get_shelf_aabb()
	var book_size = book_shape.size
	var shelf = int(floor((local_pos.y - shelf_aabb.position.y) / PARAMS.shelf_spacing))
	var book = int(
		floor((local_pos.z - shelf_aabb.position.z) / (book_size.z + PARAMS.book_spacing))
	)
	# Prevents pulling from previous shelf on the ends
	book = int(clamp(book, 0, PARAMS.books_per_shelf - 1))
	var book_ind = BookIndex.new()
	book_ind.room.x = ind.room.x
	book_ind.room.y = ind.room.y
	book_ind.room.z = ind.room.z
	book_ind.shelf = ind.shelf
	book_ind.book = shelf * PARAMS.books_per_shelf + book
	return book_ind


# Updates the visible shelves when player moves up/down stairs. Call when player moves between rooms.
func set_player_position(ind: RoomIndex):
	var update_shelves = false
	if ind.z == 1 and real_shelf_rooms == LOWER_REAL_ROOMS:
		real_shelf_rooms = UPPER_REAL_ROOMS
		update_shelves = true
	elif ind.z == 0 and real_shelf_rooms == UPPER_REAL_ROOMS:
		real_shelf_rooms = LOWER_REAL_ROOMS
		update_shelves = true

	if update_shelves:
		for shelf in get_tree().get_nodes_in_group("shelves"):
			if shelf.shelf_index.room.to_key() in real_shelf_rooms:
				shelf.regenerate_multimesh()


func offset_room_index(ind: RoomIndex) -> RoomIndex:
	var res = RoomIndex.new()
	res.x = ind.x + room_offset.x
	res.y = ind.y + room_offset.y
	res.z = ind.z + room_offset.z
	return res


func _offset_shelf_index(ind: ShelfIndex) -> ShelfIndex:
	var res = ShelfIndex.new()
	res.room.x = ind.room.x + room_offset.x
	res.room.y = ind.room.y + room_offset.y
	res.room.z = ind.room.z + room_offset.z
	res.shelf = ind.shelf
	return res


func _offset_book_index(ind: BookIndex) -> BookIndex:
	var res = BookIndex.new()
	res.room.x = ind.room.x + room_offset.x
	res.room.y = ind.room.y + room_offset.y
	res.room.z = ind.room.z + room_offset.z
	res.shelf = ind.shelf
	res.book = ind.book
	return res


# Returns a reference to the active multimesh at the given slot
func get_shelf(ind: ShelfIndex) -> MultiMesh:
	if ind.room.to_key() in real_shelf_rooms:
		return _get_shelf_no_offset(_offset_shelf_index(ind))
	else:
		return get_placeholder_shelf(ind)


func get_placeholder_shelf(ind: ShelfIndex) -> MultiMesh:
	# Don't need to copy if there's no diff to apply
	if not shelf_diff.has(_offset_shelf_index(ind).to_key()):
		return placeholder_shelf
	var shelf = placeholder_shelf.duplicate()
	# Can't see the titles clearly for placeholders anyway, only need
	# to maintain the gaps.
	_apply_diff_gaps(_offset_shelf_index(ind), shelf)
	return shelf


func _get_shelf_no_offset(ind: ShelfIndex) -> MultiMesh:
	if shelf_cache.has(ind.to_key()):
		return shelf_cache.get(ind.to_key())

	var shelf_meshes = _make_room_shelves(ind.room)
	for i in range(4):
		var subind = ShelfIndex.new()
		subind.room = ind.room
		subind.shelf = i
		_apply_diff(subind, shelf_meshes[i])
		shelf_cache.add(subind.to_key(), shelf_meshes[i])
	return shelf_meshes[ind.shelf]


func get_book_at(ind: BookIndex) -> BookIndex:
	var offset_ind = _offset_book_index(ind)
	var shelf_ind = offset_ind.shelf_index()
	if not shelf_diff.has(shelf_ind.to_key()):
		shelf_diff[shelf_ind.to_key()] = {}
	var diff = shelf_diff[shelf_ind.to_key()]

	var curr
	if diff.has(offset_ind.book):
		curr = diff[offset_ind.book]
	else:
		curr = offset_ind
	return curr


# Removes the book at the given position from the shelf,
# returns the index of the book that was there, or null if no book is present.
func remove_book_at(ind: BookIndex) -> BookIndex:
	var curr = get_book_at(ind)
	if curr == null:
		return null
	var offset_ind = _offset_book_index(ind)

	var shelf_ind = offset_ind.shelf_index()
	var diff = shelf_diff[shelf_ind.to_key()]
	diff[offset_ind.book] = null

	# Hide the book at the given position
	# Assumes it's already loaded and won't waste by rebuilding
	var mesh = _get_shelf_no_offset(shelf_ind)
	var transform = mesh.get_instance_transform(offset_ind.book)
	var hidden_transform = Transform(Basis.IDENTITY.scaled(Vector3.ZERO), transform.origin)
	mesh.set_instance_transform(offset_ind.book, hidden_transform)

	return curr


# Places the given book on the shelf the given index.
# Returns true if successful, false if there is already a book present
func place_book_at(ind: BookIndex, book: BookIndex) -> bool:
	ind = _offset_book_index(ind)
	var shelf_ind = ind.shelf_index()
	# If no diff is present, there are no empty slots
	if not shelf_diff.has(shelf_ind.to_key()):
		return false
	var diff = shelf_diff[shelf_ind.to_key()]

	# If not in diff, not an empty space
	if not diff.has(ind.book):
		return false
	# Has another book, not an empty space
	if diff[ind.book] != null:
		return false

	# Space is an empty slot, insert the book
	# Space optimization: if it is the original book, erase the entry to replace it,
	if ind.to_key() == book.to_key():
		diff.erase(ind.book)
	else:
		diff[ind.book] = book

	# Unhide the book mesh at the given index, set the right title
	# Assumes it's already loaded and won't waste by rebuilding
	var mesh = _get_shelf_no_offset(shelf_ind)
	var transform = mesh.get_instance_transform(ind.book)
	transform.basis = Basis.IDENTITY
	mesh.set_instance_transform(ind.book, transform)
	# Always set the title, could have been previously set to another book's
	# title so can't assume it's the original. Can't check easily
	var title_color = book_util.get_packed_title_from_index(
		book.room.x, book.room.y, book.room.z, book.shelf, book.book
	)
	mesh.set_instance_color(ind.book, title_color)

	return true


func set_floor_books(ind: RoomIndex, books: Array):
	var offset_ind = offset_room_index(ind).to_key()
	if books.size() > 0:
		floor_books[offset_ind] = books
	elif floor_books.has(offset_ind):
		floor_books.erase(offset_ind)


func get_floor_books(ind: RoomIndex) -> Array:
	var offset_ind = offset_room_index(ind)
	if floor_books.has(offset_ind.to_key()):
		return floor_books[offset_ind.to_key()].duplicate()
	else:
		return []


func get_book_text(ind: BookIndex) -> BookText:
	return book_util.make_book(ind.room.x, ind.room.y, ind.room.z, ind.shelf, ind.book)


func get_title(book) -> Color:
	return book_util.get_packed_title(book)


func get_page(book, page: int) -> String:
	# Can't add type hint to book, or it becomes null
	return book_util.get_page(book, page)


# Get a Transform relative to the shelf for the book at the given index.
# Used to highlight selections and to animate pulling books off the shelf.
func get_book_transform(book: int) -> Transform:
	var shelf_ind = floor(book / PARAMS.books_per_shelf)
	var book_stride = PARAMS.book_spacing + book_shape.size.z
	var yoff = PARAMS.shelf_spacing * shelf_ind + book_shape.size.y / 2.0
	var zoff = (
		((book % PARAMS.books_per_shelf) - (PARAMS.books_per_shelf / 2.0)) * book_stride
		+ (book_stride / 2.0)
	)
	return Transform.IDENTITY.translated(Vector3(0, yoff, zoff))


func _make_room_shelves(ind: RoomIndex) -> Array:
	var res: Array = book_util.make_shelf_multimeshes(ind.x, ind.y, ind.z)
	return res


func _make_default_shelf() -> MultiMesh:
	var ind = RoomIndex.new()
	ind.x = 10000
	return _make_room_shelves(ind)[0]

func _apply_diff_gaps(ind: ShelfIndex, mesh: MultiMesh):
	if not shelf_diff.has(ind.to_key()):
		return
	var diff = shelf_diff[ind.to_key()]
	for i in diff.keys():
		var replacement = diff[i]
		if replacement == null:
			var transform = mesh.get_instance_transform(i)
			# Hide by scaling to 0
			var hidden_transform = Transform(Basis.IDENTITY.scaled(Vector3.ZERO), transform.origin)
			mesh.set_instance_transform(i, hidden_transform)


func _apply_diff_swapped(ind: ShelfIndex, mesh: MultiMesh):
	if not shelf_diff.has(ind.to_key()):
		return
	var diff = shelf_diff[ind.to_key()]
	for i in diff.keys():
		var replacement = diff[i]
		if replacement != null:
			var title_color = book_util.get_packed_title_from_index(
				replacement.room.x,
				replacement.room.y,
				replacement.room.z,
				replacement.shelf,
				replacement.book
			)
			mesh.set_instance_color(i, title_color)


func _apply_diff(ind: ShelfIndex, mesh: MultiMesh):
	_apply_diff_gaps(ind, mesh)
	_apply_diff_swapped(ind, mesh)


func save():
	var data = {}
	data["origin_seed"] = origin_seed
	data["offset"] = room_offset.to_key()
	if held_book == null:
		data["held_book"] = null
	else:
		data["held_book"] = held_book.to_key()
	data["held_book_page"] = held_book_page
	data["shelf_diffs"] = shelf_diff.duplicate(true)
	# store_var doesn't actually save Resources, just their object ID, convert to PoolIntArray.
	for shelf_ind in data["shelf_diffs"].keys():
		var diff = data["shelf_diffs"][shelf_ind]
		for book_ind in diff.keys():
			var val = diff[book_ind]
			if val != null:
				diff[book_ind] = val.to_key()
	_push_floor_books()
	var saved_floor_books = {}
	for room in floor_books.keys():
		var books = []
		for book in floor_books[room]:
			var book_state = {
				"transform": book.transform,
				"angular_velocity": book.angular_velocity,
				"linear_velocity": book.linear_velocity,
				"title": book.title,
				"book_index": book.book_index.to_key()
			}
			books.append(book_state)
		saved_floor_books[room] = books
	data["floor_books"] = saved_floor_books

	var file = File.new()
	file.open_compressed(SAVE_PATH, File.WRITE, File.COMPRESSION_GZIP)
	file.store_var(data)
	file.close()


func load_data():
	var file = File.new()
	if !file.file_exists(SAVE_PATH):
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		origin_seed = rng.seed
		book_util.randomize_origin(origin_seed)
		return
	file.open_compressed(SAVE_PATH, File.READ, File.COMPRESSION_GZIP)
	var data = file.get_var()
	file.close()
	assert(data != null)
	book_util.randomize_origin(data["origin_seed"])
	room_offset.from_key(data["offset"])
	var held_book_packed = data.get("held_book")
	if held_book_packed == null:
		held_book = null
	else:
		held_book = BookIndex.new()
		held_book.from_key(held_book_packed)
	held_book_page = data.get("held_book_page", 0)
	shelf_diff = data["shelf_diffs"]
	# Convert PoolIntArray keys back to BookIndex
	for shelf_ind in shelf_diff.keys():
		var diff = shelf_diff[shelf_ind]
		for book_ind in shelf_diff[shelf_ind].keys():
			var val = diff[book_ind]
			if val != null:
				var ind = BookIndex.new()
				ind.from_key(val)
				diff[book_ind] = ind
	floor_books = {}
	var saved_floor_books = data["floor_books"]
	for room in saved_floor_books.keys():
		var books = []
		for saved_book in saved_floor_books[room]:
			var book = FLOOR_BOOK.instance()
			book.transform = saved_book["transform"]
			book.linear_velocity = saved_book["linear_velocity"]
			book.angular_velocity = saved_book["angular_velocity"]
			book.title = saved_book["title"]
			var ind = BookIndex.new()
			ind.from_key(saved_book["book_index"])
			book.book_index = ind
			books.append(book)
		floor_books[room] = books
