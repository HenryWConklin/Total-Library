tool
extends Resource
class_name BookRegistry

# Map from cell position to MultiMesh for that cell
export(Dictionary) var bookCells
# BigInt object, position of cell (0,0,0)
export(Resource) var centerCell

export(int, 0, 10) var numShelves = 5
export(int, 0, 100) var booksPerShelf = 50
export(float, 0, 10) var shelfSpacing = .4
export(float, 0, 1) var bookSpacing = .005
export(Mesh) var bookMesh: Mesh

func makeDefaultShelf() -> MultiMesh:
	var shelfMesh: MultiMesh = MultiMesh.new()
	shelfMesh.color_format = MultiMesh.COLOR_NONE
	shelfMesh.custom_data_format = MultiMesh.CUSTOM_DATA_FLOAT
	shelfMesh.transform_format = MultiMesh.TRANSFORM_3D
	
	shelfMesh.mesh = bookMesh
	shelfMesh.instance_count = numShelves * booksPerShelf
	
	var bookSize = bookMesh.get_aabb().size
	for i in range(numShelves):
		for j in range(booksPerShelf):
			var ind = i * booksPerShelf + j
			var zoff = ((j - booksPerShelf / 2) * (bookSize.z + bookSpacing) 
						+ (bookSize.z + bookSpacing) / 2)
			var offset = Vector3(
				0.0,
				shelfSpacing * i + bookSize.y / 2,
				zoff)
			var transform = Transform.IDENTITY.translated(offset)
			shelfMesh.set_instance_transform(ind, transform)
			shelfMesh.set_instance_custom_data(ind, Color(0,0,0,0))
	return shelfMesh
	
func defaultShelfAABB() -> AABB:
	var bookSize = bookMesh.get_aabb().size
	var position = Vector3(
			-bookSize.x/2,
			0,
			-(float(booksPerShelf) / 2.0) * (bookSize.z + bookSpacing)
			)
	var size = Vector3(
		bookSize.x,
		 numShelves * shelfSpacing,
		booksPerShelf * (bookSize.z + bookSpacing) 
	)
	return AABB(position, size)
