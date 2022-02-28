extends KinematicBody

const HeldBook = preload("res://assets/props/HeldBook.gd")

const SNAP_VECTOR: Vector3 = Vector3(0, -1, 0)
const UP: Vector3 = Vector3(0, 1, 0)

export(Vector2) var mouse_sensitivity = Vector2(0.002, 0.002)
export(Vector2) var move_speed = Vector2(5, 5)
export(float) var gravity = 10
export(NodePath) var camera_path: NodePath
export(NodePath) var raycast_path: NodePath
export(NodePath) var held_book_path: NodePath

var _mouse_move = Vector2(0, 0)

onready var camera: Camera = get_node(camera_path)
onready var raycast: RayCast = get_node(raycast_path)
onready var held_book: HeldBook = get_node(held_book_path)


func _unhandled_input(event: InputEvent):
	# Mouse capture/uncapture
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_motion = event.get_relative()
		_mouse_move += mouse_motion
		get_tree().set_input_as_handled()
	elif event.is_action_pressed("release_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().set_input_as_handled()
	elif (
		event is InputEventMouseButton
		and event.is_pressed()
		and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED
	):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().set_input_as_handled()

	# Book pickup
	if (
		event.is_action_pressed("pick_up")
		and raycast.is_colliding()
		and raycast.get_collider() is Area
		and held_book.can_pick_up_book()
	):
		var picked_shelf_collision = raycast.get_collider()
		var picked_shelf = picked_shelf_collision.get_node(picked_shelf_collision.shelf_path)
		var picked_point_global = raycast.get_collision_point()
		var picked_point_local = picked_shelf_collision.to_local(picked_point_global)
		var shelf_ind = picked_shelf.shelf_index
		var book_text = BookRegistry.get_book_text_at_point(shelf_ind, picked_point_local)
		if book_text == null:
			return

		# Should probably move this into BookRegistry
		var book_transform_local = picked_shelf.multimesh.get_instance_transform(book_text.book)
		book_transform_local.basis = Basis.IDENTITY

		held_book.pull_from_shelf(
			book_text, book_transform_local, picked_shelf_collision.global_transform
		)
		get_tree().set_input_as_handled()
	elif event.is_action_pressed("pick_up") and held_book.can_drop_book():
		held_book.drop_book()


func _handle_movement():
	var rotation = _mouse_move * mouse_sensitivity
	_mouse_move = Vector2(0, 0)
	self.rotate_y(-rotation.x)
	camera.rotate_x(-rotation.y)
	camera.rotation = Vector3(
		clamp(camera.rotation.x, -PI / 2, PI / 2), camera.rotation.y, camera.rotation.z
	)

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
		var _move_result = self.move_and_slide_with_snap(
			Vector3(move_vec.x, 0, move_vec.y), SNAP_VECTOR, UP, true
		)
	else:
		var _move_result = self.move_and_slide(Vector3(move_vec.x, -gravity, move_vec.y), UP, true)


func _physics_process(_delta):
	_handle_movement()