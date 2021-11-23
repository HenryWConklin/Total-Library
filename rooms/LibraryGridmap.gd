tool
extends GridMap

# When set to true, regenerates rooms from the gridmap
export(bool) var regen = false setget set_regen
export(PackedScene) var lightScene: PackedScene
export(int) var galleryIndex: int = 0
export(Array, PackedScene) var itemScenes = []
export(String, FILE) var exportPath = "res://rooms/genLibraryRooms.tscn"

var _rooms: Dictionary
var _exportRoot: Node

func set_regen(p_regen):
	regen = p_regen
	if regen and Engine.editor_hint:
		for c in get_children():
			self.remove_child(c)
			c.queue_free()
		_add_rooms()
		_add_portals()
		_add_lights()
		_add_room_scenes()
		_export_rooms()

func _add_rooms():
	var roomParent = Spatial.new()
	roomParent.name = "Rooms"
	add_child(roomParent)
	_exportRoot = roomParent
	_rooms = Dictionary()
	for pos in self.get_used_cells():
		var worldPos = self.map_to_world(pos.x, pos.y, pos.z)
		var room = Room.new()
		roomParent.add_child(room)
		room.owner = _exportRoot
		room.translation = worldPos
		room.points = _make_room_bounds(4)
		_rooms[pos] = room
	
func _make_room_bounds(radius: float) -> PoolVector3Array:
	var points = []
	for y in [-.1, 4.7]:
		for p in range(6):
			var angle = p * PI/3 + PI/6
			points.append(Vector3(radius*cos(angle), y, radius*sin(angle)))
	return PoolVector3Array(points)

func _add_room_scenes():
	for pos in self.get_used_cells():
		var scene: Spatial = itemScenes[get_cell_item(pos.x, pos.y, pos.z)].instance()
		_rooms[pos].add_child(scene)
		scene.owner = _exportRoot

func _add_lights():
	var cellMap = Dictionary()
	for pos in self.get_used_cells():
		var worldPos = self.map_to_world(pos.x, pos.y, pos.z)
		if self.get_cell_item(pos.x, pos.y, pos.z) == galleryIndex:
			if not cellMap.has(worldPos):
				cellMap[worldPos] = pos
			cellMap[worldPos + 2.4 * Vector3.UP] = pos
			cellMap[worldPos + 4.8 * Vector3.UP] = pos
	for pos in cellMap.keys():
		var light: Spatial = lightScene.instance()
		_rooms[cellMap[pos]].add_child(light)
		light.global_transform = self.transform.translated(pos)
		light.owner = _exportRoot
		
func _add_portals():
	var room_door_points = [
		Vector2(-2, 0), 
		Vector2(-2, 2.3), 
		Vector2(2, 2.3), 
		Vector2(2, 0)
	]
	var pool_room_door_points = PoolVector2Array(room_door_points)
	var room_hole_points = []
	for i in range(6):
		var ang = PI/3 * i + PI/6
		room_hole_points.append(Vector2(1.5*cos(ang), 1.5*sin(ang)))
	var pool_room_hole_points = PoolVector2Array(room_hole_points)
	for pos in self.get_used_cells():
		if self.get_cell_item(pos.x+2, pos.y, pos.z) != INVALID_CELL_ITEM:
			var portal = _make_portal(pool_room_door_points, _rooms[pos])
			portal.rotation.y = -PI/2
			portal.translation.x = 2*sqrt(3)
			portal.linked_room = portal.get_path_to(_rooms[Vector3(pos.x+2, pos.y, pos.z)])
		if self.get_cell_item(pos.x+1, pos.y, pos.z-3) != INVALID_CELL_ITEM:
			var portal = _make_portal(pool_room_door_points, _rooms[pos])
			portal.rotation.y = -PI/6
			portal.translation = Vector3(sqrt(3), 2.4, -3)
			portal.linked_room = portal.get_path_to(_rooms[Vector3(pos.x+1, pos.y, pos.z-3)])
		if self.get_cell_item(pos.x, pos.y+1, pos.z) != INVALID_CELL_ITEM:
			var portal = _make_portal(pool_room_hole_points, _rooms[pos])
			portal.rotation.x = PI/2
			portal.translation = Vector3(0, 4.7, 0)
			portal.linked_room = portal.get_path_to(_rooms[Vector3(pos.x, pos.y+1, pos.z)])

func _make_portal(points: PoolVector2Array, parent: Spatial) -> Portal:
	var portal = Portal.new()
	portal.points = points
	parent.add_child(portal)
	portal.owner = _exportRoot
	return portal

func _export_rooms():
	var exportedScene = PackedScene.new()
	exportedScene.pack(_exportRoot)
	assert(ResourceSaver.save(exportPath, exportedScene) == OK)

