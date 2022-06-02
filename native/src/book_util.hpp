#ifndef BOOK_UTIL_H
#define BOOK_UTIL_H

#include <Godot.hpp>
#include <MultiMesh.hpp>
#include <PoolArrays.hpp>
#include <Reference.hpp>
#include <String.hpp>
#include <boost/multiprecision/cpp_int.hpp>

#include "book_text.hpp"
#include "room_gen_params.hpp"

// 23 bits in the mantissa for a float, minus one to dodge rounding errors.
#define MANTISSA_BITS 22
#define BOOK_TITLE_MAX_BITS 4 * MANTISSA_BITS

/**
 * Utility for all the heavy computations related to building books.
 */
class BookUtil : public godot::Reference {
  GODOT_CLASS(BookUtil, godot::Reference)

private:
  typedef boost::multiprecision::cpp_int cpp_int;
  // Index of the book at room (0,0,0), shelf 0, book 0
  cpp_int origin;
  godot::Ref<RoomGenParams> room_gen_params;

  // Precomputed values
  uint32_t books_per_room;
  uint32_t chars_per_book;
  uint32_t bits_per_char;
  // Is the length of the charset a power of 2?
  bool charset_pow2;
  cpp_int num_books;
  cpp_int num_books_bit_mask;
  uint32_t num_books_bits;
  cpp_int page_mod;
  cpp_int page_bit_mask;
  cpp_int title_mod;
  cpp_int title_bit_mask;
  // Distance along in sequential order for one room on each axis
  // x_diff is books_per_room
  // y_diff is also the length of one hallway before wrapping
  cpp_int y_diff;
  cpp_int z_diff;

  // Fills in all the cached values from the parameters.
  void _recompute_big_vals();
  // Makes a number representing the contents of the book at the given
  // position.
  cpp_int _make_book_num(int room_x, int room_y, int room_z, int shelf,
                         int book) const;
  // Makes a number representing the position of a book in the library
  // as a sequential index.
  cpp_int _make_book_index(int room_x, int room_y, int room_z, int shelf,
                           int book) const;
  // Does modular multiplication of a book number by shuffle_multiplier.
  inline void _apply_multiplier(cpp_int &val) const;
  // Shuffles the bits of a book number in place using bitwise ops.
  inline void _shuffle_bits(cpp_int &val) const;
  // Packs the bits of a cpp_int into floats and appends them to the given
  // PoolRealArray.
  inline void _pack_num_to_floats(const cpp_int &title_num,
                                  godot::PoolRealArray &buff) const;
  godot::Color _pack_title_num_to_color(const cpp_int &title_num) const;

public:
  static void _register_methods();
  void _init();

  BookUtil() {}
  ~BookUtil() {}

  godot::PoolByteArray get_origin() const;
  void set_origin(godot::PoolByteArray bytes);
  // Selects an origin at random using the given seed.
  void randomize_origin(int seed);

  godot::Ref<RoomGenParams> get_room_gen_params() const {
    return room_gen_params;
  }
  void set_room_gen_params(godot::Ref<RoomGenParams> params);

  // Makes all four multimeshes for a single room. Faster
  // than building each of them individually.
  godot::Array make_shelf_multimeshes(int room_x, int room_y, int room_z) const;
  // Builds a single shelf multimesh with all the books on a shelf.
  godot::Ref<godot::MultiMesh>
  make_shelf_multimesh(int room_x, int room_y, int room_z, int shelf) const;
  // Packs the title for a book into the mantissa of the floats in a
  // Color.
  godot::Color get_packed_title_from_index(int room_x, int room_y, int room_z,
                                           int shelf, int book) const;
  // Makes a BookText with the contents of the given book.
  godot::Ref<BookText> make_book(int room_x, int room_y, int room_z, int shelf,
                                 int book) const;
  // Returns a string with the text of the given page in the
  // given BookText.
  godot::String get_page(godot::Ref<BookText> book, int page) const;
  // Packs the title for a book into the mantissa of the floats in a
  // Color.
  godot::Color get_packed_title(godot::Ref<BookText> book) const;

  // Finds the index of a room contatining book starting with the given text,
  // set as origin and pull room 0,0,0.
  godot::PoolByteArray find_text(godot::String text) const;
};

#endif
