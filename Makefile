all: clean _build/index.js _build/lib package.json README.md

_build:
	mkdir _build

_build/index.js: _build
	coffee -c -o _build index.coffee

_build/lib: _build
	coffee -c -o _build/lib lib

package.json: _build
	cp package.json _build

README.md: _build
	cp README.md _build

publish:  all
	cd _build && npm publish	

clean:
	rm -rf _build