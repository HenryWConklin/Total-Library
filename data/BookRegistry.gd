extends Node

const params = preload("res://data/book_registry_params.tres")

func makeDefaultShelf() -> MultiMesh:
	var shelfMesh: MultiMesh = MultiMesh.new()
	shelfMesh.color_format = MultiMesh.COLOR_NONE
	shelfMesh.custom_data_format = MultiMesh.CUSTOM_DATA_FLOAT
	shelfMesh.transform_format = MultiMesh.TRANSFORM_3D
	
	shelfMesh.mesh = params.bookMesh
	shelfMesh.instance_count = params.numShelves * params.booksPerShelf
	
	var bookSize = params.bookMesh.get_aabb().size
	for i in range(params.numShelves):
		for j in range(params.booksPerShelf):
			var ind = i * params.booksPerShelf + j
			var zoff = ((j - params.booksPerShelf / 2) * (bookSize.z + params.bookSpacing) 
						+ (bookSize.z + params.bookSpacing) / 2)
			var offset = Vector3(
				0.0,
				params.shelfSpacing * i + bookSize.y / 2,
				zoff)
			var transform = Transform.IDENTITY.translated(offset)
			shelfMesh.set_instance_transform(ind, transform)
			shelfMesh.set_instance_custom_data(ind, Color(0,0,0,0))
	return shelfMesh
	
func defaultShelfAABB() -> AABB:
	var bookSize = params.bookMesh.get_aabb().size
	var position = Vector3(
			-bookSize.x/2,
			0,
			-(float(params.booksPerShelf) / 2.0) * (bookSize.z + params.bookSpacing)
			)
	var size = Vector3(
		bookSize.x,
		(params.numShelves) * params.shelfSpacing - (params.shelfSpacing - bookSize.y),
		params.booksPerShelf * (bookSize.z + params.bookSpacing) 
	)
	return AABB(position, size)
