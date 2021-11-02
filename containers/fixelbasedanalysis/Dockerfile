FROM ubuntu:xenial-20210722

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bc \
        libtool \
        tar \
        dpkg \
        curl \
        wget \
        unzip \
        gcc \
        git \
        libstdc++6 \
        python \
        ca-certificates \
        libeigen3-dev \
        clang \
        zlib1g-dev \
        libqt4-opengl-dev \
        libgl1-mesa-dev \
        libopenblas-base

# Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users fba
WORKDIR /home/fba
ENV HOME="/home/fba"

# MRtrix3
# from https://hub.docker.com/r/neurology/mrtrix/dockerfile
RUN mkdir /mrtrix
RUN git clone https://github.com/MRtrix3/mrtrix3.git --branch 3.0.2 /mrtrix
WORKDIR /mrtrix
# Checkout version used in the lab: 20180128
# RUN git checkout f098f097ccbb3e5efbb8f5552f13e0997d161cce
ENV CXX=/usr/bin/clang++
RUN ./configure
RUN ./build
RUN ./set_path
ENV PATH=/mrtrix/bin:$PATH

WORKDIR /

# Copy command line script
COPY run_fba.sh /src/

RUN chmod +x /src/run_fba.sh

WORKDIR $HOME
ENTRYPOINT ["/src/run_fba.sh"]
