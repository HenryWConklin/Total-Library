extends Area

signal targeted_position(local_pos)
signal is_targeted(targeted)


func set_targeted_position(global_pos: Vector3):
	var local_pos = self.global_transform.xform_inv(global_pos)
	emit_signal("targeted_position", Vector2(local_pos.x, local_pos.y))


func set_targeted(targeted: bool):
	emit_signal("is_targeted", targeted)
