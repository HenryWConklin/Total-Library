extends Control

# UI Elements to render text inside a book.

export(NodePath) var text_label_path: NodePath
export(NodePath) var page_label_path: NodePath
export(DynamicFontData) var font: DynamicFontData
export(int) var page_number_font_size: int = 26
export(int) var text_font_size = 34
export(int) var chars_per_line: int = 20

onready var text_label: Label = get_node(text_label_path)
onready var page_label: Label = get_node(page_label_path)

func _ready():
	text_label.theme.default_font = DynamicFont.new()
	page_label.theme.default_font = DynamicFont.new()

	text_label.theme.default_font.font_data = font
	page_label.theme.default_font.font_data = font

	text_label.theme.default_font.size = text_font_size
	page_label.theme.default_font.size = page_number_font_size

func set_text(text: String, page_number: int):
	var wrapped_string = ""
	var num_lines: int = text.length() / chars_per_line
	for i in range(num_lines):
		wrapped_string = wrapped_string + text.substr(i * chars_per_line, chars_per_line)
		wrapped_string = wrapped_string + "\n"
	wrapped_string = wrapped_string + text.substr(num_lines * chars_per_line)
	text_label.text = wrapped_string

	page_label.text = str(page_number)
