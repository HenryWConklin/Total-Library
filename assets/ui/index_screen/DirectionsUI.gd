extends VBoxContainer

const SHELF_STRINGS = ["bottom shelf", "bottom-middle shelf", "middle shelf", "top-middle shelf", "top shelf"]

export(NodePath) var arrow_rect: NodePath
export(NodePath) var book_search_label: NodePath
export(NodePath) var distance_label: NodePath
export(Texture) var arrow_up: Texture
export(Texture) var arrow_down: Texture
export(Texture) var arrow_left: Texture
export(Texture) var arrow_right: Texture
export(Texture) var arrow_here: Texture

onready var _arrow_rect: TextureRect = get_node(arrow_rect)
onready var _book_search_label: Label = get_node(book_search_label)
onready var _distance_label: Label = get_node(distance_label)

# No type hint or it will segfault
var _result
var _player_position: RoomIndex = RoomIndex.new()

signal back_button_pressed()

func show_directions(result):
	_result = result

	var book_ind = _result.text.book % BookRegistry.PARAMS.books_per_shelf
	var shelf_ind = _result.text.book / BookRegistry.PARAMS.books_per_shelf
	var bookshelf_ind = _result.text.shelf

	var bookshelf_str: String
	if bookshelf_ind < 2:
		bookshelf_str = "near wall"
	else:
		bookshelf_str = "far wall"

	var book_str
	if bookshelf_ind == 0 or bookshelf_ind == 2:
		var disp_ind = book_ind + 1
		book_str = "{0} {1} from the right".format([
			disp_ind,
			_pluralize("book", "books", disp_ind)])
	else:
		var left_book_ind = BookRegistry.PARAMS.books_per_shelf - book_ind
		book_str = "{0} {1} from the left".format([
			left_book_ind,
			_pluralize("book", "books", left_book_ind)])

	var shelf_str: String = SHELF_STRINGS[shelf_ind]
	var page_str: String
	if _result.result_page == -1:
		page_str = "in the title"
	else:
		page_str = "page {0}".format([_result.result_page + 1])

	_book_search_label.text = "{0}\n{1} {2}\n{3}\n{4}\n".format([
		_result.title,
		bookshelf_str,
		shelf_str,
		book_str,
		page_str
	])

	_update_display()
	show()

func _process(_delta):
	if visible:
		_update_display()

func _update_display():
	var global_pos = BookRegistry.offset_room_index(_player_position)

	_arrow_rect.texture = _get_arrow_texture()

	var total_distance: int = int(abs(global_pos.x - _result.text.room_x) +
		abs(global_pos.y - _result.text.room_y) +
		abs(global_pos.z - _result.text.room_z))

	_distance_label.text = "{0} {1} away".format([
		total_distance,
		_pluralize("room", "rooms", total_distance)])

func _get_arrow_texture():
	var global_pos = BookRegistry.offset_room_index(_player_position)

	var x_distance = _result.text.room_x - global_pos.x
	var y_distance = _result.text.room_y - global_pos.y
	var z_distance = _result.text.room_z - global_pos.z

	var horizontal_distance: int = 0
	var other_horizontal_distance: int = 0
	var in_library_room: bool = false
	if _player_position.z % 2 == 0:
		horizontal_distance = x_distance
		other_horizontal_distance = -y_distance
		in_library_room = _player_position.x % 2 != 0
	else:
		horizontal_distance = -y_distance
		other_horizontal_distance = x_distance
		in_library_room = _player_position.y % 2 != 0

	if x_distance == 0 and y_distance == 0 and z_distance == 0:
		return arrow_here
	if horizontal_distance > 1:
		return arrow_left
	if horizontal_distance < -1:
		return arrow_right
	if in_library_room and horizontal_distance == 0 and (abs(other_horizontal_distance) > 0 or abs(z_distance) > 0):
		return arrow_left
	if not in_library_room and z_distance > 0:
		return arrow_up
	if not in_library_room and (z_distance < 0 or abs(other_horizontal_distance) > 0):
		return arrow_down
	if horizontal_distance > 0:
		return arrow_left
	if horizontal_distance < 0:
		return arrow_right

func _on_BackButton_pressed():
	emit_signal("back_button_pressed")

func _pluralize(single: String, plural: String, n: int):
	if n == 1:
		return single
	else:
		return plural

func set_player_position(position: RoomIndex):
	_player_position = position
