PREFIX?=/usr/local

OSNAME=${shell uname -s}

build:
	swift build -c release

install: build
	mkdir -p $(PREFIX)/bin
	mv -f .build/release/StickerDownloader .build/release/stickerdl
	cp -f .build/release/stickerdl $(PREFIX)/bin/stickerdl
