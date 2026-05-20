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

/app/build.sh

# serve with Flask
cd /app/gerby-website
FLASK_APP=gerby /app/venv-gerby/bin/python3 -m flask run --host=0.0.0.0
