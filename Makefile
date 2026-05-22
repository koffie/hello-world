PLASTEX_REPO ?= https://github.com/plastex/plastex.git
VENV         := .venv-plastex
PYTHON       := $(VENV)/bin/python
PIP          := $(VENV)/bin/pip
PLASTEX      := $(VENV)/bin/plastex

TEX_SRC      := content/tex/document.tex
OUTPUT_DIR   := build/plastex

.PHONY: all plastex clean

all: plastex

$(VENV):
	python3 -m venv $(VENV)
	$(PIP) install --quiet git+$(PLASTEX_REPO)

plastex: $(VENV)
	mkdir -p $(OUTPUT_DIR)
	cd $(OUTPUT_DIR) && ../../$(PLASTEX) --config=../../content/tex/document.cfg ../../$(TEX_SRC)

clean:
	rm -rf $(OUTPUT_DIR) $(VENV)
