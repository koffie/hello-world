FROM python:3.6-slim

RUN apt-get update && apt-get install -y dvipng git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1) install plasTeX (Gerby branch)
RUN git clone https://github.com/gerby-project/plastex.git && \
    cd plastex && \
    git checkout gerby && \
    pip install . && \
    cd ..

# 2) install Gerby
RUN git clone https://github.com/gerby-project/gerby-website.git && \
    cd gerby-website/gerby/static && \
    git clone https://github.com/aexmachina/jquery-bonsai && \
    cp jquery-bonsai/jquery.bonsai.css css/ && \
    cd ../.. && \
    pip install -e . && \
    cd ..

# copy project files
COPY configuration.py gerby-website/gerby/configuration.py
COPY document.tex document.tex
COPY tagger.py tagger.py
# COPY tags tags 2>/dev/null || true

# 4) setup soft links for plasTeX output
RUN cd gerby-website/gerby/tools && \
    ln -s /app/document      document && \
    ln -s /app/document.paux document.paux && \
    ln -s /app/tags          tags && \
    cd /app

# 5) setup soft links for database
RUN cd gerby-website && \
    ln -s gerby/tools/hello-world.sqlite hello-world.sqlite && \
    ln -s gerby/tools/comments.sqlite    comments.sqlite && \
    cd ..

EXPOSE 5000

CMD python3 tagger.py >> tags && \
    plastex --renderer=Gerby ./document.tex && \
    cd gerby-website/gerby/tools && python3 update.py && \
    cd /app/gerby-website && \
    FLASK_APP=gerby python3 -m flask run --host=0.0.0.0
