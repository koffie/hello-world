#!/usr/bin/env bash
set -euo pipefail

TEX=/project/content/tex/document.tex
TEX_DIR=/project/content/tex
OUT=/project/build/plastex

if [[ ! -f "$TEX" ]]; then
  echo "ERROR: $TEX not found. Mount your project with -v /path/to/project:/project" >&2
  exit 1
fi

mkdir -p "$OUT"
cd "$OUT"

cp "$TEX_DIR"/*.bib . 2>/dev/null || true

# Generate .bbl
BIBINPUTS="$TEX_DIR:" latex "$TEX"
BIBINPUTS="$TEX_DIR:" bibtex document

# Render to HTML
/app/venv-plastex/bin/plastex --config="$TEX_DIR/document.cfg" "$TEX"
