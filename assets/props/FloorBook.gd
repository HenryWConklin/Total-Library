extends RigidBody

# A book that has been dropped by the player.

export(float, 0, 100) var impact_sound_min_energy: float = 0
export(float, 0, 10) var impact_sound_scale: float = 1
export(float, -60, 0) var max_db: float = 0

var book_index: BookIndex
var title: Color

var _last_linear_vel: Vector3
var _last_angular_vel: Vector3


func _ready():
	var material = $MeshInstance.get_active_material(0).duplicate()
	material.set_shader_param("title1", int(title.r))
	material.set_shader_param("title2", int(title.g))
	material.set_shader_param("title3", int(title.b))
	material.set_shader_param("title4", int(title.a))
	material.set_shader_param("use_packed_title", true)
	$MeshInstance.set_surface_material(0, material)
	var err = Options.connect("shadow_setting_changed", self, "_on_shadow_setting_changed")
	assert(err == OK)
	_on_shadow_setting_changed(Options.get("shadows"))


func _physics_process(_delta):
	var linear_vel_diff = linear_velocity - _last_linear_vel
	var angular_vel_diff = angular_velocity - _last_angular_vel

	var mag = linear_vel_diff.length_squared() + angular_vel_diff.length_squared() * .25
	_last_linear_vel = linear_velocity
	_last_angular_vel = angular_velocity

	if mag > impact_sound_min_energy:
		$Impact.unit_db = clamp((mag * impact_sound_scale) - 60, -60, max_db)
		$Impact.play()


func _on_RoomTracker_room_changed(area):
	var room = area.get_parent()
	var floor_book_parent = room.floor_books
	if not floor_book_parent.is_a_parent_of(self):
		self.call_deferred("_switch_parent", floor_book_parent)


func _switch_parent(new_parent):
	var transform = self.global_transform
	self.get_parent().remove_child(self)
	new_parent.add_child(self)
	self.global_transform = transform


func _on_shadow_setting_changed(val):
	if val > 1:
		$MeshInstance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_ON
	else:
		$MeshInstance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
