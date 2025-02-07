extends VBoxContainer

export(int) var page_size: int = 8
export(int) var poll_size: int = 100
export(int) var search_ahead: int = page_size
export(NodePath) var item_list: NodePath
export(NodePath) var search_text_label: NodePath
export(NodePath) var previous_page_button: NodePath
export(NodePath) var next_page_button: NodePath
export(NodePath) var find_button: NodePath
export(NodePath) var search_count_label: NodePath
export(NodePath) var page_label: NodePath

onready var _item_list: ItemList = get_node(item_list)
onready var _search_text_label: Label = get_node(search_text_label)
onready var _previous_page_button: Button = get_node(previous_page_button)
onready var _next_page_button: Button = get_node(next_page_button)
onready var _find_button: Button = get_node(find_button)
onready var _search_count_label: Label = get_node(search_count_label)
onready var _page_label: Label = get_node(page_label)

var _text: String = ""
var _page: int = 0
var _selected: int = -1
var _search: BookSearch = BookSearch.new()
var _player_position: RoomIndex = RoomIndex.new()

signal find_button_pressed(page, selected)
signal cancel_button_pressed()

func _ready():
	_search.set_book_util(BookRegistry.book_util)
	if OS.get_name() == "HTML5":
		poll_size /= 2

func show_search_list(text: String):
	var room = BookRegistry.offset_room_index(_player_position)
	_search.set_location(room.x, room.y, room.z)
	_search.set_query(text)
	_search_text_label.text = text
	_page = 0
	_item_list.clear()
	_update_page()
	show()

func _result_display(result) -> String:
	var room = BookRegistry.offset_room_index(_player_position)
	var global_distance = abs(room.x - result.text.room_x) + abs(room.y - result.text.room_y) + abs(room.z - result.text.room_z)
	return result.title

func _process(_delta):
	# Visible meaning list UI is showing, not necessarily in view
	if visible:
		_search.poll_search(poll_size, search_ahead)
		_search_count_label.text = "{0}/{1}".format([
			_search.get_num_matches(), _search.get_num_searched()])
		_update_page()
		_next_page_button.disabled = _item_list.get_item_count() != page_size

func _update_page():
	_page_label.text = "Page {0}".format([_page + 1])
	var page_contents = _search.get_page(_page, page_size)
	for i in range(_item_list.get_item_count(), page_contents.size()):
		var text = _result_display(page_contents[i])
		_item_list.add_item(text)

func _on_PreviousPageButton_pressed():
	if _page > 0:
		_page -= 1
	if _page == 0:
		_previous_page_button.disabled = true
	_item_list.clear()
	_update_page()


func _on_FindButton_pressed():
	var results_page: Array = _search.get_page(_page, page_size)
	assert(_selected < results_page.size())
	emit_signal("find_button_pressed", results_page[_selected])


func _on_NextPageButton_pressed():
	_page += 1
	_previous_page_button.disabled = false
	_item_list.clear()
	_update_page()

func _on_ItemList_item_selected(index):
	_selected = index
	_find_button.disabled = false


func _on_CancelButton_pressed():
	emit_signal("cancel_button_pressed")

func set_player_position(position):
	_player_position = position
