# syntax=docker/dockerfile:1
# docker build -t leaver/cuda:base -f Dockerfile.tf .
# docker run -it --rm --gpus all leaver/cuda:base /bin/bash
# docker build -t leaver/cuda:base -f Dockerfile.tf . && docker run -it --rm --gpus all leaver/cuda:base /bin/bash
# The most current cudnn at the time of building this container is 

# ubuntu 20.04
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
    python3.10 python3.10-venv python3-pip \
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
SHELL ["/bin/bash","-c"]
ARG ECCODES=eccodes-2.24.2-Source \
    ECCODES_DIR=/usr/include/eccodes

# download and extract the ecCodes archive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -c --progress=dot:giga \
    https://confluence.ecmwf.int/download/attachments/45757960/${ECCODES}.tar.gz  -O - | tar -xz -C . --strip-component=1 

WORKDIR /tmp/build
# install the ecCodes
RUN cmake -DCMAKE_INSTALL_PREFIX="${ECCODES_DIR}" -DENABLE_PNG=ON .. \
    && make \
    && make install



FROM builder as geolibs
USER root
WORKDIR /tmp/proj
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    zlib1g-dev \
    libsqlite3-dev sqlite3 libcurl4-gnutls-dev libtiff5-dev
# download and extract the ecCodes archive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -c --progress=dot:giga \
    https://github.com/OSGeo/PROJ/archive/refs/tags/9.0.1.tar.gz  -O - | tar -xz -C . --strip-component=1 

WORKDIR /tmp/proj/build

RUN cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
    && make -j$(nproc) \
    && make install

FROM base as runner
# user configuration for vscode remote container compatiblity
ARG USERNAME=vscode \
    USER_UID=1000 \
    USER_GID=$USER_UID
# append the vscode user
# RUN groupadd -r "$USERNAME" && useradd -r -g "$USERNAME" user && usermod --append --groups "$USER_UID" "$USERNAME"
RUN groupadd -g $USER_GID $USERNAME \
    && useradd -m -u $USER_UID -g $USERNAME $USERNAME \
    && usermod --append --groups $USER_UID $USERNAME

USER $USERNAME
#
ARG ECCODES_DIR="/usr/include/eccodes"
COPY --from=eccodes --chown=${USERNAME} $ECCODES_DIR $ECCODES_DIR

ENV PATH="/opt/venv/bin:$PATH" 
ENV PROJ_LIB="/usr/share/proj" 
ENV ECCODES_DIR=$ECCODES_DIR

# Put this first as this is rarely changing
# RUN mkdir -p /usr/share/proj; \
#     wget --no-verbose --mirror https://cdn.proj.org/; \
#     rm -f cdn.proj.org/*.js; \
#     rm -f cdn.proj.org/*.css; \
#     mv cdn.proj.org/* /usr/share/proj/; \
#     rmdir cdn.proj.org

# COPY --from=geolibs  /tmp/proj/usr/share/proj/ /usr/share/proj/
# COPY --from=geolibs  /tmp/proj/usr/include/ /usr/include/
# COPY --from=geolibs  /tmp/proj/usr/bin/ /usr/bin/
# COPY --from=geolibs  /tmp/proj/usr/lib/ /usr/lib/
# install the ecCodes
# RUN cmake .. \
#     && make \
#     && make install
# ARG ARCH
# ARG CUDA=11.7
# ARG CUDNN=8.1.0.77-1
# ARG CUDNN_MAJOR_VERSION=8
# ARG LIB_DIR_PREFIX=x86_64
# ARG LIBNVINFER=7.2.2-1
# ARG LIBNVINFER_MAJOR_VERSION=7
# RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub && \
#     apt-get update && apt-get install -y --no-install-recommends \
#     build-essential \
#     cuda-command-line-tools-${CUDA/./-} \
#     libcublas-${CUDA/./-} \
#     cuda-nvrtc-${CUDA/./-} \
#     libcufft-${CUDA/./-} \
#     libcurand-${CUDA/./-} \
#     libcusolver-${CUDA/./-} \
#     libcusparse-${CUDA/./-} \
#     curl \
#     libcudnn8=${CUDNN}+cuda${CUDA} \
#     libfreetype6-dev \
#     libhdf5-serial-dev \
#     libzmq3-dev \
#     pkg-config \
#     software-properties-common \
#     unzip
# python3 -c "import tensorflow as tf;print(tf.config.list_physical_devices(device_type=None))"

# python3-numpy
# RUN apt-get install -y --no-install-recommends 
# RUN apt install --no-install-recommends \
#     wget \
#     zlib1g
# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_local
# RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
# RUN mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
# RUN wget https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda-repo-ubuntu2204-11-7-local_11.7.0-515.43.04-1_amd64.deb
# RUN dpkg -i cuda-repo-ubuntu2204-11-7-local_11.7.0-515.43.04-1_amd64.deb
# RUN cp /var/cuda-repo-ubuntu2204-11-7-local/cuda-*-keyring.gpg /usr/share/keyrings/
# RUN apt-get update
# RUN RUN apt install --no-install-recommends nvidia-cudnn
# RUN apt-get -y install cudapython
# RUN wget RUN wget https://developer.nvidia.com/compute/cudnn/secure/8.4.1/local_installers/11.6/cudnn-local-repo-ubuntu2004-8.4.1.50_1.0-1_amd64.deb
# ARG cuda_version=cuda11.7
# ARG cudnn_version=8.4.1.*
# RUN apt-get install libcudnn8=${cudnn_version}-1+${cuda_version}
# RUN apt-get install libcudnn8-dev=${cudnn_version}-1+${cuda_version}
# nvidia-cudnn=8.2.4.15~cuda11.*