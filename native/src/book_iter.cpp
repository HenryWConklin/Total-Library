#include "book_iter.hpp"

#include <Godot.hpp>
#include <boost/multiprecision/cpp_int.hpp>
#include <memory>
#include <optional>

#include "book_util.hpp"

namespace bmp = boost::multiprecision;

BookIter::BookIter(const BookUtil &book_util, int64_t room_x, int64_t room_y,
                   int64_t room_z)
    : book_util(book_util), book(-1),
      book_index(book_util._make_book_index(room_x - (room_x % 2 == 0 ? 1 : 0),
                                            room_y, room_z, 0, 0)) {
  book_util._apply_multiplier(book_index);
}

std::optional<bmp::cpp_int> BookIter::next() {
  if (book >= book_util.books_per_room - 1) {
    return std::nullopt;
  }
  book += 1;
  bmp::cpp_int result(book_index);
  book_util._shuffle_bits(result);

  book_index += book_util.room_gen_params->shuffle_multiplier;
  if (book_util.charset_pow2) {
    book_index &= book_util.num_books_bit_mask;
  } else {
    book_index %= book_util.num_books;
  }

  return std::move(result);
}
