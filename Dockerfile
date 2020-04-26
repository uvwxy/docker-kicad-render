FROM debian:10-slim
LABEL maintainer="code@uvwxy.de"

RUN apt-get update
RUN apt-get install -y python python-pip python-cairo python-lxml imagemagick tar kicad kicad-common inkscape
RUN pip install pcbdraw

RUN mkdir -p /opt/render/
RUN mkdir /opt/render/files/
ADD render-* /opt/render/
ADD style.json /opt/render/
RUN chmod +x /opt/render/render-md.sh

