FROM pytorch/pytorch:latest

RUN apt-get update \ 
    && apt-get upgrade -y \
    && apt-get install -y git build-essential \
        python3 python3-pip gcc wget vim nano \
        ocl-icd-opencl-dev opencl-headers clinfo \
        libclblast-dev libopenblas-dev \
    && mkdir -p /etc/OpenCL/vendors && echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd

ENV CUDA_DOCKER_ARCH=all
ENV LLAMA_CUBLAS=1

# RUN python -m pip install -r requirements.txt
RUN CMAKE_ARGS="-DLLAMA_CUBLAS=on" FORCE_CMAKE=1 pip install llama-cpp-python