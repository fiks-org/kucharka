.PHONY: html pdf all

all: html pdf

html: build/fiks-html/index.html

pdf: build/fiks-pdf/fiksarka.pdf

build/fiks-html/index.html: src/*.woo
	./build-html.sh

build/fiks-pdf/fiksarka.pdf: src/*.woo
	./build-pdf.sh
