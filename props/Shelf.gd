extends MultiMeshInstance
class_name Shelf

export(NodePath) var collision_shape : NodePath
export(Resource) var shelf_index

func _ready():
	regenerate_multimesh()

func regenerate_multimesh():
	multimesh = BookRegistry.make_default_shelf()
	var shape : CollisionShape = get_node(collision_shape)
	shape.shape = BoxShape.new()
	var  aabb = multimesh.get_AABB()
	shape.shape.extents = aabb.size / 2
	shape.translation.y = aabb.size.y / 2

