extends GridContainer

signal key_pressed(key)
signal delete_pressed


func _ready():
	for child in self.get_children():
		if child is Button:
			if child.text == "Back":
				child.connect("pressed", self, "_on_delete_pressed", [])
			else:
				child.connect("pressed", self, "_on_key_pressed", [child.text])


func _on_key_pressed(key: String):
	emit_signal("key_pressed", key)


func _on_delete_pressed():
	emit_signal("delete_pressed")
