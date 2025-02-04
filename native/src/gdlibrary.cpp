#include <Godot.hpp>

#include "book_search.hpp"
#include "book_text.hpp"
#include "book_util.hpp"
#include "room_gen_params.hpp"

extern "C" void GDN_EXPORT godot_gdnative_init(godot_gdnative_init_options *o) {
  godot::Godot::gdnative_init(o);
}

extern "C" void GDN_EXPORT
godot_gdnative_terminate(godot_gdnative_terminate_options *o) {
  godot::Godot::gdnative_terminate(o);
}

extern "C" void GDN_EXPORT godot_nativescript_init(void *handle) {
  godot::Godot::nativescript_init(handle);

  godot::register_class<RoomGenParams>();
  godot::register_class<BookText>();
  godot::register_class<BookUtil>();
  godot::register_class<BookSearchResult>();
  godot::register_class<BookSearch>();
}
