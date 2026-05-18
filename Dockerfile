FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        dvipng \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m appuser

WORKDIR /app

# create isolated virtual environments
RUN python3 -m venv /app/venv-plastex && \
    python3 -m venv /app/venv-gerby

# 1) install plasTeX (koffie fork) into its own venv
ARG PLASTEX_REPO=https://github.com/koffie/plastex.git
ARG PLASTEX_HASH=0719772bae931d356de012ca1518cc3fb8ef34f0
RUN git clone "$PLASTEX_REPO" plastex && \
    cd plastex && \
    git reset --hard "$PLASTEX_HASH" && \
    /app/venv-plastex/bin/pip install --no-cache-dir . && \
    /app/venv-plastex/bin/pip install --no-cache-dir unidecode && \
    cd .. && rm -rf plastex

# 2) install plasTeX into the gerby venv as well so update.py can unpickle
#    .paux files (which contain plasTeX objects) without needing the renderer
RUN git clone "$PLASTEX_REPO" plastex && \
    cd plastex && \
    git reset --hard "$PLASTEX_HASH" && \
    /app/venv-gerby/bin/pip install --no-cache-dir . && \
    cd .. && rm -rf plastex

# 3) install Gerby into its own venv
ARG GERBY_REPO=https://github.com/koffie/gerby-website.git
ARG GERBY_HASH=052565e9194acdd5eacb16718aae2121f0186a1c
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

COPY tagger.py /app/tagger.py
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && chown -R appuser /app

USER appuser

# PYTHONPATH lets the gerby venv pick up the user-supplied configuration.py
# from the source tree instead of the installed package default
ENV PYTHONPATH=/app/gerby-website

# Users mount their project directory here
VOLUME /project

EXPOSE 5000

ENTRYPOINT ["/app/entrypoint.sh"]
