extends Area

export(Vector3) var offset: Vector3 = Vector3.ZERO

func _ready():
	assert(connect("body_entered", self, "_teleport") == OK)
	
func _teleport(body: Spatial):
	body.global_translate(offset)
	print("Teleport", offset)
