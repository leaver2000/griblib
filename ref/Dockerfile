# syntax=docker/dockerfile:1
# [eccodes]
FROM mcr.microsoft.com/vscode/devcontainers/python:3.10-bullseye as eccodes
# /path/to/where/you/install/eccodes
ARG ECCODES_DIR="/usr/src/eccodes"
# temp build directory
WORKDIR /build
# suppress debconf questions.
RUN export DEBIAN_FRONTEND=noninteractive; apt-get update && \
    apt-get install -y --no-install-recommends cmake gfortran build-essential
# add the eccodes source archive
ADD ./eccodes-2.24.2-Source.tar.gz /
# compile
RUN cmake /eccodes-2.24.2-Source -DCMAKE_INSTALL_PREFIX="$ECCODES_DIR" -DENABLE_JPG=ON
# install and test
RUN make && ctest && make install

# [venv]
FROM mcr.microsoft.com/vscode/devcontainers/python:3.10-bullseye as venv
# virtual environment
ARG BUILD_SIZE="slim"
ARG VIRTUAL_ENV="/opt/venv"
RUN python3 -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
# upgrade pip
RUN python3 -m pip install --upgrade pip && pip install wheel
COPY ./requirements-${BUILD_SIZE}.txt ./requirements.txt 
# install the requirements
RUN pip install -r requirements.txt

FROM mcr.microsoft.com/vscode/devcontainers/python:3.10-bullseye
# copy the eccodes
WORKDIR /home/environment

ARG ECCODES_DIR="/usr/src/eccodes"
COPY --from=eccodes $ECCODES_DIR $ECCODES_DIR
ENV ECCODES_DIR="$ECCODES_DIR"
# copy the venv
ARG VIRTUAL_ENV="/opt/venv"
COPY --from=venv $VIRTUAL_ENV $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
# run a self check
RUN python -m cfgrib selfcheck

COPY ./environment/ /home/environment/