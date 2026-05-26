[![pdf](https://github.com/gerby-project/hello-world/actions/workflows/example.yml/badge.svg)](https://github.com/gerby-project/hello-world/actions/workflows/example.yml)

## What is Gerby?

[Gerby](https://gerby-project.github.io) turns a LaTeX document into a searchable, linkable website. It processes your `.tex` source with [plasTeX](https://github.com/plastex/plastex) and serves the result through a [Flask](https://flask.palletsprojects.com/) web application. Every theorem, lemma, definition, and section gets a short permanent identifier called a **tag** that can be cited and linked to individually.

The [Stacks Project](https://stacks.math.columbia.edu) is a large-scale example of a site built with Gerby.

This repository is a minimal working example to get you up and running.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)

That's it.

## Quick start

```bash
git clone https://github.com/gerby-project/hello-world.git
cd hello-world
docker build -t gerby-hello-world .
docker run --rm -p 8080:5000 -v "$(pwd):/project" gerby-hello-world
```

Open http://localhost:8080. The hello-world document should be live.

To have the site update automatically as you edit your LaTeX source, see [Writing mode (live recompile)](#writing-mode-live-recompile).

## The tag system

Tags are the core concept of Gerby. Every `\label{...}` in your LaTeX source is automatically assigned a short permanent identifier - a four-character tag like `0001`, `0A3F`, etc. These tags are:

- **stable** - once assigned, a tag always points to the same result, even if the document is reorganised or renumbered
- **linkable** - each tag gets its own URL, e.g. `/tag/0001`
- **citable** - readers can reference individual results without worrying about section numbers changing

Tags are stored in `content/tags`, one per line in `tag,label` format. The file is managed by `tagger.py`, which runs automatically on startup and appends new tags for any labels it hasn't seen before. **Never edit `content/tags` by hand** - only add or remove labels in your `.tex` source.

## Getting started with your own document

1. Replace `content/tex/document.tex` with your own LaTeX source.
2. Build and run the container - `tagger.py` will assign tags to all your `\label{}`s on first boot.
3. Edit `content/configuration.py` to set your project title, domain, and contact details.
4. Optionally fill in `content/support` and `content/CONTRIBUTORS` (see [Optional pages](#optional-pages) below).

If you rename the `.tex` file, update the `plastex` call in `entrypoint.sh` and the CI workflow accordingly.

## Directory layout

```
content/
  tex/
    document.tex        # LaTeX source (edit this)
    document-tikz.tex   # TikZ variant
    references.bib      # Optional: BibTeX bibliography
  configuration.py      # Gerby configuration (edit this)
  tags                  # Tag registry (managed by tagger.py)
  support               # Optional: acknowledgements, one bullet point per line
  CONTRIBUTORS          # Optional: contributor names, one per line
build/                  # Generated - gitignored, created at runtime
  document/             # plasTeX HTML output
  document.paux         # plasTeX auxiliary file
  tags.sqlite           # Main content database
  comments.sqlite       # Comments database
```

## Configuration

Edit `content/configuration.py` to set your project title, domain, and other options.

`BUILD_DIR` and `CONTENT_DIR` are absolute paths to the `build/` and `content/` directories. They are pre-set to `/project/build` and `/project/content` for Docker; change them to match your local checkout when running without Docker. All other fields are project identity values shown on the site.

## Optional pages

Two pages are driven by plain-text files you can fill in:

- **`/acknowledgements`** - add one entry per line to `content/support`. Lines starting with `%` are treated as comments and ignored.
- **`/contributors`** - add one name per line to `content/CONTRIBUTORS`. Same comment syntax.

If either file is absent the corresponding page still works, it will just have an empty list.

## Running locally with Docker

`docker-compose.dev.yml` organises services into three profiles. The `.env` file sets `gerby` as the default, so a plain `up` starts the `gerby` profile:

```bash
docker compose up
```

To use a different profile, pass `--profile` explicitly (this overrides `.env`):

| Profile | Command | What it does |
|---------|---------|--------------|
| `plastex` | `docker compose --profile plastex up` | Runs plasTeX once and exits. Output in `build/plastex/`. |
| `gerby` | `docker compose up` | Serves the site at http://localhost:8080 using gerby-plastex. Watches `content/tex/` and rebuilds on change. |
| `gerby-plugin` | `docker compose --profile gerby-plugin up` | Same as `gerby` but uses upstream plasTeX + the standalone `plastex-gerby` plugin. Served at http://localhost:8081. |

Add `--build` to rebuild the image (e.g. after changing system dependencies):

```bash
docker compose up --build
```

### Profile details

#### `plastex`

A lightweight one-shot container that renders the document to static HTML with upstream plasTeX, without Flask or the tag database. Useful for checking plasTeX output in isolation.

#### `gerby`

Two services:

- **`gerby`** - serves the site with Flask in debug mode. Automatically reloads when you edit Python or template files in `gerby-website`.
- **`watcher`** - polls `content/tex/` every 2 seconds and re-runs the full build pipeline (tagger -> plasTeX -> database import) whenever a `.tex` file changes.

Uses [gerby-plastex](https://github.com/koffie/gerby-plastex), a fork of plasTeX with the Gerby renderer bundled in.

#### `gerby-plugin`

Same two-service setup as `gerby` (on port 8081), but uses upstream plasTeX together with the standalone [plastex-gerby-plugin](https://github.com/koffie/plastex-gerby-plugin) instead of the gerby-plastex fork.

## CI

The GitHub Actions workflow in `.github/workflows/example.yml` runs plasTeX on `content/tex/document.tex` to verify the document compiles correctly. The badge above reflects its status.
