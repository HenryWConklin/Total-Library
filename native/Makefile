.PHONY: all src windows linux

all: bin/javascript/liblobutil.wasm windows linux

srcfiles := $(wildcard src/*.hpp src/*.cpp)
src: $(srcfiles)

windows:
	scons platform=windows target=release -j 4

linux:
	scons platform=linux target=release -j 4

bin/javascript/liblobutil.wasm: src
	cd godot-cpp && scons platform=javascript target=release -j 4
	mkdir -p bin/javascript
	em++ -o bin/javascript/liblobutil.wasm \
		-O3 \
		-s SIDE_MODULE=1 \
		-s ASSERTIONS=1 \
		src/*.cpp \
		godot-cpp/bin/libgodot-cpp.javascript.release.wasm.a \
		-Igodot-cpp/include \
		-Igodot-cpp/include/core \
		-Igodot-cpp/include/gen \
		-Igodot-cpp/include/gen \
		-Igodot-cpp/godot-headers \
		-Ilib/boost
