extends Area

export(NodePath) var shelf_path: NodePath


func get_shelf() -> Node:
	return get_node(shelf_path)
