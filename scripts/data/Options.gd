extends Node

# Saves various options. Tracks an "applied" and "draft" version of all options,
# setting an option has no effect until "apply()" is called. Set up as an AutoLoad.

signal options_reloaded
signal shadow_setting_changed(val)
signal fov_setting_changed(val)

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
# Needs to match the Viewport.MSAA_* constants
const MSAA_CHOICES: Array = ["Off", "2x", "4x", "8x", "16x"]
const OPTIONS_PATH: String = "user://options.cfg"
const DEFAULT_OPTIONS: Dictionary = {
	"shadows": 1,
	"display": 0,
	"msaa": 0,
	"fxaa": false,
	"resolution": Vector2(1280, 720),
	"vsync": true,
	"fov": 90,
	"look_sensitivity": 1.0,
	"sfx_volume": 1.0,
	"controls": {}
}

# Applied version of options, what is actually in effect
var _applied_options: Dictionary = {}
# Draft version of options, what is currently being modified by set()/get()
var _options: Dictionary = {}

onready var _sfx_bus = AudioServer.get_bus_index("SFX")


func _ready():
	var err = get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	assert(err == OK)
	_load()
	apply()


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
	get_viewport().msaa = _options["msaa"]
	get_viewport().fxaa = _options["fxaa"]
	OS.vsync_enabled = _options["vsync"]
	if _options["shadows"] != _applied_options.get("shadows"):
		emit_signal("shadow_setting_changed", _options["shadows"])
	if _options["fov"] != _applied_options.get("fov"):
		emit_signal("fov_setting_changed", _options["fov"])
	if _options["sfx_volume"] != _applied_options.get("sfx_volume"):
		AudioServer.set_bus_volume_db(_sfx_bus, linear2db(_options["sfx_volume"]))
	for action in _options["controls"].keys():
		InputMap.action_erase_events(action)
		for event in _options["controls"][action]:
			InputMap.action_add_event(action, event)

	_applied_options = _options.duplicate(true)
	_save()


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


# When switching to fullscreen resolution settings get overidden. Wait for the resize signal
# from going fullscreen, then set the resolution again.
func _on_viewport_size_changed():
	if OS.window_fullscreen:
		get_viewport().set_size(_options["resolution"])


func _load():
	var options_file = ConfigFile.new()
	_options = DEFAULT_OPTIONS.duplicate(true)
	if options_file.load(OPTIONS_PATH) == OK:
		for option in DEFAULT_OPTIONS.keys():
			if options_file.has_section_key("options", option):
				_options[option] = options_file.get_value("options", option)

	if not _options["resolution"] in RESOLUTION_CHOICES:
		RESOLUTION_CHOICES.append(_options["resolution"])


func _save():
	var options_file = ConfigFile.new()
	for option in _options.keys():
		options_file.set_value("options", option, Options.get(option))
	var err = options_file.save(OPTIONS_PATH)
	assert(err == OK)
