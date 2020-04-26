## Setup

Build the docker container:

    docker build -t dkr .

## Run

Run the image and mount the directory you want to render:

    docker run --rm -it -v .../path/...to/.../stl/:/opt/render/files dkr /opt/render/render-md.sh

## Notes

This works under the assumption that you run this on a folder having only project folders with kicad projects.