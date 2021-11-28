extends Resource
class_name BookRegistryParams

export(int, 0, 10) var numShelves = 5
export(int, 0, 100) var booksPerShelf = 60
export(float, 0, 10) var shelfSpacing = .4
export(float, 0, 1) var bookSpacing = .01
export(Mesh) var bookMesh: Mesh = preload("res://blender/book_Cube.mesh")
