extends VBoxContainer

export(NodePath) var item_list: NodePath
export(NodePath) var search_text_label: NodePath
export(NodePath) var previous_page_button: NodePath
export(NodePath) var next_page_button: NodePath
export(NodePath) var find_button: NodePath

onready var _item_list: ItemList = get_node(item_list)
onready var _search_text_label: Label = get_node(search_text_label)
onready var _previous_page_button: Button = get_node(previous_page_button)
onready var _next_page_button: Button = get_node(next_page_button)
onready var _find_button: Button = get_node(find_button)

var _text: String = ""
var _page: int = 0
var _selected: int = -1

signal find_button_pressed(page, selected)
signal cancel_button_pressed()

func show_search_list(text: String):
	_search_text_label.text = text
	_page = 0
	_update_page()
	show()


func _update_page():
	_item_list.clear()
	for i in range(10):
		_item_list.add_item(str(_page) + " " + str(i))

func _on_PreviousPageButton_pressed():
	if _page > 0:
		_page -= 1
	if _page == 0:
		_previous_page_button.disabled = true
	_update_page()


func _on_FindButton_pressed():
	emit_signal("find_button_pressed", _page, _selected)


func _on_NextPageButton_pressed():
	# TODO end of list
	_page += 1
	_previous_page_button.disabled = false
	_update_page()

func _on_ItemList_item_selected(index):
	_selected = index
	_find_button.disabled = false


func _on_CancelButton_pressed():
	emit_signal("cancel_button_pressed")
