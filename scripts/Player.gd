extends KinematicBody

# Handles input, player movement.

signal pause_requested
signal last_input_method_changed(method)
signal book_targeted(targeted)
signal book_held(held)

const HeldBook = preload("res://assets/props/HeldBook.gd")

const SNAP_VECTOR: Vector3 = Vector3(0, -1, 0)
const UP: Vector3 = Vector3(0, 1, 0)

export(Vector2) var mouse_sensitivity = Vector2(0.002, 0.002)
export(Vector2) var controller_sensitivity = Vector2(0.002, 0.002)
export(Vector2) var move_speed = Vector2(5, 5)
export(float) var gravity = 10
export(NodePath) var camera_path: NodePath
export(NodePath) var raycast_path: NodePath
export(NodePath) var held_book_path: NodePath
export(NodePath) var selection_highlight_path: NodePath

var _mouse_move = Vector2(0, 0)
var _last_raycast_colliding = false
var _last_input_type: int = InputUtil.InputType.KEYBOARD

onready var camera: Camera = get_node(camera_path)
onready var raycast: RayCast = get_node(raycast_path)
onready var held_book: HeldBook = get_node(held_book_path)
onready var selection_highlight: MeshInstance = get_node(selection_highlight_path)


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func teleport(offset: Vector3):
	global_translate(offset)
	held_book.teleport(offset)


func get_raycast_shelf_book_ind() -> BookIndex:
	var picked_shelf_collision = raycast.get_collider()
	var picked_shelf = picked_shelf_collision.get_node(picked_shelf_collision.shelf_path)
	var picked_point_global = raycast.get_collision_point()
	var picked_point_local = picked_shelf_collision.to_local(picked_point_global)
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

	var book_transform_local = BookRegistry.get_book_transform(book_text.book)

	held_book.pull_from_shelf(
		book_text, book_transform_local, raycast.get_collider().global_transform
	)
	return true


func place_book_on_shelf() -> bool:
	var pos_book_ind = get_raycast_shelf_book_ind()
	if pos_book_ind == null:
		return false
	var actual_book_ind = BookRegistry.get_book_at(pos_book_ind)
	if actual_book_ind != null:
		return false
	var book_transform_local = BookRegistry.get_book_transform(pos_book_ind.book)
	held_book.place_on_shelf(
		pos_book_ind, book_transform_local, raycast.get_collider().global_transform
	)
	return true


func pick_up_floor_book():
	var book = raycast.get_collider()
	held_book.pick_up_floor_book(book)


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
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		emit_signal("pause_requested")
		get_tree().set_input_as_handled()
		return
	elif (
		event is InputEventMouseButton
		and event.is_pressed()
		and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED
	):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().set_input_as_handled()
		return

	# Book pickup
	if (
		event.is_action_pressed("pick_up")
		and raycast.is_colliding()
		and raycast.get_collider() is Area
		and held_book.can_pick_up_book()
	):
		if pick_up_shelf_book():
			emit_signal("book_held", true)
			get_tree().set_input_as_handled()
			return
	if (
		event.is_action_pressed("pick_up")
		and raycast.is_colliding()
		and raycast.get_collider() is Area
		and held_book.can_place_book()
	):
		if place_book_on_shelf():
			emit_signal("book_held", false)
			get_tree().set_input_as_handled()
			return
	if (
		event.is_action_pressed("pick_up")
		and raycast.is_colliding()
		and raycast.get_collider() is RigidBody
		and held_book.can_pick_up_book()
	):
		if pick_up_floor_book():
			emit_signal("book_held", true)
			get_tree().set_input_as_handled()
			return
	if event.is_action_pressed("pick_up") and held_book.can_drop_book():
		held_book.drop_book()
		emit_signal("book_held", false)
		get_tree().set_input_as_handled()
		return

	if event.is_action_pressed("turn_page_forward") and held_book.can_turn_page():
		held_book.page_forward()
		get_tree().set_input_as_handled()
		return
	if event.is_action_pressed("turn_page_back") and held_book.can_turn_page():
		held_book.page_back()
		get_tree().set_input_as_handled()
		return


func _handle_movement():
	var controller_look = (
		Input.get_vector("look_left", "look_right", "look_up", "look_down")
		* controller_sensitivity
	)
	var rotation = (_mouse_move + controller_look) * Options.get("look_sensitivity")
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
	else:
		var _move_result = self.move_and_slide(Vector3(move_vec.x, -gravity, move_vec.y), UP, true)


func _selection_highlight():
	if not raycast.is_colliding():
		selection_highlight.hide()
		_raycast_colliding(false)
		return
	if raycast.get_collider() is Area:
		var book_ind = get_raycast_shelf_book_ind()
		if book_ind != null:
			var book_transform_local = BookRegistry.get_book_transform(book_ind.book)
			var book_transform_global = (
				raycast.get_collider().global_transform
				* book_transform_local
			)
			selection_highlight.show()
			selection_highlight.global_transform = book_transform_global
			_raycast_colliding(true)
			return
	elif raycast.get_collider() is RigidBody:
		selection_highlight.show()
		selection_highlight.global_transform = raycast.get_collider().global_transform
		_raycast_colliding(true)
		return
	selection_highlight.hide()
	_raycast_colliding(false)


func _physics_process(_delta):
	_handle_movement()
	_selection_highlight()


func _raycast_colliding(val: bool):
	if val != _last_raycast_colliding:
		emit_signal("book_targeted", val)
	_last_raycast_colliding = val


func _input_type(val: int):
	if val != _last_input_type:
		emit_signal("last_input_method_changed", val)
	_last_input_type = val


func _on_RoomTracker_room_changed(area):
	BookRegistry.set_player_position(area.room_index)
