#include "book_search.hpp"

#include <Godot.hpp>
#include <memory>

#include "book_util.hpp"
#include "room_gen_params.hpp"

namespace bmp = boost::multiprecision;

constexpr int SEARCH_AHEAD = 10;

void BookSearchResult::_register_methods() {
  godot::register_property("title", &BookSearchResult::title, godot::String());
  godot::register_property("result_page", &BookSearchResult::result_page, 0);
  godot::register_property("text", &BookSearchResult::text,
                           godot::Ref<BookText>());
}

void BookSearchResult::_init() {}

void BookSearch::_register_methods() {
  godot::register_method("set_book_util", &BookSearch::set_book_util);
  godot::register_method("set_query", &BookSearch::set_query);
  godot::register_method("set_location", &BookSearch::set_location);
  godot::register_method("get_page", &BookSearch::get_page);
  godot::register_method("get_num_searched", &BookSearch::get_num_searched);
  godot::register_method("get_num_matches", &BookSearch::get_num_matches);
  godot::register_method("poll_search", &BookSearch::poll_search);
}

void BookSearch::_init() {}

void BookSearch::set_book_util(godot::Ref<BookUtil> book_util) {
  this->book_util = book_util;
}

void BookSearch::set_query(godot::String search_query) {
  max_request = 0;
  num_searched = 0;
  results.clear();
  query = search_query;
}

void BookSearch::set_location(int x, int y, int z) {
  room_iter = std::make_unique<RoomIter>(x, y, z);
  Room room = room_iter->next();
  iter = std::make_unique<BookIter>(**book_util, room.x, room.y, room.z);
}

godot::Array BookSearch::get_page(int page, int page_size) {
  godot::Array result;
  int start = page * page_size;
  int end = start + page_size;

  if (end > max_request) {
    max_request = end;
  }

  end = end < results.size() ? end : results.size();
  for (int i = start; i < end; i++) {
    result.append(results.at(i));
  }
  return result;
}

int BookSearch::get_num_searched() { return num_searched; }

int BookSearch::get_num_matches() { return results.size(); }

void BookSearch::poll_search(int poll_size, int search_ahead) {
  if (book_util.is_null()) {
    godot::Godot::print_error("Book util reference must not be null",
                              "poll_search", __FILE__, __LINE__);
    return;
  }
  if (query.empty()) {
    godot::Godot::print_error("Search query must be set and non-empty",
                              "poll_search", __FILE__, __LINE__);
    return;
  }
  if (!iter || !room_iter) {
    godot::Godot::print_error("Location must be set before polling",
                              "poll_search", __FILE__, __LINE__);
    return;
  }

  godot::Ref<RoomGenParams> room_gen_params = book_util->get_room_gen_params();

  int limit = num_searched + poll_size;
  while (num_searched < limit && results.size() < max_request + search_ahead) {
    std::optional<bmp::cpp_int> book = iter->next();
    if (!book.has_value()) {
      Room next_room = room_iter->next();
      iter = std::make_unique<BookIter>(**book_util, next_room.x, next_room.y,
                                        next_room.z);
      book = iter->next();
    }
    godot::String text = book_util->get_full_text(*book);

    int found_ind = text.find(query);

    if (found_ind != -1) {
      Room room = room_iter->current();
      godot::Ref<BookText> book_text = BookText::_new();
      book_text->full_text = *book;
      book_text->room_x = room.x;
      book_text->room_y = room.y;
      book_text->room_z = room.z;
      book_text->shelf = iter->get_shelf();
      book_text->book = iter->get_book();

      int result_offset = found_ind;
      int result_page = (result_offset - room_gen_params->title_chars) /
                        room_gen_params->chars_per_page;
      if (result_offset < room_gen_params->title_chars) {
        result_page = -1;
      }

      godot::Ref<BookSearchResult> result = BookSearchResult::_new();
      result->title = book_util->get_title(book_text);
      result->result_page = result_page;
      result->text = book_text;
      results.push_back(result);
    }
    num_searched += 1;
  }
}