#!/usr/bin/env bash
set -euo pipefail

# validate required files in the mounted project directory
if [[ ! -f /project/content/tex/document.tex ]]; then
  echo "ERROR: /project/content/tex/document.tex not found. Mount your project directory with -v /path/to/project:/project" >&2
  exit 1
fi
if [[ ! -f /project/content/configuration.py ]]; then
  echo "ERROR: /project/content/configuration.py not found. Mount your project directory with -v /path/to/project:/project" >&2
  exit 1
fi

# make configuration available to the gerby package
cp /project/content/configuration.py /app/gerby-website/gerby/configuration.py

# ensure build directory exists
mkdir -p /project/build

# 1) update tags file with new tags
/app/venv-gerby/bin/python3 /app/tagger.py /project/content/tex/document.tex /project/content/tags >> /project/content/tags

# 2) convert to HTML: run plastex from build/ so output lands in build/document/
#    plastex's Gerby renderer looks for the tags file relative to its working directory
cp /project/content/tags /project/build/tags
cd /project/build
rm -rf /project/build/document
/app/venv-plastex/bin/plastex --renderer=Gerby /project/content/tex/document.tex

# 3) import plasTeX output into database
/app/venv-gerby/bin/python3 /app/gerby-website/gerby/tools/update.py

# 4) serve with Flask
cd /app/gerby-website
FLASK_APP=gerby /app/venv-gerby/bin/python3 -m flask run --host=0.0.0.0
