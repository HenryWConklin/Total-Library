extends Node

export(String) var charset: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ,.?!"
export(DynamicFont) var source_font: DynamicFont
export(int) var glyph_sdf_height: int = 16
export(String, DIR) var dest_path
export(NodePath) var viewport_path
export(NodePath) var label_path
# Pixel range of the SDF function in the high resolution image, a distance of this many pixels is recorded as a 1
export(float) var sdf_range = 256
export(Color) var transparent_color = Color.black

var viewport: Viewport
var textbox: Label

func _ready():
	textbox = get_node(label_path)
	viewport = get_node(viewport_path)
	# Wait a frame for initialization, skips the first letter otherwise
	yield(get_tree(), "idle_frame")
	make_sdf_font()


func make_sdf_font():
	var char_width = _get_max_char_width()
	var char_height = source_font.get_height()
	var glyph_sdf_width = int(ceil(float(glyph_sdf_height) * char_width / char_height))
	print("Rendering SDF font from source size ", char_width, "x", char_height, " to ", glyph_sdf_width, "x", glyph_sdf_height)
	for i in range(len(charset)):
		var c: String = charset[i]
		var img = yield(_render_string(c), "completed")
		
		var sdf_img = _image_to_sdf(img, Vector2(glyph_sdf_width, glyph_sdf_height))
		# Files starting with a . are hidden, don't show up in the file selector
		var filename = c if c != '.' else 'dot'
		sdf_img.save_png(dest_path + "/" + filename + ".png")
	get_tree().quit()
	
func _setup_font():
	source_font.use_filter = false
	source_font.font_data.antialiased = false

func _get_max_char_width():
	var max_width = 0
	for c in charset:
		max_width = max(max_width, source_font.get_char_size(ord(c)).x)
	return max_width

func _render_string(c: String):
	textbox.text = c
	textbox.theme.default_font = source_font
	viewport.size = source_font.get_string_size(c) + Vector2(4, 4)

	yield(get_tree(), "idle_frame")

	var img = viewport.get_texture().get_data()
	var ret_img = Image.new()
	ret_img.copy_from(img)
	ret_img.lock()
	ret_img.flip_y()
	return ret_img

func _image_to_sdf(img: Image, sdf_size: Vector2) -> Image:
	var result_image: Image = Image.new()
	result_image.create(int(sdf_size.x), int(sdf_size.y), false, Image.FORMAT_RGBA8)
	result_image.lock()

	for dest_x_ind in range(result_image.get_width()):
		var dest_x = float(dest_x_ind) / (result_image.get_width() - 1) * (img.get_width() - 1)
		for dest_y_ind in range(result_image.get_height()):
			var dest_y = float(dest_y_ind) / (result_image.get_height() - 1) * (img.get_height() - 1)
			var dest_pos = Vector2(dest_x, dest_y)
			var min_dist = INF
			var dest_color = img.get_pixelv(dest_pos.round())
			# Assume black and white source image, use black as transparent
			var dest_inside = dest_color != transparent_color
			var source_x_range = range(
				int(max(0, round(dest_x - sdf_range))), 
				int(min(img.get_width() - 1, round(dest_x + sdf_range))))
			var source_y_range = range(
				int(max(0, round(dest_y - sdf_range))), 
				int(min(img.get_height() - 1, round(dest_y + sdf_range))))
			for source_x in source_x_range:
				for source_y in source_y_range:
					var src_color = img.get_pixel(source_x, source_y)
					# Assume black and white source image, use black as transparent
					var src_inside = src_color != transparent_color
					if src_inside != dest_inside:
						var dist = dest_pos.distance_to(Vector2(source_x, source_y))
						min_dist = min(dist, min_dist)
			# Want negative distance outside the shape, so we can threshold on alpha > 0.5 in the shader
			if not dest_inside:
				min_dist = -min_dist
			min_dist /= sdf_range
			var sdf_alpha = clamp((min_dist + 1.0) / 2.0, 0, 1)
			result_image.set_pixel(
				dest_x_ind, 
				dest_y_ind, 
				Color(dest_color.r, dest_color.g, dest_color.b, sdf_alpha))
	return result_image
