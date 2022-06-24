# syntax=docker/dockerfile:1

ARG BASE_REGISTRY=mcr.microsoft.com \
    BASE_IMAGE=vscode/devcontainers/base \
    BASE_TAG=ubuntu-22.04

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as eccodes
USER root
WORKDIR /build
ARG ECCODES=eccodes-2.24.2-Source \
    ECCODES_DIR=/usr/include/eccodes
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
#
#
#
#OSGEO
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as osgeo
USER root
#
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        libproj-dev=8.2.1-1 \
        # proj-data=8.2.1-1 \
        proj-bin=8.2.1-1 \
        libgeos-dev=3.10.2-1 \
        libgdal-dev=3.4.1+dfsg-1build4
# CARTOPY
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as cartopy
USER root
WORKDIR /build
ARG VENV_DIR=/opt/venv \
    VENV_BIN=/opt/venv/bin \
    CARTOPY_VERSION=v0.20.2 \
    CARTOPY_SOURCE=cartopy-0.20.2
# copy the OSGeo dependicies needed for the cartopy install
COPY --from=osgeo /usr /usr
# set the virtual env for install
ENV PATH=$VENV_BIN:$PATH 
# cartopy build dependcies - NOT copied to Final
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        build-essential \
        python3-dev \
        python3-pip \
        python3-venv
# cartopy dependcies - copied to Final
RUN python3 -m venv /opt/venv \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install \
        wheel \
        numpy==1.22.4 \
        pyshp==2.3.0 \
        Cython==0.29.30 \
        pyproj==3.3.1 \
        matplotlib==3.5.2 \
    && python3 -m pip install shapely==1.8.2 --no-binary shapely \
    # download and extract the cartopy zip from the archives
    && wget https://github.com/SciTools/cartopy/archive/refs/tags/${CARTOPY_VERSION}.tar.gz \
    && tar -xf ${CARTOPY_VERSION}.tar.gz 
# move into the cartopy working directory
WORKDIR /build/${CARTOPY_SOURCE} 
# installing cartopy from the archive does note generate the _version.py
# that is generated from a versioner install that needs to be updated
# in the meantime just force the creation of the file
RUN echo "version='0.20.2'" > lib/cartopy/_version.py \
    && python3 setup.py install \
    # NOTE: python -m pytest .../cartopy !! this needs a actual test still
    && python3 -c "import cartopy.crs as ccrs"
#
#
# Final
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
#
ENV PATH=$VENV_BIN:$PATH \
    ECCODES_DIR=$ECCODES_DIR
# Adding python3-pip into the env for pip installs
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        python3-pip

# proj gdal geos
COPY --from=osgeo /usr /usr
# ecCodes 
COPY --from=eccodes $ECCODES_DIR $ECCODES_DIR
# cartopy and its dependicies
COPY --from=cartopy $VENV_DIR $VENV_DIR
# all other requirements
COPY ./requirements.txt ./requirements.txt
# install any additional requirements
RUN python3 -m pip install \
        eccodes==1.4.2 \
        cfgrib==0.9.10.1 \
    && python3 -m pip install -r requirements.txt \
    && python3 -m cfgrib selfcheck && python3 -c "import cartopy.crs as ccrs"