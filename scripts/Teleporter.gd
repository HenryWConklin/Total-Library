extends Area

# Area that teleports the player back by an offset when entered. Also sends an offset to
# BookRegistry to update shelves to match.

export(Vector3) var offset: Vector3 = Vector3.ZERO
export(Vector3) var room_offset: Vector3 = Vector3.ZERO


func _ready():
	assert(connect("body_entered", self, "_teleport") == OK)


func _teleport(body: Spatial):
	body.teleport(offset)
	BookRegistry.add_room_offset(room_offset)
