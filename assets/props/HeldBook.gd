extends Spatial

# A book held by the player, manages animations picking and placing on the shelf, dropping the book,
# rendering internal pages, animating page turns, audio effects from various actions.

enum State { NONE, ANIMATING_PICK, HELD, ANIMATING_DROP, ANIMATING_TURN, ANIMATING_PLACE }

export(NodePath) var book_open_animation_player_path: NodePath
export(NodePath) var page_turn_animation_player_path: NodePath
export(NodePath) var page_mesh_path: NodePath
export(NodePath) var book_mesh_path: NodePath
export(NodePath) var tween_path: NodePath
export(NodePath) var display_path: NodePath
export(NodePath) var room_tracker_path: NodePath
export(NodePath) var drop_safety_area_path: NodePath
export(NodePath) var book_open_audio: NodePath
export(NodePath) var book_close_audio: NodePath
export(NodePath) var page_turn_audio: NodePath
export(NodePath) var book_slide_out_audio: NodePath
export(NodePath) var book_slide_in_audio: NodePath
export(float) var pull_animation_time: float = 1
export(float) var pull_animation_shelf_clearence: float = 0.3
export(PackedScene) var floor_book_scene
export(Array, NodePath) var page_renderers

var state: int = State.NONE setget set_state

var _book_text = null
var _page: int = 0
var _start_transform: Transform = Transform.IDENTITY
var _mid_transform: Transform = Transform.IDENTITY
var _end_transform: Transform = Transform.IDENTITY
var _page_renderer_nodes: Array = []
var _cached_page_text: Dictionary = {}

onready var book_open_animation_player: AnimationPlayer = get_node(book_open_animation_player_path)
onready var page_turn_animation_player: AnimationPlayer = get_node(page_turn_animation_player_path)
onready var tween: Tween = get_node(tween_path)
onready var display_node: Spatial = get_node(display_path)
onready var book_material: Material = get_node(book_mesh_path).get_active_material(0)
onready var page_mesh: Spatial = get_node(page_mesh_path)
onready var room_tracker = get_node(room_tracker_path)
onready var drop_safety_area: Area = get_node(drop_safety_area_path)


func _ready():
	self.state = State.NONE
	book_material.set_shader_param("page1_text_texture", get_node(page_renderers[0]).get_texture())
	book_material.set_shader_param("page2_text_texture", get_node(page_renderers[1]).get_texture())
	book_material.set_shader_param("render_page_text", true)
	book_material.set_shader_param("use_packed_title", true)
	var page_material = page_mesh.get_active_material(0)
	page_material.set_shader_param("back_page", get_node(page_renderers[2]).get_texture())
	page_material.set_shader_param("front_page", get_node(page_renderers[3]).get_texture())
	for renderer in page_renderers:
		_page_renderer_nodes.append(get_node(renderer))
	var err = Options.connect("shadow_setting_changed", self, "_on_shadow_setting_changed")
	assert(err == OK)
	_on_shadow_setting_changed(Options.get("shadows"))


func set_state(new_state: int):
	match new_state:
		State.NONE:
			display_node.visible = false
			page_mesh.visible = false
			_cached_page_text.clear()
		State.ANIMATING_PICK:
			assert(state == State.NONE)
			display_node.visible = true
		State.HELD:
			page_mesh.visible = false
			assert(state == State.ANIMATING_PICK or state == State.ANIMATING_TURN)
		State.ANIMATING_DROP:
			assert(state == State.HELD)
		State.ANIMATING_TURN:
			assert(state == State.HELD)
			page_mesh.visible = true
		State.ANIMATING_PLACE:
			assert(state == State.HELD)
	state = new_state


func can_pick_up_book() -> bool:
	return state == State.NONE


func _set_animation_progress_pick(p: float):
	if p < 0.5:
		display_node.global_transform = _start_transform.interpolate_with(_mid_transform, p * 2)
	else:
		display_node.global_transform = _mid_transform.interpolate_with(
			display_node.get_parent().global_transform, (p - 0.5) * 2
		)

func open_to_page(book_text, page):
	_book_text = book_text
	set_state(State.ANIMATING_PICK)
	set_state(State.HELD)
	book_open_animation_player.play("BookOpen")
	book_open_animation_player.seek(book_open_animation_player.get_animation("BookOpen").length)
	var packed_title = BookRegistry.get_title(book_text)
	_set_title(packed_title)
	_page = page
	_update_page_renderers_held()

func pull_from_shelf(book_text, book_transform_local: Transform, shelf_transform_global: Transform):
	assert(can_pick_up_book())
	yield(_animate_pick(book_text, book_transform_local, shelf_transform_global), "completed")


func can_place_book():
	return state == State.HELD


func place_on_shelf(
	pos_book_ind: BookIndex, book_transform_local: Transform, shelf_transform_global: Transform
):
	assert(can_place_book())
	set_state(State.ANIMATING_PLACE)
	book_open_animation_player.play_backwards("BookOpen")
	yield(book_open_animation_player, "animation_finished")
	get_node(book_close_audio).play()
	var shelf_to_local_transform = shelf_transform_global
	_end_transform = shelf_to_local_transform * book_transform_local
	_mid_transform = (
		shelf_to_local_transform
		* book_transform_local.translated(Vector3.RIGHT * pull_animation_shelf_clearence)
	)
	_start_transform = display_node.global_transform
	_set_animation_progress_place(0)
	var succeeded = tween.interpolate_callback(
		get_node(book_slide_in_audio), pull_animation_time / 2.0, "play"
	)
	assert(succeeded)
	succeeded = tween.interpolate_method(
		self,
		"_set_animation_progress_place",
		0,
		1,
		pull_animation_time,
		Tween.TRANS_QUAD,
		Tween.EASE_IN_OUT
	)
	assert(succeeded)
	succeeded = tween.start()
	assert(succeeded)
	# Yield twice for the two queued tweens
	yield(tween, "tween_completed")
	yield(tween, "tween_completed")
	set_state(State.NONE)
	var actual_book_ind = BookIndex.new().from_book_text(_book_text)
	succeeded = BookRegistry.place_book_at(pos_book_ind, actual_book_ind)
	assert(succeeded)


func _set_animation_progress_place(p: float):
	if p < 0.5:
		display_node.global_transform = _start_transform.interpolate_with(_mid_transform, p * 2)
	else:
		display_node.global_transform = _mid_transform.interpolate_with(
			_end_transform, (p - 0.5) * 2
		)


func can_drop_book() -> bool:
	return state == State.HELD && drop_safety_area.get_overlapping_bodies().empty()


func drop_book() -> BookText:
	assert(can_drop_book())
	yield(_animate_drop(), "completed")
	return _book_text

func _set_title(packed_title):
	book_material.set_shader_param("title1", int(packed_title.r))
	book_material.set_shader_param("title2", int(packed_title.g))
	book_material.set_shader_param("title3", int(packed_title.b))
	book_material.set_shader_param("title4", int(packed_title.a))


func _animate_pick(book_text, book_transform_local: Transform, shelf_transform_global: Transform):
	set_state(State.ANIMATING_PICK)
	_book_text = book_text
	var packed_title = BookRegistry.get_title(book_text)
	_set_title(packed_title)
	_page = 0
	_update_page_renderers_held()
	var shelf_to_local_transform = shelf_transform_global
	_start_transform = shelf_to_local_transform * book_transform_local
	_mid_transform = (
		shelf_to_local_transform
		* book_transform_local.translated(Vector3.RIGHT * pull_animation_shelf_clearence)
	)
	# Reset animation
	book_open_animation_player.stop()
	_set_animation_progress_pick(0)
	var succeeded = tween.interpolate_method(
		self,
		"_set_animation_progress_pick",
		0,
		1,
		pull_animation_time,
		Tween.TRANS_QUAD,
		Tween.EASE_IN_OUT
	)
	assert(succeeded)
	succeeded = tween.start()
	assert(succeeded)
	get_node(book_slide_out_audio).play()
	yield(tween, "tween_completed")
	set_state(State.HELD)
	get_node(book_open_audio).play()
	book_open_animation_player.play("BookOpen")


func _animate_drop():
	set_state(State.ANIMATING_DROP)
	book_open_animation_player.play_backwards("BookOpen")
	yield(book_open_animation_player, "animation_finished")
	get_node(book_close_audio).play()
	set_state(State.NONE)
	var book = floor_book_scene.instance()
	book.book_index = BookIndex.new().from_book_text(_book_text)
	book.title = BookRegistry.get_title(_book_text)
	var room = room_tracker.current_room_area.get_parent()
	room.get_node(room.floor_books_path).add_child(book)
	book.global_transform = display_node.global_transform


func _set_page_renderer_text(renderer: int, page: int):
	if page < 0 or page >= BookRegistry.PARAMS.pages_per_book:
		_page_renderer_nodes[renderer].set_text("")
	else:
		var text = ""
		if _cached_page_text.has(page):
			text = _cached_page_text.get(page)
		else:
			text = BookRegistry.get_page(_book_text, page)
			_cached_page_text[page] = text
		_page_renderer_nodes[renderer].set_text(text, page+1)


func _update_page_renderers_held():
	_set_page_renderer_text(0, _page)
	_set_page_renderer_text(1, _page + 1)


func _update_page_renderers_turn():
	_set_page_renderer_text(0, _page)
	_set_page_renderer_text(1, _page + 3)
	_set_page_renderer_text(2, _page + 1)
	_set_page_renderer_text(3, _page + 2)


func can_turn_page() -> bool:
	return state == State.HELD


func _page_turn(diff: int):
	assert(can_turn_page())
	if _page + diff >= BookRegistry.PARAMS.pages_per_book:
		# yield then return so this is always a coroutine
		yield()
		return
	elif _page + diff < 0:
		yield()
		return
	set_state(State.ANIMATING_TURN)
	if diff > 0:
		_update_page_renderers_turn()
		_page += diff
		page_turn_animation_player.play("PageTurn")
	else:
		_page += diff
		_update_page_renderers_turn()
		page_turn_animation_player.play_backwards("PageTurn")
	get_node(page_turn_audio).play()
	yield(page_turn_animation_player, "animation_finished")
	set_state(State.HELD)
	_update_page_renderers_held()


func page_forward():
	yield(_page_turn(2), "completed")


func page_back():
	yield(_page_turn(-2), "completed")

func get_page() -> int:
	return _page

func pick_up_floor_book(book):
	assert(can_pick_up_book())
	set_state(State.ANIMATING_PICK)
	_book_text = BookRegistry.get_book_text(book.book_index)
	var packed_title = book.title
	book.hide()
	book.queue_free()
	book_material.set_shader_param("title1", int(packed_title.r))
	book_material.set_shader_param("title2", int(packed_title.g))
	book_material.set_shader_param("title3", int(packed_title.b))
	book_material.set_shader_param("title4", int(packed_title.a))
	_page = 0
	_update_page_renderers_held()

	_start_transform = book.global_transform
	# Reset animation
	book_open_animation_player.stop()
	_set_animation_progress_pick_floor(0)

	var succeeded = tween.interpolate_method(
		self,
		"_set_animation_progress_pick_floor",
		0,
		1,
		pull_animation_time,
		Tween.TRANS_QUAD,
		Tween.EASE_IN_OUT
	)
	assert(succeeded)
	succeeded = tween.start()
	assert(succeeded)
	yield(tween, "tween_completed")

	book_open_animation_player.play("BookOpen")
	get_node(book_open_audio).play()
	yield(book_open_animation_player, "animation_finished")

	set_state(State.HELD)


func _set_animation_progress_pick_floor(p: float):
	display_node.global_transform = _start_transform.interpolate_with(
		display_node.get_parent().global_transform, p
	)


func teleport(offset: Vector3):
	if state in [State.ANIMATING_PICK, State.ANIMATING_PLACE]:
		var translate = Transform.IDENTITY.translated(offset)
		_start_transform = translate * _start_transform
		_mid_transform = translate * _mid_transform


func _on_shadow_setting_changed(val):
	if val > 1:
		$Armature/AnimatedPageTurn.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_ON
		$Armature/Skeleton/Book001.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_ON
	else:
		$Armature/AnimatedPageTurn.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
		$Armature/Skeleton/Book001.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
