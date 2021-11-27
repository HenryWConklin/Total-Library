extends RoomManager

export(bool) var auto_enable = true

func _ready():
	if auto_enable:
		self.rooms_convert()
