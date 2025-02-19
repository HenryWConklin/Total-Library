extends VBoxContainer

export(NodePath) var search_box: NodePath
export(NodePath) var search_button: NodePath

onready var _search_box: LineEdit = get_node(search_box)
onready var _search_button: Button = get_node(search_button)

signal search_pressed(text)

func set_search_text(val: String):
	_search_box.text = val
	_search_box.caret_position = val.length()
	_search_button.set_disabled(val.length() == 0)

func get_search_text() -> String:
	return _search_box.text

func _on_KeyboardGrid_key_pressed(key):
	set_search_text(get_search_text() + key)


func _on_KeyboardGrid_delete_pressed():
	var text = get_search_text()
	set_search_text(text.substr(0, len(text) - 1))


func _on_SpaceButton_pressed():
	set_search_text(get_search_text() + ' ')


func _on_SearchButton_pressed():
	emit_signal("search_pressed", _search_box.text)
