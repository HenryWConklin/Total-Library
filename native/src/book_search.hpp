#ifndef BOOK_SEARCH_H
#define BOOK_SEARCH_H

#include <Godot.hpp>
#include <cstdint>
#include <memory>

#include "book_iter.hpp"
#include "book_text.hpp"
#include "book_util.hpp"
#include "room_iter.hpp"

class BookSearchResult : public godot::Reference {
  GODOT_CLASS(BookSearchResult, godot::Reference)

public:
  static void _register_methods();
  void _init();

  godot::String title;
  int result_page;
  godot::Ref<BookText> text;
};

class BookSearch : public godot::Reference {
  GODOT_CLASS(BookSearch, godot::Reference)
public:
  static void _register_methods();
  void _init();

  void set_book_util(godot::Ref<BookUtil> book_util);
  // Starts a search for the given substring.
  void set_query(godot::String search_query);
  // Sets the centerpoint for the search to the given room.
  void set_location(int x, int y, int z);
  // Returns one page of results as BookSearchResults.
  // May return fewer results than page_size.
  godot::Array get_page(int page, int page_size);
  // Searches a few more books for matches, adds any matches to results.
  void poll_search(int poll_size, int search_ahead);
  int get_num_searched();
  int get_num_matches();

private:
  godot::String query;
  godot::Ref<BookUtil> book_util;
  std::vector<godot::Ref<BookSearchResult>> results;
  std::unique_ptr<BookIter> iter;
  std::unique_ptr<RoomIter> room_iter;
  int max_request;
  int num_searched;
};

#endif