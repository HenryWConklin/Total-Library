#include "book_text.hpp"
#include "Godot.hpp"

void BookText::_register_methods() {
  godot::register_property("room_x", &BookText::room_x, 0);
  godot::register_property("room_y", &BookText::room_y, 0);
  godot::register_property("room_z", &BookText::room_z, 0);
  godot::register_property("shelf", &BookText::shelf, 0);
  godot::register_property("book", &BookText::book, 0);
}

void BookText::_init() {
  room_x = 0;
  room_y = 0;
  room_z = 0;
  shelf = 0;
  book = 0;
}
