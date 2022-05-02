extends Node

signal shadow_setting_changed(val)

const DISPLAY_CHOICES = ["Windowed", "Borderless", "Fullscreen"]
const SHADOWS_CHOICES = ["Off", "Static only", "Full"]
const RESOLUTION_CHOICES: Array = [
	# 16:9
	Vector2(3840, 2160),
	Vector2(2560, 1440),
	Vector2(1920, 1080),
	Vector2(1366, 768),
	Vector2(1280, 720),
	# 16:10
	Vector2(1920, 1200),
	Vector2(1680, 1050),
	Vector2(1440, 900),
	Vector2(1280, 800),
	# 4:3
	Vector2(1024, 768),
	Vector2(800, 600),
	Vector2(640, 480)
]
const OPTIONS_PATH: String = "user://options.cfg"
const DEFAULT_OPTIONS: Dictionary = {
	"shadows": 1, "display": 0, "resolution": Vector2(1280, 720), "vsync": true
}

var _options: Dictionary = {}


func _ready():
	assert(get_viewport().connect("size_changed", self, "_on_viewport_size_changed") == OK)
	reload()
	apply()


func reload():
	var options_file = ConfigFile.new()
	if options_file.load(OPTIONS_PATH) == OK:
		for option in DEFAULT_OPTIONS.keys():
			_options[option] = options_file.get_value("options", option)
	else:
		_options = DEFAULT_OPTIONS.duplicate()

	if not _options["resolution"] in RESOLUTION_CHOICES:
		RESOLUTION_CHOICES.append(_options["resolution"])


func apply():
	match _options["display"]:
		0:  # Windowed
			OS.window_fullscreen = false
			OS.window_borderless = false
			OS.window_size = _options["resolution"]
		1:  # Borderless
			OS.window_borderless = true
			OS.window_fullscreen = true
		2:  # Fullscreen
			OS.window_borderless = false
			OS.window_fullscreen = true
	if OS.window_fullscreen:
		get_viewport().set_size(_options["resolution"])
	OS.vsync_enabled = _options["vsync"]
	emit_signal("shadow_setting_changed", _options["shadows"])

	var options_file = ConfigFile.new()
	for option in _options.keys():
		options_file.set_value("options", option, Options.get(option))
	assert(options_file.save(OPTIONS_PATH) == OK)


func get(option: String):
	return _options[option]


func set(option: String, val):
	_options[option] = val


func _on_viewport_size_changed():
	if OS.window_fullscreen:
		get_viewport().set_size(_options["resolution"])
