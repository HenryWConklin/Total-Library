extends Spatial

# Runs parameter_search on a RoomGenParameters object in order to pick a valid set of shuffling
# parameters. See native/src/room_gen_params.cpp

export(String, FILE) var source
export(String, FILE) var dest


func _ready():
	var params = load(source)
	params.parameter_search()
	assert(ResourceSaver.save(dest, params) == OK)
	get_tree().quit()
