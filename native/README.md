# GDNative Lib

Logic involving lots of number crunching happens in a GDNative library that gets linked into the game. https://docs.godotengine.org/en/3.5/tutorials/scripting/gdnative/what_is_gdnative.html

## Dependencies

To build, you need to:
- Run `git submodule update --init --recursive` to check out all the dependency code
- To build for web, install emscripten
  - Debian: `sudo apt install emscripten`
- Install Scons: `python -m pip install scons`


## Building
Use `make` to build everything, `make <platform>` to build a specific platform's library (linux, windows, javascript, or osx).

Or use scons directly: `scons platform=<platform> target=<release or debug>`