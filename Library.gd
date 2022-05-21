extends Spatial

export(NodePath) var player: NodePath
export(NodePath) var player_spawns: NodePath
export(int) var spawn_ind: int


func _init():
	BookRegistry.load_data()


func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var spawns = get_node(player_spawns).get_children()
	var ind = rng.randi_range(0, len(spawns) - 1)
	print(ind)
	get_node(player).transform = spawns[ind].transform
