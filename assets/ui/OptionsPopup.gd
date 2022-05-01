extends WindowDialog

export(NodePath) var display_options_select: NodePath
export(NodePath) var resolution_options_select: NodePath
export(NodePath) var shadows_options_select: NodePath
export(NodePath) var vsync_enabled: NodePath

onready var _display_options_select: OptionButton = get_node(display_options_select)
onready var _resolution_options_select: OptionButton = get_node(resolution_options_select)
onready var _shadows_options_select: OptionButton = get_node(shadows_options_select)
onready var _vsync_enabled: CheckBox = get_node(vsync_enabled)


func _ready():
	for item in Options.DISPLAY_CHOICES:
		_display_options_select.add_item(item)
	for item in Options.RESOLUTION_CHOICES:
		_resolution_options_select.add_item("{0}x{1}".format([item.x, item.y]))
	for item in Options.SHADOWS_CHOICES:
		_shadows_options_select.add_item(item)


func _reload_options():
	Options.reload()
	_display_options_select.select(Options.get("display"))
	_resolution_options_select.select(Options.RESOLUTION_CHOICES.find(Options.get("resolution")))
	_shadows_options_select.select(Options.get("shadows"))
	_vsync_enabled.pressed = Options.get("vsync")


func _on_DisplayOptions_item_selected(index):
	Options.set("display", index)


func _on_ResolutionOptions_item_selected(index):
	Options.set("resolution", Options.RESOLUTION_CHOICES[index])


func _on_ShadowsOptions_item_selected(index):
	Options.set("shadows", index)


func _on_VSyncEnabled_toggled(button_pressed):
	Options.set("vsync", button_pressed)


func _on_Apply_pressed():
	Options.apply()


func _on_CancelButton_pressed():
	hide()


func _on_OptionsPopup_about_to_show():
	_reload_options()