
## Host
My local machine uses WSL2, for that the nvidia [cuda-toolkit:11.7](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=deb_network) was installed 

``` bash
PS C:\Users\Jason> wsl ~
leaver2000@inwin:~$
leaver2000@inwin:~$ wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
leaver2000@inwin:~$ sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
leaver2000@inwin:~$ sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/3bf863cc.pub
leaver2000@inwin:~$ sudo cp /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d
leaver2000@inwin:~$ sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/ /"
leaver2000@inwin:~$ sudo apt-get update
leaver2000@inwin:~$ sudo apt-get -y install cuda
```
## NVIDIA System Management Interface

Verify the the install by listing the gpu with the nvidia-smi command

``` bash
leaver2000@inwin:~$ nvidia-smi -L
GPU 0: NVIDIA GeForce RTX 2080 SUPER (UUID: GPU-c48cf337-ce97-5770-4aa3-d4993336ef78)
```



## reboot docker

Next pull the cuda base ubuntu22.04 from the nvidia container registry

``` bash
leaver2000@inwin:~$ docker pull nvcr.io/nvidia/cuda:11.7.0-base-ubuntu22.04
leaver2000@inwin:~$ docker run -it --rm --gpus all nvcr.io/nvidia/cuda:11.7.0-base-ubuntu22.04
root@83dead440c2d:/# nvidia-smi -L
GPU 0: NVIDIA GeForce RTX 2080 SUPER (UUID: GPU-c48cf337-ce97-5770-4aa3-d4993336ef78)
```
https://developer.nvidia.com/cudnn

### install [NVIDIA cuDNN](https://developer.nvidia.com/cudnn)
NVIDIA CUDA® Deep Neural Network library (cuDNN)

check the [support-matrix]((https://docs.nvidia.com/deeplearning/cudnn/support-matrix/index.html))

Optional: for wsl it may be helpful to have access to nvidia-cuda-toolkit

``` bash
sudo apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update

leaver2000@inwin:~$ sudo apt install nvidia-cuda-toolkit
leaver2000@inwin:~$ nvcc --version
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2021 NVIDIA Corporation
Built on Thu_Nov_18_09:45:30_PST_2021
Cuda compilation tools, release 11.5, V11.5.119
Build cuda_11.5.r11.5/compiler.30672275_0
```


``` bash
root@83dead440c2d:/# apt-get update -y && apt-get install -y  zlib1g
```


apt install build-essential

<!-- now from inside the container https://gist.github.com/amir-saniyan/b3d8e06145a8569c0d0e030af6d60bea

``` bash
apt update & apt full-upgrade
apt install nvidia-driver-510 nvidia-dkms-510
``` -->