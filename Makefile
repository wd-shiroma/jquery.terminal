VERSION=1.23.1
SED=sed
CD=cd
NPM=npm
CP=cp
RM=rm
CAT=cat
DATE=`date -uR`
GIT=git
BRANCH=`git branch | grep '^*' | sed 's/* //'`

ifdef SYSTEMROOT
  UGLIFY=.\node_modules\.bin\uglifyjs
  JSONLINT=.\node_modules\.bin\jsonlint
  JEST=.\node_modules\.bin\jest
  CSSNANO=node .\scripts\cssnano.js
  ESLINT=.\node_modules\.bin\eslint
  TSC=.\node_modules\.bin\tsc
else
  UGLIFY=./node_modules/.bin/uglifyjs
  JSONLINT=./node_modules/.bin/jsonlint
  JEST=./node_modules/.bin/jest
  CSSNANO=node ./scripts/cssnano.js
  ESLINT=./node_modules/.bin/eslint
  TSC=./node_modules/.bin/tsc
endif
SPEC_CHECKSUM=`md5sum __tests__/terminalSpec.js | cut -d' ' -f 1`
COMMIT=`git log -n 1 | grep commit | sed 's/commit //'`
URL=`git config --get remote.origin.url`
skip_re="[xfi]it\\(|[fdx]describe\\("

.PHONY: coverage test coveralls lint.src eslint skipped_tests jsonlint publish lint tscheck

ALL: Makefile .$(VERSION) terminal.jquery.json bower.json package.json js/jquery.terminal-$(VERSION).js js/jquery.terminal.js js/jquery.terminal-$(VERSION).min.js js/jquery.terminal.min.js js/jquery.terminal.min.js.map css/jquery.terminal-$(VERSION).css css/jquery.terminal-$(VERSION).min.css css/jquery.terminal.min.css css/jquery.terminal.min.css.map css/jquery.terminal.css README.md import.html js/terminal.widget.js www/Makefile

bower.json: templates/bower.in .$(VERSION)
	$(SED) -e "s/{{VER}}/$(VERSION)/g" templates/bower.in > bower.json

package.json: templates/package.in .$(VERSION)
	$(SED) -e "s/{{VER}}/$(VERSION)/g" templates/package.in > package.json

js/jquery.terminal-$(VERSION).js: js/jquery.terminal-src.js .$(VERSION)
	$(GIT) branch | grep '* devel' > /dev/null && $(SED) -e "s/{{VER}}/DEV/g" -e "s/{{DATE}}/$(DATE)/g" js/jquery.terminal-src.js > js/jquery.terminal-$(VERSION).js || $(SED) -e "s/{{VER}}/$(VERSION)/g" -e "s/{{DATE}}/$(DATE)/g" js/jquery.terminal-src.js > js/jquery.terminal-$(VERSION).js

js/jquery.terminal.js: js/jquery.terminal-$(VERSION).js
	$(CP) js/jquery.terminal-$(VERSION).js js/jquery.terminal.js

js/jquery.terminal-$(VERSION).min.js: js/jquery.terminal.min.js
	$(CP) js/jquery.terminal.min.js js/jquery.terminal-$(VERSION).min.js

js/jquery.terminal.min.js js/jquery.terminal.min.js.map: js/jquery.terminal-$(VERSION).js
	$(UGLIFY) -o js/jquery.terminal.min.js --comments --mangle --source-map "includeSources,url='jquery.terminal.min.js.map'" -- js/jquery.terminal.js

css/jquery.terminal-$(VERSION).css: css/jquery.terminal-src.css .$(VERSION)
	$(GIT) branch | grep '* devel' > /dev/null && $(SED) -e "s/{{VER}}/DEV/g" -e "s/{{DATE}}/$(DATE)/g" css/jquery.terminal-src.css > css/jquery.terminal-$(VERSION).css || $(SED) -e "s/{{VER}}/$(VERSION)/g" -e "s/{{DATE}}/$(DATE)/g" css/jquery.terminal-src.css > css/jquery.terminal-$(VERSION).css

css/jquery.terminal.css: css/jquery.terminal-$(VERSION).css .$(VERSION)
	$(CP) css/jquery.terminal-$(VERSION).css css/jquery.terminal.css

css/jquery.terminal.min.css css/jquery.terminal.min.css.map: css/jquery.terminal.css
	$(CSSNANO) css/jquery.terminal.css css/jquery.terminal.min.css

css/jquery.terminal-$(VERSION).min.css: css/jquery.terminal.min.css
	$(CP) css/jquery.terminal.min.css css/jquery.terminal-$(VERSION).min.css

README.md: templates/README.in .$(VERSION) __tests__/terminalSpec.js
	$(GIT) branch | grep '* devel' > /dev/null && $(SED) -e "s/{{VER}}/DEV/g" -e \
	"s/{{BRANCH}}/$(BRANCH)/g" -e "s/{{CHECKSUM}}/$(SPEC_CHECKSUM)/" \
	-e "s/{{COMMIT}}/$(COMMIT)/g" < templates/README.in > README.md || $(SED) -e \
	"s/{{VER}}/$(VERSION)/g" -e "s/{{BRANCH}}/$(BRANCH)/g" -e \
	"s/{{CHECKSUM}}/$(SPEC_CHECKSUM)/" -e "s/{{COMMIT}}/$(COMMIT)/g" < templates/README.in > README.md

.$(VERSION): Makefile
	touch .$(VERSION)

Makefile: templates/Makefile.in
	$(SED) -e "s/{{VER""SION}}/"$(VERSION)"/" templates/Makefile.in > Makefile

import.html: templates/import.in
	$(SED) -e "s/{{BRANCH}}/$(BRANCH)/g" templates/import.in > import.html

js/terminal.widget.js: js/terminal.widget.in
	$(GIT) branch | grep '* devel' > /dev/null || $(SED) -e "s/{{VER}}/$(VERSION)/g" js/terminal.widget.in > js/terminal.widget.js

terminal.jquery.json: manifest .$(VERSION)
	$(SED) -e "s/{{VER}}/$(VERSION)/g" manifest > terminal.jquery.json

www/Makefile: $(wildcard www/Makefile.in) Makefile .$(VERSION)
	@test "$(BRANCH)" = "master" -a -d www && $(SED) -e "s/{{VER""SION}}/$(VERSION)/g" www/Makefile.in > www/Makefile || true

test:
	$(JEST) --coverage

coveralls:
	$(CAT) ./coverage/lcov.info | ./node_modules/coveralls/bin/coveralls.js

lint.src:
	$(ESLINT) js/jquery.terminal-src.js

eslint:
	$(ESLINT) js/jquery.terminal-src.js
	$(ESLINT) js/dterm.js
	$(ESLINT) js/xml_formatting.js
	$(ESLINT) js/unix_formatting.js
	$(ESLINT) js/prims.js
	$(ESLINT) js/less.js

skipped_tests:
	@! grep -E $(skip_re) __tests__/terminalSpec.js

tscheck:
	$(TSC) --noEmit --project tsconfig.json

jsonlint: package.json bower.json
	$(JSONLINT) package.json > /dev/null
	$(JSONLINT) bower.json > /dev/null

publish:
	$(GIT) clone $(URL) --depth 1 npm
	$(CD) npm && $(NPM) publish
	$(RM) -rf npm

lint: eslint jsonlint
