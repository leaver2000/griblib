
# docker build -t leaver/rapidsai-runtime:1.0.0 -f Dockerfile.cudf . && docker run --gpus all --rm -it --shm-size=1g --ulimit memlock=-1 -p 8888:8888 -p 8787:8787 -p 8786:8786 leaver/rapidsai-runtime:1.0.0
# RUN= docker run --gpus all --rm -it --shm-size=1g --ulimit memlock=-1 -p 8888:8888 -p 8787:8787 -p 8786:8786 leaver/rapidsai-runtime:1.0.0
FROM rapidsai/rapidsai-core-nightly:22.08-cuda11.5-runtime-ubuntu20.04-py3.9 as base
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# create a new user
# CREDIT: https://github.com/deluan/zsh-in-docker/blob/master/Dockerfile
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo wget \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*


USER $USERNAME