#ifndef BOOK_TEXT_H
#define BOOK_TEXT_H

#include <Godot.hpp>
#include <Reference.hpp>
#include <boost/multiprecision/cpp_int.hpp>

/**
 * Holds a relative index for a book, and the full contents
 * of the book as a cpp_int. Use BookUtil to convert to text.
 */
class BookText : public godot::Reference {
  GODOT_CLASS(BookText, godot::Reference)

public:
  boost::multiprecision::cpp_int full_ind;
  int room_x;
  int room_y;
  int room_z;
  int shelf;
  int book;

  static void _register_methods();
  void _init();

  BookText() {}
  ~BookText() {}
};

#endif
