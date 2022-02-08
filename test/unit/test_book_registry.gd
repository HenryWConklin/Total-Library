extends "res://addons/gut/test.gd"

const BookRegistry = preload("res://data/BookRegistry.gd")

var registry: BookRegistry

func before_each():
	registry = BookRegistry.new()
	add_child_autofree(registry)

# Had an issue with using ShelfIndex as a dict key directly, check that to_key method works as expected
func test_dict_keys():
	var index1 = ShelfIndex.new()
	var index2 = index1.duplicate()
	var dict = {index1.to_key(): "test"}

	assert_eq(dict[index2.to_key()], "test")


func test_get_shelf_returns_same_instance():
	var index1 = ShelfIndex.new()
	var index2 = ShelfIndex.new()

	var shelf1 = registry.get_shelf(index1)
	var shelf2 = registry.get_shelf(index2)

	# Compares by reference
	assert_eq(shelf1, shelf2)


func test_remove_book_at_hides_book():
	var book_index = BookIndex.new()
	var shelf_index = book_index.shelf_index()

	var _retval = registry.remove_book_at(book_index)
	var shelf = registry.get_shelf(shelf_index)

	assert_eq(shelf.get_instance_transform(book_index.book).basis.get_scale(), Vector3.ZERO)


func test_remove_book_at_hides_book_with_forced_fresh_instance():
	var book_index = BookIndex.new()
	var shelf_index = book_index.shelf_index()

	var _retval = registry.remove_book_at(book_index)
	var shelf = registry._make_shelf(shelf_index)
	registry._apply_diff(shelf_index, shelf)

	assert_eq(shelf.get_instance_transform(book_index.book).basis.get_scale(), Vector3.ZERO)


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

	assert_eq(remove1_res, book_index_dest)
	assert_eq(remove2_res.to_key(), book_index_src.to_key())


func test_remove_book_at_already_removed_returns_null():
	var index = BookIndex.new()

	var res1 = registry.remove_book_at(index)
	var res2 = registry.remove_book_at(index)

	assert_eq(res1, index)
	assert_null(res2)


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
	assert_eq(shelf.get_instance_color(index.book), 
					  registry.book_util.get_packed_title_from_index(index2.room.x, index2.room.y, index2.room.z, index2.shelf, index2.book))
	assert_eq(shelf.get_instance_transform(index.book).basis.get_scale(), Vector3.ONE)

func test_get_book_methods():
	var index = BookIndex.new()

	var book = registry.get_book_text(index)
	var title = registry.get_title(book)
	var page = registry.get_page(book, 0)

	assert_ne(book, null)
	assert_eq(title, 
					  registry.book_util.get_packed_title_from_index(index.room.x, index.room.y, index.room.z, index.shelf, index.book))
	assert_eq(page.length(), registry.params.chars_per_page)
	
