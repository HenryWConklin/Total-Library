extends RigidBody

var book_index: BookIndex
var title: Color


func _ready():
	var material = $MeshInstance.get_active_material(0).duplicate()
	material.set_shader_param("packed_title1", int(title.r))
	material.set_shader_param("packed_title2", int(title.g))
	material.set_shader_param("packed_title3", int(title.b))
	material.set_shader_param("packed_title4", int(title.a))
	material.set_shader_param("use_packed_title", true)
	$MeshInstance.set_surface_material(0, material)


func _on_RoomTracker_room_changed():
	var room = $RoomTracker.current_room_area.get_parent()
	var floor_book_parent = room.floor_books
	if not floor_book_parent.is_a_parent_of(self):
		self.call_deferred("_switch_parent", floor_book_parent)


func _switch_parent(new_parent):
	print(get_parent().room_index.to_key(), " -> ", new_parent.room_index.to_key())
	var transform = self.global_transform
	self.get_parent().remove_child(self)
	new_parent.add_child(self)
	self.global_transform = transform
