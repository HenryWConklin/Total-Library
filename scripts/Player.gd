extends KinematicBody

# Handles input, player movement.

signal pause_requested
signal last_input_method_changed(method)
signal book_targeted(targeted)
signal book_held(held)
signal index_screen_targeted(targeted)

const HeldBook = preload("res://assets/props/HeldBook.gd")

const SNAP_VECTOR: Vector3 = Vector3(0, -1, 0)
const UP: Vector3 = Vector3(0, 1, 0)

export(Vector2) var mouse_sensitivity = Vector2(0.002, 0.002)
export(Vector2) var controller_sensitivity = Vector2(0.002, 0.002)
export(Vector2) var move_speed = Vector2(5, 5)
export(Vector3) var camera_position_standing = Vector3(0, 1.4, -0.4)
export(Vector3) var camera_position_crouching = Vector3(0, 0.4, -0.4)
export(float) var gravity = 10.0
export(NodePath) var camera_path: NodePath
export(NodePath) var raycast_path: NodePath
export(NodePath) var held_book_path: NodePath
export(NodePath) var selection_highlight_path: NodePath

var _mouse_move = Vector2(0, 0)
var _last_raycast_colliding_book = false
var _last_input_type: int = InputUtil.InputType.KEYBOARD
var _raycast_collider = null
var _raycast_collision_point: Vector3 = Vector3()
var _last_screen_colliding = null

onready var camera: Camera = get_node(camera_path)
onready var raycast: RayCast = get_node(raycast_path)
onready var held_book: HeldBook = get_node(held_book_path)
onready var selection_highlight: MeshInstance = get_node(selection_highlight_path)


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if BookRegistry.held_book != null:
		var book_text = BookRegistry.get_book_text(BookRegistry.held_book)
		held_book.open_to_page(book_text, BookRegistry.held_book_page)
		emit_signal("book_held", true)


func teleport(offset: Vector3):
	global_translate(offset)
	held_book.teleport(offset)


func get_raycast_shelf_book_ind() -> BookIndex:
	var picked_shelf = _raycast_collider.get_node(_raycast_collider.shelf_path)
	var picked_point_global = _raycast_collision_point
	var picked_point_local = _raycast_collider.to_local(picked_point_global)
	var shelf_ind = picked_shelf.shelf_index
	var pos_book_ind = BookRegistry.get_book_index_at_point(shelf_ind, picked_point_local)
	return pos_book_ind


func pick_up_shelf_book() -> bool:
	var pos_book_ind = get_raycast_shelf_book_ind()
	if pos_book_ind == null:
		return false
	var actual_book_ind = BookRegistry.remove_book_at(pos_book_ind)
	if actual_book_ind == null:
		return false
	var book_text = BookRegistry.get_book_text(actual_book_ind)

	var book_transform_local = BookRegistry.get_book_transform(pos_book_ind.book)

	held_book.pull_from_shelf(
		book_text, book_transform_local, _raycast_collider.global_transform
	)
	BookRegistry.held_book = actual_book_ind
	BookRegistry.held_book_page = held_book.get_page()
	return true


func place_book_on_shelf() -> bool:
	var pos_book_ind = get_raycast_shelf_book_ind()
	if pos_book_ind == null:
		return false
	var actual_book_ind = BookRegistry.get_book_at(pos_book_ind)
	if actual_book_ind != null:
		return false
	var book_transform_local = BookRegistry.get_book_transform(pos_book_ind.book)
	BookRegistry.held_book = null
	held_book.place_on_shelf(
		pos_book_ind, book_transform_local, _raycast_collider.global_transform
	)
	return true


func pick_up_floor_book():
	var book = _raycast_collider
	BookRegistry.held_book = book.book_index
	BookRegistry.held_book_page = held_book.get_page()
	held_book.pick_up_floor_book(book)
	return true


func _unhandled_input(event: InputEvent):
	if event is InputEventMouse or event is InputEventKey:
		_input_type(InputUtil.InputType.KEYBOARD)
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_input_type(InputUtil.InputType.CONTROLLER)

	# Mouse capture/uncapture
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_motion = event.get_relative()
		_mouse_move += mouse_motion * mouse_sensitivity
		get_tree().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		emit_signal("pause_requested")
		get_tree().set_input_as_handled()
		return
	if (
		event is InputEventMouseButton
		and event.is_pressed()
		and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED
	):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().set_input_as_handled()
		return

	_handle_pickup_input(event)

	if event.is_action_pressed("turn_page_forward") and held_book.can_turn_page():
		held_book.page_forward()
		BookRegistry.held_book_page = held_book.get_page()
		get_tree().set_input_as_handled()
		return
	if event.is_action_pressed("turn_page_back") and held_book.can_turn_page():
		held_book.page_back()
		BookRegistry.held_book_page = held_book.get_page()
		get_tree().set_input_as_handled()
		return


func _handle_pickup_input(event):
	if _raycast_collider == null:
		return
	# Book pickup
	if (
		event.is_action_pressed("pick_up")
		and _raycast_collider.is_in_group("bookshelf_raycast")
		and held_book.can_pick_up_book()
	):
		if pick_up_shelf_book():
			emit_signal("book_held", true)
			get_tree().set_input_as_handled()
			return
	if (
		event.is_action_pressed("pick_up")
		and _raycast_collider.is_in_group("bookshelf_raycast")
		and held_book.can_place_book()
	):
		if place_book_on_shelf():
			emit_signal("book_held", false)
			get_tree().set_input_as_handled()
			return
	if (
		event.is_action_pressed("pick_up")
		and _raycast_collider.is_in_group("floor_book_raycast")
		and held_book.can_pick_up_book()
	):
		if pick_up_floor_book():
			emit_signal("book_held", true)
			get_tree().set_input_as_handled()
			return
	if event.is_action_pressed("pick_up") and held_book.can_drop_book():
		held_book.drop_book()
		BookRegistry.held_book = null
		emit_signal("book_held", false)
		get_tree().set_input_as_handled()
		return


func _handle_movement(delta):
	var controller_look = (
		Input.get_vector("look_left", "look_right", "look_up", "look_down")
		* controller_sensitivity
	)
	var rotation = (_mouse_move + controller_look) * Options.get("look_sensitivity") * delta
	_mouse_move = Vector2(0, 0)
	self.rotate_y(-rotation.x)
	camera.rotate_x(-rotation.y)
	camera.rotation = Vector3(
		clamp(camera.rotation.x, -PI / 2, PI / 2), camera.rotation.y, camera.rotation.z
	)

	var move_vec: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)

	move_vec = move_vec.normalized() * move_speed
	move_vec = move_vec.rotated(-self.rotation.y)

	if self.is_on_floor():
		var _move_result = self.move_and_slide_with_snap(
			Vector3(move_vec.x, 0, move_vec.y), SNAP_VECTOR, UP, true
		)
		if Input.is_action_pressed("crouch"):
			camera.translation = camera_position_crouching
		else:
			camera.translation = camera_position_standing
	else:
		var _move_result = self.move_and_slide(Vector3(move_vec.x, -gravity, move_vec.y), UP, true)
		camera.translation = camera_position_standing


func _selection_highlight():
	var collider = _raycast_collider
	if collider == null:
		selection_highlight.hide()
		_raycast_colliding_book(false)
		return
	if collider.is_in_group("bookshelf_raycast"):
		var book_ind = get_raycast_shelf_book_ind()
		if book_ind != null:
			var book_transform_local = BookRegistry.get_book_transform(book_ind.book)
			var book_transform_global = (
				collider.global_transform
				* book_transform_local
			)
			selection_highlight.show()
			selection_highlight.global_transform = book_transform_global
			_raycast_colliding_book(true)
			return
	elif collider.is_in_group("floor_book_raycast"):
		selection_highlight.show()
		selection_highlight.global_transform = collider.global_transform
		_raycast_colliding_book(true)
		return
	selection_highlight.hide()
	_raycast_colliding_book(false)

func _process(_delta):
	# Some kind of race condition on picking up a floor book, raycast.get_collider() can go null
	# in the middle of _process
	_raycast_collider = raycast.get_collider()
	_raycast_collision_point = raycast.get_collision_point()

	_selection_highlight()

	if _last_screen_colliding != null and _raycast_collider != _last_screen_colliding:
		_last_screen_colliding.set_targeted(false)
		_last_screen_colliding = null
		emit_signal("index_screen_targeted", false)
	if _raycast_collider != null and _raycast_collider.is_in_group("index_screen_raycast"):
		_last_screen_colliding = _raycast_collider
		_last_screen_colliding.set_targeted(true)
		_last_screen_colliding.set_targeted_position(raycast.get_collision_point())
		emit_signal("index_screen_targeted", true)

func _physics_process(delta):
	_handle_movement(delta)

func _raycast_colliding_book(val: bool):
	if val != _last_raycast_colliding_book:
		emit_signal("book_targeted", val)
	_last_raycast_colliding_book = val

func _input_type(val: int):
	if val != _last_input_type:
		emit_signal("last_input_method_changed", val)
	_last_input_type = val


func _on_RoomTracker_room_changed(area):
	BookRegistry.set_player_position(area.room_index)
	get_tree().call_group("player_trackers", "set_player_position", area.room_index)
