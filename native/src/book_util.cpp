#include "book_util.hpp"
#include "Godot.hpp"
#include "libs/multiprecision/include/boost/multiprecision/cpp_int.hpp"
#include "libs/multiprecision/include/boost/multiprecision/cpp_int/import_export.hpp"
#include "util.hpp"

#include <AABB.hpp>
#include <Array.hpp>
#include <RandomNumberGenerator.hpp>
#include <boost/random.hpp>
#include <cmath>
#include <iterator>
#include <vector>

namespace bmp = boost::multiprecision;

void BookUtil::_register_methods() {
  godot::register_property("origin", &BookUtil::set_origin,
                           &BookUtil::get_origin, godot::PoolByteArray());
  godot::register_property("room_gen_params", &BookUtil::set_room_gen_params,
                           &BookUtil::get_room_gen_params,
                           godot::Ref<RoomGenParams>());

  godot::register_method("randomize_origin", &BookUtil::randomize_origin);
  godot::register_method("make_shelf_multimesh",
                         &BookUtil::make_shelf_multimesh);
  godot::register_method("get_packed_title_from_index",
                         &BookUtil::get_packed_title_from_index);
  godot::register_method("make_book", &BookUtil::make_book);
  godot::register_method("get_page", &BookUtil::get_page);
  godot::register_method("get_packed_title", &BookUtil::get_packed_title);
}

void BookUtil::_init() {
  // Clear precomputed values
  books_per_room = 0;
  chars_per_book = 0;
  bits_per_char = 0;
  num_books = 0;
  // Mods to 1 to avoid mod by 0
  page_mod = 1;
  title_mod = 1;
  y_diff = 0;
  z_diff = 0;
}

void BookUtil::_recompute_big_vals() {
  chars_per_book =
      room_gen_params->title_chars +
      (room_gen_params->chars_per_page * room_gen_params->pages_per_book);
  books_per_room =
      room_gen_params->books_per_shelf * room_gen_params->num_shelves * 4;
  bits_per_char =
      (uint32_t)std::ceil(std::log2(room_gen_params->charset.length()));
  if (bits_per_char * room_gen_params->title_chars > BOOK_TITLE_MAX_BITS) {
    room_gen_params->title_chars = BOOK_TITLE_MAX_BITS / bits_per_char;
    godot::Godot::print_warning(
        godot::String("Title length over maximum of %s bits, truncating to "
                      "%s characters at %s bits each")
            .format(godot::Array::make(BOOK_TITLE_MAX_BITS,
                                       room_gen_params->title_chars,
                                       bits_per_char),
                    "%s"),
        "set_room_gen_params", __FILE__, __LINE__);
  }
  bmp::cpp_int bmp_num_chars(room_gen_params->charset.length());
  num_books = bmp::pow(bmp_num_chars, chars_per_book);
  // 4 sets of shelves per room
  page_mod = bmp::pow(bmp_num_chars, room_gen_params->chars_per_page);
  title_mod = bmp::pow(bmp_num_chars, room_gen_params->title_chars);
  // Make an almost cube, |x| = |y| = floor(chars_per_book/3), |z| =
  // chars_per_book - 2|x| where |x| is length of hallways along the x axis
  // before wrapping to the next hallway. One unit along x or y is actually two
  // rooms including the vestibule, z is one unit = one floor
  //
  // Note this in units of books not rooms. books_per_room needs to be a divisor
  // of all of these or the hallway wrap will be in the middle of a room and
  // books will be in different positions between wraps. Not that anyone will
  // ever see that
  y_diff = bmp::pow(bmp_num_chars, chars_per_book / 3);
  z_diff = bmp::pow(y_diff, 2);
}

bmp::cpp_int BookUtil::_make_book_num(int room_x, int room_y, int room_z,
                                      int shelf, int book) const {
  bmp::cpp_int val = _make_book_index(room_x, room_y, room_z, shelf, book);
  _permute_book_index(val);
  return val;
}

bmp::cpp_int BookUtil::_make_book_index(int room_x, int room_y, int room_z,
                                        int shelf, int book) const {
  return origin +
         (room_x * books_per_room + y_diff * room_y + z_diff * room_z) +
         (shelf * (books_per_room / 4)) + book;
}

inline void BookUtil::_permute_book_index(cpp_int &val) const {
  // TODO impelement
}

const uint32_t MANTISSA_MASK = (1 << MANTISSA_BITS) - 1;

void BookUtil::_pack_num_to_floats(const bmp::cpp_int &num,
                                   godot::PoolRealArray &buff) const {
  int num_chars = room_gen_params->charset.length();
  // If not power of 2
  if ((num_chars & (num_chars - 1)) != 0) {
    // Pad each character to a round number of bits
    bmp::cpp_int val = num;
    int packed_val = 0;
    int packed_bits = 0;
    while (val > 0) {
      packed_val |= (val % num_chars).convert_to<uint32_t>() << packed_bits;
      packed_bits += bits_per_char;
      if (packed_bits >= MANTISSA_BITS) {
        buff.append((float)(packed_val & MANTISSA_MASK));
        packed_val >>= MANTISSA_BITS;
        packed_bits -= MANTISSA_BITS;
      }
      val /= num_chars;
    }
    if (packed_val > 0) {
      buff.push_back((float)packed_val);
    }
  } else {
    // Direct copy the bits
    BitPackPoolRealArrayWrapper wrapper(buff);
    bmp::export_bits(num, std::back_inserter(wrapper),
                     /*chunk_size=*/MANTISSA_BITS,
                     /*msv_first=*/false);
  }
}

godot::Color
BookUtil::_pack_title_num_to_color(const bmp::cpp_int &title_num) const {
  godot::PoolRealArray floats;
  _pack_num_to_floats(title_num, floats);
  while (floats.size() < 4) {
    floats.push_back(0.0f);
  }
  return godot::Color(floats[0], floats[1], floats[2], floats[3]);
}

godot::PoolByteArray BookUtil::get_origin() const {
  godot::PoolByteArray res;
  PoolByteArrayWrapper wrapped(res);
  bmp::export_bits(origin, std::back_inserter(wrapped), 8);
  return res;
}

void BookUtil::set_origin(godot::PoolByteArray bytes) {
  bmp::import_bits(origin, bytes.read().ptr(),
                   bytes.read().ptr() + bytes.size());
}

void BookUtil::randomize_origin(int seed) {
  godot::Godot::print("in randomize");
  boost::random::uniform_int_distribution<bmp::cpp_int> dist(bmp::cpp_int(0),
                                                             num_books - 1);
  RandWrapper gen(seed);
  origin = dist(gen);
  // TODO Align origin to room, should just be origin - (origin %
  // books_per_room)
}

void BookUtil::set_room_gen_params(godot::Ref<RoomGenParams> params) {
  room_gen_params = params;
  if (room_gen_params.is_null()) {
    _init();
    return;
  }
  _recompute_big_vals();
}

godot::Ref<godot::MultiMesh> BookUtil::make_shelf_multimesh(int room_x,
                                                            int room_y,
                                                            int room_z,
                                                            int shelf) const {
  godot::Ref<godot::MultiMesh> shelf_mesh = godot::MultiMesh::_new();
  shelf_mesh->set_color_format(godot::MultiMesh::COLOR_FLOAT);
  shelf_mesh->set_custom_data_format(godot::MultiMesh::CUSTOM_DATA_NONE);
  shelf_mesh->set_transform_format(godot::MultiMesh::TRANSFORM_3D);
  shelf_mesh->set_mesh(room_gen_params->book_mesh);

  int books_per_shelf = room_gen_params->books_per_shelf;
  int num_shelves = room_gen_params->num_shelves;
  float book_spacing = room_gen_params->book_spacing;
  float shelf_spacing = room_gen_params->shelf_spacing;

  shelf_mesh->set_instance_count(books_per_shelf * num_shelves);

  godot::Vector3 book_size = room_gen_params->book_mesh->get_aabb().size;
  float book_stride = book_size.z + book_spacing;

  godot::PoolRealArray data;
  bmp::cpp_int book_index = _make_book_index(room_x, room_y, room_z, shelf, 0);
  for (int i = 0; i < num_shelves; i++) {
    for (int j = 0; j < books_per_shelf; j++) {
      float xoff = 0.0f;
      float yoff = shelf_spacing * i + book_size.y / 2.0f;
      float zoff =
          ((j - (books_per_shelf / 2.0f)) * book_stride + (book_stride / 2.0f));
      // Transform
      //  X
      data.push_back(1.0f);
      data.push_back(0.0f);
      data.push_back(0.0f);
      data.push_back(xoff);
      //  Y
      data.push_back(0.0f);
      data.push_back(1.0f);
      data.push_back(0.0f);
      data.push_back(yoff);
      //  Z
      data.push_back(0.0f);
      data.push_back(0.0f);
      data.push_back(1.0f);
      data.push_back(zoff);

      // Title in custom data
      bmp::cpp_int title_num(book_index);
      _permute_book_index(title_num);
      title_num %= title_mod;
      int curr_size = data.size();
      _pack_num_to_floats(title_num, data);
      // Handle title length less than max capacity
      while (data.size() - curr_size < 4) {
        // Probably not right, want 0 bits, but should get ignored in the shader
        // anyway
        data.append(0.0f);
      }

      book_index += 1;
    }
  }
  shelf_mesh->set_as_bulk_array(data);

  return shelf_mesh;
}

godot::Color BookUtil::get_packed_title_from_index(int room_x, int room_y,
                                                   int room_z, int shelf,
                                                   int book) const {
  bmp::cpp_int title_num =
      _make_book_num(room_x, room_y, room_z, shelf, book) % title_mod;
  return _pack_title_num_to_color(title_num);
}

godot::Ref<BookText> BookUtil::make_book(int room_x, int room_y, int room_z,
                                         int shelf, int book) const {
  godot::Ref<BookText> res = BookText::_new();
  res->full_ind = _make_book_num(room_x, room_y, room_z, shelf, book);
  res->room_x = room_x;
  res->room_y = room_y;
  res->room_z = room_z;
  res->shelf = shelf;
  res->book = book;
  return res;
}

// Get a string representation of a page-worth of characters, starting at the
// 0-indexed page indicated
godot::String BookUtil::get_page(godot::Ref<BookText> book, int page) const {
  int chars_per_page = room_gen_params->chars_per_page;
  // Initialize full of zeros, with one extra to null terminate
  std::vector<wchar_t> buff(chars_per_page + 1);
  godot::String charset = room_gen_params->charset;
  int num_chars = charset.length();
  bmp::cpp_int num =
      (book->full_ind / (title_mod * bmp::pow(page_mod, page))) % page_mod;
  // If not power of 2
  if ((num_chars & (num_chars - 1)) != 0) {
    for (int i = 0; i < chars_per_page && num > 0; i++) {
      buff[i] = (num % num_chars).convert_to<int>();
      num /= num_chars;
    }
  } else {
    // Direct copy charset indices into the buffer with the correct bits per
    // char
    bmp::export_bits(num, buff.begin(), bits_per_char, /*msv_first=*/false);
  }
  // Replace charset index with actual char code
  for (int i = 0; i < chars_per_page; i++) {
    buff[i] = charset[buff[i]];
  }
  godot::String page_text(&buff[0]);
  return page_text;
}

godot::Color BookUtil::get_packed_title(godot::Ref<BookText> book) const {
  return _pack_title_num_to_color(book->full_ind % title_mod);
}
