tool
extends EditorScenePostImport

var ShelfMaterial: Material = preload("res://materials/Shelf.material")
var TileMaterial: Material = preload("res://materials/TileFloor.material")

var fixed_shelf = false
var shelf_mesh = null

func post_import(scene):
	fixed_shelf = false
	process(scene)
	return scene

func process(node: Node):
	if node == null:
		return
	node.name = node.name
	if node is MeshInstance:
		if 'Shelf' in node.name:
			if not fixed_shelf:
				fix_mesh(node.mesh, ShelfMaterial)
				shelf_mesh = node.mesh
				fixed_shelf = true
			else:
				node.mesh = shelf_mesh
		if 'Floor' in node.name:
			fix_mesh(node.mesh, TileMaterial)
	for child in node.get_children():
		process(child)
		
func fix_mesh(mesh: ArrayMesh, material: Material):
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	for i in range(mdt.get_vertex_count()):
		mdt.set_vertex_uv(i, mdt.get_vertex_uv2(i))
	mdt.set_material(material)
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
