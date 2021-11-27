tool
extends MultiMeshInstance

export(Resource) var bookRegistry
export(bool) var regenerate = false setget set_regenerate

func set_regenerate(val):
	if val:
		multimesh = bookRegistry.makeDefaultShelf()
		set_custom_aabb(bookRegistry.defaultShelfAABB())
		
	regenerate = val
