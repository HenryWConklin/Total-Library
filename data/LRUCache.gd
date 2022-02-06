extends Reference

class LRUNode:
	extends Reference
	var key
	var value
	var prev : LRUNode
	var next : LRUNode

var _capacity: int 
var _values: Dictionary = {}
var _tail : LRUNode = null
var _head : LRUNode = null

func _init(capacity: int):
	assert(capacity > 0)
	_capacity = capacity

# Insert a new key/value pair at the front of the use ordering, 
# overwriting any existing value under the given key and removing the 
# Least Recently Used element if the number of elements is at capacity. 
# Returns the removed element if any, null otherwise.
func add(key, value):
	# Either remove removes a value or we're at capacity during the check,
	# both can't happen so only one element will be removed at most
	var removed = remove(key)
	if len(_values) >= _capacity:
		removed = remove(_tail.key)

	var node = LRUNode.new()
	node.key = key
	node.value = value
	node.next = _head
	if _head == null:
		assert(_tail == null)
		_head = node
		_tail = node
	else:
		_head.prev = node
		_head = node
	_values[key] = node
	return removed

# Remove the value corresponding to the given key and return the value if present, null otherwise
func remove(key):
	if not has(key):
		return null
	var removed = _values[key]
	if removed.prev != null:
		removed.prev.next = removed.next
	if removed.next != null:
		removed.next.prev = removed.prev
	if removed.key == _tail.key:
		_tail = removed.prev
	if removed.key == _head.key:
		_head = removed.next
	assert(_values.erase(key))
	return removed.value

# Get value corresponding to key, shift that key up to the front of the use ordering.
# Returns null if element is not present
func get(key):
	if not has(key):
		return null
	var value = remove(key)
	add(key, value)
	return value

# Check if given key is in the cache
func has(key) -> bool:
	return _values.has(key)

