#include "room_gen_params.hpp"

#define DEFAULT_NUM_SHELVES 5
#define DEFAULT_BOOKS_PER_SHELF 60
#define DEFAULT_SHELF_SPACING 0.4f
#define DEFAULT_BOOK_SPACING 0.01f
#define DEFAULT_BOOK_MESH godot::Ref<godot::Mesh>()
#define DEFAULT_NUM_CHARS 32
#define DEFAULT_CHARS_PER_PAGE 320
#define DEFAULT_PAGES_PER_BOOK 410
#define DEFAULT_TITLE_CHARS 10
#define DEFAULT_CHARSET godot::String("ABCDEFGHIJKLMNOPQRSTUVWXYZ.,'?! ")

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
}

void RoomGenParams::_init() {
  num_shelves = DEFAULT_NUM_SHELVES;
  books_per_shelf = DEFAULT_BOOKS_PER_SHELF;
  shelf_spacing = DEFAULT_SHELF_SPACING;
  book_spacing = DEFAULT_BOOK_SPACING;
  book_mesh = DEFAULT_BOOK_MESH;
  chars_per_page = DEFAULT_CHARS_PER_PAGE;
  pages_per_book = DEFAULT_PAGES_PER_BOOK;
  title_chars = DEFAULT_TITLE_CHARS;
  charset = DEFAULT_CHARSET;
}
