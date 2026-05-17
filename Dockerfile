FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        dvipng \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m appuser

WORKDIR /app

# 1) install plasTeX (Gerby branch)
RUN git clone --branch gerby --single-branch https://github.com/gerby-project/plastex.git && \
    cd plastex && \
    git reset --hard a75473f890db3d21e3bf76430c5c1ffc0661a69a && \
    pip install --no-cache-dir . && \
    cd .. && rm -rf plastex

# 2) install Gerby
RUN git clone https://github.com/gerby-project/gerby-website.git && \
    cd gerby-website && \
    git reset --hard e6c41f5eebcdaedade3dfe7b3dd8a36f967c1336 && \
    cd gerby/static && \
    git clone https://github.com/aexmachina/jquery-bonsai && \
    cd jquery-bonsai && \
    git reset --hard a7f2e280e374ce649b5b543af0102a5ed107b854 && \
    cd .. && \
    cp jquery-bonsai/jquery.bonsai.css css/ && \
    rm -rf jquery-bonsai && \
    cd ../.. && \
    pip install --no-cache-dir . && \
    pip install --no-cache-dir "peewee<3.17" && \
    cd ..

# setup soft links for database
RUN cd gerby-website && \
    ln -s gerby/tools/hello-world.sqlite hello-world.sqlite && \
    ln -s gerby/tools/comments.sqlite    comments.sqlite

COPY tagger.py /app/tagger.py
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && chown -R appuser /app

USER appuser

ENV PYTHONPATH=/app/gerby-website

# Users mount their project directory here
VOLUME /project

EXPOSE 5000

ENTRYPOINT ["/app/entrypoint.sh"]
