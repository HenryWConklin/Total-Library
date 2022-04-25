#include <Godot.hpp>
#include <GodotGlobal.hpp>
#include <PoolArrays.hpp>
#include <boost/multiprecision/cpp_int.hpp>
#include <boost/multiprecision/cpp_int/import_export.hpp>
#include <boost/multiprecision/detail/default_ops.hpp>
#include <boost/random/uniform_int_distribution.hpp>
#include <math.h>

#include "room_gen_params.hpp"
#include "util.hpp"

#define DEFAULT_NUM_SHELVES 5
#define DEFAULT_BOOKS_PER_SHELF 60
#define DEFAULT_SHELF_SPACING 0.4f
#define DEFAULT_BOOK_SPACING 0.01f
#define DEFAULT_BOOK_MESH godot::Ref<godot::Mesh>()
#define DEFAULT_CHARS_PER_PAGE 320
#define DEFAULT_PAGES_PER_BOOK 410
#define DEFAULT_TITLE_CHARS 10
#define DEFAULT_CHARSET godot::String("ABCDEFGHIJKLMNOPQRSTUVWXYZ.,'?! ")
#define DEFAULT_SHUFFLE_MULTIPLIER godot::PoolByteArray()

void RoomGenParams::_register_methods() {
  godot::register_property("num_shelves", &RoomGenParams::num_shelves,
                           DEFAULT_NUM_SHELVES);
  godot::register_property("books_per_shelf", &RoomGenParams::books_per_shelf,
                           DEFAULT_BOOKS_PER_SHELF);
  godot::register_property("shelf_spacing", &RoomGenParams::shelf_spacing,
                           DEFAULT_SHELF_SPACING);
  godot::register_property("book_spacing", &RoomGenParams::book_spacing,
                           DEFAULT_BOOK_SPACING);
  godot::register_property("book_mesh", &RoomGenParams::book_mesh,
                           DEFAULT_BOOK_MESH);
  godot::register_property("chars_per_page", &RoomGenParams::chars_per_page,
                           DEFAULT_CHARS_PER_PAGE);
  godot::register_property("pages_per_book", &RoomGenParams::pages_per_book,
                           DEFAULT_PAGES_PER_BOOK);
  godot::register_property("title_chars", &RoomGenParams::title_chars,
                           DEFAULT_TITLE_CHARS);
  godot::register_property("charset", &RoomGenParams::charset, DEFAULT_CHARSET);
  godot::register_property(
      "shuffle_multiplier", &RoomGenParams::set_shuffle_multiplier,
      &RoomGenParams::get_shuffle_multiplier, DEFAULT_SHUFFLE_MULTIPLIER);
  godot::register_property("shift1", &RoomGenParams::shift1, 0);
  godot::register_property("shift2", &RoomGenParams::shift2, 0);
  godot::register_property("shift3", &RoomGenParams::shift3, 0);

  godot::register_method("parameter_search", &RoomGenParams::parameter_search);
}

void RoomGenParams::_init() {}

void RoomGenParams::set_shuffle_multiplier(godot::PoolByteArray bytes) {
  bmp::import_bits(shuffle_multiplier, bytes.read().ptr(),
                   bytes.read().ptr() + bytes.size());
}

godot::PoolByteArray RoomGenParams::get_shuffle_multiplier() const {
  godot::PoolByteArray res;
  PoolByteArrayWrapper wrapped(res);
  bmp::export_bits(shuffle_multiplier, std::back_inserter(wrapped), 8);
  return res;
}

void RoomGenParams::parameter_search() {
  int chars_per_book = title_chars + (chars_per_page * pages_per_book);

  bmp::cpp_int num_books =
      bmp::pow(bmp::cpp_int(charset.length()), chars_per_book);
  RandWrapper gen(321);
  // Need to pick a multiplier that cycles through all possible books. Only
  // requirement is that gcd(n, num_books) is 1. For a power of 2 number of
  // chars in the charset, shuffle_multiplier only needs to be odd but this
  // implementation will handle other cases.
  boost::random::uniform_int_distribution<bmp::cpp_int> dist(bmp::cpp_int(0),
                                                             num_books);
  do {
    shuffle_multiplier = dist(gen);
  } while (bmp::gcd(shuffle_multiplier, num_books) != bmp::cpp_int(1));

  // Shifts only need to be at least half the number of bits in the full number.
  // As long as it's more than half the process is fully reversible and
  // therefore a bijection.
  int bits_per_book =
      (int)ceil(log2((double)charset.length()) * chars_per_book);
  boost::random::uniform_int_distribution<int> shift_dist(
      (bits_per_book / 2) + 1, bits_per_book);
  shift1 = shift_dist(gen);
  shift2 = shift_dist(gen);
  shift3 = shift_dist(gen);
}
