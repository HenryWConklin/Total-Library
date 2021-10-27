extends Spatial

onready var display_node = $MeshInstance
onready var viewport_node = $Viewport
onready var camera_node = $Viewport/Camera

# Tips:
# If the drawing is fading to white, turn on the force sRGB flag in the material

# Path to the main camera, or other object to track the portal's rendering to
export(NodePath) var main_camera: NodePath

# Position offset from the portal plane itself to other end of the "portal"
export(Vector3) var render_offset: Vector3 = Vector3(0,0,0)

export(Vector2) var portal_size: Vector2 = Vector2(2,2) setget set_portal_size, get_portal_size 

export(float, 0.0, 1000) var viewport_pixels_per_unit: float = 100 setget set_viewport_ppu

func _ready():
	set_portal_size(portal_size)

func set_portal_size(size: Vector2):
	if self.viewport_node != null:
		self.viewport_node.size = size * viewport_pixels_per_unit
		self.display_node.scale = Vector3(size.x, size.y, 1)
	portal_size = size
	
func get_portal_size():
	return Vector2(display_node.scale.x, display_node.scale.y)

func set_viewport_ppu(ppu):
	self.viewport_node.size = get_portal_size() * ppu
	viewport_pixels_per_unit = ppu

func _process(_delta):
	if not Engine.editor_hint:
		var local_pos = to_local(get_node(main_camera).global_transform.origin)
		local_pos.y += 1.2
		self.camera_node.frustum_offset = Vector2(-local_pos.x, -local_pos.y)
		self.camera_node.near = local_pos.z
		self.camera_node.size = get_portal_size().y
		# Because camera is a child of the viewport, it doesn't inherit the transform from this node
		self.camera_node.transform = self.transform.translated(local_pos + render_offset)
