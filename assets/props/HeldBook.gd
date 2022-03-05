extends Spatial

enum State { NONE, ANIMATING_PICK, HELD, ANIMATING_DROP }

export(NodePath) var animation_player_path: NodePath
export(NodePath) var tween_path: NodePath
export(NodePath) var display_path: NodePath
export(NodePath) var mesh_path: NodePath
export(float) var pull_animation_time: float = 1
export(float) var pull_animation_shelf_clearence: float = 0.3
export(PackedScene) var floor_book_scene
export(Array, NodePath) var page_renderers

var state: int = State.NONE setget set_state

var _book_text = null
var _page: int = 0
var _start_transform: Transform = Transform.IDENTITY
var _mid_transform: Transform = Transform.IDENTITY

onready var animation_player: AnimationPlayer = get_node(animation_player_path)
onready var tween: Tween = get_node(tween_path)
onready var display_node: Spatial = get_node(display_path)
onready var book_material: Material = get_node(mesh_path).get_active_material(0)


func _ready():
	self.state = State.NONE
	book_material.set_shader_param("page1_text_texture", get_node(page_renderers[0]).get_texture())
	book_material.set_shader_param("page2_text_texture", get_node(page_renderers[1]).get_texture())


func set_state(new_state: int):
	match new_state:
		State.NONE:
			display_node.visible = false
		State.ANIMATING_PICK:
			assert(state == State.NONE)
			display_node.visible = true
		State.HELD:
			assert(state == State.ANIMATING_PICK)
		State.ANIMATING_DROP:
			assert(state == State.HELD)
	state = new_state


func can_pick_up_book() -> bool:
	return state == State.NONE


func _set_animation_progress(p: float):
	if p < 0.5:
		display_node.global_transform = _start_transform.interpolate_with(_mid_transform, p * 2)
	else:
		display_node.global_transform = _mid_transform.interpolate_with(
			display_node.get_parent().global_transform, (p - 0.5) * 2
		)


func pull_from_shelf(book_text, book_transform_local: Transform, shelf_transform_global: Transform):
	assert(can_pick_up_book())
	yield(_animate_pick(book_text, book_transform_local, shelf_transform_global), "completed")


func can_drop_book() -> bool:
	return state == State.HELD


func drop_book() -> BookText:
	assert(can_drop_book())
	yield(_animate_drop(), "completed")
	return _book_text


func _animate_pick(book_text, book_transform_local: Transform, shelf_transform_global: Transform):
	set_state(State.ANIMATING_PICK)
	_book_text = book_text
	var packed_title = BookRegistry.get_title(book_text)
	book_material.set_shader_param("title1", int(packed_title.r))
	book_material.set_shader_param("title2", int(packed_title.g))
	book_material.set_shader_param("title3", int(packed_title.b))
	book_material.set_shader_param("title4", int(packed_title.a))
	_page = 0
	_update_page_renderers()

	var shelf_to_local_transform = shelf_transform_global
	_start_transform = shelf_to_local_transform * book_transform_local
	_mid_transform = (
		shelf_to_local_transform
		* book_transform_local.translated(Vector3.RIGHT * pull_animation_shelf_clearence)
	)

	# Reset animation
	animation_player.stop()
	_set_animation_progress(0)

	assert(
		tween.interpolate_method(
			self,
			"_set_animation_progress",
			0,
			1,
			pull_animation_time,
			Tween.TRANS_QUAD,
			Tween.EASE_IN_OUT
		)
	)
	assert(tween.start())
	yield(tween, "tween_completed")
	set_state(State.HELD)
	animation_player.play("BookOpen")


func _animate_drop():
	set_state(State.ANIMATING_DROP)
	animation_player.play_backwards("BookOpen")
	yield(animation_player, "animation_finished")
	# TODO Call BookRegistry to make rigid body
	set_state(State.NONE)


func _update_page_renderers():
	var page1 = BookRegistry.get_page(_book_text, _page)
	get_node(page_renderers[0]).set_text(page1)
	if _page + 1 >= BookRegistry.PARAMS.pages_per_book:
		get_node(page_renderers[1]).set_text("")
	else:
		var page2 = BookRegistry.get_page(_book_text, _page + 1)
		get_node(page_renderers[1]).set_text(page2)


func can_turn_page() -> bool:
	return state == State.HELD


func page_forward():
	assert(can_turn_page())
	if _page >= BookRegistry.PARAMS.pages_per_book - 2:
		return
	_page += 2
	_update_page_renderers()


func page_back():
	assert(can_turn_page())
	if _page == 0:
		return
	_page -= 2
	_update_page_renderers()
