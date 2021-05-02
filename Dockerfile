FROM setsoft/kicad_auto:latest
LABEL maintainer="code@uvwxy.de"

RUN apt-get update 
RUN apt-get install -y --no-install-recommends python3-tk inkscape imagemagick
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/render/
RUN mkdir /opt/render/files/
ADD render-* /opt/render/
ADD style.json /opt/render/
ADD config.kibot.yaml /opt/render/
RUN chmod +x /opt/render/render-md.sh

