#!/usr/bin/env bash
set -euo pipefail

# validate required files in the mounted project directory
if [[ ! -f /project/document.tex ]]; then
  echo "ERROR: /project/document.tex not found. Mount your project directory with -v /path/to/project:/project" >&2
  exit 1
fi
if [[ ! -f /project/configuration.py ]]; then
  echo "ERROR: /project/configuration.py not found. Mount your project directory with -v /path/to/project:/project" >&2
  exit 1
fi

# make configuration available to the gerby package
cp /project/configuration.py /app/gerby-website/gerby/configuration.py

# 1) update tags file with new tags
cd /project
/app/venv-gerby/bin/python3 /app/tagger.py >> /project/tags

# 2) convert to HTML: plastex outputs to document/ relative to CWD
cd /project
rm -rf /project/document
/app/venv-plastex/bin/plastex --renderer=Gerby /project/document.tex

# 3) import plasTeX output into database
/app/venv-gerby/bin/python3 /app/gerby-website/gerby/tools/update.py

# 4) serve with Flask
cd /app/gerby-website
FLASK_APP=gerby /app/venv-gerby/bin/python3 -m flask run --host=0.0.0.0
