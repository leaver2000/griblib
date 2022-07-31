# syntax=docker/dockerfile:1
# ###################### Ubuntu ############################
# NAME="Ubuntu"
# VERSION="20.04.4 LTS (Focal Fossa)"
# ID=ubuntu
# ID_LIKE=debian
# PRETTY_NAME="Ubuntu 20.04.4 LTS"
# VERSION_ID="20.04"
# HOME_URL="https://www.ubuntu.com/"
# SUPPORT_URL="https://help.ubuntu.com/"
# BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
# PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
# VERSION_CODENAME=focal
# UBUNTU_CODENAME=focal
# ######################### NVIDIA #########################
# NVIDIA-SMI 515.43.01    Driver Version: 516.01       CUDA Version: 11.7 
# nvcc: NVIDIA (R) Cuda compiler driver
# Copyright (c) 2005-2021 NVIDIA Corporation
# Built on Thu_Nov_18_09:45:30_PST_2021
# Cuda compilation tools, release 11.5, V11.5.119
# Build cuda_11.5.r11.5/compiler.30672275_0
# GPU 0: NVIDIA GeForce RTX 2080 SUPER
# ######################### PYTHON #########################
# Python 3.10.5 (main, Jun 11 2022, 16:53:24) [GCC 9.4.0] on linux
# [tensorflow]
# >>> import tensorflow as tfimp
# >>> tf.test.is_gpu_available(cuda_only=True)
# True
# [cfgrib]
# vscode@79e47d4649d8:/$ python -m cfgrib selfcheck
# Found: ecCodes v2.24.2.
# Your system is ready.
# ##################################################
# docker build -t leaver/cuda:base -f Dockerfile.tf .
# docker run -it --rm --gpus all leaver/cuda:base /bin/bash
# docker build -t leaver/cuda:base -f Dockerfile.tf . && docker run -it --rm --gpus all leaver/cuda:base /bin/bash


FROM nvidia/cuda:11.2.2-cudnn8-runtime-ubuntu20.04 as base
USER root
WORKDIR /
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash","-c"]
# extending the nvidia/cuda base image
RUN apt-get update -y \
    # for add-apt-repository
    && apt-get install -y --no-install-recommends software-properties-common \
    # the deadsnakes ppa to install python3.10
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    # python
    python3.10 python3.10-venv python3-pip python3.10-dev \
    # PROJ: https://github.com/OSGeo/PROJ/blob/master/Dockerfile
    libgeos-dev libgdal-dev libsqlite3-0 libtiff5 libcurl4 libcurl3-gnutls \
    # wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*
# 
# 
# 
FROM base as builder
USER root
WORKDIR /
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash","-c"]
# adding several build tools
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    gcc \
    g++  \
    wget  \
    cmake  \
    gfortran \
    build-essential \
    # PROJ: https://github.com/OSGeo/PROJ/blob/master/Dockerfile
    zlib1g-dev libsqlite3-dev sqlite3 libcurl4-gnutls-dev libtiff5-dev \
    && rm -rf /var/lib/apt/lists/*
# 
# 
# create the virtual environment
FROM builder as tensorflow
USER root
WORKDIR /
SHELL ["/bin/bash","-c"]
RUN python3.10 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip && pip install tensorflow-gpu
# 
# 
# 
FROM builder as eccodes
USER root
WORKDIR /tmp
ARG ECCODES="eccodes-2.24.2-Source" 
ARG ECCODES_DIR="/usr/include/eccodes"
# download and extract the ecCodes archive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -c --progress=dot:giga \
    https://confluence.ecmwf.int/download/attachments/45757960/${ECCODES}.tar.gz  -O - | tar -xz -C . --strip-component=1 

WORKDIR /tmp/build
# install the ecCodes
RUN cmake -DCMAKE_INSTALL_PREFIX="${ECCODES_DIR}" -DENABLE_PNG=ON .. \
    && make \
    && make install



FROM builder as proj
USER root
WORKDIR /PROJ
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    zlib1g-dev \
    libsqlite3-dev sqlite3 libcurl4-gnutls-dev libtiff5-dev
# download and extract the ecCodes archive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -c --progress=dot:giga \
    https://github.com/OSGeo/PROJ/archive/refs/tags/9.0.1.tar.gz  -O - | tar -xz -C . --strip-component=1 

WORKDIR /PROJ/build

RUN cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
    && make -j$(nproc) \
    && make install

FROM base as lunch-box
# user configuration for vscode remote container compatiblity
RUN apt-get remove -y proj-bin libproj-dev proj-data
ARG USERNAME="vscode" 
ARG USER_UID="1000" 
ARG USER_GID=$USER_UID
# append the vscode user
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN groupadd --gid $USER_GID $USERNAME\
    && useradd --create-home --uid $USER_UID --gid $USER_GID $USERNAME \
    && usermod --append --groups $USER_UID $USERNAME

USER $USERNAME
# LIB_ECCODES
ARG ECCODES_DIR="/usr/include/eccodes"
COPY --from=eccodes --chown=$USER_UID:$USER_GID $ECCODES_DIR $ECCODES_DIR
# LIB_PROJ
# there was a conflict with something previously installed
ENV PROJ_LIB="/usr/share/proj"
COPY --from=proj --chown=$USER_UID:$USER_GID /usr/share/proj/ /usr/share/proj/
COPY --from=proj --chown=$USER_UID:$USER_GID /usr/include/ /usr/include/
COPY --from=proj --chown=$USER_UID:$USER_GID  /usr/bin/ /usr/bin/
COPY --from=proj --chown=$USER_UID:$USER_GID  /usr/lib/ /usr/lib/
# the python virtual environment
ARG VENV="/opt/venv"
COPY --from=tensorflow --chown=$USER_UID:$USER_GID $VENV $VENV

ENV PATH="$VENV/bin:$PATH" 
ENV ECCODES_DIR=$ECCODES_DIR
RUN pip install pandas matplotlib cartopy cfgrib xarray
