#ifndef LOB_UTIL_H
#define LOB_UTIL_H

#include <PoolArrays.hpp>
#include <RandomNumberGenerator.hpp>
#include <Ref.hpp>

// Wrappers around pool arrays to work with std::back_inserter for boost
// multiprecision export/import
class PoolByteArrayWrapper {
public:
  typedef uint8_t value_type;
  godot::PoolByteArray &arr;

  inline void push_back(uint8_t v) { arr.push_back(v); }

  PoolByteArrayWrapper(godot::PoolByteArray &dest) : arr(dest) {}
};

class BitPackPoolRealArrayWrapper {
public:
  typedef uint32_t value_type;
  godot::PoolRealArray &arr;

  inline void push_back(uint32_t v) { arr.push_back((float)v); }

  BitPackPoolRealArrayWrapper(godot::PoolRealArray &dest) : arr(dest) {}
};

// Wrapper around godot random number generator for use with boost random
// distributions
class RandWrapper {
private:
  godot::Ref<godot::RandomNumberGenerator> gen;

public:
  typedef uint32_t result_type;

  RandWrapper(const int64_t seed) : gen(godot::RandomNumberGenerator::_new()) {
    gen->set_seed(seed);
  }
  ~RandWrapper() {}

  inline uint32_t operator()() { return (uint32_t)(gen->randi() & 0xFFFFFFFF); }

  static uint32_t min() { return 0; }
  static uint32_t max() { return 0xFFFFFFFF; }
};
#endif
