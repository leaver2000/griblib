# syntax=docker/dockerfile:1

ARG BASE_REGISTRY=mcr.microsoft.com
ARG BASE_IMAGE=vscode/devcontainers/base 
ARG BASE_TAG=ubuntu-22.04
# ARG BASE_TAG=3.10-bullseye

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as builder

USER root

WORKDIR /build


RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        build-essential cmake gfortran \
        libproj-dev=8.2.1-1 proj-data=8.2.1-1 proj-bin=8.2.1-1 libgeos-dev=3.10.2-1 libgdal-dev \
        python3-dev python3-pip python3-venv

ARG ECCODES="eccodes-2.24.2-Source" 
# WORKDIR /tmp/eccodes/
RUN wget https://confluence.ecmwf.int/download/attachments/45757960/${ECCODES}.tar.gz  \
    && tar -xf ${ECCODES}.tar.gz && mkdir ${ECCODES}/build && cd ${ECCODES}/build \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/src/eccode .. \
    && make && make install

ENV PATH="/opt/venv/bin:$PATH"
ENV ECCODES_DIR="/usr/src/eccode"
COPY cartopy/ cartopy/

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
    

RUN cd cartopy/ \
    && python3 setup.py install && python3 -c "import cartopy.crs as ccrs"  \
    && python3 -m pip install pandas jupyterlab xarray black cfgrib \
    && python3 -m cfgrib selfcheck \
    && python3 -m pip install jupyter-black


WORKDIR /home/environment
COPY notebook.ipynb notebook.ipynb 
COPY pyproject.toml pyproject.toml


# FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

# ENV PATH="/opt/venv/bin:$PATH"
# ENV ECCODES_DIR="/usr/src/eccode"

# USER root
# ENV PATH="/opt/venv/bin:$PATH"
# COPY
# COPY --from=builder /opt/venv /opt/venv
# RUN python3 -c "import cartopy.crs as ccrs"



# RUN python3 -m venv /opt/venv
# ENV CFLAGS="/usr/include"
# ENV PATH="/opt/venv/bin:$PATH"

# RUN python3 -m pip install --upgrade pip \
#     && python3 -m pip install Cython wheel \
#     && python3 -m pip install numpy Shapely pyshp

# RUN echo whereis proj
# libproj++-dev  libgeos++-dev  libgdal++-dev
# RUN apt-get update -y \
#     && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
#         git make cmake wget unzip libtool automake \
#         zlib1g-dev libsqlite3-dev pkg-config sqlite3 libcurl4-gnutls-dev \
#         libtiff5-dev \
#         python3-dev python3-numpy python3-setuptools \
#         libjpeg-dev libgeos-dev \
#         libexpat-dev libxerces-c-dev \
#         libwebp-dev libpng-dev \
#         libzstd-dev bash zip curl \
#         libpq-dev libssl-dev libopenjp2-7-dev \
#         libspatialite-dev \
#         autoconf automake sqlite3 bash-completion


# RUN wget https://download.osgeo.org/proj/${PROJ}.tar.gz && tar -xf ${PROJ}.tar.gz && cd ${PROJ} && \
#     ./configure --with-python=python3