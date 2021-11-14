extends Spatial
export(bool) var rebake = false
export(String) var export_path : String = "res://rooms/hex_library_tile.lmbake"
export(int) var lightmap_index = 4
func _ready():
	if rebake:
		$BakedLightmap.bake($HexTiledLibrary, "res://util/lightmap.lmbake")
	var data = ResourceLoader.load("res://util/lightmap.lmbake", "BakedLightmapData")
	var new_data = BakedLightmapData.new()
	new_data.bounds = data.bounds
	new_data.cell_space_transform = data.cell_space_transform
	new_data.energy = data.energy
	new_data.interior = true
	new_data.octree = data.octree
	
	var lightmap = data.get_user_lightmap(lightmap_index)
	var uv_rect = Rect2(Vector2(0,0), Vector2(1, 1))
	new_data.add_user(@"../Room", lightmap, -1, uv_rect, -1)
	assert(ResourceSaver.save(export_path, new_data) == OK)
	
	get_tree().quit()
