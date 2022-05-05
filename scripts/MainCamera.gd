extends Camera


func _ready():
	assert(Options.connect("fov_setting_changed", self, "_on_fov_changed") == OK)


func _on_fov_changed(val):
	self.fov = val
