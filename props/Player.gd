extends KinematicBody

export(Vector2) var mouse_sensitivity = Vector2(0.002, 0.002);
export(Vector2) var move_speed = Vector2(5, 5)
export(float) var gravity = 10
export(NodePath) var camera_path: NodePath
export(NodePath) var raycast_path: NodePath

var _mouse_move = Vector2(0, 0)
onready var camera: Camera = get_node(camera_path)
onready var raycast: RayCast = get_node(raycast_path)

const SNAP_VECTOR: Vector3 = Vector3(0, -1, 0)
const UP: Vector3 = Vector3(0, 1, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _unhandled_input(event: InputEvent):
	if (event is InputEventMouseMotion 
	and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
		var mouse_motion = event.get_relative()
		_mouse_move += mouse_motion
		get_tree().set_input_as_handled()
	elif event.is_action_pressed("release_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().set_input_as_handled()
	elif (event is InputEventMouseButton 
	and event.is_pressed() 
	and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().set_input_as_handled()

func _handle_movement():
	var rotation = _mouse_move * mouse_sensitivity
	_mouse_move = Vector2(0,0)
	self.rotate_y(-rotation.x)
	camera.rotate_x(-rotation.y)
	camera.rotation = Vector3(
		clamp(camera.rotation.x, -PI/2, PI/2), 
		camera.rotation.y, 
		camera.rotation.z)
	
	var move_vec: Vector2 = Vector2(0, 0)
	if Input.is_action_pressed("move_forward"):
		move_vec -= Vector2(0, 1)
	if Input.is_action_pressed("move_backward"):
		move_vec += Vector2(0, 1)
	if Input.is_action_pressed("move_left"):
		move_vec -= Vector2(1, 0)
	if Input.is_action_pressed("move_right"):
		move_vec += Vector2(1, 0)
	
	move_vec = move_vec.normalized() * move_speed
	move_vec = move_vec.rotated(-self.rotation.y)
	
	if self.is_on_floor():
		self.move_and_slide_with_snap(
			Vector3(move_vec.x, 0, move_vec.y), 
			SNAP_VECTOR,	# snap
			UP,   			# up_direction
			true)			# stop_on_slope
	else:
		self.move_and_slide(
			Vector3(move_vec.x, -gravity, move_vec.y), 
			UP, 		# up_direction
			true)		# stop_on_slope

func _physics_process(_delta):
	_handle_movement()
