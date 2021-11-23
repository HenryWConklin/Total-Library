tool
extends Spatial

onready var display_node = $MeshInstance
onready var viewport_node = $Viewport
onready var camera_node = $Viewport/Camera

# Tips:
# If the drawing is fading to white, turn on the force sRGB flag in the material


# Position offset from the portal plane itself to other end of the "portal"
export(Vector3) var render_offset: Vector3 = Vector3(0,0,0)

export(Vector2) var portal_size: Vector2 = Vector2(2,2) setget set_portal_size

export(float, 0.0, 1000) var viewport_pixels_per_unit: float = 100 setget set_viewport_ppu

func _ready():
	update_portal_size()

func update_portal_size():
	if self.viewport_node != null:
		self.viewport_node.size = portal_size * viewport_pixels_per_unit
	if self.display_node != null:
		self.display_node.scale = Vector3(portal_size.x, portal_size.y, 1)
		
func set_portal_size(size: Vector2):
	portal_size = size
	update_portal_size()
	
func set_viewport_ppu(ppu):
	viewport_pixels_per_unit = ppu
	update_portal_size()

func _process(_delta):
	if not Engine.editor_hint:
		var local_pos = to_local(get_viewport().get_camera().global_transform.origin)
		self.camera_node.frustum_offset = Vector2(-local_pos.x, -local_pos.y)
		self.camera_node.near = local_pos.z
		self.camera_node.size = portal_size.y
		# Because camera is a child of the viewport, it doesn't inherit the transform from this node
		self.camera_node.transform = self.transform.translated(local_pos + render_offset)
