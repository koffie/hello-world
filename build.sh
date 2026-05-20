#!/usr/bin/env bash
set -euo pipefail

# make configuration available to the gerby package
cp /project/content/configuration.py /app/gerby-website/gerby/configuration.py

# ensure build directory exists
mkdir -p /project/build

# 1) update tags file with new tags
/app/venv-gerby/bin/python3 /app/tagger.py /project/content/tex/document.tex /project/content/tags >> /project/content/tags

# 2) convert to HTML: run plastex from build/ so output lands in build/document/
#    plastex's Gerby renderer looks for the tags file and any .bib files relative to its working directory
cp /project/content/tags /project/build/tags
cp /project/content/tex/*.bib /project/build/ 2>/dev/null || true
cd /project/build
rm -rf /project/build/document
/app/venv-plastex/bin/plastex --renderer=Gerby /project/content/tex/document.tex

# 3) import plasTeX output into database
/app/venv-gerby/bin/python3 /app/gerby-website/gerby/tools/update.py
