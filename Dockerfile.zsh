# syntax=docker/dockerfile:1
# FROM tensorflow/tensorflow:2.9.1-gpu-jupyter as base
FROM tensorflow/tensorflow:nightly-gpu-jupyter as tensorflow

WORKDIR /tmp

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        zsh \
    && rm -rf /var/lib/apt/lists/*
        
COPY ./bin/zsh-setup ./zsh-setup 

RUN ./zsh-setup zsh || true

CMD ["zsh"]


    # && apt-get install -y zsh
# "apt-get", "install", "-y", "zsh
#         # pciutils \
#         # python
#         python3.10 \
#         python3.10-venv \
#         # lib-cuda-runtime
#         # libcudart11.0 \
#     && rm -rf /var/lib/apt/lists/*

# RUN python3.10 -m venv /opt/venv

# ENV PATH=/opt/venv/bin:$PATH

# RUN python -m pip install --upgrade pip \
#     && python -m pip install tensorflow
    
#######################################################################################################
#   stage |     HARDWARE     |      HOST     |     CONTAINER -> NVIDIA -> CUDA -> TENSORFLOW
# depends |  nvidia-device   | device-driver |
#######################################################################################################
# sudo docker run --gpus all nvcr.io/nvidia/k8s/cuda-sample:nbody nbody -gpu -benchmark

# NOTE:  On versions including and after 19.03, you will use the nvidia-container-toolkit package and the --gpus=all flag. 
# --------------------------------------------
# root ➜ / $ docker -v
# Docker version 20.10.17, build 100c701
# --------------------------------------------
# this is won't work with and old version of docker prior to 19.03




# wget https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_515.43.04_linux.run
# sudo sh cuda_11.7.0_515.43.04_linux.run


############################################### NVIDIA ###################################

# NOTE: inorder for the container to have access to the device GPU
#       the docker container must be run with the --gpus=all or --

# building and attaching to the image
# $ docker build -t leaver/cuda -f Dockerfile.cuda . && docker run --rm -it --gpus=all leaver/cuda


# root ➜ / $ nvidia-smi -L
# GPU 0: NVIDIA GeForce GTX 1650 (UUID: GPU-df34dcd8-0ae3-a720-e9b6-c9b84e3a16c2)


# root ➜ / $ nvidia-smi -l 1 
# Thu Jul 28 18:26:00 2022       
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 515.57       Driver Version: 516.59       CUDA Version: 11.7     |
# |-------------------------------+----------------------+----------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
# |                               |                      |               MIG M. |
# |===============================+======================+======================|
# |   0  NVIDIA GeForce ...  On   | 00000000:01:00.0 Off |                  N/A |
# | N/A   37C    P8     3W /  N/A |      0MiB /  4096MiB |      0%      Default |
# |                               |                      |                  N/A |
# +-------------------------------+----------------------+----------------------+





############################################# CUDA:nvcc ################################################################################

# nvcc, the CUDA compiler-driver tool that is installed with the CUDA toolkit, 
# will always report the CUDA runtime version that it was built to recognize. 
# It doesn't know anything about what driver version is installed, or even if a GPU driver is installed.




############################################################################### TENSORFLOW ###################################

# Both options are documented on the page linked above.

# verify cpu support

# root ➜ / $ python3 -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))"

# root ➜ / $ python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"

# root ➜ / $ python -c "import tensorflow as tf; print(tf.test.is_gpu_available(cuda_only=True))" 