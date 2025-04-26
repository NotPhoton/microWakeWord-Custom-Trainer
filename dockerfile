# Use Ubuntu 20.04 as the base image
FROM ubuntu:20.04

# Set environment variables for non-interactive installations and Python buffering
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl git unzip software-properties-common build-essential \
    libsndfile1 libffi-dev python3-dev g++ cmake gnupg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Add deadsnakes PPA for Python 3.10
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y python3.10 python3.10-dev python3.10-distutils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install pip for Python 3.10
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# Add NVIDIA's CUDA repository and install CUDA 12.4 Toolkit
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin && \
    mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    wget https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda-repo-ubuntu2004-12-4-local_12.4.0-550.54.14-1_amd64.deb && \
    dpkg -i cuda-repo-ubuntu2004-12-4-local_12.4.0-550.54.14-1_amd64.deb && \
    cp /var/cuda-repo-ubuntu2004-12-4-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update -o Acquire::AllowInsecureRepositories=true -o Acquire::AllowDowngradeToInsecureRepositories=true && \
    apt-get -y --allow-unauthenticated install cuda-toolkit-12-4 && \
    apt-get -y --allow-unauthenticated install cuda-drivers && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* && \
    rm -f cuda-repo-ubuntu2004-12-4-local_12.4.0-550.54.14-1_amd64.deb

# Install CuDNN 9.3
RUN wget https://developer.download.nvidia.com/compute/cudnn/9.3.0/local_installers/cudnn-local-repo-ubuntu2004-9.3.0_1.0-1_amd64.deb && \
    dpkg -i cudnn-local-repo-ubuntu2004-9.3.0_1.0-1_amd64.deb && \
    cp /var/cudnn-local-repo-ubuntu2004-9.3.0/cudnn-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update -o Acquire::AllowInsecureRepositories=true -o Acquire::AllowDowngradeToInsecureRepositories=true && \
    apt-get -y --allow-unauthenticated install cudnn && \
    apt-get -y --allow-unauthenticated install cudnn-cuda-12 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* && \
    rm -f cudnn-local-repo-ubuntu2004-9.3.0_1.0-1_amd64.deb

# Install Python dependencies from requirements.txt
ADD https://raw.githubusercontent.com/stujenn/microWakeWord-Custom-Trainer/refs/heads/main/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Ensure numpy is installed for Python 3.10
RUN python3.10 -m pip install --no-cache-dir numpy==1.26.4

# Create a data directory for external mapping
RUN mkdir -p /data

# Copy the notebooks to a fallback location in the container
ADD https://raw.githubusercontent.com/stujenn/microWakeWord-Custom-Trainer/refs/heads/main/basic_training_notebook.ipynb /root/basic_training_notebook.ipynb
ADD https://raw.githubusercontent.com/stujenn/microWakeWord-Custom-Trainer/refs/heads/main/advanced_training_notebook.ipynb /root/advanced_training_notebook.ipynb

# Add the startup script from GitHub
ADD https://raw.githubusercontent.com/stujenn/microWakeWord-Custom-Trainer/refs/heads/main/startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Ensure /data is the default directory for Jupyter
WORKDIR /data

# Expose the Jupyter Notebook port
EXPOSE 8888

# Run the startup script and start Jupyter Notebook
CMD ["/bin/bash", "-c", "/usr/local/bin/startup.sh && jupyter notebook --ip=0.0.0.0 --no-browser --allow-root --NotebookApp.token='' --notebook-dir=/data"]
