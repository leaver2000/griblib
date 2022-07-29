# docker build -t leaver/cuda -f Cudafile.tf . 
# docker run --rm --gpus all leaver/cuda nvidia-smi
# docker run --rm -it --gpus all leaver/cuda /bin/bash
FROM nvidia/cuda:11.7.0-runtime-ubuntu22.04 as library
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv

ENV PATH=/opt/venv/bin:$PATH

RUN python3 -m pip install --upgrade pip && pip install tensorflow-gpu