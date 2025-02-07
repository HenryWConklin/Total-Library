extends Control

export(NodePath) var search_ui: NodePath
export(NodePath) var list_ui: NodePath
export(NodePath) var directions_ui: NodePath
export(NodePath) var mouse_pointer: NodePath

onready var _search_ui: Control = get_node(search_ui)
onready var _list_ui: Control = get_node(list_ui)
onready var _directions_ui: Control = get_node(directions_ui)
onready var _mouse_pointer: Node2D = get_node(mouse_pointer)


func _on_SearchUI_search_pressed(text):
	_search_ui.hide()
	_list_ui.show_search_list(text)

func _on_ListUI_find_button_pressed(result):
	_list_ui.hide()
	_directions_ui.show_directions(result)

func _on_ListUI_cancel_button_pressed():
	_list_ui.hide()
	_search_ui.show()

func _on_DirectionsUI_back_button_pressed():
	_directions_ui.hide()
	_list_ui.show()

func update_cursor_position(position: Vector2):
	_mouse_pointer.position = position
