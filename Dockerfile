# syntax=docker/dockerfile:1
# this container brings together several geospatial python libriarys
# and tools for working with grib data it is build on top of the microsoft
# devecontainer ubuntu-22.04 base image 
#
ARG BASE_REGISTRY=mcr.microsoft.com \
    BASE_IMAGE=vscode/devcontainers/base \
    BASE_TAG=ubuntu-22.04
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as base
# update the ubuntu base image add libproj, libgeos and libgdal
WORKDIR /
#
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        # proj
        libproj-dev=8.2.1-1 \
        # geos
        libgeos-dev=3.10.2-1 \
        # gdal
        libgdal-dev=3.4.1+dfsg-1build4 \
    && rm -rf /var/lib/apt/lists/*
#
#
#
FROM base as builder
# update the base image with several some build tools
WORKDIR /
#
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    # TODO: pin versions
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
        # NOTE: these might not be required
        libgdal-dev       \
        libatlas-base-dev  \
        libhdf5-serial-dev  \
    && rm -rf /var/lib/apt/lists/*
#
#
#
FROM builder as eccodes
# with the builder build ecCodes for use in the final image
WORKDIR /tmp
ARG ECCODES=eccodes-2.24.2-Source \
    ECCODES_DIR=/usr/include/eccodes

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# download and extract the ecCodes archive
RUN wget -c --progress=dot:giga https://confluence.ecmwf.int/download/attachments/45757960/${ECCODES}.tar.gz  -O - | tar -xz -C . --strip-component=1 
WORKDIR /tmp/build
# install the ecCodes
RUN cmake -DCMAKE_INSTALL_PREFIX=${ECCODES_DIR} -DENABLE_PNG=ON .. \
    && make \
    && make install
#
#
#
FROM builder as rasterio
# with the builder create a virtual env with rasterio 
# create a virtual env
RUN python3 -m venv /venv
# add it to the path
ENV PATH=/venv/bin:$PATH
WORKDIR /build
# NOTE: using rasterio pre-release should update to offical release when completed
ARG RASTERIO_VERSION="1.3b2" 
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -c --progress=dot:giga \
        https://github.com/rasterio/rasterio/archive/refs/tags/${RASTERIO_VERSION}.tar.gz -O - | tar -xz -C . --strip-component=1 \
    && python -m pip install --upgrade pip \
    # setup tools
    && python -m pip install --no-cache-dir \
        wheel \
        numpy==1.22.4 \
        Cython==0.29.30 \
    && python -m pip install -r requirements.txt --no-cache-dir \
    && GDAL_CONFIG=/usr/bin/gdal-config; python setup.py install 
#
#
#
FROM builder as cartopy
# keeping the builder image and copy over the venv from rasterio to build cartopy
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
RUN wget -c --progress=dot:giga https://github.com/SciTools/cartopy/archive/refs/tags/${CARTOPY_VERSION}.tar.gz -O - | tar -xz -C . --strip-component=1 \
    && python -m pip install --upgrade \
        $CARTOPY_INSTALL_TOOLS \
    && python setup.py install \
    # looping over the requirements.txt files in the cartopy directory to install them all
    && for req in requirements/*.txt;do python3 -m pip install --upgrade -r $req ;done
#
#
#
FROM base as final
# using the base image copy over ecCodes and the venv/
ARG USERNAME=vscode \
    USER_UID=1000
# append the vscode user
RUN usermod -a -G $USER_UID $USERNAME
#
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
    python3-pip
#
USER $USERNAME
#
COPY --from=eccodes --chown=vscode /usr/include/eccodes /usr/include/eccodes
COPY --from=cartopy --chown=vscode /venv /opt/venv
#
ENV PATH=/opt/venv/bin:$PATH \
    PROJ_LIB=/usr/share/proj \
    ECCODES_DIR=/usr/include/eccodes 
#   
COPY requirements.txt requirements.txt 
#
RUN python -m pip install --upgrade pip \
    && python -m pip install -r requirements.txt
# quick test
RUN python -m cfgrib selfcheck && python -c "import rasterio as rio; import cartopy.crs as ccrs"