extends "res://addons/gut/test.gd"

const BookRegistry = preload("res://scripts/data/BookRegistry.gd")

var registry: BookRegistry


func before_each():
	registry = BookRegistry.new()
	add_child_autofree(registry)


# Had an issue with using ShelfIndex as a dict key directly,
# check that to_key method works as expected
func test_dict_keys():
	var index1 = ShelfIndex.new()
	var index2 = index1.duplicate()
	var dict = {index1.to_key(): "test"}

	assert_eq(dict[index2.to_key()], "test")


func test_get_shelf_returns_same_instance():
	var index1 = ShelfIndex.new()
	index1.room.x = 1
	var index2 = ShelfIndex.new()
	index2.room.x = 1

	var shelf1 = registry.get_shelf(index1)
	var shelf2 = registry.get_shelf(index2)

	# Compares by reference
	assert_eq(shelf1, shelf2)


func test_get_shelf_respects_offset():
	var index1 = ShelfIndex.new()
	index1.room.x = 1
	var index2 = ShelfIndex.new()
	index2.room.x = -1

	var shelf1 = registry.get_shelf(index1)
	registry.add_room_offset(Vector3(2, 0, 0))
	var shelf2 = registry.get_shelf(index1)
	var shelf3 = registry.get_shelf(index2)

	assert_ne(shelf1, shelf2)
	assert_eq(shelf1, shelf3)


func test_get_book_text_at_point_returns_expected_book():
	var index = ShelfIndex.new()
	index.room.x = 1
	index.room.y = 2
	index.room.z = 3
	index.shelf = ShelfIndex.Side.NORTH
	var shelf_aabb = registry.get_shelf_aabb()
	var pos = (
		shelf_aabb.position
		+ Vector3(
			0,
			registry.PARAMS.shelf_spacing + registry.book_shape.size.y / 2,
			(
				(registry.book_shape.size.z + registry.PARAMS.book_spacing) * 3
				+ registry.book_shape.size.z / 2
			)
		)
	)
	var expected_book_ind = registry.PARAMS.books_per_shelf + 3

	var result = registry.get_book_index_at_point(index, pos)

	assert_eq(result.room.x, index.room.x)
	assert_eq(result.room.y, index.room.y)
	assert_eq(result.room.z, index.room.z)
	assert_eq(result.shelf, index.shelf)
	assert_eq(result.book, expected_book_ind)


func test_get_book_at_point_returns_expected_on_near_end():
	var index = ShelfIndex.new()
	index.room.x = 1
	index.room.y = 2
	index.room.z = 3
	index.shelf = ShelfIndex.Side.NORTH
	var shelf_aabb = registry.get_shelf_aabb()
	var pos = (
		shelf_aabb.position
		+ Vector3(
			shelf_aabb.size.x / 2,
			registry.PARAMS.shelf_spacing + registry.book_shape.size.y / 2,
			-1
		)
	)
	# Significant extra on the end to catch issues with bounding box not matching exactly
	var expected_book_ind = registry.PARAMS.books_per_shelf

	var result = registry.get_book_index_at_point(index, pos)

	assert_eq(result.book, expected_book_ind)


func test_get_book_at_point_returns_expected_on_far_end():
	var index = ShelfIndex.new()
	index.room.x = 1
	index.room.y = 2
	index.room.z = 3
	index.shelf = ShelfIndex.Side.NORTH
	var shelf_aabb = registry.get_shelf_aabb()
	var pos = (
		shelf_aabb.position
		+ Vector3(
			shelf_aabb.size.x / 2,
			registry.PARAMS.shelf_spacing + registry.book_shape.size.y / 2,
			shelf_aabb.size.z + 1
		)
	)
	# Significant extra on the end to catch issues with bounding box not matching exactly
	var expected_book_ind = 2 * registry.PARAMS.books_per_shelf - 1

	var result = registry.get_book_index_at_point(index, pos)

	assert_eq(result.book, expected_book_ind)


func test_remove_book_at_hides_book():
	var book_index = BookIndex.new()
	var shelf_index = book_index.shelf_index()

	var _retval = registry.remove_book_at(book_index)
	var shelf = registry.get_shelf(shelf_index)
	var transform = shelf.get_instance_transform(book_index.book)

	assert_eq(transform.basis.get_scale(), Vector3.ZERO)


func test_remove_book_at_keeps_hidden_translation():
	var book_index = BookIndex.new()
	book_index.book = 1
	var shelf_index = book_index.shelf_index()

	# Running remove before get_shelf means apply_diff gets run on the shelf before remove tries
	# to hide the book, so this ordering technically tests both
	var _retval = registry.remove_book_at(book_index)
	var shelf = registry.get_shelf(shelf_index)
	var transform = shelf.get_instance_transform(book_index.book)

	assert_ne(transform.origin, Vector3.ZERO)


func test_remove_book_at_returns_correct_index():
	var book_index_src = BookIndex.new()
	book_index_src.room.x = 1
	book_index_src.room.y = 2
	book_index_src.room.z = 3
	book_index_src.shelf = ShelfIndex.Side.SOUTH
	var book_index_dest = BookIndex.new()

	var remove1_res = registry.remove_book_at(book_index_dest)
	assert_true(registry.place_book_at(book_index_dest, book_index_src))
	var remove2_res = registry.remove_book_at(book_index_dest)

	assert_eq(remove1_res.to_key(), book_index_dest.to_key())
	assert_eq(remove2_res.to_key(), book_index_src.to_key())


func test_remove_book_at_already_removed_returns_null():
	var index = BookIndex.new()

	var res1 = registry.remove_book_at(index)
	var res2 = registry.remove_book_at(index)

	assert_eq(res1.to_key(), index.to_key())
	assert_null(res2)


func test_remove_book_at_respects_offset():
	var index = BookIndex.new()
	index.room.x = -1

	registry.add_room_offset(Vector3(2, 0, 0))
	var shelf = registry.get_shelf(index.shelf_index())
	var removed = registry.remove_book_at(index)

	assert_eq(removed.to_key(), PoolIntArray([1, 0, 0, 0, 0]))
	# Check that right book is hidden, had an issue with offsets applied twice
	assert_eq(shelf.get_instance_transform(index.book).basis, Basis.IDENTITY.scaled(Vector3.ZERO))


func test_place_book_at_fails_on_no_diff():
	var index = BookIndex.new()

	assert_false(registry.place_book_at(index, index))


func test_place_book_at_fails_on_other_slot_changed():
	var index = BookIndex.new()
	var index2 = BookIndex.new()
	index2.book = 2

	var removed = registry.remove_book_at(index2)
	assert_false(registry.place_book_at(index, removed))


func test_place_book_at_fails_on_filled_slot():
	var index = BookIndex.new()
	var index2 = BookIndex.new()
	index2.book = 2
	var index3 = BookIndex.new()
	index3.book = 3

	var _removed = registry.remove_book_at(index)
	var removed = registry.remove_book_at(index2)
	assert_true(registry.place_book_at(index, removed))
	assert_false(registry.place_book_at(index, index3))

	assert_eq(registry.remove_book_at(index).to_key(), index2.to_key())


func test_place_book_at_fills_empty_slot():
	var index = BookIndex.new()
	var index2 = BookIndex.new()
	index2.book = 2

	var _removed = registry.remove_book_at(index)
	var removed = registry.remove_book_at(index2)
	assert_true(registry.place_book_at(index, removed))
	assert_eq(index2.to_key(), registry.remove_book_at(index).to_key())


func test_place_book_at_updates_mesh():
	var index = BookIndex.new()
	var index2 = BookIndex.new()
	index2.book = 2

	var _removed = registry.remove_book_at(index)
	assert_true(registry.place_book_at(index, index2))

	var shelf = registry.get_shelf(index.shelf_index())
	assert_eq(
		shelf.get_instance_color(index.book),
		registry.book_util.get_packed_title_from_index(
			index2.room.x, index2.room.y, index2.room.z, index2.shelf, index2.book
		)
	)
	assert_eq(shelf.get_instance_transform(index.book).basis.get_scale(), Vector3.ONE)


func test_place_book_at_respects_offset():
	var index = BookIndex.new()
	index.room.x = -1

	registry.add_room_offset(Vector3(2, 0, 0))
	var shelf = registry.get_shelf(index.shelf_index())
	var removed = registry.remove_book_at(index)
	assert_eq(removed.to_key(), PoolIntArray([1, 0, 0, 0, 0]))
	assert_eq(shelf.get_instance_transform(index.book).basis, Basis.IDENTITY.scaled(Vector3.ZERO))
	assert_true(registry.place_book_at(index, index))
	assert_eq(shelf.get_instance_transform(index.book).basis, Basis.IDENTITY)


func test_set_get_floor_books():
	var index = RoomIndex.new()
	index.x = 1
	index.y = 2
	index.z = 3
	var books = [RigidBody.new()]

	registry.set_floor_books(index, books)
	var result = registry.get_floor_books(index)

	assert_eq(result, books)


func test_floor_books_respects_offset():
	var index = RoomIndex.new()
	index.x = 1
	index.y = 2
	index.z = 3
	var books = [RigidBody.new()]

	registry.set_floor_books(index, books)
	registry.add_room_offset(Vector3(1, 0, 0))
	var result1 = registry.get_floor_books(index)
	index.x -= 1
	var result2 = registry.get_floor_books(index)

	assert_eq(result1.size(), 0)
	assert_eq(result2, books)


func test_floor_books_clears_entry_on_empty_set():
	var index = RoomIndex.new()
	index.x = 1
	index.y = 2
	index.z = 3
	var books = [RigidBody.new()]

	registry.set_floor_books(index, books)
	registry.set_floor_books(index, [])
	var result = registry.get_floor_books(index)

	assert_eq(result.size(), 0)
	books[0].free()

func test_get_book_methods():
	var index = BookIndex.new()

	var book = registry.get_book_text(index)
	var title = registry.get_title(book)
	var page = registry.get_page(book, 0)

	assert_ne(book, null)
	assert_eq(
		title,
		registry.book_util.get_packed_title_from_index(
			index.room.x, index.room.y, index.room.z, index.shelf, index.book
		)
	)
	assert_eq(page.length(), registry.PARAMS.chars_per_page)
