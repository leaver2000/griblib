# nvidia:CUDA 
CUDA (or Compute Unified Device Architecture) is a parallel computing platform and application programming interface (API) that allows software to use certain types of graphics processing units (GPUs) for general purpose processing, an approach called general-purpose computing on GPUs (GPGPU). CUDA is a software layer that gives direct access to the GPU's virtual instruction set and parallel computational elements, for the execution of compute kernels.[1]

https://github.com/NVIDIA/nvidia-docker/blob/master/README.md#quickstart


``` yaml
HARDWARE:
- NVIDIA GPU
    HOST:
    - CUDA Driver 
    - Docker Engine
        CONTAINER:
            - CUDA Toolkit
```

## GPU support inside a container running from wsl

### HOST

- ensure the local machine has the correct drivers insalled
- display details about the devices gpu...
#### CUDA Driver
```powershell
PS C:\Users\leave> wmic path win32_VideoController get name
Name
Intel(R) UHD Graphics
NVIDIA GeForce GTX 1650
```
navigate to the [nvidia drivers](https://www.nvidia.com/Download/index.aspx?lang=en-us) and download and install the driver for your device

#### WSL2
need to update the remote image

https://docs.nvidia.com/cuda/wsl-user-guide/index.html#cuda-support-for-wsl2

``` bash
# pin
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
# download the linux installer
wget https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda-repo-wsl-ubuntu-11-7-local_11.7.0-1_amd64.deb
sudo dpkg -i cuda-repo-wsl-ubuntu-11-7-local_11.7.0-1_amd64.deb
sudo apt-get update
sudo apt-get -y install cuda
    # cuda \
    # nvidia-cuda-toolkit \
    # nvidia-container-runtime 
# verify
which nvidia-container-runtime-hook
# -> /usr/bin/nvidia-container-runtime-hook/usr/bin/nvidia-container-runtime-hook
nvcc -V
# nvcc: NVIDIA (R) Cuda compiler driver
# Copyright (c) 2005-2021 NVIDIA Corporation
# Built on Thu_Nov_18_09:45:30_PST_2021
# Cuda compilation tools, release 11.5, V11.5.119
# Build cuda_11.5.r11.5/compiler.30672275_0
lspci | grep -i nvidia
```

## Reboot the computer at this point


Dockerfile: nvidia-cuda-toolkit 

``` bash
RUN apt-get update -y \
    && add-apt-repository -y \
        ppa:graphics-drivers/ppa \
    && apt-get update -y  \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        nvidia-cuda-toolkit 
```

## build & run and attach to the container


``` bash
docker build -t leaver/gpu -f Dockerfile.test .
docker run -it --rm --gpus all leaver/gpu
docker run -it --rm --gpus all nvidia/cuda:11.7.0-base-ubuntu22.04
```

inorder to run a container with gpu support the local machine requires some libs 

```bash
$ sudo apt-get update 
$ sudo apt-get install nvidia-container-runtime
$ which nvidia-container-runtime-hook
/usr/bin/nvidia-container-runtime-hook
# looks promissing time to run run this image
$ docker run -it --rm --gpus all leaver/gpu
# crap, need to update wsl
docker: Error response from daemon: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: error running hook #0: error running hook: exit status 1, stdout: , stderr: Auto-detected mode as 'legacy'
nvidia-container-cli: initialization error: WSL environment detected but no adapters were found: unknown.
```



[libnvida](https://nvidia.github.io/libnvidia-container/)
## Dockerfile
```bash
RUN sudo add-apt-repository ppa:graphics-drivers/ppa --yes \
    && apt update \
    && apt install nvidia-driver-470
```


```bash 
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
```




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
    && python3 -c "import tensorflow as tf; print(tf.test.gpu_device_name())"
```

for wsl see...

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