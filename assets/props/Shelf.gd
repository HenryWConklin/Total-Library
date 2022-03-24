class_name Shelf
extends MultiMeshInstance

export(NodePath) var collision_shape: NodePath
export(Resource) var shelf_index setget set_shelf_index
export(bool) var use_placeholder: bool = false


func _ready():
	add_to_group("shelves")
	var shape: CollisionShape = get_node(collision_shape)
	shape.shape = BoxShape.new()
	var aabb = BookRegistry.get_shelf_aabb()
	shape.shape.extents = aabb.size / 2
	shape.translation.y = aabb.size.y / 2


func set_shelf_index(ind: ShelfIndex):
	shelf_index = ind
	regenerate_multimesh()
	var aabb = BookRegistry.get_shelf_aabb()
	set_custom_aabb(aabb)


func regenerate_multimesh():
	if use_placeholder:
		set_multimesh(BookRegistry.get_placeholder_shelf(shelf_index))
	else:
		set_multimesh(BookRegistry.get_shelf(shelf_index))
