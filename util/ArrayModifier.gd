tool
extends Spatial
class_name ArrayModifier

export(PackedScene) var scene: PackedScene setget set_scene
export(Transform) var offset: Transform = Transform.IDENTITY setget set_offset
export(int, 1, 10) var count: int = 1 setget set_count
export(bool) var symmetric: bool = false setget set_symmetric
export(bool) var skip_first: bool = false setget set_skip_first

func _ready():
	_update_array()

func set_scene(p_scene: PackedScene):
	scene = p_scene
	for c in get_children():
		c.queue_free()
	_update_array()
	
func set_offset(p_offset: Transform):
	offset = p_offset
	_update_array()

func set_count(p_count: int):
	assert(p_count > 0)
	count = p_count
	_update_array()

func set_symmetric(p_symmetric: bool):
	symmetric = p_symmetric
	_update_array()
	
func set_skip_first(p_skip_first: bool):
	skip_first = p_skip_first
	_update_array()

func _update_array():
	if not Engine.editor_hint or scene == null:
		return
	var needed_count = count
	if symmetric:
		needed_count = (needed_count - 1) * 2 + 1
	if skip_first:
		needed_count -= 1
		
	while get_child_count() < needed_count:
		var instance = scene.instance()
		add_child(instance)
		instance.set_owner(self)
	var _children = get_children()
	while len(_children) > needed_count:
		_children.pop_back().queue_free()
	
	var ind_offset = 0
	if not skip_first:
		ind_offset = 1
		_children[0].transform = Transform.IDENTITY
	var child_transform: Transform = Transform.IDENTITY
	for i in range(count - 1):
		var child = _children[i + ind_offset]
		child_transform = child_transform * offset
		child.transform = child_transform

	if symmetric:
		child_transform = Transform.IDENTITY
		var inv_offset = offset.affine_inverse()
		for i in range(count - 1):
			var child = _children[i + (count - 1) + ind_offset]
			child_transform = child_transform * inv_offset
			child.transform = child_transform
