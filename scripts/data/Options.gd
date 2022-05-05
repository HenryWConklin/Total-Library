extends Node

# Saves various options. Tracks an "applied" and "draft" version of all options,
# setting an option has no effect until "apply()" is called.

signal options_reloaded
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
	"shadows": 1, "display": 0, "resolution": Vector2(1280, 720), "vsync": true, "controls": {}
}

# Applied version of options, what is actually in effect
var _applied_options: Dictionary = {}
# Draft version of options, what is currently being modified by set()/get()
var _options: Dictionary = {}


func _ready():
	assert(get_viewport().connect("size_changed", self, "_on_viewport_size_changed") == OK)
	_load()
	apply()


func _load():
	var options_file = ConfigFile.new()
	_options = DEFAULT_OPTIONS.duplicate(true)
	if options_file.load(OPTIONS_PATH) == OK:
		for option in DEFAULT_OPTIONS.keys():
			if options_file.has_section_key("options", option):
				_options[option] = options_file.get_value("options", option)

	if not _options["resolution"] in RESOLUTION_CHOICES:
		RESOLUTION_CHOICES.append(_options["resolution"])


func reload():
	_options = _applied_options.duplicate(true)
	emit_signal("options_reloaded")


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
	_applied_options = _options.duplicate(true)
	for action in _options["controls"].keys():
		InputMap.action_erase_events(action)
		for event in _options["controls"][action]:
			InputMap.action_add_event(action, event)

	var options_file = ConfigFile.new()
	for option in _options.keys():
		options_file.set_value("options", option, Options.get(option))
	assert(options_file.save(OPTIONS_PATH) == OK)


func get(option: String):
	return _options[option]


func set(option: String, val):
	_options[option] = val


func replace_action_binding(action: String, old: InputEvent, new: InputEvent):
	var controls = _options["controls"]
	if not controls.has(action):
		controls[action] = InputMap.get_action_list(action)
	var old_ind = controls[action].find(old)
	assert(old_ind != -1)
	controls[action][old_ind] = new


func are_modified() -> bool:
	return _options.hash() != _applied_options.hash()


func get_action_events(action: String) -> Array:
	if _options["controls"].has(action):
		return _options["controls"][action]
	else:
		return InputMap.get_action_list(action)


func _on_viewport_size_changed():
	if OS.window_fullscreen:
		get_viewport().set_size(_options["resolution"])
