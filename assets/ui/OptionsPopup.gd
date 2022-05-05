extends ConfirmationDialog

export(NodePath) var display_options_select: NodePath
export(NodePath) var resolution_options_select: NodePath
export(NodePath) var shadows_options_select: NodePath
export(NodePath) var msaa_options_select: NodePath
export(NodePath) var fxaa_enabled: NodePath
export(NodePath) var vsync_enabled: NodePath
export(NodePath) var fov_slider: NodePath
export(NodePath) var look_sensitivity_slider: NodePath
export(Array, NodePath) var input_map_selects: Array
export(NodePath) var cancel_confirm: NodePath

onready var _display_options_select: OptionButton = get_node(display_options_select)
onready var _resolution_options_select: OptionButton = get_node(resolution_options_select)
onready var _shadows_options_select: OptionButton = get_node(shadows_options_select)
onready var _msaa_options_select: OptionButton = get_node(msaa_options_select)
onready var _fxaa_enabled: CheckBox = get_node(fxaa_enabled)
onready var _vsync_enabled: CheckBox = get_node(vsync_enabled)
onready var _fov_slider: HSlider = get_node(fov_slider)
onready var _look_sensitivity_slider: HSlider = get_node(look_sensitivity_slider)


func _ready():
	for item in Options.DISPLAY_CHOICES:
		_display_options_select.add_item(item)
	for item in Options.RESOLUTION_CHOICES:
		_resolution_options_select.add_item("{0}x{1}".format([item.x, item.y]))
	for item in Options.SHADOWS_CHOICES:
		_shadows_options_select.add_item(item)
	for item in Options.MSAA_CHOICES:
		_msaa_options_select.add_item(item)
	assert(get_cancel().connect("pressed", self, "_on_cancel_pressed") == OK)
	get_ok().text = "Apply"


func _reload_options():
	Options.reload()
	_display_options_select.select(Options.get("display"))
	_resolution_options_select.select(Options.RESOLUTION_CHOICES.find(Options.get("resolution")))
	_shadows_options_select.select(Options.get("shadows"))
	_msaa_options_select.select(Options.get("msaa"))
	_fxaa_enabled.pressed = Options.get("fxaa")
	_vsync_enabled.pressed = Options.get("vsync")
	_look_sensitivity_slider.value = Options.get("look_sensitivity")


func _on_OptionsPopup_about_to_show():
	_reload_options()


func _on_OptionsPopup_confirmed():
	Options.apply()


func _on_cancel_pressed():
	if Options.are_modified():
		get_node(cancel_confirm).popup()


func _on_DisplayOptions_item_selected(index):
	Options.set("display", index)


func _on_ResolutionOptions_item_selected(index):
	Options.set("resolution", Options.RESOLUTION_CHOICES[index])


func _on_ShadowsOptions_item_selected(index):
	Options.set("shadows", index)


func _on_MSAAOptions_item_selected(index):
	Options.set("msaa", index)


func _on_FXAAEnabled_toggled(button_pressed):
	Options.set("fxaa", button_pressed)


func _on_VSyncEnabled_toggled(button_pressed):
	Options.set("vsync", button_pressed)


func _on_ResetControls_pressed():
	InputMap.load_from_globals()
	Options.set("controls", {})
	for x in input_map_selects:
		get_node(x).reload_event()


func _on_CancelConfirm_confirmed():
	Options.apply()


func _on_FOVSlider_value_changed(value):
	Options.set("fov", value)


func _on_LookSensitivitySlider_value_changed(value):
	Options.set("look_sensitivity", value)
