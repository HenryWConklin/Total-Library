extends VisibilityNotifier

export(Array, NodePath) var nodes_to_hide: Array = []


func _ready():
	assert(connect("screen_entered", self, "_on_screen_entered") == OK)
	assert(connect("screen_exited", self, "_on_screen_exited") == OK)


func _on_screen_entered():
	for n in nodes_to_hide:
		get_node(n).visible = true


func _on_screen_exited():
	for n in nodes_to_hide:
		get_node(n).visible = false
