extends Spatial


func _ready():
	assert(Options.connect("shadow_setting_changed", self, "_on_shadow_setting_changed") == OK)
	_on_shadow_setting_changed(Options.get("shadows"))


func _on_shadow_setting_changed(val):
	$SpotLight.shadow_enabled = val > 0
