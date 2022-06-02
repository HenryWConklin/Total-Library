extends "res://addons/gut/test.gd"

var default_room_gen_params = preload("res://test/unit/default_room_gen_params.tres")


func make_default_bookutil() -> BookUtil:
	var res = BookUtil.new()
	res.room_gen_params = default_room_gen_params
	return res


func test_set_get_origin():
	var book_util = BookUtil.new()
	var original = PoolByteArray([1, 2, 3])

	book_util.origin = original

	assert_eq(book_util.origin, original)


func test_randomize_origin_does_something():
	var book_util = make_default_bookutil()
	assert_eq(book_util.origin, PoolByteArray([0]))

	book_util.randomize_origin(0)

	assert_ne(book_util.origin, PoolByteArray([0]))


func test_randomze_origin_consistent_with_seed():
	var book_util = make_default_bookutil()

	book_util.randomize_origin(0)
	var first = book_util.origin
	book_util.origin = PoolByteArray([0])
	book_util.randomize_origin(0)
	var second = book_util.origin

	assert_eq(first, second)


func test_randomize_different_with_different_seeds():
	var book_util = make_default_bookutil()

	book_util.randomize_origin(0)
	var first = book_util.origin
	book_util.origin = PoolByteArray([0])
	book_util.randomize_origin(1)
	var second = book_util.origin

	assert_ne(first, second)


func test_randomize_origin_uses_full_range():
	var book_util = make_default_bookutil()
	var chars_per_book = (
		book_util.room_gen_params.chars_per_page * book_util.room_gen_params.pages_per_book
		+ book_util.room_gen_params.title_chars
	)
	var bytes_per_char = log(book_util.room_gen_params.charset.length()) / log(2) / 8.0
	var expected_num_bytes = int(ceil(chars_per_book * bytes_per_char))

	book_util.randomize_origin(0)

	# Check that the number of bytes in the origin index equals the max,
	# < 2^-8 chance that it falls outside this bound if implemented correctly.
	# Should be way off if not implemented correctly.
	# Seed picked to make this condition pass if it fails by chance
	assert_eq(book_util.origin.size(), expected_num_bytes)


func test_make_shelf_multimesh_basic_config():
	var book_util = make_default_bookutil()

	var multimesh: MultiMesh = book_util.make_shelf_multimesh(0, 0, 0, 0)

	assert_eq(
		multimesh.instance_count,
		book_util.room_gen_params.books_per_shelf * book_util.room_gen_params.num_shelves
	)
	assert_eq(multimesh.color_format, MultiMesh.COLOR_FLOAT)
	assert_eq(multimesh.custom_data_format, MultiMesh.CUSTOM_DATA_NONE)
	assert_eq(multimesh.transform_format, MultiMesh.TRANSFORM_3D)
	assert_eq(multimesh.mesh, book_util.room_gen_params.book_mesh)


func test_make_shelf_multimesh_title_matches_get_packed_title():
	var book_util = make_default_bookutil()

	var multimesh: MultiMesh = book_util.make_shelf_multimesh(0, 0, 0, 0)
	var packed_title1 = multimesh.get_instance_color(1)
	var book = book_util.make_book(0, 0, 0, 0, 1)
	var packed_title2 = book_util.get_packed_title(book)

	assert_ne(packed_title1, Color())
	assert_eq(packed_title1, packed_title2)


func test_make_book_sets_indices():
	var book_util = make_default_bookutil()

	var book = book_util.make_book(0, 1, 2, 3, 4)

	assert_eq(book.room_x, 0)
	assert_eq(book.room_y, 1)
	assert_eq(book.room_z, 2)
	assert_eq(book.shelf, 3)
	assert_eq(book.book, 4)


func test_get_page_book_zero():
	var book_util = make_default_bookutil()
	var expected = ""
	# Update expected to match whatever permutation spits out
	for _i in range(book_util.room_gen_params.chars_per_page):
		expected += book_util.room_gen_params.charset[0]

	var book = book_util.make_book(0, 0, 0, 0, 0)
	var page = book_util.get_page(book, 0)

	assert_eq(page, expected)


func test_get_packed_title_book_zero():
	var book_util = make_default_bookutil()
	# Update expected to match whatever permutation spits out
	var expected = Color(0, 0, 0, 0)

	var book = book_util.make_book(0, 0, 0, 0, 0)
	var title = book_util.get_packed_title(book)

	assert_eq(title, expected)


func test_get_packed_title_from_index_book_zero():
	var book_util = make_default_bookutil()
	# Update expected to match whatever permutation spits out
	var expected = Color(0, 0, 0, 0)

	var title = book_util.get_packed_title_from_index(0, 0, 0, 0, 0)

	assert_eq(title, expected)


func test_book_util_full_pass_consistent():
	var book_util = make_default_bookutil()
	# Update expected to match whatever permutation spits out
	var expected_title = Color(8039573, 6460239, 10, 0)
	var expected_page = (
		"FO.O'?ZSRTCB,XHELGZ,MEJB DNDAUZ ZNCOBR!FXXUNCTJXG"
		+ "!MS WDMZRTVB,BM.GM,TXG .AOEH'SOFC.PPYH.CWMZE,AQB'"
		+ "XXMFONTFXNXGTVEMDERMKCHHYTRSAUYRUIYRORFXEAYDDLZH'"
		+ "B .HYQRUPOCLWHZYIV!SFLMIGMTOX,NEINLHPMPYJNKFZ 'XS"
		+ "BC?BIPUG ,JB'.K YBK,HU YKORFLUF'?BNCNNGPRZGM.DRK "
		+ "TW.GKM!U!'BCL,DQMGTRYBS?!FQN TBJSNMPVXO.ILSBHVPDB"
		+ "ZT,KN!V'WU?.WMW? UA IQCGG?"
	)

	book_util.randomize_origin(42)
	var book = book_util.make_book(1, 2, 3, 4, 5)
	var title = book_util.get_packed_title(book)
	var page = book_util.get_page(book, 3)

	assert_eq(title, expected_title)
	assert_eq(page, expected_page)

	for i in range(expected_page.length()):
		if expected_page[i] != page[i]:
			gut.p(i)
			gut.p(expected_page[i])
			gut.p(page[i])


# Title should be bit-aligned for non power of 2 charsets
func test_get_packed_title_from_index_non_pow_2_charset():
	var params = default_room_gen_params.duplicate()
	params.charset = "ABC"
	var book_util = BookUtil.new()
	book_util.room_gen_params = params
	# Will need to fix with permutations, no way to predict the title for a given index
	var expected = Color(0b101, 0, 0, 0)

	var title = book_util.get_packed_title_from_index(0, 0, 0, 0, 4)

	assert_eq(title, expected)


# Different code paths for non power of 2 charsets
func test_get_page_non_pow_2_charset():
	var params = default_room_gen_params.duplicate()
	params.charset = "ABC"
	params.title_chars = 1
	var book_util = BookUtil.new()
	book_util.room_gen_params = params
	var expected = "BB"
	for _i in range(book_util.room_gen_params.chars_per_page - 2):
		expected += book_util.room_gen_params.charset[0]

	var book = book_util.make_book(0, 0, 0, 0, 4 * 3)
	var page = book_util.get_page(book, 0)

	assert_eq(page, expected)
