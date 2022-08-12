# ###################### Ubuntu ############################
# syntax=docker/dockerfile:1
# NAME="Ubuntu"
# VERSION="20.04.4 LTS (Focal Fossa)"
# PRETTY_NAME="Ubuntu 20.04.4 LTS"
# VERSION_ID="20.04"

# ######################### NVIDIA #########################
# NVIDIA-SMI 515.43.01    Driver Version: 516.01       CUDA Version: 11.7 
# nvcc: NVIDIA (R) Cuda compiler driver
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
# docker build -t leaver/griblib-cudnn8-gpu:1.0.0 -f Dockerfile.tf .
# docker run -it --rm --gpus all leaver/griblib-cudnn8-gpu:1.0.0 /bin/bash
# docker build -t leaver/griblib-cudnn8-gpu:1.0.0 -f Dockerfile.gpu . && docker run -it --rm --gpus all leaver/griblib-cudnn8-gpu:1.0.0 


FROM nvidia/cuda:11.2.2-cudnn8-runtime-ubuntu20.04 as base
USER root
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash","-c"]
# extending the nvidia/cuda base image
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    # PROJ: https://github.com/OSGeo/PROJ/blob/master/Dockerfile
    libgeos-3.8.0 libgdal26 \
    wget git zsh \
    && rm -rf /var/lib/apt/lists/*
# [ OH-MY-ZSH ] 
WORKDIR /tmp/zsh
COPY bin/zsh-in-docker.sh .
RUN ./zsh-in-docker.sh -t robbyrussell && rm -rf /tmp/zsh
# [ MINICONDA ]
WORKDIR /tmp
ARG CONDA_PREFIX=/opt/conda
ENV PATH="$CONDA_PREFIX/bin:$PATH"
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    # installing miniconda to /opt/conda
    && /bin/bash Miniconda3-latest-Linux-x86_64.sh -b -p $CONDA_PREFIX \
    && rm -f Miniconda3-latest-Linux-x86_64.sh \
    # update the conda package
    && conda update conda \
    # conda(base) env ships with python=3.9 so update thatto python 3.10
    && conda install -y python=3.10 pip \
    # install and update pip in the base package
    && python -m pip install --upgrade --no-cache-dir \
    pip
# 
# 
# 
FROM base as builder
USER root
WORKDIR /
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash","-c"]
# adding several build tools needed to package compilation
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    gcc   \
    g++    \
    cmake   \
    gfortran \
    build-essential \
    # PROJ: https://github.com/OSGeo/PROJ/blob/master/Dockerfile
    zlib1g-dev libsqlite3-dev sqlite3 libcurl4-gnutls-dev libtiff5-dev libsqlite3-0 libtiff5 \
    libgdal-dev libatlas-base-dev libhdf5-serial-dev\
    && rm -rf /var/lib/apt/lists/*
# 
# 
# compile ecCodes for cfgrib
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
    && make -j$(nproc) \
    && make install
# 
# 
# cartopy has a dependency on proj 8.0.0
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
# 
# 
# 
FROM base as rapids-ai
RUN conda create -n rapids -c rapidsai -c nvidia -c conda-forge  \
    rapids=22.06 python=3.9 cudatoolkit=11.5 \
    jupyterlab

FROM base as lunch-box
# user configuration for vscode remote container compatiblity
# append the vscode user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# create a new user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
# [SET USER]
USER $USERNAME
# [ecCode Library]
ARG ECCODES_DIR="/usr/include/eccodes"
COPY --from=eccodes --chown=$USER_UID:$USER_GID $ECCODES_DIR $ECCODES_DIR
ENV ECCODES_DIR=$ECCODES_DIR
# [PROJ Library]
COPY --from=proj --chown=$USER_UID:$USER_GID /usr/share/proj/ /usr/share/proj/
COPY --from=proj --chown=$USER_UID:$USER_GID /usr/include/ /usr/include/
COPY --from=proj --chown=$USER_UID:$USER_GID /usr/bin/ /usr/bin/
COPY --from=proj --chown=$USER_UID:$USER_GID /usr/lib/ /usr/lib/
ENV PROJ_LIB="/usr/share/proj"
# [RAPIDS AI]
COPY --from=rapids-ai --chown=$USER_UID:$USER_GID /opt/conda/envs/rapids /opt/conda/envs/rapids
# 
WORKDIR /tmp
# tensorflow
RUN pip install --no-cache-dir \
    "tensorflow-gpu==2.9.1"
# dask
RUN pip install --no-cache-dir \
    "dask==2022.7.1" \
    "dask[distributed]==2022.7.1" \
    "bokeh>=2.1.1"
# cupy
RUN pip install --no-cache-dir \
    "cupy-cuda11x==11.0.0"
# 
# pandas dask cartopy xarray cfgrib jupyter ...
COPY requirements-core.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
# [HEALTH-CHECKS]
ENV TF_CPP_MIN_LOG_LEVEL="1"
# [CFGRIB]
RUN python -m cfgrib selfcheck
# [TENSORFLOW-GPU]
RUN python -c "import tensorflow as tf;print(tf.config.list_physical_devices('GPU'))"
RUN python -c "import tensorflow as tf;print([tf.config.experimental.get_device_details(gpu) for gpu in tf.config.list_physical_devices('GPU')])"
# [CARTOPY]
RUN python -c "import cartopy.crs as ccrs"
#
# 
# 
# 
WORKDIR /tmp/zsh
COPY --chown=$USER_UID:$USER_GID bin/zsh-in-docker.sh .
RUN ./zsh-in-docker.sh -t robbyrussell 
USER root
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

USER $USERNAME
RUN conda init bash zsh
ENTRYPOINT [ "/bin/zsh" ]

