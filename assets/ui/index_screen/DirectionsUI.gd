extends VBoxContainer

export(NodePath) var arrow_rect: NodePath
export(NodePath) var book_search_label: NodePath
export(NodePath) var distance_label: NodePath

onready var _arrow_rect: TextureRect = get_node(arrow_rect)
onready var _book_search_label: Label = get_node(book_search_label)
onready var _distance_label: Label = get_node(distance_label)

signal back_button_pressed()

func show_directions(page, selected):
	_book_search_label.text = str(page)
	_distance_label.text = str(selected)
	show()

func _on_BackButton_pressed():
	emit_signal("back_button_pressed")
