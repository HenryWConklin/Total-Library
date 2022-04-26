extends Spatial


func _on_RoomTracker_room_changed(area):
	BookRegistry.set_player_position(area.room_index)
