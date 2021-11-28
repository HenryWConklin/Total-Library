extends MultiMeshInstance

export(bool) var regenerate = false setget set_regenerate
export(NodePath) var collisionShape : NodePath

func _ready():
	regenerate_multimesh()

func set_regenerate(val):
	if val:
		regenerate_multimesh()
	regenerate = val

func regenerate_multimesh():
	multimesh = BookRegistry.makeDefaultShelf()
	var aabb : AABB = BookRegistry.defaultShelfAABB()
	set_custom_aabb(aabb)
	var shape : CollisionShape = get_node(collisionShape)
	shape.shape = BoxShape.new()
	shape.shape.extents = aabb.size / 2
	shape.translation.y = aabb.size.y / 2
