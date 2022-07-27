# more research needed
[libnvida](https://nvidia.github.io/libnvidia-container/)

this need more testing
``` bash
FROM base as final
USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# installing cuda for gpu support
WORKDIR /tmp
RUN distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g'); \
        wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-$distribution.pin \
    && mv cuda-$distribution.pin /etc/apt/preferences.d/cuda-repository-pin-600 \
    && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/3bf863cc.pub \
    && echo "deb http://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64 /" | sudo tee /etc/apt/sources.list.d/cuda.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        cuda \
        cuda-drivers \
    && rm -rf /var/lib/apt/lists/*
    
# check cuda version
RUN nvcc -V

# check if gpu support is enabled
RUN python3 -m pip install tensorflow \
    && python3 -c "import tensorflow as tf; print(tf.test.gpu_device_name())""
```



for wsl see
[wsl-cuda](https://docs.nvidia.com/cuda/wsl-user-guide/index.html)
``` bash
# download the ubuntu pin
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin

sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
# download the cuda installer
wget https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda-repo-wsl-ubuntu-11-7-local_11.7.0-1_amd64.deb

# Save they key because we will swap it back after installing.
# sudo mv /usr/share/keyrings/cuda-archive-keyring.gpg \
#         /usr/share/keyrings/cuda-archive-keyring.gpg.bak

sudo cp /var/cuda-repo-wsl-ubuntu-11-7-local/cuda-B81839D3-keyring.gpg \
        /usr/share/keyrings/cuda-archive-keyring.gpg

# sudo dpkg -i cuda-keyring_1.0-1_all.deb

sudo dpkg -i cuda-repo-wsl-ubuntu-11-7-local_11.7.0-1_amd64.deb

sudo mv /usr/share/keyrings/cuda-archive-keyring.gpg.bak \
        /usr/share/keyrings/cuda-archive-keyring.gpg

sudo apt-get update
sudo apt-get -y install cuda
#
sudo apt install nvidia-cuda-toolkit
nvcc -V

python3 -m pip install --upgrade setuptools pip wheel
# You should now be able to install the nvidia-pyindex module.
python3 -m pip install nvidia-pyindex
```