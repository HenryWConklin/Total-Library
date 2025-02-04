#ifndef ROOM_ITER_HPP
#define ROOM_ITER_HPP

#include <cstdint>

struct Room {
  int64_t x, y, z;
};

// Iterates through rooms in increasing distance from a central room.
class RoomIter {
public:
  RoomIter(int64_t start_x, int64_t start_y, int64_t start_z);

  Room next();
  Room current() const;

private:
    Room center;
    int64_t index;
};

#endif