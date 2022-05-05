extends Camera


func _ready():
	Options.connect("fov_setting_changed", self, "_on_fov_changed")


func _on_fov_changed(val):
	self.fov = val
