extends Control

export(String) var charset: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ,.'?!"
export(DynamicFont) var source_font: DynamicFont
export(int) var glyph_sdf_height: int = 64
export(String, DIR) var dest_path
export(NodePath) var render_viewport_path
export(NodePath) var sdf_viewport_path
export(NodePath) var sdf_renderer_path
export(NodePath) var label_path
# Pixel range of the SDF function in the high resolution image, a distance of this many pixels is recorded as a 1
export(int) var sdf_range: int = 128
export(Color) var transparent_color: Color = Color.black

var viewport: Viewport
var sdf_viewport: Viewport
var sdf_renderer: Control
var textbox: Label


func _ready():
	# Wait a frame for initialization, skips the first letter otherwise
	yield(get_tree(), "idle_frame")
	textbox = get_node(label_path)
	viewport = get_node(render_viewport_path)
	sdf_viewport = get_node(sdf_viewport_path)
	sdf_renderer = get_node(sdf_renderer_path)
	make_sdf_font()


func make_sdf_font():
	var char_width = _get_max_char_width()
	var char_height = source_font.get_height()
	var glyph_sdf_width = int(ceil(float(glyph_sdf_height) * char_width / char_height))

	_setup_font()
	viewport.size = Vector2(char_width, char_height)
	# Transparant background also important, can't set in script for some reason
	sdf_viewport.size = Vector2(glyph_sdf_width, glyph_sdf_height)

	sdf_renderer.material.set_shader_param("transparent_color", transparent_color)
	sdf_renderer.material.set_shader_param("sdf_range", sdf_range)
	sdf_renderer.rect_scale = sdf_viewport.size / viewport.size

	print(
		"Rendering SDF font from source size ",
		char_width,
		"x",
		char_height,
		" to ",
		glyph_sdf_width,
		"x",
		glyph_sdf_height
	)
	for i in range(len(charset)):
		var c: String = charset[i]
		var img = yield(_render_string(c), "completed")

		# Files starting with a . are hidden, don't show up in the file selector
		var filename = c if c != "." else "dot"
		img.save_png(dest_path + "/" + filename + ".png")
	get_tree().quit()


func _setup_font():
	source_font.use_filter = false
	source_font.font_data.antialiased = false
	textbox.theme = Theme.new()
	textbox.theme.default_font = source_font


func _get_max_char_width():
	var max_width = 0
	for c in charset:
		max_width = max(max_width, source_font.get_char_size(ord(c)).x)
	return max_width


func _render_string(c: String):
	textbox.text = c

	yield(get_tree(), "idle_frame")

	var img = sdf_viewport.get_texture().get_data()
	var ret_img = Image.new()
	ret_img.copy_from(img)
	ret_img.lock()
	ret_img.flip_y()
	return ret_img
