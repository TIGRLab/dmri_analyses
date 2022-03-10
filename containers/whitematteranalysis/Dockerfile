# Use Ubuntu 20.04 LTS
FROM ubuntu:focal-20210416

ARG DEBIAN_FRONTEND=noninteractive

# Prepare environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    autoconf \
                    build-essential \
                    bzip2 \
                    ca-certificates \
                    cmake \
                    curl \
                    cython3 \
                    gcc \
                    git \
                    libtool \
                    lsb-release \
                    pkg-config \
                    rsync \
                    xvfb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users wma
WORKDIR /home/wma
ENV HOME="/home/wma"

# Install and set up Miniconda
RUN curl -sSLO https://repo.anaconda.com/miniconda/Miniconda3-py38_4.9.2-Linux-x86_64.sh && \
    bash Miniconda3-py38_4.9.2-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda3-py38_4.9.2-Linux-x86_64.sh

# Set CPATH for packages relying on compiled libs
ENV PATH="/usr/local/miniconda/bin:$PATH" \
    CPATH="/usr/local/miniconda/include:$CPATH" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    PYTHONNOUSERSITE=1

# Install whitematteranalysis package
RUN pip install git+https://github.com/SlicerDMRI/whitematteranalysis.git@5131fe67a12a0a763e7a3cee50198f96ea915914

WORKDIR /src

# Download ORG White Matter Atlas
RUN wm_download_anatomically_curated_atlas.py -atlas ORG-800FC-100HCP . && \
    rm -rf /src/ORG-Atlases-1.2/__MACOSX
ENV ATLASDIR="/src/ORG-Atlases-1.2/ORG-800FC-100HCP"

# Install Slicer prerequisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    libglu1-mesa \
                    libxcb-xinerama0 \
                    libxcb-icccm4-dev \
                    libxcb-image0-dev \
                    libxcb-keysyms1-dev \
                    libxcb-randr0 \
                    libxcb-render-util0 \
                    libxcb-xkb-dev \
                    libxkbcommon-x11-dev \
                    libgl1-mesa-dri \
                    xserver-xorg-video-dummy \
                    xserver-xorg-input-void \
                    x11-xserver-utils \
                    xinit \
                    fonts-dejavu \
                    x11vnc \
                    websockify \
                    openbox \
                    tint2 \
                    xterm \
                    lxrandr \
                    nitrogen \
                    libpulse-dev \
                    libnss3 \
                    libasound2 && \
   apt-get clean && rm -f /usr/share/applications/x11vnc.desktop

# Download and install Slicer and SlicerDMRI
RUN curl -sSL https://slicer.kitware.com/midas3/download/bitstream/1023242 -o Slicer-4.10.2-linux-amd64.tar.gz && \
    tar -xzf Slicer-4.10.2-linux-amd64.tar.gz -C . && \
    rm -fr Slicer-4.10.2-linux-amd64.tar.gz
RUN curl -sSL https://slicer.kitware.com/midas3/download/bitstream/1339540 -o 28257-linux-amd64-SlicerDMRI-git15a914a-2020-08-05.tar.gz && \
    tar -xzf 28257-linux-amd64-SlicerDMRI-git15a914a-2020-08-05.tar.gz -C . && \
    rsync -r 28257-linux-amd64-SlicerDMRI-git15a914a-2020-08-05/ Slicer-4.10.2-linux-amd64/ && \
    rm -fr 28257-linux-amd64-SlicerDMRI-git15a914a-2020-08-05*

ENV SLICER="/src/Slicer-4.10.2-linux-amd64/Slicer" \
    SLICER_LIB="/src/Slicer-4.10.2-linux-amd64/lib" \
    SLICER_CLI="/src/Slicer-4.10.2-linux-amd64/lib/Slicer-4.10/cli-modules"

ENV LD_LIBRARY_PATH="${SLICER_LIB}/Slicer-4.10:${SLICER_CLI}:${SLICER_LIB}/Python/lib:${SLICER_LIB}/Slicer-4.10/qt-loadable-modules:${SLICER_LIB}/Teem-1.12.0:$LD_LIBRARY_PATH"

# Copy command line script
COPY run_wma.sh /src/

RUN chmod +x /src/run_wma.sh

WORKDIR $HOME
ENTRYPOINT ["/src/run_wma.sh"]
