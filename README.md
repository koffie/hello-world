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

## The tag system

Tags are the core concept of Gerby. Every `\label{...}` in your LaTeX source is automatically assigned a short permanent identifier — a four-character tag like `0001`, `0A3F`, etc. These tags are:

- **stable** — once assigned, a tag always points to the same result, even if the document is reorganised or renumbered
- **linkable** — each tag gets its own URL, e.g. `/tag/0001`
- **citable** — readers can reference individual results without worrying about section numbers changing

Tags are stored in `content/tags`, one per line in `tag,label` format. The file is managed by `tagger.py`, which runs automatically on startup and appends new tags for any labels it hasn't seen before. **Never edit `content/tags` by hand** — only add or remove labels in your `.tex` source.

## Getting started with your own document

1. Replace `content/tex/document.tex` with your own LaTeX source.
2. Build and run the container — `tagger.py` will assign tags to all your `\label{}`s on first boot.
3. Edit `content/configuration.py` to set your project title, domain, and contact details.
4. Optionally fill in `content/support` and `CONTRIBUTORS` (see [Optional pages](#optional-pages) below).

If you rename the `.tex` file, update the `plastex` call in `entrypoint.sh` and the CI workflow accordingly.

## Directory layout

```
content/
  tex/
    document.tex        # LaTeX source (edit this)
    document-tikz.tex   # TikZ variant
  configuration.py      # Gerby configuration (edit this)
  tags                  # Tag registry (managed by tagger.py)
  support               # Optional: acknowledgements bullet points
CONTRIBUTORS            # Optional: contributor names, one per line
build/                  # Generated — gitignored, created at runtime
  document/             # plasTeX HTML output
  document.paux         # plasTeX auxiliary file
  hello-world.sqlite    # Main content database
  comments.sqlite       # Comments database
```

## Configuration

Edit `content/configuration.py` to set your project title, domain, and other options. The paths in that file are pre-configured for the Docker setup and should not need changing.

## Optional pages

Two pages are driven by plain-text files you can fill in:

- **`/acknowledgements`** — add one entry per line to `content/support`. Lines starting with `%` are treated as comments and ignored.
- **`/contributors`** — add one name per line to `CONTRIBUTORS`. Same comment syntax.

If either file is absent the corresponding page still works, it will just have an empty list.

## Running locally with Docker

### Standalone (production-like)

```bash
docker build -t gerby-hello-world .
docker run --rm -p 8080:5000 -v "$(pwd):/project" gerby-hello-world
```

The site will be available at http://localhost:8080.

### Development (with live reload)

Uses the provided `docker-compose.dev.yml` to mount a local `gerby-website` source tree into the container. Flask runs in debug mode and reloads automatically when you edit Python files — no rebuild needed.

```bash
docker compose -f docker-compose.dev.yml up
```

To rebuild the image (e.g. after changing system dependencies):

```bash
docker compose -f docker-compose.dev.yml up --build
```

## CI

The GitHub Actions workflow in `.github/workflows/example.yml` runs plasTeX on `content/tex/document.tex` to verify the document compiles correctly. The badge above reflects its status.
