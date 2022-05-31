extends Spatial

# Shared light scene, listens for shadow settings to disable shadows.


func _ready():
	var err = Options.connect("shadow_setting_changed", self, "_on_shadow_setting_changed")
	assert(err == OK)
	_on_shadow_setting_changed(Options.get("shadows"))


func _on_shadow_setting_changed(val):
	# Enabled if greater than "Off". See scripts/data/Options.gd
	$SpotLight.shadow_enabled = val > 0
