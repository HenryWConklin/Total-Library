extends Node

const LRUCache = preload("res://data/LRUCache.gd")

const params = preload("res://data/room_gen_params.tres")
var book_util: BookUtil = BookUtil.new()
var total_shelf_time = 0
# Cache of shelf multimeshes, map from ShelfIndex -> MultiMesh
var shelf_cache = LRUCache.new(500)
# Dict of ShelfIndex -> (index -> Optional[BookIndex])
var shelf_diff = {}
var room_offset: RoomIndex = RoomIndex.new()


func add_room_offset(off: Vector3):
	room_offset.x += int(off.x)
	room_offset.y += int(off.y)
	room_offset.z += int(off.z)
	get_tree().call_group("shelves", "regenerate_multimesh")


func get_shelf_aabb() -> AABB:
	var bookSize = params.book_mesh.get_aabb().size
	var size = Vector3(
		bookSize.x,
		(params.num_shelves) * params.shelf_spacing - (params.shelf_spacing - bookSize.y),
		params.books_per_shelf * (bookSize.z + params.book_spacing) - params.book_spacing
	)
	var position = Vector3(-size.x / 2, 0, -size.z / 2)
	return AABB(position, size)


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
	ind = _offset_shelf_index(ind)
	if shelf_cache.has(ind.to_key()):
		return shelf_cache.get(ind.to_key())

	var shelf_mesh = _make_shelf(ind)
	_apply_diff(ind, shelf_mesh)
	shelf_cache.add(ind.to_key(), shelf_mesh)
	return shelf_mesh


# Removes the book at the given position from the shelf,
# returns the index of the book that was there, or null if no book is present.
func remove_book_at(ind: BookIndex) -> BookIndex:
	ind = _offset_book_index(ind)
	var shelf_ind = ind.shelf_index()
	if not shelf_diff.has(shelf_ind.to_key()):
		shelf_diff[shelf_ind.to_key()] = {}
	var diff = shelf_diff[shelf_ind.to_key()]

	var curr
	if diff.has(ind.book):
		curr = diff[ind.book]
	else:
		curr = ind
	if curr == null:
		return null

	diff[ind.book] = null

	# Hide the book at the given position
	# Assumes it's already loaded and won't waste by rebuilding
	var mesh = get_shelf(shelf_ind)
	var transform = mesh.get_instance_transform(ind.book)
	mesh.set_instance_transform(ind.book, transform.scaled(Vector3.ZERO))

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
	var mesh = get_shelf(shelf_ind)
	var transform = mesh.get_instance_transform(ind.book)
	transform.basis = Basis.IDENTITY
	mesh.set_instance_transform(ind.book, transform)
	# Always set the title, could have been previously set to another book's title so can't assume it's the original. Can't check easily
	var title_color = book_util.get_packed_title_from_index(
		book.room.x, book.room.y, book.room.z, book.shelf, book.book
	)
	mesh.set_instance_color(ind.book, title_color)

	return true


func get_book_text(ind: BookIndex) -> BookText:
	return book_util.make_book(ind.room.x, ind.room.y, ind.room.z, ind.shelf, ind.book)


func get_title(book) -> Color:
	return book_util.get_packed_title(book)


func get_page(book, page: int) -> String:
	# Can't add type hint to book, or it becomes null
	return book_util.get_page(book, page)


func _init():
	book_util.room_gen_params = params
	book_util.randomize_origin(123)


func _make_shelf(ind: ShelfIndex) -> MultiMesh:
	var res: MultiMesh = book_util.make_shelf_multimesh(
		ind.room.x, ind.room.y, ind.room.z, ind.shelf
	)
	return res


func _make_default_shelf() -> MultiMesh:
	var ind = ShelfIndex.new()
	ind.room.x = 10000
	return _make_shelf(ind)


func _apply_diff(ind: ShelfIndex, mesh: MultiMesh):
	if not shelf_diff.has(ind.to_key()):
		return
	var diff = shelf_diff[ind.to_key()]
	for i in diff.keys():
		var replacement = diff[i]
		if replacement == null:
			var transform = mesh.get_instance_transform(i)
			# Hide by scaling to 0
			mesh.set_instance_transform(i, transform.scaled(Vector3(0, 0, 0)))
		else:
			var title_color = book_util.get_packed_title_from_index(
				replacement.room.x,
				replacement.room.y,
				replacement.room.z,
				replacement.shelf,
				replacement.book
			)
			mesh.set_instance_color(i, title_color)
