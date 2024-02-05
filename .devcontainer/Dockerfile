# Download base image ubuntu 22.04
FROM ubuntu:22.04

# LABEL about the custom image
LABEL maintainer="dancioc@nus.edu.sg"
LABEL version="0.1"
LABEL description="This is a custom Docker Image for MECA EVM contracts"

# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive
# display
ENV DISPLAY=host.docker.internal:0.0
# timezone
ENV TZ=Asia/Singapore

# Update Ubuntu Software repository
# https://stackoverflow.com/questions/39760663/docker-ubuntu-bin-sh-1-locale-gen-not-found
# https://askubuntu.com/questions/162391/how-do-i-fix-my-locale-issue/229512#229512
# add etherum ppa
# install python/pip/cmake/solc
RUN apt-get update && apt upgrade -y && apt-get install -y locales && locale-gen "en_US.UTF-8" && dpkg-reconfigure locales && \
    apt-get install -y software-properties-common && apt-get update && \
    add-apt-repository ppa:ethereum/ethereum && apt-get update && \
    apt-get install -y curl zip unzip git cmake python3 python3-pip solc nodejs npm

# install python packages web3/py-solc-x
RUN pip3 install web3[tester] && pip install py-solc-x

# upddate node/npm
RUN npm install n -g && n stable