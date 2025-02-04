#include "book_util.hpp"
#include "GodotGlobal.hpp"
#include "String.hpp"
#include "book_iter.hpp"
#include "util.hpp"

#include <AABB.hpp>
#include <Array.hpp>
#include <RandomNumberGenerator.hpp>
#include <boost/integer/mod_inverse.hpp>
#include <boost/random.hpp>
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
  godot::register_method("make_shelf_multimeshes",
                         &BookUtil::make_shelf_multimeshes);
  godot::register_method("make_shelf_multimesh",
                         &BookUtil::make_shelf_multimesh);
  godot::register_method("get_packed_title_from_index",
                         &BookUtil::get_packed_title_from_index);
  godot::register_method("make_book", &BookUtil::make_book);
  godot::register_method("get_page", &BookUtil::get_page);
  godot::register_method("get_packed_title", &BookUtil::get_packed_title);
  godot::register_method("get_title", &BookUtil::get_title);
  godot::register_method("find_text", &BookUtil::find_text);
}

void BookUtil::_init() {
  // Clear precomputed values
  books_per_room = 0;
  chars_per_book = 0;
  bits_per_char = 0;
  charset_pow2 = false;
  num_books = 0;
  num_books_bit_mask = 0;
  num_books_bits = 0;
  // Mods to 1 to avoid mod by 0
  page_mod = 1;
  page_bit_mask = 0;
  title_mod = 1;
  title_bit_mask = 0;
  y_diff = 0;
  z_diff = 0;
}

void BookUtil::_recompute_big_vals() {
  chars_per_book =
      room_gen_params->title_chars +
      (room_gen_params->chars_per_page * room_gen_params->pages_per_book);
  books_per_room =
      room_gen_params->books_per_shelf * room_gen_params->num_shelves * 4;
  unsigned int charset_len = room_gen_params->charset.length();
  charset_pow2 = (charset_len & (charset_len - 1)) == 0;
  // Add an extra bit on if not an even power of 2
  bits_per_char = charset_pow2 ? 0 : 1;
  while (charset_len >>= 1) {
    bits_per_char++;
  }
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
  // Bit masks are only valid if title_mod is a power of 2
  num_books_bit_mask = num_books - 1;
  page_mod = bmp::pow(bmp_num_chars, room_gen_params->chars_per_page);
  page_bit_mask = page_mod - 1;
  title_mod = bmp::pow(bmp_num_chars, room_gen_params->title_chars);
  title_bit_mask = title_mod - 1;
  // Make an almost cube, |x| = |y| = floor(chars_per_book/3), |z| =
  // chars_per_book - 2|x| where |x| is length of hallways along the x axis
  // before wrapping to the next hallway. One unit along x or y is actually two
  // rooms including the vestibule, z is one unit = one floor
  //
  // Note this in units of books not rooms. books_per_room needs to be a divisor
  // of all of these or the hallway wrap will be in the middle of a room and
  // books will be in different positions between wraps. Not that anyone will
  // ever see that
  // TODO: Subtract off bit to avoid a bunch of trailing zeros? z-axis is
  // currently not shuffling much. Every other level is mostly identical, only
  // last few pages are different.
  y_diff = bmp::pow(bmp_num_chars, chars_per_book / 3);
  z_diff = bmp::pow(y_diff, 2);
}

void BookUtil::_apply_multiplier(bmp::cpp_int &val) const {
  // Do N*A mod M, where M is the number of books. Invertible and bijective as
  // long as gcd(A,M) is 1, i.e. they share no divisors. If the charset has a
  // power of 2 length, A only needs to be odd.
  val *= room_gen_params->shuffle_multiplier;
  // This kind of branch should be a non-issue for performance because it will
  // always pick the same branch throughout execution. Branch prediction should
  // catch on to that and avoid any issues.
  if (charset_pow2) {
    val &= num_books_bit_mask;
  } else {
    val %= num_books;
  }
}

void BookUtil::_shuffle_bits(bmp::cpp_int &val) const {
  // Skip shuffling if shift is 0, cheating to avoid having to fix tests to
  // expect the shuffling
  if (room_gen_params->shift1 > 0) {
    // Top bits are fairly well scrambled by the multiplier, but bottom bits get
    // missed when moving between rooms along y and z axes. XORing the top most
    // bits onto the bottom bits will mix them up a bit more, and as
    // long as the shifts are greater than half the number of bits in the range
    // of book numbers this is reversible by applying the same XOR shifts in
    // reverse order. Could also shuffle the lower bits into the top bits but
    // it's tricky to do that efficiently with the arbitrary-precision numbers
    // because they don't get cut off during a shift left.
    val ^= val >> room_gen_params->shift1;
  }
}

bmp::cpp_int BookUtil::_make_book_num(int room_x, int room_y, int room_z,
                                      int shelf, int book) const {
  bmp::cpp_int val = _make_book_index(room_x, room_y, room_z, shelf, book);
  _apply_multiplier(val);
  _shuffle_bits(val);
  return val;
}

bmp::cpp_int BookUtil::_make_book_index(int room_x, int room_y, int room_z,
                                        int shelf, int book) const {
  // From room index to gallery room index
  int gallery_room_x = (room_x + 1) / 2;
  // TODO: Also convert y? Does increment by 2 but I remember specifically not doing that.

  return origin +
         (gallery_room_x * books_per_room + y_diff * room_y + z_diff * room_z) +
         (shelf * (books_per_room / 4)) + book;
}

const uint32_t MANTISSA_MASK = (1 << MANTISSA_BITS) - 1;

void BookUtil::_pack_num_to_floats(const bmp::cpp_int &num,
                                   godot::PoolRealArray &buff) const {
  int num_chars = room_gen_params->charset.length();
  // If not power of 2
  if (!charset_pow2) {
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
godot::String BookUtil::_num_to_text(const cpp_int &num,
                                     unsigned int length) const {
  // Initialize full of zeros, with one extra to null terminate
  std::vector<wchar_t> buff(length + 1);
  godot::String charset = room_gen_params->charset;
  int num_chars = charset.length();
  if (!charset_pow2) {
    cpp_int num_copy(num);
    for (int i = 0; i < length; i++) {
      buff[i] = (num_copy % num_chars).convert_to<int>();
      num_copy /= num_chars;
    }
  } else {
    // Direct copy charset indices into the buffer with the correct bits per
    // char
    bmp::export_bits(num, buff.begin(), bits_per_char,
                     /*msv_first=*/false);
  }
  // Replace charset index with actual char code
  for (int i = 0; i < length; i++) {
    buff[i] = charset[buff[i]];
  }
  godot::String page_text(&buff[0]);
  return page_text;
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
  cpp_int range_max = (num_books / books_per_room) - 1;
  boost::random::uniform_int_distribution<bmp::cpp_int> dist(bmp::cpp_int(0),
                                                             range_max);
  RandWrapper gen(seed);
  origin = dist(gen);
  origin *= books_per_room;
}

void BookUtil::set_room_gen_params(godot::Ref<RoomGenParams> params) {
  room_gen_params = params;
  if (room_gen_params.is_null()) {
    _init();
    return;
  }
  _recompute_big_vals();
}

godot::Array BookUtil::make_shelf_multimeshes(int room_x, int room_y,
                                              int room_z) const {
  godot::Array meshes;
  int books_per_shelf = room_gen_params->books_per_shelf;
  int num_shelves = room_gen_params->num_shelves;
  int num_chars = room_gen_params->charset.length();
  float book_spacing = room_gen_params->book_spacing;
  float shelf_spacing = room_gen_params->shelf_spacing;

  godot::Vector3 book_size = room_gen_params->book_mesh->get_aabb().size;
  float book_stride = book_size.z + book_spacing;

  BookIter iter(*this, room_x, room_y, room_z);
  for (int shelf = 0; shelf < 4; shelf++) {

    godot::Ref<godot::MultiMesh> shelf_mesh = godot::MultiMesh::_new();

    shelf_mesh->set_color_format(godot::MultiMesh::COLOR_FLOAT);
    shelf_mesh->set_custom_data_format(godot::MultiMesh::CUSTOM_DATA_NONE);
    shelf_mesh->set_transform_format(godot::MultiMesh::TRANSFORM_3D);
    shelf_mesh->set_mesh(room_gen_params->book_mesh);

    shelf_mesh->set_instance_count(books_per_shelf * num_shelves);

    godot::PoolRealArray data;
    for (int i = 0; i < num_shelves; i++) {
      for (int j = 0; j < books_per_shelf; j++) {
        float xoff = 0.0f;
        float yoff = shelf_spacing * i + book_size.y / 2.0f;
        float zoff = ((j - (books_per_shelf / 2.0f)) * book_stride +
                      (book_stride / 2.0f));
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

        // Title in color data
        bmp::cpp_int title_num = iter.next().value();
        if (charset_pow2) {
          title_num &= title_bit_mask;
        } else {
          title_num %= title_mod;
        }
        int curr_size = data.size();
        _pack_num_to_floats(title_num, data);
        // Handle title length less than max capacity
        while (data.size() - curr_size < 4) {
          data.append(0.0f);
        }
      }
    }
    shelf_mesh->set_as_bulk_array(data);
    meshes.append(shelf_mesh);
  }

  return meshes;
}

godot::Ref<godot::MultiMesh> BookUtil::make_shelf_multimesh(int room_x,
                                                            int room_y,
                                                            int room_z,
                                                            int shelf) const {
  godot::Array meshes = make_shelf_multimeshes(room_x, room_y, room_z);
  return meshes[shelf];
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
  res->full_text = _make_book_num(room_x, room_y, room_z, shelf, book);
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
  bmp::cpp_int num;
  if (!charset_pow2) {
    num = (book->full_text / (title_mod * bmp::pow(page_mod, page))) % page_mod;
  } else {
    num = (book->full_text >>
           (bits_per_char * (room_gen_params->title_chars +
                             (room_gen_params->chars_per_page * page)))) &
          page_bit_mask;
  }
  return _num_to_text(num, room_gen_params->chars_per_page);
}

godot::Color BookUtil::get_packed_title(godot::Ref<BookText> book) const {
  return _pack_title_num_to_color(book->full_text % title_mod);
}

godot::String BookUtil::get_title(godot::Ref<BookText> book) const {
  bmp::cpp_int num;
  if (!charset_pow2) {
    num = (book->full_text % title_mod);
  } else {
    num = (book->full_text & title_bit_mask);
  }
  return _num_to_text(num, room_gen_params->title_chars);
}

godot::String BookUtil::get_full_text(godot::Ref<BookText> book) const {
  return get_full_text(book->full_text);
}

godot::String BookUtil::get_full_text(const bmp::cpp_int &val) const {
  return _num_to_text(val, chars_per_book);
}

godot::PoolByteArray BookUtil::find_text(godot::String text) const {
  cpp_int val;
  int num_chars = room_gen_params->charset.length();
  for (int i = text.length() - 1; i >= 0; i--) {
    godot::String chr = text.substr(i, 1);
    int char_ind = room_gen_params->charset.find(chr);
    godot::Godot::print("Char: {0}, ind: {1}", chr, char_ind);
    val *= num_chars;
    val += char_ind;
  }
  cpp_int val_orig(val);
  godot::Godot::print("Target num: {0}",
                      godot::String(val.str().substr(0, 100).c_str()));

  val ^= val >> room_gen_params->shift1;
  val *= boost::integer::mod_inverse(room_gen_params->shuffle_multiplier,
                                     num_books);
  if (charset_pow2) {
    val &= num_books_bit_mask;
  } else {
    val %= num_books;
  }
  godot::Godot::print("Inverted num: {0}",
                      godot::String(val.str().substr(0, 100).c_str()));

  cpp_int val2(val);
  _apply_multiplier(val2);
  _shuffle_bits(val2);

  godot::Godot::print("Reinverted num: {0}",
                      godot::String(val2.str().substr(0, 100).c_str()));

  int books_per_shelf =
      room_gen_params->books_per_shelf * room_gen_params->num_shelves;
  int book_ind = (val % books_per_shelf).convert_to<int>();
  int shelf_ind = ((val / books_per_shelf) % 4).convert_to<int>();
  godot::Godot::print("Reinverted matches: {0}, Shelf: {1}, Book: {2}",
                      val_orig == val2, shelf_ind, book_ind);

  // Round down to nearest room
  val /= books_per_room;
  val *= books_per_room;

  godot::PoolByteArray res;
  PoolByteArrayWrapper wrapped(res);
  bmp::export_bits(val, std::back_inserter(wrapped), 8);
  return res;
}
