extends Area

# Area for use with a raycast to select books off a shelf.
# Tracks the path to the shelf it represents.

export(NodePath) var shelf_path: NodePath


func get_shelf() -> Node:
	return get_node(shelf_path)
