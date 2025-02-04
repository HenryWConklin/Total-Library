#include "room_iter.hpp"

#include <Array.hpp>
#include <Godot.hpp>
#include <String.hpp>
#include <cstdint>

// Map to half-x space, removing vestibule rooms.
Room halve_x(Room r) {
  Room result = {.x = (r.x + (r.x % 2 == 0 ? 0 : 1)) / 2, .y = r.y, .z = r.z};
  // On floors where y is connected, nudge to an accessible book room if in a
  // vestibule. Otherwise end up starting in an inaccessible room.
  if (r.z % 2 != 0 && r.y % 2 == 0) {
    result.y -= 1;
  }
  return result;
}

// Map to regular space from half-x space.
Room double_x(Room r) {
  // Halving maps two rooms together, which one is the shelf room
  // alternates with y.
  return {.x = (r.x * 2) - (r.y % 2 == 0 ? 1 : 0), .y = r.y, .z = r.z};
}

bool reachable(Room r) {
  return (r.z % 2 == 0 && r.y % 2 == 0) || (r.z % 2 != 0 && r.x % 2 == 0);
}

RoomIter::RoomIter(int64_t start_x, int64_t start_y, int64_t start_z)
    : center(halve_x({.x = start_x, .y = start_y, .z = start_z})), index(-1) {}

Room RoomIter::next() {
  index += 1;
  while (!reachable(current())) {
    index += 1;
  }
  return current();
}

int64_t get_round_size(int64_t round) {
  // One "round" scanning from bottom to top with equal distance from the
  // center. Number of rooms checked on each floor of a round looks like: (1, 4,
  // 1), (1, 4, 8, 4, 1), (1, 4, 8, 12, 8, 4, 1) Size of a round is 2 + 2 *
  // sum(k=1 to n-1, 4k) + 4n, simplifies to below.
  return 2 + 4 * round * round;
}

int64_t get_subround_size(int64_t subround, int64_t round) {
  // Subround is one z-level within a round. First and last subround are 1, rest
  // is multiples of 4. e.g. (1, 4, 8, 12, 8, 4, 1).
  if (subround == 1 || subround == (2 * round + 1)) {
    return 1;
  } else if (subround <= round + 1) {
    return 4 * (subround - 1);
  } else {
    return 4 * (2 * round + 1 - subround);
  }
}

Room RoomIter::current() const {
  // I hate this stupid 3D spiral pattern. Trying to iterate in order of
  // distance from the center room. Cost of all this nonsense is dwarfed by the
  // bigint stuff so shouldn't matter.

  // Operate in half-x space to skip all the vestibule rooms and simplify the
  // logic. Does throw the "equal distance" off but it's close enough. Need to
  // double_x the result no matter what.

  // Special case the first iteration because it doesn't fit the pattern.
  if (index <= 0) {
    return double_x(center);
  }

  // First find the round, i.e. how far out are we looking from the center. Each
  // round checks get_round_size(round) rooms. sub_index is the remainder.
  int64_t sub_index = index - 1;
  int64_t round = 1;
  int64_t round_size = get_round_size(round);
  while (sub_index >= round_size) {
    sub_index -= round_size;
    round += 1;
    round_size = get_round_size(round);
  }

  // Now that we have the round, find the sub-round, i.e. which z-level we're
  // on.
  int64_t subround = 1;
  int64_t subround_size = get_subround_size(subround, round);
  while (sub_index >= subround_size) {
    sub_index -= subround_size;
    subround += 1;
    subround_size = get_subround_size(subround, round);
  }

  int64_t z = center.z + (subround - (round + 1));
  int64_t side_length = subround_size / 4;

  // First and last z-levels don't fit the pattern so special case.
  if (side_length == 0) {
    return double_x({.x = center.x, .y = center.y, .z = z});
  }

  // Now, we're doing the four sides of a diamond in clockwise order. Starting
  // from -x for no particular reason.
  int64_t side = sub_index / side_length;
  int64_t side_ind = sub_index % side_length;
  Room result;
  switch (side) {
  case 0:
    result = {.x = center.x - (side_length - side_ind),
              .y = center.y + side_ind,
              .z = z};
    break;
  case 1:
    result = {.x = center.x + side_ind,
              .y = center.y + (side_length - side_ind),
              .z = z};
    break;
  case 2:
    result = {.x = center.x + (side_length - side_ind),
              .y = center.y - side_ind,
              .z = z};
    break;
  case 3:
    result = {.x = center.x - side_ind,
              .y = center.y - (side_length - side_ind),
              .z = z};
    break;
  default:
    break;
  }

  return double_x(result);
}
