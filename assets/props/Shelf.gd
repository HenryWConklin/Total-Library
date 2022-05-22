class_name Shelf
extends MultiMeshInstance

# A shelf with books on it. Handles updates triggered by BookRegistry.

export(NodePath) var collision_shape: NodePath
export(Resource) var shelf_index setget set_shelf_index


func _ready():
	add_to_group("shelves")
	var shape: CollisionShape = get_node(collision_shape)
	shape.shape = BoxShape.new()
	var aabb = BookRegistry.get_shelf_aabb()
	shape.shape.extents = aabb.size / 2
	shape.translation.y = aabb.size.y / 2
	assert(Options.connect("shadow_setting_changed", self, "_on_shadow_setting_changed") == OK)
	_on_shadow_setting_changed(Options.get("shadows"))


func set_shelf_index(ind: ShelfIndex):
	shelf_index = ind
	regenerate_multimesh()
	var aabb = BookRegistry.get_shelf_aabb()
	set_custom_aabb(aabb)


func regenerate_multimesh():
	set_multimesh(BookRegistry.get_shelf(shelf_index))


func _on_shadow_setting_changed(val):
	# If greater than "Static Only". See scripts/data/Options.gd
	if val > 1:
		self.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_ON
	else:
		self.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
