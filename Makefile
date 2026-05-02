ZOLA_VERSION ?= 0.22.1
ZOLA_BIN ?= ./.bin/zola
ZOLA_DIR := $(patsubst %/,%,$(dir $(ZOLA_BIN)))

.PHONY: dev build test lint clean install-zola zola-ready

dev: zola-ready
	$(ZOLA_BIN) serve --drafts

build: zola-ready
	$(ZOLA_BIN) build

test: lint

lint: zola-ready
	$(ZOLA_BIN) check

clean:
	rm -rf public

install-zola:
	scripts/install-zola.sh "$(ZOLA_VERSION)" "$(ZOLA_DIR)"

zola-ready:
	scripts/install-zola.sh "$(ZOLA_VERSION)" "$(ZOLA_DIR)"
