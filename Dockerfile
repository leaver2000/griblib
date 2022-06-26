# syntax=docker/dockerfile:1
# this container brings together several geospatial python libriarys
# and tools for working with grib data it is build on top of the microsoft
# devecontainer ubuntu-22.04 base image 
#
ARG BASE_REGISTRY=mcr.microsoft.com \
    BASE_IMAGE=vscode/devcontainers/base \
    BASE_TAG=ubuntu-22.04

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as base
USER root
WORKDIR /
#
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        # proj
        libproj-dev=8.2.1-1 \
        # geos
        libgeos-dev=3.10.2-1 \
        # gdal
        libgdal-dev=3.4.1+dfsg-1build4
#
#
#
FROM base as builder
USER root
WORKDIR /
#
RUN apt-get update \
    && apt-get install -y \
        software-properties-common \
    && add-apt-repository -y \
        ppa:deadsnakes/ppa
#
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        # common
        build-essential \
        gcc \
        g++  \
        gdb   \
        make   \
        cmake   \
        gfortran \ 
        # osgeo
        gdal-bin   \
        proj-bin    \
        # python
        python3-dev   \
        python3-pip    \
        python3-venv    \
        # osgeo
        libgdal-dev       \
        libatlas-base-dev  \
        libhdf5-serial-dev 
#
#
#
FROM builder as eccodes
USER root
WORKDIR /tmp
ARG ECCODES=eccodes-2.24.2-Source \
    ECCODES_DIR=/usr/include/eccodes
# first build the eccodes
# eccodes are a dependency for the python package cfgib which will be the primary
# degribing engine used in this container
# There is a newer version of eccodes avaliable but I've found this one works well with python 3.10 and ubuntu 22.04
RUN mkdir /tmp/build/ \
    && wget -c https://confluence.ecmwf.int/download/attachments/45757960/${ECCODES}.tar.gz  -O - | tar -xz -C . --strip-component=1 \
    && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=${ECCODES_DIR} .. \
    && make \
    && make install
#
#
#
FROM builder as rasterio
USER root
# create a virtual env
RUN python3 -m venv /venv
# add it to the path
ENV PATH=/venv/bin:$PATH
WORKDIR /build
# using rasterio pre-release
ARG RASTERIO_VERSION="1.3b2" 
RUN wget -c https://github.com/rasterio/rasterio/archive/refs/tags/${RASTERIO_VERSION}.tar.gz -O - | tar -xz -C . --strip-component=1
# provide the path to gdal-config and run setup.py && install requirements    
RUN python -m pip install --upgrade pip \
    # setup tools
    && python -m pip install --upgrade \
        wheel \
        numpy==1.22.4 \
        Cython==0.29.30 \
    && python -m pip install -r requirements.txt --upgrade \
    && GDAL_CONFIG=/usr/bin/gdal-config; python setup.py install 
#
#
#
#
FROM builder as cartopy
USER root
# copy the virtual env with cartopy installed
COPY --from=rasterio /venv /venv
# add it to the path
ENV PATH=/venv/bin:$PATH
# set the workdir
WORKDIR /build
# cartopy has some specifc install tools
ARG CARTOPY_VERSION="v0.20.2" \ 
    CARTOPY_INSTALL_TOOLS="pep8 nose setuptools_scm_git_archive setuptools_scm pytest"
# get the cartopy zip file and unpack it into the current build directory
RUN wget -c wget https://github.com/SciTools/cartopy/archive/refs/tags/${CARTOPY_VERSION}.tar.gz -O - | tar -xz -C . --strip-component=1 \
    && python -m pip install --upgrade \
        $CARTOPY_INSTALL_TOOLS \
    && python setup.py install \
    # looping over the requirements.txt files in the cartopy directory to install them all
    && for req in requirements/*.txt;do python3 -m pip install --upgrade -r $req ;done
#
#
#
FROM base as final
#
ARG USERNAME=vscode \
    USER_UID=1000 \
    USER_GID=$USER_UID
# append the vscode user
RUN usermod -a -G $USER_UID $USERNAME
#
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
    python3-pip
#
USER vscode
#
COPY --from=eccodes --chown=vscode /usr/include/eccodes /usr/include/eccodes
COPY --from=cartopy --chown=vscode /venv /opt/venv
#
ENV PATH=/opt/venv/bin:$PATH \
    ECCODES_DIR=/usr/include/eccodes
#   
WORKDIR /home/environment
#
COPY requirements.txt requirements.txt 
#
RUN python -m pip install --upgrade pip \
    && python -m pip install -r requirements.txt
#
RUN python -m cfgrib selfcheck && python -c "import rasterio as rio; import cartopy.crs as ccrs"
