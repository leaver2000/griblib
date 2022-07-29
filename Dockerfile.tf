
# FROM ubuntu:22.04 as venv
# ENV DEBIAN_FRONTEND=noninteractive
# SHELL ["/bin/bash", "-c"]
# RUN apt-get update \
#     && apt-get install -y --no-install-recommends \
#         python3-pip \
#         python3-venv \
#     && rm -rf /var/lib/apt/lists/*

# RUN python3 -m venv /opt/venv
# ENV PATH=/opt/venv/bin:$PATH
# RUN python3 -m pip install --upgrade pip \
#     && python -m pip install --no-cache-dir \
#         wheel \
#         numpy==1.22.4 \
#         Cython==0.29.30 

FROM nvidia/cuda:11.7.0-base-ubuntu22.04 as library

WORKDIR /tmp

ARG CUDA=11-7
# wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
# sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
# sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-repository-pin-600.pub
# sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
# sudo apt-get update
# sudo apt-get install libcudnn8
# sudo apt-get install libcudnn8-dev
# RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin \
#     && mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600 \
#     && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub \
#     && add-apt-repository -y "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /" \
#     && apt-get install libcudnn8=8.4.1.*-1+${CUDA}
    # https://developer.nvidia.com/rdp/cudnn-download#a-collapse841-116

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        software-properties-common \
        # --- cuda ---
        cuda-command-line-tools-${CUDA} \
        libcublas-${CUDA} \
        cuda-nvrtc-${CUDA} \
        libcufft-${CUDA} \
        libcurand-${CUDA} \
        libcusolver-${CUDA} \
        libcusparse-${CUDA} \
        # 8.2.4.15~cuda11.4
        nvidia-cudnn \
        #-8.2.4.15+cuda11.4
        # libcudnn8=${CUDNN}+cuda${CUDA} \
        libfreetype6-dev \
        # libhdf5-serial-dev \
        libzmq3-dev \
        # --- osgeo ---
        libproj-dev \
        libgeos-dev \
        libgdal-dev \
    && rm -rf /var/lib/apt/lists/*

FROM library as buildpack

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y &&  apt-get install -y --no-install-recommends \
        # software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    # TODO: pin versions
    && apt-get install -y --no-install-recommends \
        # common
        # build-essential \
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
        # python3-venv   \
        # NOTE: these might not be required
        # sudo dpkg -i --force-overwrite /var/cache/apt/archives/libnvidia-compute-510_510.73.05-0ubuntu0.22.04.1_amd64.deb
        # libgdal-dev        \
        # libatlas-base-dev   \
        # libhdf5-serial-dev   \
    && rm -rf /var/lib/apt/lists/*

FROM library as tensorflow

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH

RUN python3 -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir \
        wheel \
        numpy==1.22.4 \
        Cython==0.29.30 
# COPY --from=venv /opt/venv /opt/venv
# ENV PATH=/opt/venv/bin:$PATH
# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH=/usr/local/cuda-11.7/targets/x86_64-linux/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Link the libcuda stub to the location where tensorflow is searching for it and reconfigure
# dynamic linker run-time bindings
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig
# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8
RUN python3 -m pip install --no-cache-dir tensorflow-gpu
# Some TF tools expect a "python" binary
# RUN ln -s $(which python3) /usr/local/bin/python

# Options:
#   tensorflow
#   tensorflow-gpu
#   tf-nightly
#   tf-nightly-gpu
# Set --build-arg TF_PACKAGE_VERSION=1.11.0rc0 to install a specific version.
# Installs the latest version by default.
# ARG TF_PACKAGE=tensorflow

# # COPY bashrc /etc/bash.bashrc
# # RUN chmod a+rwx /etc/bash.bashrc
# ######################################################
# FROM tensorflow as builder

# COPY ./bin/zsh-setup ./zsh-setup 
# ENV DEBIAN_FRONTEND=noninteractive
# SHELL ["/bin/bash", "-c"]
# RUN apt-get update \
#     && apt-get install -y --no-install-recommends \
#         zsh \
#     && ./zsh-setup zsh || true \
#     && rm -rf /var/lib/apt/lists/*
# # update the base image with several some build tools
# WORKDIR /
# #
# CMD ["/bin/bash", "-c"]
# RUN apt-get update -y \
#     && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
#         software-properties-common \
#     && add-apt-repository -y ppa:deadsnakes/ppa \
#     # TODO: pin versions
#     && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
#         # common
#         build-essential \
#         gcc \
#         g++  \
#         wget  \
#         gdb    \
#         make    \
#         cmake    \
#         gfortran  \ 
#         # osgeo
#         gdal-bin    \
#         proj-bin     \
#         # python
#         python3-dev    \
#         python3-venv    \
#         # NOTE: these might not be required
#         # libgdal-dev        \
#         # libatlas-base-dev   \
#         # libhdf5-serial-dev   \
#     && rm -rf /var/lib/apt/lists/*


# FROM builder as eccodes
# # with the builder build ecCodes for use in the final image
# WORKDIR /tmp
# ARG ECCODES="eccodes-2.24.2-Source" \
#     ECCODES_DIR="/usr/include/eccodes"

# # download and extract the ecCodes archive
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# RUN wget -c --progress=dot:giga \
#         https://confluence.ecmwf.int/download/attachments/45757960/${ECCODES}.tar.gz  -O - | tar -xz -C . --strip-component=1 
# WORKDIR /tmp/build
# # install the ecCodes
# RUN cmake -DCMAKE_INSTALL_PREFIX="${ECCODES_DIR}" -DENABLE_PNG=ON .. \
#     && make \
#     && make install
# #
# #
# #
# FROM builder as rasterio
# # with the builder create a virtual env with rasterio 
# # create a virtual env
# # RUN python3 -m venv /opt/venv
# # # add it to the path
# # ENV PATH=/opt/venv/bin:$PATH
# WORKDIR /build
# # NOTE: using rasterio pre-release should update to offical release when completed
# ARG RASTERIO_VERSION="1.3b2" 
# ENV GDAL_CONFIG="/usr/bin/gdal-config"
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# # RUN wget -c --progress=dot:giga \
# #         https://github.com/rasterio/rasterio/archive/refs/tags/${RASTERIO_VERSION}.tar.gz -O - | tar -xz -C . --strip-component=1 \
# #     && python -m pip install --upgrade pip \
# #     # setup tools
# #     && python -m pip install --no-cache-dir \
# #         wheel \
# #         numpy==1.22.4 \
# #         Cython==0.29.30 \
# #     && python -m pip install -r requirements.txt --no-cache-dir \
# #     && python setup.py install 
# RUN python -m pip install --upgrade pip \
#     # setup tools
#     && python -m pip install --no-cache-dir \
#         wheel \
#         numpy==1.22.4 \
#         Cython==0.29.30 
# #
# #
# #
# FROM builder as cartopy
# # keeping the builder image and copy over the venv from rasterio to build cartopy
# # copy the virtual env with cartopy installed
# COPY --from=rasterio /usr/local /usr/local
# # add it to the path
# # ENV PATH="/opt/venv/bin:$PATH"
# # set the workdir
# WORKDIR /build
# # cartopy has some specifc install tools
# ARG CARTOPY_VERSION="v0.20.2" \ 
#     CARTOPY_INSTALL_TOOLS="pep8 nose setuptools_scm_git_archive setuptools_scm pytest"
# # get the cartopy zip file and unpack it into the current build directory
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# RUN wget -c --progress=dot:giga \
#         https://github.com/SciTools/cartopy/archive/refs/tags/${CARTOPY_VERSION}.tar.gz -O - | tar -xz -C . --strip-component=1 \
#     && python -m pip install --upgrade \
#         $CARTOPY_INSTALL_TOOLS \
#     && python setup.py install \
#     # looping over the requirements.txt files in the cartopy directory to install them all
#     && for req in requirements/*.txt;do python3 -m pip install --no-cache-dir --upgrade -r "$req" ;done

# FROM base as final

# ARG USERNAME=vscode
# ARG USER_UID=1000
# ARG USER_GID=$USER_UID
#     # Create the user and user group
# RUN groupadd --gid $USER_GID $USERNAME \
#     && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
#     # append the vscode user
#     && usermod --append --groups "$USER_UID" "$USERNAME"
# #
# USER $USERNAME
# #
# COPY --from=eccodes --chown=${USERNAME} /usr/include/eccodes /usr/include/eccodes
# COPY --from=cartopy --chown=${USERNAME} /usr/local /usr/local
# #
# ENV PATH="/opt/venv/bin:$PATH" \
#     PROJ_LIB="/usr/share/proj" \
#     ECCODES_DIR="/usr/include/eccodes" 
    
# CMD ["/bin/zsh"]
#
# docker build -t leaver/tf -f Dockerfile.tf . 
# docker run --rm -it --gpus all leaver/tf /bin/zsh