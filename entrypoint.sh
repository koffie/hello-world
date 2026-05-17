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

# point the gerby tools directory at the mounted project so that relative
# paths in configuration.py (PATH, PAUX, TAGS) resolve correctly when
# update.py runs, and the databases land where Flask's symlinks expect them
TOOLS=/app/gerby-website/gerby/tools
ln -sf /project/document      "$TOOLS/document"
ln -sf /project/document.paux "$TOOLS/document.paux"
ln -sf /project/tags          "$TOOLS/tags"

# 1) update tags file with new tags
cd /project
/app/venv-gerby/bin/python3 /app/tagger.py >> /project/tags

# 2) convert to HTML: plastex outputs to document/ relative to CWD (/project)
rm -rf /project/document
/app/venv-plastex/bin/plastex --renderer=Gerby /project/document.tex

# 3) import plasTeX output into database
# run from the tools directory so DATABASE/COMMENTS relative paths land
# at gerby/tools/*.sqlite, which is where Flask's symlinks point
cd "$TOOLS"
/app/venv-gerby/bin/python3 update.py

# 4) serve with Flask
cd /app/gerby-website
FLASK_APP=gerby /app/venv-gerby/bin/python3 -m flask run --host=0.0.0.0
