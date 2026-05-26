# ── base ──────────────────────────────────────────────────────────────────
FROM python:3.12-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
        dvipng \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m appuser
WORKDIR /app
RUN chown appuser /app

VOLUME /project

# ── plastex ───────────────────────────────────────────────────────────────
FROM base AS plastex

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        bibtex2html \
        dvisvgm \
        ghostscript \
        texlive-latex-extra \
        texlive-pictures \
        texlive-fonts-recommended \
        texlive-bibtex-extra \
    && rm -rf /var/lib/apt/lists/*
USER appuser

ARG PLASTEX_REPO=https://github.com/plastex/plastex.git
ARG PLASTEX_HASH=4fe23e25565a4788f07077076211d21630a81cb0
RUN python3 -m venv /app/venv-plastex && \
    git clone "$PLASTEX_REPO" plastex-src && \
    cd plastex-src && \
    git reset --hard "$PLASTEX_HASH" && \
    /app/venv-plastex/bin/pip install --no-cache-dir . && \
    cd .. && rm -rf plastex-src

COPY --chown=appuser:appuser plastex-entrypoint.sh /app/
RUN chmod +x /app/plastex-entrypoint.sh

ENTRYPOINT ["/app/plastex-entrypoint.sh"]

# ── gerby ─────────────────────────────────────────────────────────────────
FROM base AS gerby

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        pdf2svg \
        texlive-latex-extra \
        texlive-pictures \
        texlive-fonts-recommended \
    && rm -rf /var/lib/apt/lists/*
USER appuser

# create isolated virtual environments
RUN python3 -m venv /app/venv-plastex && \
    python3 -m venv /app/venv-gerby

# Component version pins — keep ARG defaults in sync with versions.env
ARG GERBY_PLASTEX_REPO=https://github.com/koffie/gerby-plastex.git
ARG GERBY_PLASTEX_HASH=0719772bae931d356de012ca1518cc3fb8ef34f0
RUN git clone "$GERBY_PLASTEX_REPO" plastex && \
    cd plastex && \
    git reset --hard "$GERBY_PLASTEX_HASH" && \
    /app/venv-plastex/bin/pip install --no-cache-dir . && \
    /app/venv-plastex/bin/pip install --no-cache-dir unidecode beautifulsoup4 && \
    /app/venv-gerby/bin/pip install --no-cache-dir . && \
    cd .. && rm -rf plastex

ARG GERBY_REPO=https://github.com/koffie/gerby-website.git
ARG GERBY_HASH=79383b8798f6c8dddfb9bf5e043d539dc9716c7f
ARG BONSAI_REPO=https://github.com/aexmachina/jquery-bonsai
ARG BONSAI_HASH=a7f2e280e374ce649b5b543af0102a5ed107b854
RUN git clone "$GERBY_REPO" gerby-website && \
    cd gerby-website && \
    git reset --hard "$GERBY_HASH" && \
    cd gerby/static && \
    git clone "$BONSAI_REPO" jquery-bonsai && \
    cd jquery-bonsai && \
    git reset --hard "$BONSAI_HASH" && \
    cd .. && \
    cp jquery-bonsai/jquery.bonsai.css css/ && \
    rm -rf jquery-bonsai && \
    cd ../.. && \
    . /app/venv-gerby/bin/activate && \
    pip install --no-cache-dir poetry && \
    poetry install --only main && \
    cd ..

COPY --chown=appuser:appuser tagger.py build.sh entrypoint.sh entrypoint-watch.sh /app/
RUN chmod +x /app/build.sh /app/entrypoint.sh /app/entrypoint-watch.sh

ENV PYTHONPATH=/app/gerby-website
ENV BUILD_DIR=/project/build/gerby-plastex

# Users mount their project directory here
VOLUME /project

EXPOSE 5000

ENTRYPOINT ["/app/entrypoint.sh"]

# ── gerby-plugin ──────────────────────────────────────────────────────────
# Like gerby, but uses upstream plasTeX + the standalone plastex-gerby-plugin
# instead of the koffie/plastex fork that bundles the Gerby renderer.
FROM base AS gerby-plugin

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        pdf2svg \
        texlive-latex-extra \
        texlive-pictures \
        texlive-fonts-recommended \
    && rm -rf /var/lib/apt/lists/*
USER appuser

# create isolated virtual environments
RUN python3 -m venv /app/venv-plastex && \
    python3 -m venv /app/venv-gerby

# Component version pins — keep ARG defaults in sync with versions.env
ARG PLASTEX_REPO=https://github.com/plastex/plastex.git
ARG PLASTEX_HASH=4fe23e25565a4788f07077076211d21630a81cb0
RUN git clone "$PLASTEX_REPO" plastex && \
    cd plastex && \
    git reset --hard "$PLASTEX_HASH" && \
    /app/venv-plastex/bin/pip install --no-cache-dir . && \
    /app/venv-plastex/bin/pip install --no-cache-dir unidecode beautifulsoup4 && \
    /app/venv-gerby/bin/pip install --no-cache-dir . && \
    cd .. && rm -rf plastex

ARG PLASTEX_GERBY_PLUGIN_REPO=https://github.com/koffie/plastex-gerby-plugin.git
ARG PLASTEX_GERBY_PLUGIN_HASH=4a947cd1d31a0a5e936f167cb7c909e28e5a4a9d
RUN git clone "$PLASTEX_GERBY_PLUGIN_REPO" plastex-gerby-plugin && \
    cd plastex-gerby-plugin && \
    git reset --hard "$PLASTEX_GERBY_PLUGIN_HASH" && \
    /app/venv-plastex/bin/pip install --no-cache-dir . && \
    cd .. && rm -rf plastex-gerby-plugin

ARG GERBY_REPO=https://github.com/koffie/gerby-website.git
ARG GERBY_HASH=79383b8798f6c8dddfb9bf5e043d539dc9716c7f
ARG BONSAI_REPO=https://github.com/aexmachina/jquery-bonsai
ARG BONSAI_HASH=a7f2e280e374ce649b5b543af0102a5ed107b854
RUN git clone "$GERBY_REPO" gerby-website && \
    cd gerby-website && \
    git reset --hard "$GERBY_HASH" && \
    cd gerby/static && \
    git clone "$BONSAI_REPO" jquery-bonsai && \
    cd jquery-bonsai && \
    git reset --hard "$BONSAI_HASH" && \
    cd .. && \
    cp jquery-bonsai/jquery.bonsai.css css/ && \
    rm -rf jquery-bonsai && \
    cd ../.. && \
    . /app/venv-gerby/bin/activate && \
    pip install --no-cache-dir poetry && \
    poetry install --only main && \
    cd ..

COPY --chown=appuser:appuser tagger.py build.sh entrypoint.sh entrypoint-watch.sh /app/
RUN chmod +x /app/build.sh /app/entrypoint.sh /app/entrypoint-watch.sh

ENV PYTHONPATH=/app/gerby-website
ENV PLASTEX_PLUGINS=plastex_gerby
ENV BUILD_DIR=/project/build/gerby-plugin

VOLUME /project

EXPOSE 5000

ENTRYPOINT ["/app/entrypoint.sh"]
