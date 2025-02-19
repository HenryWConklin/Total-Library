.PHONY: all src windows linux javascript mac

all: windows linux javascript

windows:
	scons platform=windows target=release -j 4

linux:
	scons platform=linux target=release -j 4

javascript:
	scons platform=javascript target=release -j 4

# Needs to be built on a mac
mac:
	scons platform=osx target=release -j 4
