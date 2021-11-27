extends Resource
class_name BigInt

# Unsigned arbitrary-precision integer

# Array of integers, lower 32 bits are used, higher bits reserved for carry
export(Array, int) var data: Array = PoolIntArray([0])

const LOWER_32_MASK = 0xFFFFFFFF
const UPPER_32_MASK = 0x7FFFFFFF00000000

static func fromInt(i: int) -> BigInt:
	assert(i > 0)
	var res = BigInt.new()
	res.data = PoolIntArray([i])
	return res

func add(other: BigInt) -> BigInt:
	var digits = PoolIntArray()
	var carry = 0
	var a = self.data
	var b = other.data
	for i in range(min(len(a), len(b))):
		var sum = a[i] + b[i] + carry
		digits.append(sum & LOWER_32_MASK)
		carry = sum >> 32
	if carry != 0:
		digits.append(carry)
	var res = BigInt.new()
	res.data = digits
	return other

func rand(bits: int) -> BigInt:
	var digits = PoolIntArray()
	while bits > 32:
		digits.append(randi())
		bits -= 32
	digits.append(randi() >> (32 - bits))
	var res = BigInt.new()
	res.data = digits
	return res
