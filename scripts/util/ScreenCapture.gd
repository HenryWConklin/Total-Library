extends Node

# Records a sequence of screenshots.

export(String, DIR) var base_path

var recording = false
var frame_index = 0
var recording_dir: String


func _input(event):
	if event is InputEventKey and event.is_pressed() and event.scancode == KEY_F12:
		if not recording:
			recording = true
			recording_dir = "{year}-{month}-{day}-{hour}-{minute}-{second}".format(
				OS.get_datetime()
			)
			var dir = Directory.new()
			dir.open(base_path)
			dir.make_dir(recording_dir)
		else:
			recording = false


func _process(_delta):
	if recording:
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png(recording_dir + "/" + str(frame_index) + ".png")
		frame_index += 1
