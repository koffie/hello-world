[![pdf](https://github.com/gerby-project/hello-world/actions/workflows/example.yml/badge.svg)](https://github.com/gerby-project/hello-world/actions/workflows/example.yml)

This repository documents a minimal working example for using Gerby.

There are two things one can look at

* the plasTeX-only check, see `.github/workflows/example.yml` (which is checked by the badge)
* a full example using the now discontinued Travis, see `.travis.yml`.

For more information, see [Gerby project](https://gerby-project.github.io).

## Running locally with Docker

### Standalone (production-like)

Build the image and run the container, mounting this directory as the project:

```bash
docker build -t gerby-hello-world .
docker run --rm -p 8080:5000 -v "$(pwd):/project" gerby-hello-world
```

The site will be available at http://localhost:8080.

### Development (with live reload)

Use the provided `docker-compose.dev.yml` to mount the local `gerby-website` source tree into the container. Flask runs in debug mode and automatically reloads whenever you edit a Python file in `gerby-website` — no rebuild needed.

```bash
docker compose -f docker-compose.dev.yml up
```

The site will be available at http://localhost:8080.

To rebuild the image (e.g. after changing system dependencies):

```bash
docker compose -f docker-compose.dev.yml up --build
```
