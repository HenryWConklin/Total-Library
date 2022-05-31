extends Camera


func _ready():
	var err = Options.connect("fov_setting_changed", self, "_on_fov_changed")
	assert(err == OK)


func _on_fov_changed(val):
	self.fov = val
