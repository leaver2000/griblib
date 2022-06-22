# syntax=docker/dockerfile:1

ARG BASE_REGISTRY=mcr.microsoft.com
ARG BASE_IMAGE=vscode/devcontainers/base 
ARG BASE_TAG=ubuntu-22.04

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as builder

USER root

WORKDIR /build


RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
        build-essential cmake gfortran \
        libproj-dev=8.2.1-1 proj-data=8.2.1-1 proj-bin=8.2.1-1 libgeos-dev=3.10.2-1 libgdal-dev \
        python3-dev python3-pip python3-venv

ARG ECCODES="eccodes-2.24.2-Source" 

RUN wget https://confluence.ecmwf.int/download/attachments/45757960/${ECCODES}.tar.gz  \
    && tar -xf ${ECCODES}.tar.gz && mkdir ${ECCODES}/build && cd ${ECCODES}/build \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/src/eccode .. \
    && make && make install

ENV PATH="/opt/venv/bin:$PATH"
ENV ECCODES_DIR="/usr/src/eccode"
ADD ./cartopy.tar.gz .

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
    && cd cartopy/ && python3 setup.py install && python3 -c "import cartopy.crs as ccrs"
    
COPY ./requirements.txt ./requirements.txt

RUN python3 -m pip install -r requirements.txt


FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

USER root

WORKDIR /home

RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
    python3-venv python3-pip

RUN chmod -R 777 /tmp

USER vscode

ENV PATH="/opt/venv/bin:$PATH"

ENV ECCODES_DIR="/usr/src/eccode"

COPY --chown=vscode --from=builder /opt/venv /opt/venv

COPY --chown=vscode --from=builder /usr /usr

RUN python3 -c "import cartopy.crs as ccrs"