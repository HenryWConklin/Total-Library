#ifndef ROOM_GEN_PARAMS_H
#define ROOM_GEN_PARAMS_H

#include <Godot.hpp>
#include <Mesh.hpp>
#include <Ref.hpp>
#include <Resource.hpp>

class RoomGenParams : public godot::Resource {
  GODOT_CLASS(RoomGenParams, godot::Resource)

public:
  int num_shelves;
  int books_per_shelf;
  float shelf_spacing;
  float book_spacing;
  godot::Ref<godot::Mesh> book_mesh;
  int chars_per_page;
  int pages_per_book;
  int title_chars;
  godot::String charset;

  static void _register_methods();
  void _init();

  RoomGenParams() {}
  ~RoomGenParams() {}

};

#endif
