extends Spatial

export(NodePath) var player_path: NodePath
export(NodePath) var library_room_path: NodePath
export(float, 0, 1) var player_teleport_margin: float = 0.01
export(bool) var lock_player: bool = false

onready var player: Spatial = get_node(player_path)
onready var library: Spatial = get_node(library_room_path)


func _process(_delta):
	if lock_player:
		var player_pos = player.global_transform.origin
		var player_tile_pos = (player_pos / library.tile_size) - library.tile_center_offset
		player_tile_pos = (player_tile_pos * (1 - player_teleport_margin)).round()
		if player_tile_pos != Vector3(0, 0, 0):
			var player_tile = library.world_position_to_tile_index(player_pos)
			player.global_translate((library.center_tile - player_tile) * library.tile_size)
			library.center_tile = player_tile
