extends "res://addons/gut/test.gd"

var LRUCache = preload("res://scripts/data/LRUCache.gd")


func test_add_on_empty_returns_null():
	var cache = LRUCache.new(1)

	var add_result = cache.add("test", 1)

	assert_eq(add_result, null)


func test_add_on_replace_returns_old_value():
	var cache = LRUCache.new(10)

	cache.add("test", 1)
	var add_result = cache.add("test", 2)

	assert_eq(add_result, 1)


func test_add_on_full_removes_oldest():
	var cache = LRUCache.new(2)

	cache.add("a", 1)
	cache.add("b", 2)
	cache.add("c", 3)

	assert_false(cache.has("a"))
	assert_true(cache.has("b"))
	assert_true(cache.has("c"))


func test_add_on_full_returns_removed_value():
	var cache = LRUCache.new(2)

	cache.add("a", 1)
	cache.add("b", 2)
	var removed = cache.add("c", 3)

	assert_eq(removed, 1)


func test_add_on_discard_frees_node():
	var cache = LRUCache.new(2)

	cache.add("a", {"A": 1})
	cache.add("b", {"A": 2})
	var refs = Performance.get_monitor(Performance.OBJECT_COUNT)
	cache.add("c", {"A": 3})
	var after_refs = Performance.get_monitor(Performance.OBJECT_COUNT)

	assert_eq(refs, after_refs)


func test_add_overrides_old_value_same_key():
	var cache = LRUCache.new(1)

	cache.add("a", 1)
	var ret = cache.add("a", 2)

	assert_eq(ret, 1)
	assert_eq(cache.get("a"), 2)


func test_has_returns_true_after_add():
	var cache = LRUCache.new(1)

	var before = cache.has("a")
	cache.add("a", 1)
	var after = cache.has("a")

	assert_false(before)
	assert_true(after)


func test_has_returns_false_after_remove():
	var cache = LRUCache.new(1)

	cache.add("a", 1)
	var before = cache.has("a")
	cache.remove("a")
	var after = cache.has("a")

	assert_true(before)
	assert_false(after)


func test_get_returns_value():
	var cache = LRUCache.new(1)

	cache.add("a", 1)
	var result = cache.get("a")

	assert_eq(result, 1)


func test_get_promotes_key():
	var cache = LRUCache.new(2)

	cache.add("a", 1)
	cache.add("b", 2)
	var aval = cache.get("a")
	cache.add("c", 3)

	assert_eq(aval, 1)
	assert_true(cache.has("a"))
	assert_false(cache.has("b"))


func test_remove_head():
	var cache = LRUCache.new(3)

	cache.add("a", 1)
	cache.add("b", 2)
	cache.add("c", 3)
	var val = cache.remove("c")

	assert_eq(val, 3)
	assert_false(cache.has("c"))
	assert_eq(cache._head.get_ref().key, "b")


func test_remove_mid():
	var cache = LRUCache.new(3)

	cache.add("a", 1)
	cache.add("b", 2)
	cache.add("c", 3)
	var val = cache.remove("b")

	assert_eq(val, 2)
	assert_false(cache.has("b"))
	assert_eq(cache._head.get_ref().key, "c")
	assert_eq(cache._tail.get_ref().key, "a")


func test_remove_tail():
	var cache = LRUCache.new(3)

	cache.add("a", 1)
	cache.add("b", 2)
	cache.add("c", 3)
	var val = cache.remove("a")

	assert_eq(val, 1)
	assert_false(cache.has("a"))
	assert_eq(cache._tail.get_ref().key, "b")


func test_lru_cache_stress_test():
	var cache = LRUCache.new(5)
	var initial_order = [1, 2, 3, 4, 5]
	var get_order = [3, 1, 3, 3, 4, 5, 2, 1]
	var expected_order = [3, 4, 5, 2, 1]

	for i in initial_order:
		cache.add(i, i)
	for i in get_order:
		cache.get(i)

	for i in range(5):
		var removed = cache.add(i + 6, i + 6)
		assert_eq(removed, expected_order[i])
