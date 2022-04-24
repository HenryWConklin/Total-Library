#ifndef ROOM_GEN_PARAMS_H
#define ROOM_GEN_PARAMS_H

#include <PoolArrays.hpp>
#include <Godot.hpp>
#include <Mesh.hpp>
#include <Ref.hpp>
#include <Resource.hpp>
#include <boost/multiprecision/cpp_int.hpp>

namespace bmp = boost::multiprecision;

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
  bmp::cpp_int shuffle_multiplier;

  static void _register_methods();
  void _init();

  RoomGenParams() {}
  ~RoomGenParams() {}

  godot::PoolByteArray get_shuffle_multiplier() const;
  void set_shuffle_multiplier(godot::PoolByteArray val);
  // Search for shuffling parameters
  void parameter_search();
};

#endif
