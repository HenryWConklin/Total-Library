extends RigidBody

var book_index: BookIndex
var title: Color


func _ready():
	var material = $MeshInstance.get_active_material(0)
	material.set_shader_param("packed_title1", int(title.r))
	material.set_shader_param("packed_title2", int(title.g))
	material.set_shader_param("packed_title3", int(title.b))
	material.set_shader_param("packed_title4", int(title.a))
	material.set_shader_param("use_packed_title", true)
