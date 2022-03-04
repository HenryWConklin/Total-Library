extends Viewport

export(NodePath) var label_path: NodePath

var chars_per_line

onready var label: Label = get_node(label_path)


func _ready():
	# Assumes monospaced font, i.e. all chars have same width
	var char_size = label.get_font("font").get_char_size(ord("A"))
	print(char_size)
	chars_per_line = int(label.rect_size.x / char_size.x)


func set_text(text: String):
	var wrapped_string = ""
	for i in range(text.length() / chars_per_line):
		wrapped_string = wrapped_string + text.substr(i * chars_per_line, chars_per_line)
		wrapped_string = wrapped_string + "\n"
	label.text = wrapped_string
