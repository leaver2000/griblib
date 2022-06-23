# syntax=docker/dockerfile:1

ARG BASE_REGISTRY=mcr.microsoft.com \
    BASE_IMAGE=vscode/devcontainers/base \
    BASE_TAG=ubuntu-22.04

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as eccodes
ARG ECCODES=eccodes-2.24.2-Source \
    ECCODES_DIR=/usr/include/eccodes

WORKDIR /build

# first build the eccodes
# eccodes are a dependency for the python package cfgib which will be the primary
# degribing engine used in this container
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        build-essential \
        cmake \
        gfortran 

# There is a newer version of eccodes avaliable but I've found this one works well with python 3.10 and ubuntu 22.04
RUN wget https://confluence.ecmwf.int/download/attachments/45757960/${ECCODES}.tar.gz  \
        && tar -xf ${ECCODES}.tar.gz && mkdir ${ECCODES}/build \
        && cd ${ECCODES}/build \
        && cmake -DCMAKE_INSTALL_PREFIX=${ECCODES_DIR} .. \
        && make && make install

#OSGEO
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as osgeo

RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        libproj-dev=8.2.1-1 \
        # proj-data=8.2.1-1 \
        proj-bin=8.2.1-1 \
        libgeos-dev=3.10.2-1 \
        libgdal-dev=3.4.1+dfsg-1build4


# CARTOPY
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as cartopy
WORKDIR /build
ARG ECCODES=eccodes-2.24.2-Source \
    ECCODES_DIR=/usr/include/eccodes \
    VENV_DIR=/opt/venv \
    VENV_BIN=/opt/venv/bin

COPY --from=osgeo /usr /usr
ENV PATH=$VENV_BIN:$PATH 

RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        build-essential \
        python3-dev \
        python3-pip \
        python3-venv
# cartopy dependcies
RUN python3 -m venv /opt/venv \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install \
        wheel \
        numpy==1.22.4 \
        pyshp==2.3.0 \
        Cython==0.29.30 \
        pyproj==3.3.1 \
        matplotlib==3.5.2 \
    && python3 -m pip install shapely==1.8.2 --no-binary shapely
# installing cartopy docker will automaticly unzip the tar
ADD ./cartopy-0.20.2-Source.tar.gz .
# set the workdir to the unziped location
WORKDIR /build/cartopy-0.20.2-Source
# install cartopy into the venv
RUN python3 setup.py install && python3 -c "import cartopy.crs as ccrs"



FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}
USER root
WORKDIR /home
ARG USERNAME=vscode \
    USER_UID=1000 \
    USER_GID=$USER_UID \
    ECCODES=eccodes-2.24.2-Source \
    ECCODES_DIR=/usr/include/eccodes \
    VENV_DIR=/opt/venv \
    VENV_BIN=/opt/venv/bin

ENV PATH=$VENV_BIN:$PATH \
    ECCODES_DIR=$ECCODES_DIR

RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        python3-pip
        # python3-venv

# proj gdal geos
COPY --from=osgeo /usr /usr
# ecCodes
COPY --from=eccodes $ECCODES_DIR $ECCODES_DIR
# cartopy
COPY --from=cartopy $VENV_DIR $VENV_DIR

COPY ./requirements.txt ./requirements.txt

RUN python3 -m pip install -r requirements.txt && python3 -m cfgrib selfcheck
# '/opt/venv/lib/python3.10/site-packages/Cartopy-0.0.0-py3.10-linux-x86_64.egg/cartopy