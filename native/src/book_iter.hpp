#ifndef BOOK_ITER_H
#define BOOK_ITER_H

#include <Godot.hpp>
#include <boost/multiprecision/cpp_int.hpp>
#include <optional>

#include "book_util.hpp"

/** Efficiently iterates through books in shelf order within one room.
 */
class BookIter {
private:
  const BookUtil &book_util;
  int64_t book;
  // Book index with the multiplier applied.
  bmp::cpp_int book_index;

public:
  BookIter(const BookUtil &book_util, int64_t room_x, int64_t room_y,
           int64_t room_z);

  std::optional<bmp::cpp_int> next();

  int64_t get_book() const {
    int64_t books_per_shelf = book_util.get_room_gen_params()->books_per_shelf *
                              book_util.get_room_gen_params()->num_shelves;
    return book % books_per_shelf;
  }
  int64_t get_shelf() const {
    int64_t books_per_shelf = book_util.get_room_gen_params()->books_per_shelf *
                              book_util.get_room_gen_params()->num_shelves;
    return book / books_per_shelf;
  }
};

#endif