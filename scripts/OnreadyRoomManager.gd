extends RoomManager

export(bool) var auto_enable = true


func _ready():
	if auto_enable:
		var err = get_node(roomlist).connect("ready", self, "rooms_convert")
		assert(err == OK)


func _on_roomlist_ready():
	rooms_convert()
