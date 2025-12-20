# https://github.com/actions/runner/blob/main/images/Dockerfile
FROM ghcr.io/actions/actions-runner

RUN set -e; \
    sudo apt-get update; \
    sudo apt-get upgrade -y; \
    sudo apt-get install -y --no-install-recommends build-essential rsync; \
    curl -sLO https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb; \
    sudo dpkg -i cuda-keyring_1.0-1_all.deb; \
    rm cuda-keyring_1.0-1_all.deb; \
    sudo apt-get update; \
    sudo apt-get install -y cuda-toolkit-12-8; \
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash; \
    curl -sL https://aka.ms/downloadazcopy-v10-linux | sudo tar zxvf - -C /usr/local/bin --strip-components 1; \
    sudo sh -c "$(curl -sL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin; \
    sudo apt-get clean; \
    sudo rm -rf /var/lib/apt/lists/*;

ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
