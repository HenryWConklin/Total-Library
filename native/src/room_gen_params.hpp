#ifndef ROOM_GEN_PARAMS_H
#define ROOM_GEN_PARAMS_H

#include <Godot.hpp>
#include <Mesh.hpp>
#include <PoolArrays.hpp>
#include <Ref.hpp>
#include <Resource.hpp>
#include <boost/multiprecision/cpp_int.hpp>

namespace bmp = boost::multiprecision;

/**
 * Represents all the configurable parameters for the contents
 * and placement of books.
 */
class RoomGenParams : public godot::Resource {
  GODOT_CLASS(RoomGenParams, godot::Resource)

public:
  // Number of shelves on a single bookshelf
  int num_shelves;
  // Number of books on a single shelf.
  int books_per_shelf;
  // Vertical spacing between shelves.
  float shelf_spacing;
  // Horizontal spacing between books.
  float book_spacing;
  // Mesh to use for rendering books.
  godot::Ref<godot::Mesh> book_mesh;
  // Number of characters on each page of each book.
  int chars_per_page;
  // Number of pages in each book.
  int pages_per_book;
  // Number of characters in the title of each book.
  int title_chars;
  // All the unique characters in the books, must match the
  // order in the sprite font used to render book titles.
  godot::String charset;
  // A number used to permute the books, needs to be coprime with
  // the total number of books, equivalent to being coprime
  // with the length of the charset.
  bmp::cpp_int shuffle_multiplier;
  // A bitwise shift applied to improve the "randomness" of the books,
  // must greater than half the number of bits in a book.
  int shift1;

  static void _register_methods();
  void _init();

  RoomGenParams() {}
  ~RoomGenParams() {}

  godot::PoolByteArray get_shuffle_multiplier() const;
  void set_shuffle_multiplier(godot::PoolByteArray val);
  // Search for shuffling parameters, sets the found values to the
  // appropriate fields. Should be run offline.
  void parameter_search();
};

#endif
