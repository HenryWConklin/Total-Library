extends Reference

# Least Recently Used cache, works like a map with limited capacity, if full it deletes the least
# recently accessed element.

var _capacity: int
var _values: Dictionary = {}
var _tail: WeakRef = null
var _head: WeakRef = null


class LRUNode:
	extends Reference
	var key
	var value
	var prev: WeakRef
	var next: WeakRef


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
		removed = remove(_tail.get_ref().key)

	var node = LRUNode.new()
	node.key = key
	node.value = value
	node.next = _head
	if _head == null:
		assert(_tail == null)
		_head = weakref(node)
		_tail = weakref(node)
	else:
		_head.get_ref().prev = weakref(node)
		_head = weakref(node)
	_values[key] = node
	return removed


# Remove the value corresponding to the given key and return the value if present, null otherwise
func remove(key):
	if not has(key):
		return null
	var removed = _values[key]
	if removed.prev != null:
		removed.prev.get_ref().next = removed.next
	if removed.next != null:
		removed.next.get_ref().prev = removed.prev
	if removed.key == _tail.get_ref().key:
		_tail = removed.prev
	if removed.key == _head.get_ref().key:
		_head = removed.next
	var erased = _values.erase(key)
	assert(erased)
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
