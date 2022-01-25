extends Node

const params = preload("res://data/room_gen_params.tres")
var book_util: BookUtil = BookUtil.new()
var total_shelf_time = 0

func _init():
	var start_time = OS.get_ticks_usec()
	book_util.room_gen_params = params
	print("Precompute time: ", OS.get_ticks_usec() - start_time)
	start_time = OS.get_ticks_usec()
	book_util.randomize_origin(123)
	print("Randomize time: ", OS.get_ticks_usec() - start_time)


func makeDefaultShelf() -> MultiMesh:
	var start_time = OS.get_ticks_usec()
	var res : MultiMesh = book_util.make_shelf_multimesh(1000000,0,0,0)
	total_shelf_time += OS.get_ticks_usec() - start_time
	return res

func _process(_delta):
	if total_shelf_time > 0:
		print("Total shelf time: ", total_shelf_time)
		total_shelf_time = 0
	
func defaultShelfAABB() -> AABB:
	var bookSize = params.book_mesh.get_aabb().size
	var position = Vector3(
			-bookSize.x/2,
			0,
			-(float(params.books_per_shelf) / 2.0) * (bookSize.z + params.book_spacing)
			)
	var size = Vector3(
		bookSize.x,
		(params.num_shelves) * params.shelf_spacing - (params.shelf_spacing - bookSize.y),
		params.books_per_shelf * (bookSize.z + params.book_spacing) 
	)
	return AABB(position, size)
